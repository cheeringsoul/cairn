# Conversation Context Loading

> How Cairn assembles the context it feeds the LLM on every turn.
> Covers: system prompt composition, history strategy, tool definitions, streaming commit.

---

## 1. Overview

Each `sendMessage` call composes the request from three parts before handing it to the provider:

```
┌──────────────── system prompt ────────────────┐   ┌─── messages ───┐   ┌── tools ──┐
│ aboutMe + persona + recall + cairn-meta instr │ + │  history list  │ + │  enabled  │
└───────────────────────────────────────────────┘   └────────────────┘   └───────────┘
```

The entry point is `ChatProvider.sendMessage`. Once assembled it is passed to
`StreamingChatMixin.streamAndCommit`, which runs the multi-round streaming call
(including any tool turns) and writes the reply back to SQLite.

Key files:

- `lib/services/chat_provider.dart` — entry, system prompt composition, auto-archive
- `lib/services/streaming_chat_mixin.dart` — history window, stream handling, tool loop, error fallback
- `lib/services/llm/anthropic_provider.dart` / `openai_provider.dart` — provider adapters
- `lib/services/library_provider.dart` — cross-conversation vector recall
- `lib/services/cairn_meta.dart` — instruction block that makes the model emit archivable metadata
- `lib/services/constants.dart` — window thresholds for the no-embedding fallback

---

## 2. Data Model

Drift / SQLite. Three relevant tables (`lib/services/db/database.dart`):

| Table           | Key fields                                                         | Notes                                         |
|-----------------|--------------------------------------------------------------------|-----------------------------------------------|
| `Conversations` | `personaId`, `providerId`, `model`, `systemPrompt?`, `kind`        | Conversation-level config; model is locked in at creation |
| `Messages`      | `conversationId`, `role`, `content`, `createdAt`                   | Plain text only; no attachment structure      |
| `Personas`      | `name`, `instruction`, `icon`, `sortOrder`                         | Reusable system-prompt templates              |

Note: `Messages.content` stores only the final text. Intermediate tool-call
messages live in memory for the duration of the turn and never hit the DB.

---

## 3. System Prompt Composition

`ChatProvider._buildSystemPrompt` (`chat_provider.dart:503-527`) concatenates, in order:

1. **About Me** — free-form self-description the user writes in settings; shapes tone / preferences.
2. **Persona instruction** — the active persona's instruction; falls back to the default persona when none is selected.
3. **Recall context** — cross-conversation knowledge retrieved via embeddings,
   rendered as a markdown bullet list by
   `LibraryProvider.formatRecallContext` (`library_provider.dart:853-870`). Top 5.
4. **`cairnMetaSystemInstruction`** (`cairn_meta.dart:140-156`) — asks the model to
   append a parseable metadata block (entity, type, tags, `reviewable`, …) at the
   end of the reply so the app can auto-archive.

Call site: `chat_provider.dart:325-327`. Only `recallContext` is passed in — the
other parts are read from injected providers directly.

---

## 4. Recall

`chat_provider.dart:322-324` runs recall in parallel with the user-message DB insert:

```dart
final recallFuture = _library.recallRelated(trimmed); // network ~100-300ms
await _db.into(_db.messages).insert(userMsg);          // local ~1ms
final recalled = await recallFuture;
```

The parallelism hides the 100–300 ms embedding round-trip behind the DB write.
If **none** of the user's configured providers supports embeddings, recall
silently returns empty and the turn continues under the "no-embedding fallback"
described in §5.

---

## 5. History Strategy

The branch point is in `StreamingChatMixin.streamAndCommit`
(`lib/services/streaming_chat_mixin.dart:166-171`):

```dart
final persisted = msgs.take(msgs.length - 1).toList(); // drop the placeholder draft
var history = hasEmbeddingFallback
    ? persisted.map((m) => LlmMessage(role: m.role, content: m.content)).toList()
    : await _buildUserOnlyHistory(persisted, adapter, model);
```

### 5a. With embedding (default path)

The whole transcript is sent verbatim (user + assistant turns preserved). Window
pressure is borne by the provider's context window; cross-conversation
reinforcement comes from recall.

### 5b. No-embedding fallback

`_buildUserOnlyHistory` (`streaming_chat_mixin.dart:403-432`) takes a more conservative tack:

1. **Keep only user messages** — assistant turns are dropped; the intent trail
   lives entirely in the user's own questions.
