import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'llm_provider.dart';

/// Anthropic Messages API adapter.
///
/// Uses the SSE `stream: true` variant. System prompt is top-level,
/// not a message with role 'system' (Anthropic's API quirk).
class AnthropicProvider implements LlmProvider {
  static const _apiVersion = '2023-06-01';
  static const _defaultMaxTokens = 4096;

  final String baseUrl;
  final String apiKey;

  AnthropicProvider({required this.baseUrl, required this.apiKey});

  @override
  Stream<StreamEvent> streamChat({
    required List<LlmMessage> messages,
    required String model,
    String? systemPrompt,
    List<ToolDefinition>? tools,
    void Function(TokenUsage usage)? onUsage,
  }) async* {
    final body = <String, dynamic>{
      'model': model,
      'max_tokens': _defaultMaxTokens,
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        'system': systemPrompt,
      'messages': [
        for (final m in messages.where((m) => m.role != 'system'))
          _encodeMessage(m),
      ],
      'stream': true,
    };
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = [
        for (final t in tools)
          {
            'name': t.name,
            'description': t.description,
            'input_schema': t.parameters,
          },
      ];
    }

    final request = http.Request('POST', Uri.parse('$baseUrl/messages'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['x-api-key'] = apiKey;
    request.headers['anthropic-version'] = _apiVersion;
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode(body);

    final response = await http.Client().send(request);
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw LlmException(
        _extractError(responseBody) ?? 'Request failed',
        status: response.statusCode,
      );
    }

    // Anthropic reports input_tokens on message_start and streams output
    // token counts on message_delta. We accumulate both and emit once at
    // message_stop.
    int inputTokens = 0;
    int outputTokens = 0;

    // Track current tool-use content block being streamed.
    String? currentToolId;
    String? currentToolName;
    final toolArgBuf = StringBuffer();

    final stream = response.stream.transform(utf8.decoder);
    String buffer = '';
    await for (final chunk in stream) {
      buffer += chunk;
      while (true) {
        final nl = buffer.indexOf('\n');
        if (nl < 0) break;
        final line = buffer.substring(0, nl).trim();
        buffer = buffer.substring(nl + 1);
        if (line.isEmpty || !line.startsWith('data:')) continue;
        final data = line.substring(5).trim();
        try {
          final json = jsonDecode(data);
          final type = json['type'];

          if (type == 'content_block_start') {
            final block = json['content_block'];
            if (block is Map && block['type'] == 'tool_use') {
              currentToolId = block['id'] as String?;
              currentToolName = block['name'] as String?;
              toolArgBuf.clear();
            }
          } else if (type == 'content_block_delta') {
            final delta = json['delta'];
            if (delta is Map) {
              final deltaType = delta['type'];
              if (deltaType == 'text_delta') {
                final text = delta['text'];
                if (text is String && text.isNotEmpty) yield TextDelta(text);
              } else if (deltaType == 'input_json_delta') {
                final partial = delta['partial_json'];
                if (partial is String) toolArgBuf.write(partial);
              }
            }
          } else if (type == 'content_block_stop') {
            // If we were accumulating a tool-use block, flush it.
            final toolId = currentToolId;
            final toolName = currentToolName;
            if (toolId != null && toolName != null) {
              yield ToolCallDelta(ToolCall(
                id: toolId,
                name: toolName,
                arguments: toolArgBuf.toString(),
              ));
              currentToolId = null;
              currentToolName = null;
              toolArgBuf.clear();
            }
          } else if (type == 'message_start') {
            final usage = json['message']?['usage'];
            if (usage is Map) {
              inputTokens = (usage['input_tokens'] as num?)?.toInt() ?? 0;
              outputTokens = (usage['output_tokens'] as num?)?.toInt() ?? 0;
            }
          } else if (type == 'message_delta') {
            final usage = json['usage'];
            if (usage is Map) {
              outputTokens = (usage['output_tokens'] as num?)?.toInt() ??
                  outputTokens;
            }
          } else if (type == 'message_stop') {
            onUsage?.call(TokenUsage(
              inputTokens: inputTokens,
              outputTokens: outputTokens,
            ));
            return;
          }
        } catch (_) {
          // Ignore malformed / keep-alive frames.
        }
      }
    }
  }

  /// Encode an [LlmMessage] into the Anthropic wire format.
  Map<String, dynamic> _encodeMessage(LlmMessage m) {
    if (m.role == 'tool') {
      return {
        'role': 'user',
        'content': [
          {
            'type': 'tool_result',
            'tool_use_id': m.toolCallId ?? '',
            'content': m.content,
          },
        ],
      };
    }
    if (m.role == 'assistant' && m.toolCalls != null && m.toolCalls!.isNotEmpty) {
      return {
        'role': 'assistant',
        'content': [
          if (m.content.isNotEmpty)
            {'type': 'text', 'text': m.content},
          for (final tc in m.toolCalls!)
            {
              'type': 'tool_use',
              'id': tc.id,
              'name': tc.name,
              'input': tc.arguments.isNotEmpty
                  ? jsonDecode(tc.arguments)
                  : <String, dynamic>{},
            },
        ],
      };
    }
    return {'role': m.role, 'content': m.content};
  }

  String? _extractError(String body) {
    try {
      final j = jsonDecode(body);
      final msg = j is Map ? (j['error']?['message'] ?? j['error']) : null;
      if (msg is String && msg.isNotEmpty) return msg;
    } catch (_) {}
    return null;
  }
}
