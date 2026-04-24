import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../http_client.dart';
import 'llm_provider.dart';

/// OpenAI + OpenAI-compatible endpoints (DeepSeek, local servers,
/// anything that speaks `/chat/completions` with bearer auth).
class OpenAiProvider implements LlmProvider {
  final String baseUrl;
  final String apiKey;

  OpenAiProvider({required this.baseUrl, required this.apiKey});

  @override
  Stream<StreamEvent> streamChat({
    required List<LlmMessage> messages,
    required String model,
    String? systemPrompt,
    List<ToolDefinition>? tools,
    void Function(TokenUsage usage)? onUsage,
  }) async* {
    final msgs = <Map<String, dynamic>>[
      if (systemPrompt != null && systemPrompt.trim().isNotEmpty)
        {'role': 'system', 'content': systemPrompt},
      for (final m in messages) _encodeMessage(m),
    ];

    final body = <String, dynamic>{
      'model': model,
      'messages': msgs,
      'stream': true,
      'stream_options': {'include_usage': true},
    };
    if (tools != null && tools.isNotEmpty) {
      body['tools'] = [
        for (final t in tools)
          {
            'type': 'function',
            'function': {
              'name': t.name,
              'description': t.description,
              'parameters': t.parameters,
            },
          },
      ];
    }

    final request = http.Request('POST', Uri.parse('$baseUrl/chat/completions'));
    request.headers['Content-Type'] = 'application/json';
    request.headers['Authorization'] = 'Bearer $apiKey';
    request.headers['Accept'] = 'text/event-stream';
    request.body = jsonEncode(body);

    final response = await createPlatformClient().send(request);
    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw LlmException(
        _extractError(responseBody) ?? 'Request failed',
        status: response.statusCode,
      );
    }

    // Accumulate partial tool calls keyed by index.
    final partialToolCalls = <int, _PartialToolCall>{};

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
        if (data == '[DONE]') {
          // Flush any tool calls that weren't terminated by a
          // `finish_reason: tool_calls` frame (some providers, e.g.
          // MiniMax, send `finish_reason: stop` after tool_calls or
          // omit it entirely).
          for (final partial in partialToolCalls.values) {
            if (partial.name.isNotEmpty) {
              yield ToolCallDelta(partial.toToolCall());
            }
          }
          partialToolCalls.clear();
          return;
        }
        try {
          final json = jsonDecode(data);

          final choice = (json['choices'] as List?)?.firstOrNull;
          if (choice is Map) {
            final delta = choice['delta'];

            // Text content
            final content = delta?['content'];
            if (content is String && content.isNotEmpty) {
              yield TextDelta(content);
            }

            // Tool call deltas — arrive incrementally by index.
            final tcDeltas = delta?['tool_calls'];
            if (tcDeltas is List) {
              for (final tc in tcDeltas) {
                // Some providers (e.g. MiniMax) omit `index` when there's
                // only one call — fall back to 0.
                final idx = (tc['index'] as num?)?.toInt() ?? 0;
                final partial = partialToolCalls.putIfAbsent(
                    idx, () => _PartialToolCall());
                // Qwen sends `id: ""` and `name: ""` in continuation
                // frames — don't let them clobber the real values that
                // arrived in the first frame.
                final id = tc['id'];
                if (id is String && id.isNotEmpty) partial.id = id;
                final fn = tc['function'];
                if (fn is Map) {
                  final name = fn['name'];
                  if (name is String && name.isNotEmpty) partial.name = name;
                  final args = fn['arguments'];
                  if (args is String) partial.arguments.write(args);
                }
              }
            }

            // When finish_reason signals tool_calls, flush them.
            final finishReason = choice['finish_reason'];
            if (finishReason == 'tool_calls') {
              for (final partial in partialToolCalls.values) {
                yield ToolCallDelta(partial.toToolCall());
              }
              partialToolCalls.clear();
            }
          }

          // Usage frame (usually the last frame before [DONE]).
          final usage = json['usage'];
          if (usage is Map && onUsage != null) {
            onUsage(TokenUsage(
              inputTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
              outputTokens:
                  (usage['completion_tokens'] as num?)?.toInt() ?? 0,
            ));
          }
        } catch (_) {
          // Ignore malformed frames; OpenAI sometimes interleaves keep-alives.
        }
      }
    }

    // Stream ended without a [DONE] frame — flush any pending tool calls.
    for (final partial in partialToolCalls.values) {
      if (partial.name.isNotEmpty) {
        yield ToolCallDelta(partial.toToolCall());
      }
    }
  }

  /// Encode an [LlmMessage] into the OpenAI wire format.
  Map<String, dynamic> _encodeMessage(LlmMessage m) {
    if (m.role == 'tool') {
      return {
        'role': 'tool',
        'tool_call_id': m.toolCallId ?? '',
        'content': m.content,
      };
    }
    if (m.role == 'assistant' && m.toolCalls != null && m.toolCalls!.isNotEmpty) {
      return {
        'role': 'assistant',
        if (m.content.isNotEmpty) 'content': m.content,
        'tool_calls': [
          for (final tc in m.toolCalls!)
            {
              'id': tc.id,
              'type': 'function',
              'function': {
                'name': tc.name,
                'arguments': tc.arguments,
              },
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

/// Accumulates incremental tool call data from SSE deltas.
class _PartialToolCall {
  String id = '';
  String name = '';
  final arguments = StringBuffer();

  ToolCall toToolCall() =>
      ToolCall(id: id, name: name, arguments: arguments.toString());
}