2. Thresholds in `NoEmbedContext` (`constants.dart:97-102`):
   - `compressChars = 40000` — total user-question length above which compression kicks in
   - `keepRecentTurns = 10` — most recent N user messages kept verbatim
   - `warnChars = 32000` — beyond this the UI nudges the user to start a new
     conversation (`chat_provider.dart:119-127`)
3. Older questions go through `_summarizeOlder` (`streaming_chat_mixin.dart:434-468`)
   for a secondary ≤200-word LLM summary. If that call fails, a naive 2000-char
   truncation is used as a last resort.

---

## 6. Tool Definitions

`streaming_chat_mixin.dart:152-154`:

```dart
final toolDefs = toolRegistry != null && enabledToolNames != null
    ? toolRegistry.definitionsFor(enabledToolNames)
    : <ToolDefinition>[];
```

The enabled set is resolved by `SettingsProvider.enabledToolNames` (user
toggles + per-tool defaults). The tool loop caps at `maxToolRounds = 5`
(`streaming_chat_mixin.dart:176`) to prevent infinite loops.

Per-round tool outcomes:
- Appended to in-memory `history` as `role: 'tool'`. **Not persisted**.
- If a tool result's JSON contains an `action_links` field, the links are
  rendered as markdown buttons appended after the final reply text
  (`streaming_chat_mixin.dart:252-277, 307-319`).

---

## 7. Provider Adapters — the Egress Points

| Provider  | File                                             | Notable differences                                          |
|-----------|--------------------------------------------------|--------------------------------------------------------------|
| Anthropic | `lib/services/llm/anthropic_provider.dart:22-49` | System is a top-level field; `max_tokens=4096` hardcoded     |
| OpenAI    | `lib/services/llm/openai_provider.dart:17-54`    | System is a `role: 'system'` message; tools use function-call format |

Both adapters stream via SSE and normalize events into `TextDelta` /
`ToolCallDelta` (`StreamEvent` subtypes). The mixin above them is provider-agnostic.

---

## 8. Streaming & Persistence

The listener loop in `streaming_chat_mixin.dart:188-227`:

- `TextDelta` → append to `StringBuffer`, update the in-memory draft message, trigger UI refresh.
- `ToolCallDelta` → collect into `pendingToolCalls`; executed in batch after `onDone` for the round.

Persistence path (`streaming_chat_mixin.dart:290-335`):

- Empty final text (e.g. every tool round failed) → drop the draft; don't
  pollute the next turn's history.
- Non-empty → insert into `Messages`; update the conversation's `updatedAt`.
- On error (`LlmException` or otherwise) → `_commitPartialOnError`
  (`streaming_chat_mixin.dart:364-399`) saves whatever was already streamed so
  the user keeps the partial text they saw.

After commit, `chat_provider.dart:380-389` parses cairn-meta. When `reviewable:
true` the reply is asynchronously written to the knowledge pool
(`in_library=false`) for future embedding recall.

---

## 9. Cancellation & Concurrency

Each `sendMessage` owns an `_activeCancelToken`. When the user aborts:

- The UI immediately flips `sending=false`. All callbacks guard with
  `token.isCancelled` so the in-flight partial commit doesn't clobber state
  that a subsequent turn may already own (`chat_provider.dart:352-373`).
- The background task still commits whatever text has streamed so far
  (partial commit). The user never loses content they already saw.

---

## 10. Quick Reference

| Concern                        | File : lines                                             |
|--------------------------------|----------------------------------------------------------|
| Entry                          | `chat_provider.dart:300-373`                             |
| System prompt composition      | `chat_provider.dart:503-527`                             |
| Recall concurrency             | `chat_provider.dart:322-324`                             |
| Recall formatting              | `library_provider.dart:853-870`                          |
| cairn-meta instruction         | `cairn_meta.dart:140-156`                                |
| History-window branch          | `streaming_chat_mixin.dart:166-171`                      |
| No-embedding compression       | `streaming_chat_mixin.dart:403-468`                      |
| Threshold constants            | `constants.dart:97-102`                                  |
| Tool loop                      | `streaming_chat_mixin.dart:176-288`                      |
| Egress (Anthropic)             | `llm/anthropic_provider.dart:22-49`                      |
| Egress (OpenAI)                | `llm/openai_provider.dart:17-54`                         |
| Partial-commit on error        | `streaming_chat_mixin.dart:364-399`                      |
| Auto-archive                   | `chat_provider.dart:380-389`                             |
