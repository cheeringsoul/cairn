# Product Features

> The functionality that sets Cairn apart from other LLM clients.
> Implementation details are spread across [`architecture.md`](./architecture.md), [`embeddings.md`](./embeddings.md), and [`context_loading.md`](./context_loading.md).

Cairn isn't positioned as yet another chat frontend — it's a tool that turns
"conversations with an LLM" into a **long-lived personal knowledge base**.
The features below are ordered roughly from "what you'll notice on day one" to "what keeps you coming back."

---

## 1. Cross-Conversation Semantic Recall (flagship)

On every message, Cairn embeds your question, searches the whole knowledge
base for the five most semantically related items, and injects them into the
system prompt. The result:

> You discussed SwiftUI state management three months ago in another chat.
> Today you bring up something related, and the model picks up where you left
> off instead of starting from scratch.

- Recall is **cross-conversation** — no need to remember which conversation a given snippet lived in.
- Retrieved items are injected into the **system prompt explicitly**, not into the user message itself (keeps the "useful" part of the window intact).
- The index is **fully local**. Vectors are computed by the embedding API and stored in local SQLite; the server side never sees your knowledge base.

See [`embeddings.md`](./embeddings.md) for the full pipeline.

---

## 2. Dual Knowledge Pools (auto-captured + curated)

`SavedItems.in_library` splits the pool in two:

| `in_library` | Source | Shown in UI | Participates in recall | Enters review queue |
|:--:|--------|:--:|:--:|:--:|
| `false` | auto-archived from model replies | hidden | ✅ | ✗ |
| `true`  | user saved / shared / imported | visible | ✅ | ✅ |

**Key design**: auto-archiving is silent by default — it doesn't crowd the
Library list, doesn't pile into the review queue, and just quietly serves as
recall material. That lets the model be aggressive about marking things
"worth keeping" without making the Library unmanageable. If a user later
decides an auto-captured item is worth keeping, they can promote it to the
Library.

---

## 3. cairn-meta: the Model Writes its own Metadata

Every system prompt carries the instruction block from
[`cairn_meta.dart`](../lib/services/cairn_meta.dart), which tells the model to
append a structured block at the end of its reply:

```yaml
<cairn-meta>
type: insight
entity: Quantum tunneling
tags: [physics, quantum-mechanics]
summary: Particles have a nonzero probability of crossing a barrier that classical mechanics would forbid.
reviewable: true
</cairn-meta>
```

After parsing:
- `reviewable: true` → auto-archived to the knowledge pool (`in_library=false`)
- `entity / tags / summary` → reused downstream for recall ranking, Library browsing, review cards — no post-hoc summarization pass needed

This folds "answering the question" and "curating the answer" into a single
token stream, removing the latency and cost of a follow-up LLM call to
summarize.

---

## 4. Any Provider, Hot-Swappable

16 built-in provider templates (`settings_provider.dart:75-179`):

- **International**: OpenAI, Anthropic, Google Gemini, Mistral, Groq, xAI Grok
- **Chinese**: DeepSeek, Qwen (通义千问), Zhipu (智谱), Moonshot (Kimi), Doubao (豆包), MiniMax, Baichuan (百川), StepFun (阶跃星辰), SiliconFlow
- **Custom**: any OpenAI-compatible endpoint (including local reverse proxies)

Each conversation chooses its own provider and model. Multiple providers can
coexist — e.g., Anthropic for chat, OpenAI for embeddings, Qwen for explain
sessions.

**API keys live in the OS Keychain.** The DB stores only the last 4 chars for
UI display.

---

## 5. Tool System (function-calling)

The model can invoke tools mid-reply. 16 ship built-in, grouped by domain:

| Category | Tools |
|----------|-------|
| Device | `location`, `open_maps`, `find_nearby`, `call_taxi`, `set_reminder`, `add_calendar_event` |
| Web | `app_search`, `web_search`, `crypto_price`, `weather` |
| Library | `get_stats`, `get_tag_distribution`, `get_tag_trend`, `get_recent`, `get_by_tag`, `sample_random`, `get_note_detail` |

