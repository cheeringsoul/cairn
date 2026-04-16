# Vector Construction & Recall

> Design notes for Cairn's embedding subsystem: model selection, when vectors are computed, how they're stored, and how recall finds them.
> User-facing behavior: [`features.md`](./features.md) §1. Call-site timing: [`context_loading.md`](./context_loading.md).

---

## 0. One-Line Summary

Each SavedItem is asynchronously embedded by every capable provider in the
background, stored as a little-endian float32 blob. At query time the fastest
healthy provider embeds the user's message, and **dot-product ranking runs in
Dart memory** to return the top 5.

---

## 1. Overview

```
┌──────────────────────────────────────────────────────────────────────┐
│                       Embedding subsystem                            │
│                                                                      │
│   ┌──────────────────┐                                               │
│   │ EmbeddingService │  stateless HTTP client wrapping /embeddings   │
│   └─────────┬────────┘                                               │
│             │                                                        │
│   ┌─────────┴───────────┐    ┌───────────────────────────┐           │
│   │ HealthMonitor       │    │ FanoutQueue               │           │
│   │ - 10 min probe loop │    │ - 5s tick drains pending  │           │
│   │ - rolling p-latency │    │ - multi-provider fanout   │           │
│   │ - short quarantine  │    │ - backfill for new prov.  │           │
│   │ - ASC by latency    │    │                           │           │
│   └─────────┬───────────┘    └────────────┬──────────────┘           │
│             │                              │                         │
│             ↓                              ↓                         │
│   ┌──────────────────────────────────────────────────────┐           │
│   │       SQLite (Drift)                                  │           │
│   │   ┌─────────────┐   ┌──────────────────┐              │           │
│   │   │ saved_items │←──│ item_embeddings  │  (item,model) │          │
│   │   │             │   │ vector: blob     │              │           │
│   │   └─────────────┘   └──────────────────┘              │           │
│   └──────────────────────────────────────────────────────┘           │
└──────────────────────────────────────────────────────────────────────┘
```

Four core modules:
- `EmbeddingService` — protocol layer: calls `/embeddings`, performs capability probing.
- `EmbeddingHealthMonitor` — scheduler: decides which provider each call goes through.
- `EmbeddingFanoutQueue` — write side: computes vectors for new items.
- `LibraryProvider.recall*` — read side: turns a user message into a vector and ranks results.

---

## 2. Providers & Models

### Default model map

`EmbeddingService.defaultEmbeddingModels` (`lib/services/embedding/service.dart`)
holds the **provider → embedding model** mapping. Current built-ins:

| Provider | Default embedding model |
|----------|-------------------------|
| openai | `text-embedding-3-small` |
| qwen | `text-embedding-v3` |
| gemini | `text-embedding-004` |
| zhipu | `embedding-2` |
| mistral | `mistral-embed` |
| doubao | (vendor default) |
| minimax | (vendor default) |
| siliconflow | (vendor default) |

Providers explicitly **lacking** embedding (chat-only):
Anthropic, DeepSeek, Moonshot, Baichuan, StepFun, Groq, Grok.
`probe()` short-circuits to `'no'` for these kinds without firing a request.

### Capability probing (at addProvider time)

`EmbeddingService.probe()` has a two-layer fallback:

