import 'package:flutter/widgets.dart';

import '../llm/llm_provider.dart';

/// Abstract interface that every built-in tool implements.
///
/// Each tool declares its metadata (used by both the LLM API and the
/// settings UI) and an [execute] method that performs the actual work.
abstract class Tool {
  /// Unique identifier — the function name sent to the LLM.
  String get name;

  /// Human-readable label shown in the settings UI.
  String get displayName;

  /// Short status text shown while the tool runs (e.g. "Searching…").
  String get statusLabel;

  /// Description sent to the LLM so it knows when to call this tool.
  String get description;

  /// JSON Schema for the tool's parameters.
  Map<String, dynamic> get parameters;

  /// Icon shown in the settings UI.
  IconData get icon;

  /// Whether this tool is enabled by default for new users.
  bool get enabledByDefault;

  /// Execute the tool with the given JSON arguments string.
  /// Returns the result as a string (will be sent back to the LLM).
  Future<String> execute(String argumentsJson);
}

/// Central registry of all available tools.
class ToolRegistry {
  final Map<String, Tool> _tools = {};

  void register(Tool tool) => _tools[tool.name] = tool;

  Tool? operator [](String name) => _tools[name];

  List<Tool> get allTools => _tools.values.toList(growable: false);

  /// Return [ToolDefinition]s only for tool names in [enabledNames].
  List<ToolDefinition> definitionsFor(Set<String> enabledNames) => _tools.values
      .where((t) => enabledNames.contains(t.name))
      .map((t) => ToolDefinition(
            name: t.name,
            description: t.description,
            parameters: t.parameters,
          ))
      .toList();
}