Registration: `lib/services/tools/builtin_tools.dart`. Toggles in settings,
per-tool granularity.

Notable behaviors:
- Tool results can carry an `action_links` field (label + url) that renders as **markdown buttons** appended to the reply (e.g., a navigation tool returns an "Open Maps" button).
- Tool loop caps at **5 rounds** to prevent runaway cycles.
- Intermediate tool messages are **not persisted** — they live in memory for the turn and don't pollute history on the next send.

---

## 6. FSRS Spaced Repetition

Library items (`in_library=true`) automatically enroll in a review queue,
backed by a simplified FSRS scheduler (`review_provider.dart`):

- Each item tracks `stability` (days) + `difficulty` (0–1) + `nextReviewAt`.
- Grading (forgot / hard / good / easy) drives the next-interval calculation.
- **Per-type policies**: vocab never graduates (always reviewable); "insights" graduate after 5 reviews and stop showing.
- Entry point in the UI shows the count of due items; a periodic inactivity hint appears when the app has been idle.

All scheduling is local; no cloud sync.

---

## 7. Robustness / Control Flow

Common annoyances during sending have been smoothed out:

- **Abort mid-reply**: pressing stop during streaming keeps whatever text has already arrived as the final message; nothing lost.
- **Retry failed sends**: when a reply errors out, a retry button appears on the last user message; it reruns the exact same pipeline (recall / tools / streaming included).
- **Queued sends**: if you type a follow-up before the previous one finishes, Cairn queues and flushes in order.
- **Partial commit on disconnect**: if the network drops mid-stream, whatever was already streamed is still committed — reopening the conversation doesn't show a blank reply.

See [`context_loading.md`](./context_loading.md) §9.

---

## 8. Explain Sessions (dictionary mode)

Selecting a word or short phrase triggers an "explain session" — a lightweight
conversation separate from the main chat, scoped to explaining that one item.

- Automatically brings in surrounding context (what you were reading).
- Auto-clears after 7 days without references (`cleanupStaleExplainSessions`).
- The explanation can be "promoted" to a SavedItem to land in the Library.

---

## 9. Full-Text Search

Conversations and messages both maintain FTS5 indexes:
- Search conversations by title.
- Search messages by content; results include snippets and the matched message IDs (click to jump directly to that position in the conversation).

---

## 10. Multi-Platform

| Platform | Status |
|----------|--------|
| iOS / Android | primary targets |
| macOS | multi-pane desktop shell (`MacDesktopShell`); DMG build script under `scripts/` |
| Windows / Linux | theoretically buildable; not officially distributed |

---

## 11. Localization

`lib/l10n/` ships three locales:
- `app_en.arb` — English
- `app_zh.arb` — Simplified Chinese
- `app_zh_Hant.arb` — Traditional Chinese

Toggle in settings; can follow the system locale.

---

## 12. Offline E↔C Dictionary

Bundled with a trimmed ECDICT (generated by `tools/trim_ecdict.py`). The
explain mode can look up English words without a network connection.

---

## 13. Usage Tracking

`UsageRecords` logs every LLM call's token count. Aggregations by provider ×
model × kind (chat / explain / analyze / embedding) power the usage panel in
settings — useful for estimating monthly cost.

---

## 14. Data Locality

- All data in local SQLite (Drift).
- API keys in the OS Keychain.
- No first-party server, no telemetry.
- The only network traffic is to whichever LLM provider(s) the user configures.

For readers concerned about where their data travels, [`context_loading.md`](./context_loading.md) enumerates every byte that leaves the device.

---

## What Cairn Is Not

To avoid mismatched expectations, here's what Cairn deliberately **doesn't** do:

- ❌ No ambient web search (only through the explicit `web_search` tool).
- ❌ No multi-device sync — it's single-device today.
- ❌ No collaboration / multi-user sharing.
- ❌ No filesystem or shell access — it's not a Claude Code–style agent.
- ❌ No auto prompt-engineering or chain-of-thought wrappers — the abstraction stays thin.
