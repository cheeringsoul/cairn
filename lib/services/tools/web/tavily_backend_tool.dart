import 'dart:convert';

import 'package:flutter/material.dart';

import '../../settings_provider.dart';
import '../tool_registry.dart';

/// Settings-UI row for "use Tavily as the web_search backend". Not
/// visible to the LLM — [WebSearchTool] reads the toggle + API key
/// and dispatches to Tavily when both are present.
class TavilyBackendTool extends Tool {
  @override
  String get name => SearchBackendNames.tavily;

  @override
  String get displayName => 'Tavily';

  @override
  String get statusLabel => 'Searching (Tavily)…';

  @override
  String get description =>
      'Use Tavily as the web_search backend. Returns LLM-cleaned article '
      'bodies. Requires an API key (free tier: 1000 queries/month).';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  IconData get icon => Icons.travel_explore;

  @override
  bool get enabledByDefault => false;

  @override
  bool get llmVisible => false;

  @override
  Future<String> execute(String argumentsJson) async =>
      jsonEncode({'error': 'Tavily is a web_search backend, not a tool.'});
}
