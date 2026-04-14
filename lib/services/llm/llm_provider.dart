/// Abstract interface every provider adapter implements.
///
/// A [LlmMessage] is the adapter-facing view of a chat turn, decoupled
/// from the SQLite [Message] row. Providers translate it into their own
/// wire format.
library;

class LlmMessage {
  final String role; // 'system' | 'user' | 'assistant' | 'tool'
  final String content;
  final List<ToolCall>? toolCalls; // present on assistant msgs that invoke tools
  final String? toolCallId; // present on role='tool' msgs
  const LlmMessage({
    required this.role,
    required this.content,
    this.toolCalls,
    this.toolCallId,
  });
}

/// Token accounting reported by a provider at the end of a stream.
class TokenUsage {
  final int inputTokens;
  final int outputTokens;
  const TokenUsage({required this.inputTokens, required this.outputTokens});

  int get totalTokens => inputTokens + outputTokens;
}

// ---------------------------------------------------------------------------
// Tool-use types
// ---------------------------------------------------------------------------

/// Tool definition sent to the provider so the model knows what it can call.
class ToolDefinition {
  final String name;
  final String description;
  final Map<String, dynamic> parameters; // JSON Schema object
  const ToolDefinition({
    required this.name,
    required this.description,
    required this.parameters,
  });
}

/// A single tool call requested by the model.
class ToolCall {
  final String id; // provider-assigned call ID
  final String name; // tool function name
  final String arguments; // JSON string of arguments
  const ToolCall({
    required this.id,
    required this.name,
    required this.arguments,
  });
}

/// Result of executing a tool call, sent back to the model.
class ToolResult {
  final String callId; // must match ToolCall.id
  final String content; // result string
  final bool isError;
  const ToolResult({
    required this.callId,
    required this.content,
    this.isError = false,
  });
}

// ---------------------------------------------------------------------------
// Stream events
// ---------------------------------------------------------------------------

/// What the LLM stream yields — either a text chunk or a tool call.
sealed class StreamEvent {}

class TextDelta extends StreamEvent {
  final String text;
  TextDelta(this.text);
}

class ToolCallDelta extends StreamEvent {
  final ToolCall toolCall;
  ToolCallDelta(this.toolCall);
}

// ---------------------------------------------------------------------------
// Provider interface
// ---------------------------------------------------------------------------

abstract class LlmProvider {
  /// Stream events from the LLM. The stream yields [TextDelta] for
  /// incremental text and [ToolCallDelta] when the model invokes a tool.
  ///
  /// [tools] — optional list of tool definitions the model may call.
  /// When null or empty, the provider behaves as plain text streaming.
  ///
  /// [onUsage] is invoked once, after the stream finishes, with the
  /// provider-reported token counts. Providers that can't report usage
  /// simply never call it.
  Stream<StreamEvent> streamChat({
    required List<LlmMessage> messages,
    required String model,
    String? systemPrompt,
    List<ToolDefinition>? tools,
    void Function(TokenUsage usage)? onUsage,
  });
}

class LlmException implements Exception {
  final int? status;
  final String message;
  LlmException(this.message, {this.status});

  @override
  String toString() =>
      status == null ? 'LlmException: $message' : 'LlmException($status): $message';
}
