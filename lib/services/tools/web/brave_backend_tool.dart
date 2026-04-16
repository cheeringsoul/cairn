import 'dart:convert';

import 'package:flutter/material.dart';

import '../../settings_provider.dart';
import '../tool_registry.dart';

/// Settings-UI row for "use Brave Search as the web_search backend".
/// Like [TavilyBackendTool] this is hidden from the LLM — the
/// dispatcher in [WebSearchTool] routes based on its toggle + key.
class BraveBackendTool extends Tool {
  @override
  String get name => SearchBackendNames.brave;

  @override
  String get displayName => 'Brave Search';

  @override
  String get statusLabel => 'Searching (Brave)…';

  @override
  String get description =>
      'Use Brave Search as the web_search backend. Independent search '
      'index (not a Google/Bing scraper). Requires an API key '
      '(free tier: 2000 queries/month).';

  @override
  Map<String, dynamic> get parameters => const {};

  @override
  IconData get icon => Icons.shield_outlined;

  @override
  bool get enabledByDefault => false;

  @override
  bool get llmVisible => false;

  @override
  Future<String> execute(String argumentsJson) async =>
      jsonEncode({'error': 'Brave is a web_search backend, not a tool.'});
}
