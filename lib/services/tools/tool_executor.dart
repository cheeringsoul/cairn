import 'dart:convert';

import '../llm/llm_provider.dart';
import 'tool_registry.dart';

/// Executes tool calls requested by the LLM and produces results.
class ToolExecutor {
  final ToolRegistry _registry;

  ToolExecutor(this._registry);

  /// Execute all [calls] in parallel and return their results.
  Future<List<ToolResult>> executeAll(List<ToolCall> calls) {
    return Future.wait(calls.map((call) async {
      final tool = _registry[call.name];
      if (tool == null) {
        return ToolResult(
          callId: call.id,
          content: jsonEncode({'error': 'Unknown tool: ${call.name}'}),
          isError: true,
        );
      }
      try {
        final result = await tool.execute(call.arguments);
        return ToolResult(callId: call.id, content: result);
      } catch (e) {
        return ToolResult(
          callId: call.id,
          content: jsonEncode({'error': '$e'}),
          isError: true,
        );
      }
    }));
  }
}
