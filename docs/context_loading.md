# 对话上下文加载逻辑

> 本文整理 Cairn 在每一轮发送消息时，如何组装喂给 LLM 的上下文。
> 覆盖：System Prompt 构成、历史消息策略、工具定义、流式回写。

---

## 1. 总览

一次 `sendMessage` 的上下文由四部分拼装后送入 Provider：

```
┌──────────────── system prompt ────────────────┐   ┌── messages ──┐   ┌── tools ──┐
│ aboutMe + persona + recall + cairn-meta 指令  │ + │ 历史消息列表 │ + │ 启用工具  │
└───────────────────────────────────────────────┘   └──────────────┘   └───────────┘
```

入口在 `ChatProvider.sendMessage`，组装完后交给 `StreamingChatMixin.streamAndCommit`
执行多轮（含工具）流式调用，最终把回复写回 SQLite。

关键文件：

- `lib/services/chat_provider.dart` — 入口、System Prompt 拼装、自动归档
- `lib/services/streaming_chat_mixin.dart` — 历史窗口、流处理、工具循环、错误兜底
- `lib/services/llm/anthropic_provider.dart` / `openai_provider.dart` — Provider 适配
- `lib/services/library_provider.dart` — 跨会话向量召回
- `lib/services/cairn_meta.dart` — 让模型输出可归档元信息的指令块
- `lib/services/constants.dart` — 无 embedding 时的窗口阈值

---

## 2. 数据模型

Drift / SQLite，三张相关表（`lib/services/db/database.dart`）：

| 表             | 关键字段                                                          | 说明                                |
|----------------|-------------------------------------------------------------------|-------------------------------------|
| `Conversations`| `personaId`, `providerId`, `model`, `systemPrompt?`, `kind`       | 会话级配置，创建时锁定 model        |
| `Messages`     | `conversationId`, `role`, `content`, `createdAt`                  | 纯文本，无附件结构                  |
| `Personas`     | `name`, `instruction`, `icon`, `sortOrder`                        | 可复用的 system prompt 模板         |

注意：`Messages.content` 只存最终文本；工具调用过程消息只存活在内存里，不落库。

---

## 3. System Prompt 拼装

`ChatProvider._buildSystemPrompt` (`chat_provider.dart:503-527`) 按顺序拼接：

1. **About Me** — 用户在设置里写的自我描述，引导模型口吻 / 偏好。
2. **Persona instruction** — 当前选中 persona 的指令；未选则取默认 persona。
3. **Recall context** — 通过 embedding 跨会话召回的相关历史知识，
   由 `LibraryProvider.formatRecallContext` (`library_provider.dart:853-870`)
   渲染为 markdown 列表。最多 5 条。
4. **`cairnMetaSystemInstruction`** (`cairn_meta.dart:140-156`) — 要求模型在回复尾部
   附带可解析的元数据块（实体、类型、标签、`reviewable` 等），用于自动归档。

调用点：`chat_provider.dart:325-327`，传入参数仅有 `recallContext`。

---

## 4. 召回（recall）

`chat_provider.dart:322-324` 在写入用户消息的同时并行触发：

```dart
final recallFuture = _library.recallRelated(trimmed); // 网络 ~100-300ms
await _db.into(_db.messages).insert(userMsg);          // 本地 ~1ms
final recalled = await recallFuture;
```

并发省下 100~300ms。如果用户**任何 provider** 都不支持 embedding，召回静默禁用，
转而走第 5 节的"无 embedding 兜底"。

---

## 5. 历史消息策略

`StreamingChatMixin.streamAndCommit` 中 `lib/services/streaming_chat_mixin.dart:166-171`
是分支点：

```dart
final persisted = msgs.take(msgs.length - 1).toList(); // 去掉占位 draft
var history = hasEmbeddingFallback
    ? persisted.map((m) => LlmMessage(role: m.role, content: m.content)).toList()
    : await _buildUserOnlyHistory(persisted, adapter, model);
```

### 5a. 有 embedding（默认路径）

整段对话原样发出（user + assistant 全保留）。窗口压力由 provider 上下文窗口承载，
跨会话补充由召回保证。

### 5b. 无 embedding 兜底

`_buildUserOnlyHistory` (`streaming_chat_mixin.dart:403-432`) 采用更保守策略：

