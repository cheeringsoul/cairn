# Architecture Overview

> A guided tour of Cairn's overall structure, dependency graph, and navigation layers.
> Subsystem details live in [`features.md`](./features.md), [`embeddings.md`](./embeddings.md), and [`context_loading.md`](./context_loading.md).

---

## 1. Stack

| Layer | Choice |
|-------|--------|
| UI | Flutter (iOS / Android / macOS / Windows / Linux) |
| State | `provider` (v6.x) + `ChangeNotifier` |
| Local storage | Drift (SQLite) with FTS5 full-text search |
| Secrets | `flutter_secure_storage` (iOS Keychain / Android Keystore / macOS Keychain) |
| Networking | `dart:io` + `http`, SSE streaming |
| i18n | `flutter_localizations` + `.arb` files (en / zh / zh_Hant) |

The LLM layer is a **hand-rolled thin adapter** — no LangChain-style SDK
dependency. Each provider speaks HTTP directly, which makes streaming quirks
and tool-protocol differences easy to control precisely.

---

## 2. Folder Layout

```
lib/
├── main.dart                  # entry point, dependency graph, root gate
├── pages/                     # 14 top-level pages (chat / library / profile / ...)
├── widgets/                   # shared UI components (message bubbles, etc.)
├── l10n/                      # ARB translation files + generated dart
└── services/
    ├── chat_provider.dart        # conversation state, send orchestration
    ├── streaming_chat_mixin.dart # streaming + tool loop + history window
    ├── library_provider.dart     # knowledge base + recall
    ├── settings_provider.dart    # settings, provider list, keys
    ├── persona_provider.dart     # persona templates
    ├── review_provider.dart      # FSRS spaced repetition
    ├── cairn_meta.dart           # model-readable metadata protocol
    ├── constants.dart            # global thresholds (window / embedding / FSRS)
    ├── db/                       # Drift schema + migrations
    ├── llm/                      # provider adapters (anthropic / openai-compatible)
    ├── embedding/                # vector service, health monitor, fanout queue, codec
    └── tools/                    # built-in tools (device / web / library)
```

`pages/` hosts page-level containers; UI reads state through `provider` from
the `services/*Provider` classes. Code under `services/` depends on no Flutter
UI types — it could, in principle, be lifted into a CLI or test harness.

---

## 3. Dependency Graph (boot order)

`main.dart:47-126` declares the dependency order explicitly via `MultiProvider`.
Understanding this graph helps when debugging startup:

```
AppDatabase                              ← must come first; everyone depends on it
   ↓
EmbeddingService (stateless HTTP)         ← used by SettingsProvider.addProvider to probe capabilities
   ↓
EmbeddingHealthMonitor                    ← depends on EmbeddingService
   ↓
SettingsProvider  ← load() reads from DB  ← gate the UI on its `loaded` flag
   ↓
EmbeddingFanoutQueue (start)              ← depends on DB + Service + Monitor; attached back to Settings
   ↓
PersonaProvider, LibraryProvider          ← LibraryProvider takes Settings + the embedding trio above
   ↓
ChatProvider                              ← injected with Library / Persona / built-in tool registry
   ↓
ReviewProvider, ThemeProvider             ← standalone
```

`SettingsProvider.embeddingFanoutQueue = queue` at `main.dart:93` is a
reverse-attach: it lets `addProvider()` trigger `backfillProvider()` when a
newly added provider turns out to be embedding-capable.

---

## 4. Boot & Routing

```
main()
  ├── WidgetsFlutterBinding.ensureInitialized()
  ├── NotificationService.init()         # notification permission + channel
  ├── DictProvider.ensureLoaded()        # unzip the offline E↔C dictionary in the background
  └── runApp(CairnApp)
        └── _RootGate
              ├── wait for SettingsProvider.loaded
              ├── !onboardingDone → OnboardingPage
              └── onboardingDone   → _MainShell
                    ├── macOS  → MacDesktopShell (multi-pane)
                    └── mobile → ChatPage (single-pane + drawer)
```

Desktop and mobile get different shells:
- `MacDesktopShell` is a multi-pane layout where conversations, messages, and the Library can all be visible at once.
- `ChatPage` (mobile) is a single navigator stack; Library / Settings / Review are reached via ProfilePage.

On macOS, the onboarding → main transition resizes the native window via
`MethodChannel('cairn/window')` (onboarding uses a narrow window; the main
shell uses a wide one).

---

## 5. Settings & Persistence

`SettingsProvider` manages all user-level configuration:

| Data | Storage | Notes |
|------|---------|-------|
| About Me, display name, locale, default provider/model, tool toggles, explain template, HTTP proxy | `app_settings` table (kv) | keyed by the `SettingsKeys` constants |
| Provider metadata (kind, baseUrl, model name, embedding capability, backfill timestamp) | `provider_configs` table | no secrets stored; only the last 4 chars of the key are kept for UI display |
| **API key** | OS Keychain (`flutter_secure_storage`) | the DB never holds plaintext |