1. **HTTP probe**: POST `{baseUrl}/embeddings` with the default model name + `"hello"`.
   - 200 → `'yes'`; record model name + probe latency
   - 401/403 → `'unknown'` (wrong key — don't conclude yet)
   - 429 → `'rate_limited'` (transient; retry on the next probe)
   - Other 4xx / 404 → fall through to layer 2
2. **LLM fallback**: ask the provider's chat endpoint "do you support embeddings?"
   with a strict-JSON response format. This layer is designed for
   OpenAI-compatible proxies where the model name might be custom.

The result is persisted to `provider_configs.embedding_capability` +
`embedding_model`.

---

## 3. When Vectors Are Computed

### 3.1 Write trigger

A newly inserted `SavedItem` carries `embedding_status = 'pending'` and is
**not embedded synchronously** — the background fanout queue picks it up.

Rationale:
- Saving knowledge should feel instantaneous; network latency shouldn't block it.
- A single item is embedded by multiple providers in turn; serializing makes no sense.
- Failures must not affect the main flow (chat can't stall because an embedding API hiccupped).

### 3.2 Catch-up tick

`EmbeddingFanoutQueue.start()` (`lib/services/embedding/fanout_queue.dart`)
kicks off a **5-second** periodic timer:

```
every 5 seconds:
  1. SELECT * FROM saved_items WHERE embedding_status='pending' LIMIT 10
  2. load all currently-capable providers
  3. for each item: Future.wait across every capable provider's /embeddings
  4. each success → INSERT into item_embeddings (itemId, model, providerId, vector)
  5. when an item has vectors from every currently-capable provider → flip to 'ready'
  6. any failure → HealthMonitor.recordFailure (short quarantine)
```

Concurrency is only "multi-provider per item" (usually 1–5 in flight at once).
There's no cross-item worker pool — at the expected knowledge-base size
(low thousands of items) it isn't needed.

### 3.3 Backfill (newly added provider)

When the user adds a capable provider mid-session:

```
SettingsProvider.addProvider
  → probe() returns 'yes'
  → embeddingFanoutQueue.backfillProvider(providerId)
        ↓
        walk the full saved_items table
        dispatch /embeddings with concurrency = 5 (FanoutLimits.backfillConcurrency)
        completion → set provider_configs.embedding_backfilled_at = now
```

**Only after backfill completes** does this provider join the query pool —
HealthMonitor uses `embeddingBackfilledAt != null` as its admit condition.
Otherwise you'd get "half the vectors are missing but the provider is already serving recall" inconsistency.

---

## 4. What Gets Embedded

### 4.1 Input composition

`EmbeddingInputComposer.compose(item)` (`lib/services/embedding/input_composer.dart:13-29`)
stacks fields **densest first**:

```
{title}
Entity: {entity}        ← if present
Summary: {summary}      ← if present
                        ← blank line
{body}
```

Truncated to `EmbeddingLimits.inputMaxChars = 8000` chars. Front-loading
semantically dense fields means tail truncation (which is how most embedding
models truncate past their 8192-token limit) drops body prose before it drops
titles — preserving recall quality.

### 4.2 At query time

The user's message is sent to `/embeddings` **raw**, without composition
(see `LibraryProvider.recallRelated`). Rationale: a user's question is already
a dense query — prepending labels would only dilute it.

---

## 5. Vector Storage

### 5.1 Schema

```dart
// lib/services/db/database.dart
class ItemEmbeddings extends Table {
  TextColumn  itemId       references SavedItems(id) on delete cascade
  TextColumn  model        // e.g. "text-embedding-3-small"
  TextColumn  providerId
  BlobColumn  vector       // little-endian float32, unit-normalized
  DateTimeColumn createdAt

  PRIMARY KEY (itemId, model)
}
```

**The primary key is `(itemId, model)`, not `(itemId, providerId)`** — because
the same model can be served by multiple providers (e.g. an OpenAI-compatible
proxy forwarding `text-embedding-3-small`). The vector space is identical, so
it's wasted disk to store it twice.

### 5.2 Codec (`embedding/codec.dart`)

```
encode:  List<double> → normalize in-place → little-endian float32 blob
         |vec| = N ⇒ blob length = 4N bytes

decode:  blob → Float64List

dot:     Σ aᵢ × bᵢ
         (Because vectors are pre-normalized, dot equals cosine similarity.)
```

**Pre-normalization** is a deliberate design choice — it turns each similarity
calculation from "dot + two sqrts + one divide" into "a pure dot product." At
our scale the savings aren't timing; they're code simplicity.

A full `cosineSimilarity` implementation still exists but is used only in tests.

---

## 6. Health Monitoring

`EmbeddingHealthMonitor` (`lib/services/embedding/health_monitor.dart`)
tracks three things per provider:

### 6.1 Rolling latency

An array of the last `EmbeddingTiming.rollingSampleCount = 5` successful call
durations. The mean becomes the provider's "representative latency."

`selectHealthyOrderedByLatency()` returns providers in ascending order of this
mean; `recallRelated` walks the list fastest-first.

### 6.2 Quarantine

Any embed failure calls `recordFailure(providerId)`. The provider is excluded
from the query pool until the next probe succeeds.

### 6.3 Periodic probe

Every `EmbeddingTiming.probeInterval = 10 minutes` the monitor probes every
provider once:
- First provider fires at boot + 3s; each subsequent provider +60s offset (staggered to avoid thundering herd).
- Success → releases quarantine + updates the latency sample.
- Still failing → keeps quarantined.

---

## 7. Recall Pipeline

`LibraryProvider.recallRelated(userMessage, {limit=5})` (`library_provider.dart:559-605`):

```
1. selectHealthyOrderedByLatency() → ordered provider list
   - empty? return []
2. quick check: any rows in item_embeddings?
   - empty? return [] (skips the query-side embedding API call entirely)
3. for provider in list:
     try:
       (queryVec, elapsed) = service.embed(provider, userMessage)
       monitor.recordSuccess(providerId, elapsed)
       return recallByVector(queryVec, model=provider.embeddingModel)
     catch:
       monitor.recordFailure(providerId)
       continue
4. all failed → return []  (chat continues without injected recall)
```

`recallByVector()` (`library_provider.dart:620-660`):

```
1. SELECT * FROM item_embeddings WHERE model = ?
   (all vectors for the embedding model this query used;
    providers sharing that model all contribute.)
2. normalize the query vector
3. for each row: dot = EmbeddingCodec.dot(queryVec, decode(row.vector))
4. sort by dot DESC
5. take top-K item IDs
6. one SELECT to hydrate the SavedItems
7. reorder to match top-K order and return
```

**No similarity threshold** — always return top-K (unless fewer candidates
exist). Thresholds are painful to tune; instead the system prompt tells the
model "reference these naturally, don't copy verbatim," letting the model
decide which of the five items are actually relevant.

**No `in_library` filter** — auto-captured items (`in_library=false`) participate
in recall too. This is the core mechanism behind the dual knowledge pool
(see [`features.md`](./features.md) §2).

### Performance

- Today all vectors are loaded into Dart memory for the dot product. 10,000 items × 1536 dims × 4 bytes ≈ 60 MB blob; in-memory dot + sort finishes in milliseconds. Good enough.
- The actual bottleneck is the query-side embedding API round-trip (100–300 ms).
- The send path parallelizes recall with the DB write (`chat_provider.dart:322`), hiding most of it.
- At much larger scales (100k+) this will need an ANN extension like sqlite-vec. The swap point is `recallByVector`; the public interface stays stable.

---

## 8. Threshold Reference

| Constant | Value | Meaning |
|----------|-------|---------|
| `EmbeddingLimits.inputMaxChars` | 8000 | max chars fed to the embedding API per item |
| `EmbeddingLimits.recallTopK` | 5 | max items returned from recall |
| `EmbeddingTiming.probeTimeout` | 15s | single-probe timeout |
| `EmbeddingTiming.embedTimeout` | 30s | single-embed timeout |
| `EmbeddingTiming.probeInterval` | 10min | periodic probe interval |
| `EmbeddingTiming.rollingSampleCount` | 5 | sample window for the rolling latency mean |
| `FanoutLimits.tickInterval` | 5s | catch-up tick period |
| `FanoutLimits.batchSize` | 10 | pending rows drained per tick |
| `FanoutLimits.backfillConcurrency` | 5 | parallel requests per provider during backfill |

All in `lib/services/constants.dart`.

---

## 9. SavedItem Schema (relevant fields)

Full definition: `lib/services/db/database.dart:85-145`. The embedding-relevant columns:

| Field | Notes |
|-------|-------|
| `body` | main text — fed into the composer |
| `title` | first line of the composed input |
| `entity` | normalized subject (from cairn-meta) — second line |
| `summary` | one-line summary (from cairn-meta) — third line |
| `tags` | JSON array; **not embedded** (used for UI filtering) |
| `embeddingStatus` | `pending` / `processing` / `ready` / `failed` |
| `inLibrary` | doesn't affect embedding; affects UI visibility only |
| `titleLocked` | set when the user manually edits the title; AI reanalysis won't overwrite |

Note: **editing a SavedItem does not currently trigger re-embedding**. Existing
vectors are retained. A proper reindex tool is a future addition.

---

## 10. Quick Reference

| Concern | File |
|---------|------|
| Service (probe / embed) | `lib/services/embedding/service.dart` |
| Health monitor / provider selection | `lib/services/embedding/health_monitor.dart` |
| Write-side fanout + backfill | `lib/services/embedding/fanout_queue.dart` |
| Vector codec | `lib/services/embedding/codec.dart` |
| Input composer | `lib/services/embedding/input_composer.dart` |
| Recall entry points | `lib/services/library_provider.dart` (recallRelated, recallByVector) |
| Schema | `lib/services/db/database.dart` (ItemEmbeddings, SavedItems) |
| Thresholds | `lib/services/constants.dart` (EmbeddingLimits / EmbeddingTiming / FanoutLimits) |
