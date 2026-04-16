# Cairn

> _每一次对话，都是石堆上的一块新石头。_
> _Stack your knowledge, one stone at a time._

[中文](#中文) · [English](#english)

---

<a id="中文"></a>

## 中文

**Cairn 不是又一个 ChatGPT 套壳。** 它是一个会随着你一起成长的**第二大脑**——
你和模型的每一次对话都在悄悄被结构化、索引、沉淀，下一次提问时，模型会
自动翻出你过去说过、学过、想过的东西，像一个真正记得你的人一样回答你。

聊天、知识库、语义召回、AI 工具调用、间隔重复复习——全部打包在一个
**100% 本地运行、零后端、零遥测**的 Flutter 原生应用里。一套代码同时跑在
macOS、iOS、Android 上。

### 为什么它不一样

市面上的 AI 应用大致分两类：**对话即抛型**（ChatGPT、Claude）和**笔记即孤岛型**
（Notion、Obsidian）。前者不记得你，后者不会思考。

Cairn 把两者缝合在一起——对话产出的知识自动进入你的长期记忆池，下一次对话
时由嵌入向量自动召回到上下文。你不需要"整理笔记"，不需要"打标签"，不需要
"建 wiki"——模型替你做完这一切。

| 传统笔记 App      | Cairn                                              |
| ----------------- | -------------------------------------------------- |
| 你存，你搜        | 你存，**模型替你翻**                               |
| 标签靠手打        | 标签由模型自动生成                                 |
| 复习 = 重读       | 复习 = FSRS 间隔重复算法，学过的真的记住           |
| 笔记是死文件      | 笔记喂回对话——**跨会话记忆**由向量嵌入驱动        |
| 数据在别人服务器  | **数据在你自己的 SQLite 里**，除非你自己发出去     |

### 亮点

#### 🧠 会记住你的聊天

每一条助手回复如果带 `cairn-meta` 标记，就会静默进入知识池；下一次你换一个
会话问相关问题时，Cairn 通过语义相似度把相关记忆拼进 system prompt——
**上下文跨越对话边界**，模型不再每次都是失忆状态。

没有嵌入 provider？没关系，会自动降级到用户提问摘要压缩策略，长对话也能继续跑。

#### 🔧 真·工具调用，读你自己的知识库

模型可以主动调用一组库内工具：

- `get_stats` / `get_tag_distribution` / `get_tag_trend` — 对知识做统计
- `get_recent` / `sample_random` / `get_by_tag` — 按时间/标签/随机采样
- `get_note_detail` — 精读某条笔记

于是你可以真的问它：*"我最近在想什么？"*、*"我对某某话题的观点前后有变化吗？"*、
*"从我保存的内容看，我是个什么样的人？"*——答案会基于**你真实写过的东西**，
不是模型脑补。

#### 🗂 自动标签 + 标签图

每条保存的笔记由模型自动打标签，标签之间的共现关系形成关联图谱，在
Connections 页呈现——发现你自己都没意识到的知识簇。

#### 📚 学过的真的记住：FSRS 间隔重复

保存下来的知识会进入复习队列，用学术界公认最优的 FSRS 算法调度。导航栏上
的小铃铛会告诉你今天该复习什么。

#### 🎨 三套主题 + 双形态界面

- **macOS** 三栏桌面式布局，原生窗口自适应缩放
- **iOS / Android** 抽屉式布局，支持系统级 Share Intent——从任何 App 分享
  URL 或文本一键入库
- 浅色、樱粉、深色三套主题

#### 🔌 任意 LLM provider

OpenAI、Anthropic、以及**任何 OpenAI-compatible 接口**（Qwen、DeepSeek、Gemini
兼容接入、本地 Ollama / LM Studio、自建反代……只要 base URL 能填进去就能跑）。

#### 🔒 100% 本地，零后端，零遥测

**我们没有服务器。** 对话、笔记、向量、API Key 全部写在你设备上的 SQLite 里。
唯一的网络请求是你自己配置的 LLM / 嵌入调用，从你的设备**直连** provider——
不经过我们控制的任何中转，因为根本不存在"我们的中转"。

### 功能总览

- 🤖 多 provider 聊天（OpenAI / Anthropic / 任意 OpenAI-compatible）
- 🧩 自动知识捕获（`cairn-meta` 静默落盘）
- 🎯 语义召回，跨对话上下文注入
- 🏷 标签图谱（Connections 页）
- 📖 FSRS 间隔重复复习 + 待复习徽标
- 📊 知识报告 AI 总结
- 🖥 macOS 三栏桌面壳 / 📱 移动端抽屉式
- 🌗 三套主题
- 📥 iOS / Android Share Intent
- 📖 本地 ECDICT 词典
- 🔕 零遥测零后端

### 平台支持

| 平台                  | 状态                                    |
| --------------------- | --------------------------------------- |
| macOS                 | 主力开发平台（三栏桌面壳）              |
| iOS                   | 支持（抽屉壳 + Share Intent）           |
| Android               | 支持（抽屉壳 + Share Intent）           |
| Web / Windows / Linux | 暂不支持                                |

### 快速开始

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter run                                                # 选一台设备
```

首次启动会走一次引导流程：选语言、配 HTTP 代理（可选）、选 provider、贴 API Key、
选默认模型。**在你贴入 key 之前，没有任何数据出门。**

#### 在 macOS 上运行

桌面窗口会在引导卡片尺寸（560×720）和三栏主界面尺寸（1160×760）之间自动切换——
这通过 `macos/Runner/MainFlutterWindow.swift` 的 method channel 实现。

### 架构一瞥

- **UI 层** — Flutter + Material 3，页面在 `lib/pages`，共享组件在 `lib/widgets`
- **状态管理** — 基于 `provider`，见 `chat_provider.dart` / `library_provider.dart` /
  `review_provider.dart` 等
- **持久层** — Drift (SQLite) 在 `lib/services/db/database.dart`，版本化 schema +
  显式 migration
- **LLM 抽象** — `lib/services/llm` 下的可插拔抽象，新增 provider = 实现一个类
- **工具调用** — `lib/services/tools`，`ToolExecutor` 用 `Future.wait` 并行派发
- **嵌入管线** — `lib/services/embedding_*`，带健康监控；provider 异常时自动降级到
  关键词召回
- **复习调度** — `saved_items` 表上的 FSRS 字段 + `review_provider.dart`

### 设计文档

`docs/` 目录收录了 Cairn 的内部设计说明，方便贡献者深入：

| 文档 | 内容 |
|------|------|
| [`docs/architecture.md`](./docs/architecture.md) | 整体架构：技术栈、目录布局、依赖图、启动流程、数据模型、Provider 适配层 |
| [`docs/features.md`](./docs/features.md) | 产品特色：跨会话召回、双知识池、cairn-meta、工具系统、间隔重复 |
| [`docs/embeddings.md`](./docs/embeddings.md) | 向量子系统：模型选择、扇出队列、健康监控、向量存储、召回算法 |
| [`docs/context_loading.md`](./docs/context_loading.md) | 单次发送时的上下文组装：system prompt、历史窗口、工具、流式落库 |

阅读建议：

- 想知道**数据流到了哪里** → `context_loading.md`
- 想**贡献代码** → `architecture.md`，再按要改的模块跳到对应专题
- 想理解 **AI 行为** → `features.md` §1-3
- 想做**向量层优化** → `embeddings.md`

### 代码卫生

每次提交 `flutter analyze` 必须 clean。完整规则见 `CLAUDE.md`。

### 状态

个人项目，API 和 schema 随时可能变。如果 Drift 生成文件和源码对不上：

```bash
dart run build_runner build --delete-conflicting-outputs
```

### License

TBD.

---

<a id="english"></a>

## English

**Cairn isn't just another ChatGPT wrapper.** It's a **second brain** that grows
with you — every chat is quietly structured, indexed, and distilled, so the next
time you ask something, the model pulls from what you've previously said,
learned, and thought. Like talking to someone who actually remembers you.

Chat, knowledge base, semantic recall, AI tool-calling, spaced-repetition
review — all packed into a **100% local, zero-backend, zero-telemetry** Flutter
app. One codebase, runs natively on macOS, iOS, and Android.

### What makes it different

Today's AI tools fall into two camps: **chat-and-forget** (ChatGPT, Claude) and
**notes-as-islands** (Notion, Obsidian). The first doesn't remember you. The
second doesn't think.

Cairn stitches them together — knowledge from conversations flows into a
long-term memory pool, and the next conversation pulls it back via embedding
search. No manual note-sorting, no hand-typed tags, no wiki-building. The model
does it for you.

| Plain notes app         | Cairn                                                       |
| ----------------------- | ----------------------------------------------------------- |
| You save. You search.   | You save. **The model retrieves.**                          |
| Tags typed by hand.     | Tags generated by the model.                                |
| Review = re-read.       | Review = FSRS spaced repetition — you actually remember.    |
| Notes are dead files.   | Notes feed the chat — **cross-conversation recall**.        |
| Data on someone's cloud | **Data in your own SQLite**, unless you ship it out.        |

### Highlights

#### 🧠 Chats that remember you

Every assistant reply tagged with a `cairn-meta` block silently enters the
knowledge pool. Next time you open a new conversation and ask something
related, Cairn pulls relevant memories into the system prompt via semantic
similarity — **context crosses conversation boundaries**. The model is no
longer amnesiac between sessions.

No embedding provider configured? It auto-falls-back to a user-question
summarization strategy, so long conversations still fit in the window.

#### 🔧 Real tool-calling — over your own library

The model can invoke library-aware tools:

- `get_stats` / `get_tag_distribution` / `get_tag_trend` — statistics
- `get_recent` / `sample_random` / `get_by_tag` — time / tag / random sampling
- `get_note_detail` — deep-read a specific note

So you can actually ask: *"What have I been thinking about lately?"*, *"Has my
view on X shifted over time?"*, *"Based on what I've saved, what kind of person
am I?"* — answers grounded in **what you actually wrote**, not hallucinated.

#### 🗂 Auto-tagging + tag graph

Saved notes are tagged by the model; tag co-occurrence forms a relationship
graph surfaced on the Connections page — revealing knowledge clusters you
didn't know you had.

#### 📚 Spaced repetition that actually sticks

Saved knowledge flows into a review queue scheduled by FSRS (state-of-the-art
spaced repetition). A due-count badge on the nav tells you what's up for today.

#### 🎨 Three themes, two form factors

- **macOS** — three-pane desktop shell with native window autosizing
- **iOS / Android** — drawer shell + system-level Share Intent (save URLs
  or text from any app with one tap)
- Light, Pink, and Dark themes

#### 🔌 Any LLM provider

OpenAI, Anthropic, and **any OpenAI-compatible endpoint** (Qwen, DeepSeek,
Gemini-compatible, local Ollama / LM Studio, your own reverse proxy — if it
has a base URL, it works).

#### 🔒 100% local, zero backend, zero telemetry

**We don't run a server.** Conversations, notes, embeddings, and API keys all
live in a SQLite database on your device. The only outbound traffic is the LLM
and embedding calls **you** configure, sent directly from your device to the
provider — nothing routes through infrastructure we control, because no such
infrastructure exists.

### Feature list

- 🤖 Multi-provider chat (OpenAI / Anthropic / any OpenAI-compatible)
- 🧩 Auto-captured knowledge (silent `cairn-meta` persistence)
- 🎯 Semantic recall for cross-conversation context
- 🏷 Tag graph on Connections page
- 📖 FSRS spaced-repetition review + due-count badge
- 📊 AI-generated knowledge report
- 🖥 macOS three-pane shell / 📱 mobile drawer shell
- 🌗 Three themes
- 📥 iOS / Android Share Intent
- 📖 Local ECDICT dictionary for in-chat lookup
- 🔕 Zero telemetry, zero backend

### Platforms

| Platform              | Status                                         |
| --------------------- | ---------------------------------------------- |
| macOS                 | Primary development target (three-pane shell)  |
| iOS                   | Supported (drawer shell + Share Intent)        |
| Android               | Supported (drawer shell + Share Intent)        |
| Web / Windows / Linux | Not currently targeted                         |

### Getting started

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # drift codegen
flutter run                                                # pick a device
```

First launch walks you through onboarding: language, optional HTTP proxy,
provider, API key, default model. **Nothing leaves your device until you paste
a key.**

#### Running on macOS

The desktop window auto-resizes between onboarding (560×720) and the
three-pane chat shell (1160×760), via a method channel in
`macos/Runner/MainFlutterWindow.swift`.

### Architecture

- **UI** — Flutter + Material 3. Pages under `lib/pages`, shared widgets under
  `lib/widgets`.
- **State** — `provider`-based: `chat_provider.dart`, `library_provider.dart`,
  `review_provider.dart`, etc.
- **Persistence** — Drift (SQLite) at `lib/services/db/database.dart`.
  Versioned schema with explicit migrations.
- **LLM providers** — pluggable abstraction in `lib/services/llm`. Adding a
  provider = implementing one class.
- **Tool-calling** — `lib/services/tools`. Each tool declares a JSON schema;
  `ToolExecutor` dispatches `tool_use` blocks in parallel via `Future.wait`.
- **Embeddings** — pipeline under `lib/services/embedding_*` with health
  monitoring; falls back to keyword recall when providers misbehave.
- **Review** — FSRS fields on `saved_items`; scheduler in `review_provider.dart`.

### Design docs

The `docs/` folder collects Cairn's internal design notes for contributors:

| Doc | Covers |
|-----|--------|
| [`docs/architecture.md`](./docs/architecture.md) | Overall structure: stack, layout, dependency graph, boot flow, data model, provider adapters |
| [`docs/features.md`](./docs/features.md) | Product features: cross-conversation recall, dual knowledge pools, cairn-meta, tools, spaced repetition |
| [`docs/embeddings.md`](./docs/embeddings.md) | Vector subsystem: model selection, fanout queue, health monitoring, storage, recall algorithm |
| [`docs/context_loading.md`](./docs/context_loading.md) | Per-turn context assembly: system prompt, history window, tools, streaming commit |

Suggested reading paths:

- Want to know **where your data goes** → `context_loading.md`
- Want to **contribute code** → start with `architecture.md`, then jump to the topic doc for the module you touch
- Want to understand **AI behavior** → `features.md` §1-3
- Want to **optimize the vector layer** → `embeddings.md`

### Code hygiene

`flutter analyze` must be clean on every commit. See `CLAUDE.md` for the rules
(no silenced warnings, no deprecation drift, etc.).

### Status

Personal project; APIs and schema may change without notice. If the Drift
generated file gets out of sync:

```bash
dart run build_runner build --delete-conflicting-outputs
```

### License

TBD.

---

## Screenshots · 截图

<p align="center">
  <img src="homepage.png" alt="Cairn on macOS" width="640" />
  <br />
  <em>macOS — three-pane desktop shell · 三栏桌面壳</em>
</p>

<p align="center">
  <img src="homepage1.png" alt="Cairn on iOS" width="280" />
  <br />
  <em>iOS — drawer shell · 抽屉式布局</em>
</p>

---

<p align="center">
  <em>Cairn — 把每一次思考都变成一块石头，堆成你自己的山。</em><br />
  <em>Cairn — turn every thought into a stone; build your own mountain.</em>
</p>