When a provider is added (`SettingsProvider.addProvider`):
1. Write a `provider_configs` row (embeddingCapability='unknown').
2. Immediately call `EmbeddingService.probe()` (two-layer HTTP → LLM fallback).
3. If the probe returns `'yes'`, trigger `EmbeddingFanoutQueue.backfillProvider(id)` in the background to fill in historical vectors.
4. When backfill completes, `embeddingBackfilledAt` is set and the provider joins the query pool.

---

## 6. Data Model at a Glance

Full schema: `lib/services/db/database.dart`. Tables fall into four groups:

**Conversation surface**
- `Conversations` — conversation metadata (personaId / providerId / model / kind)
- `Messages` — plain-text messages (role + content + createdAt)
- `Personas` — reusable system-prompt templates

**Knowledge surface**
- `SavedItems` — knowledge items (see `embeddings.md` §SavedItem schema)
- `ItemTags` — normalized tag index (`saved_items.tags` JSON is a denormalized mirror)
- `Folders` — user groupings
- `ItemEmbeddings` — vector rows, primary key `(itemId, model)`; details in `embeddings.md`

**Provider surface**
- `ProviderConfigs` — list of configured providers

**Misc**
- `AppSettings` — kv configuration
- `UsageRecords` — per-call token counts (chat / explain / analyze / embedding)

Current `schemaVersion = 16`. Migrations are chained idempotently in
`database.dart:269+`; new columns / tables never break an existing database.

---

## 7. LLM Adapter Layer

Two adapters in `lib/services/llm/`:

| File | Protocol | Applies to |
|------|----------|------------|
| `anthropic_provider.dart` | Anthropic Messages API | `kind='anthropic'` |
| `openai_provider.dart` | OpenAI ChatCompletions (SSE + tool_calls) | everyone else (14 official kinds + custom) |

`ProviderFactory.buildProvider(provider)` dispatches by `kind`.
**Every non-Anthropic provider speaks OpenAI protocol** — the major Chinese
vendors (DeepSeek / Qwen / Zhipu / Moonshot / Doubao / MiniMax / Baichuan /
StepFun / SiliconFlow) plus Mistral / Groq / Grok / Gemini all expose
OpenAI-compatible endpoints at their base URLs, so one adapter covers them all.

The adapter is pure protocol translation: it marshals the unified
`LlmMessage` / `ToolDefinition` into vendor JSON and normalizes SSE events into
`TextDelta` / `ToolCallDelta`. The upstream `streaming_chat_mixin.dart` does
not know which vendor is talking.

---

## 8. Platform Glue

| Capability | Package | Platforms |
|------------|---------|-----------|
| Secrets | `flutter_secure_storage` | iOS / macOS / Android |
| Image picker | `image_picker` | mobile |
| Share intents | `receive_sharing_intent` | iOS / Android |
| Geolocation | `geolocator` | iOS / Android (used by a tool) |
| Calendar | `device_calendar` | iOS / Android (used by a tool) |
| Notifications | `flutter_local_notifications` | all |
| Window control | `MethodChannel('cairn/window')` custom | macOS |

Desktop support is currently polished for macOS (see `scripts/build_macos_dmg.sh`).
Windows/Linux builds are feasible but not officially distributed.

---

## 9. End-to-End Send Flow

```
user types
  ↓ ChatProvider.sendMessage
  ├── DB insert user message         (in parallel)
  ├── LibraryProvider.recallRelated  (in parallel, ~100-300ms network)
  ↓
  compose system prompt: aboutMe + persona + recall + cairn-meta
  ↓
  StreamingChatMixin.streamAndCommit
  ├── history strategy (branch on hasEmbeddingFallback)
  ├── tool definitions (user-enabled set)
  ↓
  Provider.streamChat (SSE)
  ↓
  stream chunks → update in-memory draft → notifyListeners → UI refresh
  ↓
  no tool calls → commit assistant message to DB
  tool calls    → execute → append results to history → restream → ... (≤5 rounds)
  ↓
  parse cairn-meta; if reviewable, async archive (in_library=false)
  ↓
  EmbeddingFanoutQueue picks up the new SavedItem on its next tick and fills in vectors
```

See [`context_loading.md`](./context_loading.md) for a line-by-line breakdown.

---

## 10. Quick Reference

| Concern | File |
|---------|------|
| Entry & dependency graph | `lib/main.dart` |
| Schema | `lib/services/db/database.dart` |
| Conversation orchestration | `lib/services/chat_provider.dart` |
| Streaming + tool loop | `lib/services/streaming_chat_mixin.dart` |
| Library + recall | `lib/services/library_provider.dart` |
| Provider catalog | `lib/services/settings_provider.dart` (`ProviderKinds.catalog`) |
| LLM adapters | `lib/services/llm/anthropic_provider.dart`, `openai_provider.dart` |
| Vector subsystem | `lib/services/embedding/*` |
| Global thresholds | `lib/services/constants.dart` |
| Built-in tool registry | `lib/services/tools/builtin_tools.dart` |