1. **只保留 user 消息**（assistant 回答被丢弃，意图链由用户提问承载）。
2. 阈值见 `NoEmbedContext` (`constants.dart:97-102`)：
   - `compressChars = 40000` — 用户提问总长超此值才触发压缩
   - `keepRecentTurns = 10` — 保留最近 10 条 user 提问原文
   - `warnChars = 32000` — 超过即在 UI 提示开新会话
     (`chat_provider.dart:119-127`)
3. 老的提问交给 `_summarizeOlder` (`streaming_chat_mixin.dart:434-468`) 做 ≤200 字
   的二次 LLM 摘要；摘要失败则朴素截断到 2000 字符。

---

## 6. 工具定义

`streaming_chat_mixin.dart:152-154`：

```dart
final toolDefs = toolRegistry != null && enabledToolNames != null
    ? toolRegistry.definitionsFor(enabledToolNames)
    : <ToolDefinition>[];
```

启用工具集由 `SettingsProvider.enabledToolNames` 解析（用户开关 + 默认开关）。
工具循环上限 `maxToolRounds = 5`（`streaming_chat_mixin.dart:176`），
超出后强制收尾，避免死循环。

每轮工具结果：
- 以 `role: 'tool'` 追加到内存 `history`，**不落库**。
- 若工具结果 JSON 含 `action_links`，作为 markdown 按钮拼到最终回复尾部
  (`streaming_chat_mixin.dart:252-277, 307-319`)。

---

## 7. Provider 适配 — 真正出网点

| Provider   | 文件                                              | 关键差异                                       |
|------------|---------------------------------------------------|------------------------------------------------|
| Anthropic  | `lib/services/llm/anthropic_provider.dart:22-49` | system 顶层字段，`max_tokens=4096` 硬编码       |
| OpenAI     | `lib/services/llm/openai_provider.dart:17-54`    | system 作为 `role: system` 消息，工具走 function-call |

两侧都用 SSE 流式回写，事件被归一化为 `TextDelta` / `ToolCallDelta` 两种
`StreamEvent`，再由 mixin 统一处理。

---

## 8. 流处理与持久化

`streaming_chat_mixin.dart:188-227` 的监听循环：

- `TextDelta` → 追加到 `StringBuffer`，更新内存中 draft 消息，触发 UI 刷新。
- `ToolCallDelta` → 入 `pendingToolCalls`，待本轮 `onDone` 后批量执行。

落库逻辑 `streaming_chat_mixin.dart:290-335`：

- 文本为空（如所有工具回合都失败）→ 丢弃 draft，不污染下一轮历史。
- 文本非空 → 插入 `Messages` 表，同时更新会话 `updatedAt`。
- 出错 (`LlmException` 或其他) → 走 `_commitPartialOnError`
  (`streaming_chat_mixin.dart:364-399`)，把已经流出来的部分文本保存下来。

回复落库后，`chat_provider.dart:380-389` 解析 cairn-meta，若 `reviewable: true`
则异步写入知识池（`in_library=false`），供后续 embedding 召回用。

---

## 9. 取消与并发

每次 `sendMessage` 持有一个 `_activeCancelToken`。用户中断后：

- UI 立刻翻转 `sending=false`，回调里通过 `token.isCancelled` 守卫，避免覆盖
  下一轮已经开始的状态 (`chat_provider.dart:352-373`)。
- 后台仍会把已流出的文本提交到 DB（partial commit），不丢用户已经看到的内容。

---

## 10. 速查清单

| 关注点                 | 文件 : 行                                                |
|------------------------|----------------------------------------------------------|
| 入口                   | `chat_provider.dart:300-373`                             |
| System Prompt 拼装     | `chat_provider.dart:503-527`                             |
| 召回并发               | `chat_provider.dart:322-324`                             |
| 召回格式化             | `library_provider.dart:853-870`                          |
| cairn-meta 指令        | `cairn_meta.dart:140-156`                                |
| 历史窗口分支           | `streaming_chat_mixin.dart:166-171`                      |
| 无 embedding 压缩      | `streaming_chat_mixin.dart:403-468`                      |
| 阈值常量               | `constants.dart:97-102`                                  |
| 工具循环               | `streaming_chat_mixin.dart:176-288`                      |
| 出网（Anthropic）      | `llm/anthropic_provider.dart:22-49`                      |
| 出网（OpenAI）         | `llm/openai_provider.dart:17-54`                         |
| 错误兜底落库           | `streaming_chat_mixin.dart:364-399`                      |
| 自动归档               | `chat_provider.dart:380-389`                             |
