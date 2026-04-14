import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import '../services/embedding/service.dart';
import '../services/platform_utils.dart';
import '../services/settings_provider.dart';

/// First-run onboarding.
///
/// Flow: welcome → pick provider → paste API key → fetch models → pick
/// model → validate → done.
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  // 0: welcome, 1: language, 2: proxy, 3: pick provider, 4: paste key, 5: pick model
  int _step = 0;
  ({String kind, String label, String baseUrl, String defaultModel})? _picked;
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _proxyController = TextEditingController();
  bool _loading = false;
  String? _error;

  // Fetched model list + selected model
  List<String> _models = [];
  String? _selectedModel;

  @override
  void initState() {
    super.initState();
    // The macOS window may have been sized for the three-pane shell on
    // a previous launch (autosaved frame, or a sign-out that returned
    // here). Shrink it so the onboarding card isn't swimming in empty
    // space.
    if (!kIsWeb && Platform.isMacOS) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        const MethodChannel('cairn/window')
            .invokeMethod('resizeForOnboarding');
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _proxyController.dispose();
    super.dispose();
  }

  void _pick(
      ({String kind, String label, String baseUrl, String defaultModel}) p) {
    setState(() {
      _picked = p;
      _baseUrlController.text = p.baseUrl;
      _step = 4;
      _error = null;
      _models = [];
      _selectedModel = null;
    });
  }

  /// Fetch model list from the provider, then move to model-pick step.
  Future<void> _fetchModels() async {
    final l10n = AppLocalizations.of(context)!;
    final key = _keyController.text.trim();
    final baseUrl = _baseUrlController.text.trim();
    if (key.isEmpty) {
      setState(() => _error = l10n.apiKeyRequired);
      return;
    }
    if (baseUrl.isEmpty) {
      setState(() => _error = l10n.baseUrlRequired);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final models =
          await _listModels(_picked!.kind, baseUrl, key);
      if (models == null || models.isEmpty) {
        setState(() {
          _error ??= l10n.couldNotFetchModels;
          _loading = false;
        });
        return;
      }
      if (!mounted) return;
      setState(() {
        _models = models;
        // Auto-select a sensible default if possible
        _selectedModel = _pickDefault(models, _picked!.kind);
        _loading = false;
        _step = 5;
      });
    } catch (e) {
      setState(() {
        _error = l10n.networkError(e.toString());
        _loading = false;
      });
    }
  }

  /// Pick a sensible default model from the fetched list.
  String _pickDefault(List<String> models, String kind) {
    // Prefer well-known models by provider
    final preferences = switch (kind) {
      'anthropic' => [
        'claude-sonnet-4-5-20250514',
        'claude-4-sonnet',
        'claude-3-5-sonnet',
      ],
      'openai' => ['gpt-4o', 'gpt-4', 'gpt-3.5-turbo'],
      'deepseek' => ['deepseek-chat', 'deepseek-coder'],
      _ => <String>[],
    };
    for (final pref in preferences) {
      final match = models.where((m) => m.contains(pref)).firstOrNull;
      if (match != null) return match;
    }
    return models.first;
  }

  Future<void> _verifyAndSave() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedModel == null || _selectedModel!.isEmpty) {
      setState(() => _error = l10n.pleaseSelectModel);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final key = _keyController.text.trim();
      final baseUrl = _baseUrlController.text.trim();
      final err =
          await _ping(_picked!.kind, baseUrl, key, _selectedModel!);
      if (err != null) {
        setState(() {
          _error = err;
          _loading = false;
        });
        return;
      }

      if (!mounted) return;
      final settings = context.read<SettingsProvider>();
      await settings.addProvider(
        kind: _picked!.kind,
        displayName: _picked!.label,
        baseUrl: baseUrl,
        defaultModel: _selectedModel!,
        apiKey: key,
      );

      // If the user finished onboarding with a provider that can't
      // compute embeddings, explain that cross-conversation memory
      // will stay off until they add another (embedding-capable)
      // provider. Non-blocking — we still finalize onboarding after
      // they tap "Got it".
      if (mounted &&
          !EmbeddingService.defaultEmbeddingModels.containsKey(
              _picked!.kind)) {
        await _showNoEmbeddingWarning();
      }
      if (!mounted) return;
      await settings.markOnboardingDone();
    } catch (e) {
      setState(() {
        _error = l10n.unexpectedError(e.toString());
        _loading = false;
      });
    }
  }

  /// Explain that the just-configured provider can't do embeddings,
  /// so cross-conversation memory will stay off. Non-blocking: user
  /// taps "Got it" and we proceed with markOnboardingDone. The chat
  /// page's [_EmbeddingMissingBanner] then guides them to add
  /// another provider if they want the feature.
  Future<void> _showNoEmbeddingWarning() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          icon: const Icon(Icons.lightbulb_outline_rounded),
          title: const Text('关于跨对话记忆'),
          content: const Text(
            'Cairn 通过语义检索（embedding）让 AI 在新对话中主动回忆你之前聊过的内容。'
            '你刚刚添加的 provider 不提供 embedding 能力，所以这个功能暂时不会生效。\n\n'
            '稍后可以在"设置 → Providers"里添加一个支持 embedding 的 provider'
            '（推荐 OpenAI / Qwen / Gemini / DeepSeek 等）来开启知识库。',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('知道了'),
            ),
          ],
        );
      },
    );
  }

  // ---- API helpers ----

  /// Fetch available models from the provider.
  Future<List<String>?> _listModels(
      String kind, String baseUrl, String apiKey) async {
    try {
      if (kind == 'anthropic') {
        final resp = await http.get(
          Uri.parse('$baseUrl/models'),
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': '2023-06-01',
          },
        );
        if (resp.statusCode != 200) {
          _error = _parseError(resp.statusCode, resp.body);
          return null;
        }
        final body = jsonDecode(resp.body);
        final data = body['data'] as List?;
        if (data == null) return null;
        final models = data
            .map((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList()
          ..sort();
        return models;
      } else {
        // OpenAI-compatible
        final resp = await http.get(
          Uri.parse('$baseUrl/models'),
          headers: {'Authorization': 'Bearer $apiKey'},
        );
        if (resp.statusCode != 200) {
          _error = _parseError(resp.statusCode, resp.body);
          return null;
        }
        final body = jsonDecode(resp.body);
        final data = body['data'] as List?;
        if (data == null) return null;
        var models = data
            .map((m) => m['id']?.toString() ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
        // Gemini returns many non-chat models (embedding, imagen, etc.)
        // that don't support /chat/completions. Filter to chat models.
        if (kind == ProviderKinds.gemini) {
          models = models
              .where((m) => m.contains('gemini') &&
                  !m.contains('embedding') &&
                  !m.contains('imagen') &&
                  !m.contains('aqa'))
              .toList();
        }
        models.sort();
        return models;
      }
    } catch (e) {
      final l10n = AppLocalizations.of(context)!;
      _error = l10n.networkError(e.toString());
      return null;
    }
  }

  /// Minimal "ping" that sends a 1-token request to validate.
  /// Retries once on transient network errors (handshake failures, etc.).
  Future<String?> _ping(
      String kind, String baseUrl, String apiKey, String model) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      try {
        if (kind == 'anthropic') {
          final resp = await http.post(
            Uri.parse('$baseUrl/messages'),
            headers: {
              'Content-Type': 'application/json',
              'x-api-key': apiKey,
              'anthropic-version': '2023-06-01',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 1,
              'messages': [
                {'role': 'user', 'content': 'hi'}
              ],
            }),
          ).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) return null;
          return _parseError(resp.statusCode, resp.body);
        } else {
          final resp = await http.post(
            Uri.parse('$baseUrl/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'max_tokens': 1,
              'messages': [
                {'role': 'user', 'content': 'hi'}
              ],
            }),
          ).timeout(const Duration(seconds: 15));
          if (resp.statusCode == 200) return null;
          return _parseError(resp.statusCode, resp.body);
        }
      } catch (e) {
        // On first attempt, retry once for transient errors
        // (handshake failures, timeouts, etc.).
        if (attempt == 0) {
          await Future.delayed(const Duration(seconds: 2));
          continue;
        }
        final l10n = AppLocalizations.of(context)!;
        return l10n.networkError(e.toString());
      }
    }
    return null; // unreachable
  }

  String _parseError(int status, String body) {
    final l10n = AppLocalizations.of(context)!;
    String? providerMsg;
    try {
      final j = jsonDecode(body);
      final msg = j is Map ? (j['error']?['message'] ?? j['error']) : null;
      if (msg is String && msg.isNotEmpty) providerMsg = msg;
    } catch (_) {}
    if (providerMsg != null) return '[$status] $providerMsg';
    switch (status) {
      case 401:
      case 403:
        return l10n.apiKeyInvalid;
      case 404:
        return l10n.endpointNotFound;
      case 429:
        return l10n.rateLimited;
      case 500:
      case 502:
      case 503:
        return l10n.providerIssues;
    }
    return l10n.requestFailed(status);
  }

  // ---- UI ----

  @override
  Widget build(BuildContext context) {
    // On desktop the main window is wide (1160+ px) to accommodate
    // the three-pane chat shell, but onboarding content is vertical
    // and short — letting it stretch edge-to-edge looks lopsided.
    // Cap it to a comfortable reading column and center the column
    // in the window. Mobile keeps the full-width layout.
    final content = Padding(
      padding: const EdgeInsets.all(24),
      child: _stepBody(),
    );
    return Scaffold(
      body: SafeArea(
        child: isDesktopPlatform
            ? Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: content,
                ),
              )
            : content,
      ),
    );
  }

  Widget _stepBody() {
    switch (_step) {
      case 0:
        return _welcome();
      case 1:
        return _chooseLanguage();
      case 2:
        return _configProxy();
      case 3:
        return _pickProvider();
      case 4:
        return _pasteKey();
      case 5:
        return _pickModel();
      default:
        return _welcome();
    }
  }

  Widget _welcome() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Text(l10n.appName,
            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(
          l10n.welcomeDescription,
          style: TextStyle(
              fontSize: 15, color: cs.onSurface.withValues(alpha: 0.7)),
        ),
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () => setState(() => _step = 1),
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: Text(l10n.getStarted),
          ),
        ),
      ],
    );
  }

  Widget _chooseLanguage() {
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();

    // Use native names so the user can read their own language
    // regardless of the current locale setting.
    const languages = [
      (tag: 'en', native: 'English', flag: '🇺🇸'),
      (tag: 'zh', native: '简体中文', flag: '🇨🇳'),
      (tag: 'zh_Hant', native: '繁體中文', flag: '🇹🇼'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        const Text('🌐', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 16),
        // Show in both languages so everyone can read it.
        const Text('Choose your language',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text('选择你的语言',
            style: TextStyle(
                fontSize: 16, color: cs.onSurface.withValues(alpha: 0.5))),
        const SizedBox(height: 28),
        Expanded(
          child: ListView.separated(
            itemCount: languages.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final lang = languages[i];
              return Material(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () async {
                    await settings.setLocale(lang.tag);
                    if (mounted) setState(() => _step = 2);
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 16),
                    child: Row(
                      children: [
                        Text(lang.flag, style: const TextStyle(fontSize: 28)),
                        const SizedBox(width: 16),
                        Text(lang.native,
                            style: const TextStyle(
                                fontSize: 17, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Icon(Icons.chevron_right,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _configProxy() {
    final cs = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 40),
        Icon(Icons.vpn_lock_rounded, size: 40, color: cs.primary),
        const SizedBox(height: 16),
        const Text('HTTP 代理',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(
          '如果你需要通过代理访问 API，请在此设置。不需要可直接跳过。',
          style: TextStyle(
              fontSize: 14, color: cs.onSurface.withValues(alpha: 0.6)),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _proxyController,
          decoration: const InputDecoration(
            labelText: '代理地址',
            hintText: 'http://127.0.0.1:7890',
            border: OutlineInputBorder(),
          ),
        ),
        const Spacer(),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _step = 3),
                style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('跳过'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FilledButton(
                onPressed: () async {
                  final proxy = _proxyController.text.trim();
                  if (proxy.isNotEmpty) {
                    await settings.setHttpProxy(proxy);
                  }
                  if (mounted) setState(() => _step = 3);
                },
                style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14)),
                child: const Text('确认'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _pickProvider() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Find the Qwen entry in the catalog.
    final qwenEntry = ProviderKinds.catalog
        .firstWhere((p) => p.kind == 'qwen');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Text(l10n.chooseProvider,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l10n.pickProviderHint,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        // ---- Qwen recommendation card ----
        Material(
          color: cs.primary.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _pick(qwenEntry),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.star_rounded,
                        size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.geminiRecommended,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: cs.primary)),
                        const SizedBox(height: 2),
                        Text(l10n.geminiRecommendedDesc,
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.55))),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right,
                      color: cs.primary.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // ---- Other providers ----
        Expanded(
          child: ListView.separated(
            itemCount: ProviderKinds.catalog.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = ProviderKinds.catalog[i];
              return Material(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _pick(p),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(
                                p.baseUrl.isEmpty
                                    ? l10n.youProvideBaseUrl
                                    : p.baseUrl,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.5)),
                              ),
                            ],
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _pasteKey() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          onPressed: _loading ? null : () => setState(() => _step = 3),
        ),
        const SizedBox(height: 8),
        Text('${_picked!.label} API key',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l10n.apiKeyStoredLocally,
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        if (_picked!.kind == 'qwen') ...[
          const SizedBox(height: 10),
          GestureDetector(
            onTap: () => launchUrl(
              Uri.parse('https://bailian.console.aliyun.com/?tab=model#/api-key'),
              mode: LaunchMode.externalApplication,
            ),
            child: Row(
              children: [
                Icon(Icons.open_in_new_rounded,
                    size: 14, color: cs.primary),
                const SizedBox(width: 6),
                Text(l10n.getFreApiKey,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: cs.primary)),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        TextField(
          controller: _keyController,
          obscureText: true,
          autofocus: true,
          decoration: InputDecoration(
            labelText: l10n.apiKey,
            border: const OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _baseUrlController,
          decoration: InputDecoration(
            labelText: l10n.baseUrl,
            border: const OutlineInputBorder(),
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
        ],
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _fetchModels,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.fetchModels),
          ),
        ),
      ],
    );
  }

  Widget _pickModel() {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          padding: EdgeInsets.zero,
          onPressed: _loading
              ? null
              : () => setState(() {
                    _step = 4;
                    _error = null;
                  }),
        ),
        const SizedBox(height: 8),
        Text(l10n.selectAModel,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(l10n.modelsAvailable(_models.length, _picked!.label),
            style: TextStyle(color: cs.onSurface.withValues(alpha: 0.6))),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: _models.length,
            itemBuilder: (_, i) {
              final model = _models[i];
              final selected = model == _selectedModel;
              return ListTile(
                title: Text(model,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
                    )),
                trailing: selected
                    ? Icon(Icons.check_circle_rounded,
                        color: cs.primary, size: 20)
                    : null,
                selected: selected,
                selectedTileColor: cs.primary.withValues(alpha: 0.08),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                dense: true,
                onTap: () => setState(() => _selectedModel = model),
              );
            },
          ),
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: TextStyle(color: cs.error, fontSize: 13)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _loading ? null : _verifyAndSave,
            style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(l10n.verifyAndContinue),
          ),
        ),
      ],
    );
  }
}
