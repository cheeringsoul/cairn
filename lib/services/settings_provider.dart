import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import 'constants.dart';
import 'db/database.dart';
import 'embedding/fanout_queue.dart';
import 'embedding/health_monitor.dart';
import 'embedding/service.dart';
import 'llm/llm_provider.dart';
import 'model_service.dart';
import 'secure_key_store.dart';

/// Canonical setting keys used in the AppSettings kv table.
class SettingsKeys {
  static const aboutMe = 'about_me';
  static const defaultProviderId = 'default_provider_id';
  static const defaultModel = 'default_model';
  static const explainPromptTemplate = 'explain_prompt_template';
  static const hasCompletedOnboarding = 'onboarding_done';
  static const totalInputTokens = 'total_input_tokens';
  static const totalOutputTokens = 'total_output_tokens';
  static const totalApiCalls = 'total_api_calls';
  static const avatarPath = 'avatar_path';
  static const displayName = 'display_name';
  static const locale = 'locale';
  static const enabledTools = 'enabled_tools';
  static const httpProxy = 'http_proxy';
  /// One-shot marker: set to '1' the first time we clear the
  /// dev-auto-seeded Qwen row. Guards the purge from re-running and
  /// accidentally deleting a user's manually-added Qwen whose key
  /// happens to share the last 4 chars.
  static const legacySeedPurged = 'legacy_seed_purged';
  // Last-4 chars of each search backend API key. Stored so the
  // Settings UI can show "…abcd" without reading the Keychain on
  // every rebuild. Empty string = no key configured.
  static const tavilyKeyTail = 'tavily_key_tail';
  static const braveKeyTail = 'brave_key_tail';
}

/// Names used by the search-backend pseudo-tools (registered for UI
/// toggle purposes; not exposed to the LLM — see [WebSearchTool] which
/// dispatches based on these toggles).
class SearchBackendNames {
  static const tavily = 'web_search_tavily';
  static const brave = 'web_search_brave';
}

/// Default template used when the user first opens the app. The template
/// is user-editable from Settings → "AI 详细释义 prompt".
const defaultExplainPromptTemplate = '''请详细解释单词 "{word}" 的含义和用法。包括:
1. 核心含义(中英对照)
2. 词性和常见搭配
3. 日常口语中的使用频率(高频/中频/低频/书面语为主)，以及在口语中通常怎么用
4. 3-5 个典型例句(带中文翻译)。如果系统提示里有用户的个人介绍，请根据用户的职业或背景额外给出 1-2 个贴合其实际场景的例句(比如用户是程序员，就给出编程工作中可能用到这个词的例句)
5. 同义词和辨析(如果有容易混淆的)
6. 词源或记忆提示(如果有用)

请用简洁清晰的格式回答，不要啰嗦。''';

/// Static catalog of supported provider kinds. Displayed on the
/// onboarding page and in "+ Add provider". Custom endpoints use the
/// 'custom' kind and let the user fill in their own base URL.
class ProviderKinds {
  static const openai = 'openai';
  static const anthropic = 'anthropic';
  static const deepseek = 'deepseek';
  static const qwen = 'qwen';
  static const zhipu = 'zhipu';
  static const moonshot = 'moonshot';
  static const doubao = 'doubao';
  static const minimax = 'minimax';
  static const baichuan = 'baichuan';
  static const stepfun = 'stepfun';
  static const siliconflow = 'siliconflow';
  static const gemini = 'gemini';
  static const mistral = 'mistral';
  static const groq = 'groq';
  static const grok = 'grok';
  static const custom = 'custom';

  static const List<({String kind, String label, String baseUrl, String defaultModel})>
      catalog = [
    (
      kind: openai,
      label: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      defaultModel: 'gpt-4o',
    ),
    (
      kind: anthropic,
      label: 'Anthropic',
      baseUrl: 'https://api.anthropic.com/v1',
      defaultModel: 'claude-sonnet-4-6',
    ),
    (
      kind: deepseek,
      label: 'DeepSeek',
      baseUrl: 'https://api.deepseek.com/v1',
      defaultModel: 'deepseek-chat',
    ),
    (
      kind: qwen,
      label: '通义千问 (Qwen)',
      baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1',
      defaultModel: 'qwen-plus',
    ),
    (
      kind: zhipu,
      label: '智谱 AI (Zhipu)',
      baseUrl: 'https://open.bigmodel.cn/api/paas/v4',
      defaultModel: 'glm-4-flash',
    ),
    (
      kind: moonshot,
      label: 'Moonshot (Kimi)',
      baseUrl: 'https://api.moonshot.cn/v1',
      defaultModel: 'moonshot-v1-8k',
    ),
    (
      kind: doubao,
      label: '豆包 (Doubao)',
      baseUrl: 'https://ark.cn-beijing.volces.com/api/v3',
      defaultModel: 'doubao-1.5-pro-32k',
    ),
    (
      kind: minimax,
      label: 'MiniMax',
      baseUrl: 'https://api.minimax.chat/v1',
      defaultModel: 'MiniMax-Text-01',
    ),
    (
      kind: baichuan,
      label: '百川 (Baichuan)',
      baseUrl: 'https://api.baichuan-ai.com/v1',
      defaultModel: 'Baichuan4',
    ),
    (
      kind: stepfun,
      label: '阶跃星辰 (StepFun)',
      baseUrl: 'https://api.stepfun.com/v1',
      defaultModel: 'step-1-8k',
    ),
    (
      kind: siliconflow,
      label: 'SiliconFlow',
      baseUrl: 'https://api.siliconflow.cn/v1',
      defaultModel: 'deepseek-ai/DeepSeek-V3',
    ),
    (
      kind: gemini,
      label: 'Google Gemini',
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta/openai',
      defaultModel: 'gemini-2.5-flash',
    ),
    (
      kind: mistral,
      label: 'Mistral',
      baseUrl: 'https://api.mistral.ai/v1',
      defaultModel: 'mistral-large-latest',
    ),
    (
      kind: groq,
      label: 'Groq',
      baseUrl: 'https://api.groq.com/openai/v1',
      defaultModel: 'llama-3.3-70b-versatile',
    ),
    (
      kind: grok,
      label: 'xAI Grok',
      baseUrl: 'https://api.x.ai/v1',
      defaultModel: 'grok-2-latest',
    ),
    (
      kind: anthropic,
      label: 'Anthropic (Local Proxy)',
      baseUrl: 'http://localhost:8000/v1',
      defaultModel: 'claude-sonnet-4-6',
    ),
    (
      kind: custom,
      label: 'Custom (OpenAI-compatible)',
      baseUrl: '',
      defaultModel: '',
    ),
  ];
}

/// App-wide settings state: provider list, About me text, default
/// model selection, explain-prompt template, onboarding flag.
///
/// Data sources:
///   - Provider metadata → `provider_configs` table
///   - Provider API keys → OS keychain (`SecureKeyStore`)
///   - About me / defaults / templates → `app_settings` kv table
class SettingsProvider extends ChangeNotifier {
  final AppDatabase _db;
  final EmbeddingService? _embeddingService;
  final EmbeddingHealthMonitor? _healthMonitor;
  // Set by main.dart after construction (circular-dep workaround —
  // FanoutQueue depends on SettingsProvider via ChatProvider? Not
  // quite, but keeping it settable lets the queue attach late).
  EmbeddingFanoutQueue? embeddingFanoutQueue;
  final _uuid = const Uuid();

  SettingsProvider(
    this._db, {
    EmbeddingService? embeddingService,
    EmbeddingHealthMonitor? healthMonitor,
  })  : _embeddingService = embeddingService,
        _healthMonitor = healthMonitor;

  // Loaded state
  List<ProviderConfig> providers = const [];
  String? defaultProviderId;
  String defaultModel = '';
  String aboutMe = '';
  String avatarPath = '';
  String displayName = '';
  String explainPromptTemplate = defaultExplainPromptTemplate;
  /// `null` means follow system locale; otherwise a locale tag like 'en', 'zh', 'zh_Hant'.
  String? localeTag;
  bool onboardingDone = false;
  bool loaded = false;

  /// Global HTTP proxy used by every `dart:io` HttpClient. Stored as
  /// `host:port` or `http://host:port`. Empty string disables the
  /// override. Exists because `dart:io` ignores macOS/iOS system
  /// proxies — users on Clash/Surge etc. need to enter their local
  /// port here to route the app's traffic through the proxy.
  String httpProxy = '';

  /// Per-tool enabled/disabled overrides. Keys are tool names, values
  /// are booleans. Tools not in this map use their `enabledByDefault`.
  Map<String, bool> enabledTools = {};

  /// Last-4 chars of the configured Tavily API key, or empty string if
  /// none. The raw key lives in [SecureKeyStore] / OS Keychain.
  String tavilyKeyTail = '';

  /// Same as [tavilyKeyTail] but for Brave.
  String braveKeyTail = '';

  bool get hasTavilyKey => tavilyKeyTail.isNotEmpty;
  bool get hasBraveKey => braveKeyTail.isNotEmpty;

  // Cumulative token usage across every LLM call this app has made.
  int totalInputTokens = 0;
  int totalOutputTokens = 0;
  int totalApiCalls = 0;

  int get totalTokens => totalInputTokens + totalOutputTokens;

  // ----- loading -----

  Future<void> load() async {
    providers = await _db.select(_db.providerConfigs).get();

    // One-time cleanup: remove the legacy dev-auto-seeded Qwen row
    // (identified by its bundled API key's last-4). Earlier builds
    // inserted it automatically on first launch; now we always take
    // users through onboarding so they add their own provider.
    await _purgeLegacySeedQwen();

    // Collapse duplicate provider rows that point at the same upstream
    // endpoint. Earlier builds could end up with two Qwen rows — one
    // from the onboarding flow and one from the dev auto-seed — each
    // probed independently so one ended up embeddingCapability='yes'
    // and the other 'no'. Merging them here ensures the providers
    // page shows one row per real endpoint.
    await _dedupeProviders();

    final rows = await _db.select(_db.appSettings).get();
    final map = {for (final r in rows) r.key: r.value};

    aboutMe = map[SettingsKeys.aboutMe] ?? '';
    // Normalize legacy absolute paths to bare filename.
    final rawAvatar = map[SettingsKeys.avatarPath] ?? '';
    avatarPath = rawAvatar.contains('/') ? p.basename(rawAvatar) : rawAvatar;
    displayName = map[SettingsKeys.displayName] ?? '';
    defaultProviderId = map[SettingsKeys.defaultProviderId];
    defaultModel = map[SettingsKeys.defaultModel] ?? '';
    explainPromptTemplate =
        map[SettingsKeys.explainPromptTemplate] ?? defaultExplainPromptTemplate;
    final rawLocale = map[SettingsKeys.locale] ?? '';
    localeTag = rawLocale.isEmpty ? null : rawLocale;
    onboardingDone = (map[SettingsKeys.hasCompletedOnboarding] ?? '') == '1';
    httpProxy = map[SettingsKeys.httpProxy] ?? '';
    _applyHttpProxy(httpProxy);
    totalInputTokens = int.tryParse(map[SettingsKeys.totalInputTokens] ?? '') ?? 0;
    totalOutputTokens =
        int.tryParse(map[SettingsKeys.totalOutputTokens] ?? '') ?? 0;
    totalApiCalls = int.tryParse(map[SettingsKeys.totalApiCalls] ?? '') ?? 0;

    final rawTools = map[SettingsKeys.enabledTools] ?? '';
    if (rawTools.isNotEmpty) {
      final decoded = jsonDecode(rawTools);
      if (decoded is Map) {
        enabledTools = decoded.map((k, v) => MapEntry(k as String, v as bool));
      }
    }

    tavilyKeyTail = map[SettingsKeys.tavilyKeyTail] ?? '';
    braveKeyTail = map[SettingsKeys.braveKeyTail] ?? '';

    loaded = true;
    notifyListeners();

    // Pre-fetch models for all providers so the model picker opens instantly.
    if (providers.isNotEmpty) {
      ModelService.startBackgroundRefresh(providers);
    }

    // Wire up embedding health monitoring. The monitor schedules its
    // own staggered probe Timers — one per capable provider — so we
    // just hand it the current list.
    _healthMonitor?.start(providers);

    // For any provider that was stored with capability='unknown',
    // kick off a probe in the background. This handles the case
    // where the app was upgraded from a pre-embedding build: old
    // provider rows exist but none have been probed yet.
    for (final p in providers) {
      if (p.embeddingCapability == EmbeddingCapability.unknown ||
          p.embeddingCapability == EmbeddingCapability.rateLimited) {
        unawaited(_detectAndWireEmbedding(p.id));
      }
    }
  }

  // ----- Token usage -----

  /// Record a single LLM call's token usage. Updates both the global
  /// running totals (for quick display) and inserts a detailed row
  /// into usage_records (for breakdowns).
  Future<void> recordUsage(
    TokenUsage usage, {
    String providerId = '',
    String model = '',
    String kind = 'chat',
  }) async {
    totalInputTokens += usage.inputTokens;
    totalOutputTokens += usage.outputTokens;
    totalApiCalls += 1;
    await _writeSetting(
        SettingsKeys.totalInputTokens, totalInputTokens.toString());
    await _writeSetting(
        SettingsKeys.totalOutputTokens, totalOutputTokens.toString());
    await _writeSetting(SettingsKeys.totalApiCalls, totalApiCalls.toString());
    // Detailed per-call record.
    await _db.into(_db.usageRecords).insert(UsageRecordsCompanion.insert(
          providerId: providerId,
          model: model,
          kind: kind,
          inputTokens: usage.inputTokens,
          outputTokens: usage.outputTokens,
          createdAt: DateTime.now(),
        ));
    notifyListeners();
  }

  // ----- About me -----

  Future<void> setAboutMe(String text) async {
    aboutMe = text;
    await _writeSetting(SettingsKeys.aboutMe, text);
    notifyListeners();
  }

  // ----- Profile -----

  Future<void> setAvatarPath(String path) async {
    // Store only the filename so it survives app container path changes.
    final filename = p.basename(path);
    avatarPath = filename;
    await _writeSetting(SettingsKeys.avatarPath, filename);
    notifyListeners();
  }

  /// Resolves [avatarPath] (a bare filename) to a full filesystem path.
  /// Returns empty string if no avatar is set or the file doesn't exist.
  Future<String> resolveAvatarPath() async {
    if (avatarPath.isEmpty) return '';
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$avatarPath');
    return file.existsSync() ? file.path : '';
  }

  Future<void> setDisplayName(String name) async {
    displayName = name;
    await _writeSetting(SettingsKeys.displayName, name);
    notifyListeners();
  }

  // ----- Explain prompt template -----

  Future<void> setExplainPromptTemplate(String template) async {
    explainPromptTemplate = template;
    await _writeSetting(SettingsKeys.explainPromptTemplate, template);
    notifyListeners();
  }

  // ----- Locale -----

  /// Pass `null` to follow system locale.
  Future<void> setLocale(String? tag) async {
    localeTag = tag;
    await _writeSetting(SettingsKeys.locale, tag ?? '');
    notifyListeners();
  }

  // ----- Tools -----

  /// Whether a tool is enabled. Falls back to the tool's default if
  /// the user has not explicitly toggled it.
  bool isToolEnabled(String toolName, {required bool defaultValue}) =>
      enabledTools[toolName] ?? defaultValue;

  Future<void> setToolEnabled(String toolName, bool enabled) async {
    enabledTools[toolName] = enabled;
    await _writeSetting(
        SettingsKeys.enabledTools, jsonEncode(enabledTools));
    notifyListeners();
  }

  /// Return the set of currently-enabled tool names, given all
  /// available tools and their defaults.
  Set<String> enabledToolNames(
      List<({String name, bool enabledByDefault})> allTools) {
    return {
      for (final t in allTools)
        if (isToolEnabled(t.name, defaultValue: t.enabledByDefault)) t.name,
    };
  }

  // ----- Search backend keys (Tavily / Brave) -----

  /// Persist a Tavily API key to the Keychain and store its last-4
  /// for UI display. Also flips the Tavily backend toggle on so the
  /// configure-then-enable flow lands in a working state.
  Future<void> setTavilyKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await SecureKeyStore.instance.writeSearchKey('tavily', trimmed);
    tavilyKeyTail = _tailOf(trimmed);
    await _writeSetting(SettingsKeys.tavilyKeyTail, tavilyKeyTail);
    enabledTools[SearchBackendNames.tavily] = true;
    await _writeSetting(
        SettingsKeys.enabledTools, jsonEncode(enabledTools));
    notifyListeners();
  }

  /// Remove the Tavily key from Keychain + kv. The toggle is flipped
  /// off too — a disabled backend should never claim priority over the
  /// DDG fallback just because a stale row exists.
  Future<void> clearTavilyKey() async {
    await SecureKeyStore.instance.deleteSearchKey('tavily');
    tavilyKeyTail = '';
    await _writeSetting(SettingsKeys.tavilyKeyTail, '');
    enabledTools[SearchBackendNames.tavily] = false;
    await _writeSetting(
        SettingsKeys.enabledTools, jsonEncode(enabledTools));
    notifyListeners();
  }

  Future<void> setBraveKey(String key) async {
    final trimmed = key.trim();
    if (trimmed.isEmpty) return;
    await SecureKeyStore.instance.writeSearchKey('brave', trimmed);
    braveKeyTail = _tailOf(trimmed);
    await _writeSetting(SettingsKeys.braveKeyTail, braveKeyTail);
    enabledTools[SearchBackendNames.brave] = true;
    await _writeSetting(
        SettingsKeys.enabledTools, jsonEncode(enabledTools));
    notifyListeners();
  }

  Future<void> clearBraveKey() async {
    await SecureKeyStore.instance.deleteSearchKey('brave');
    braveKeyTail = '';
    await _writeSetting(SettingsKeys.braveKeyTail, '');
    enabledTools[SearchBackendNames.brave] = false;
    await _writeSetting(
        SettingsKeys.enabledTools, jsonEncode(enabledTools));
    notifyListeners();
  }

  String _tailOf(String key) =>
      key.length <= 4 ? key : key.substring(key.length - 4);

  // ----- Default model -----

  Future<void> setDefaultModel(String model) async {
    defaultModel = model;
    await _writeSetting(SettingsKeys.defaultModel, model);
    notifyListeners();
  }

  // ----- Providers -----

  /// Create a provider config and stash its API key in the keychain.
  /// Returns the new provider id.
  ///
  /// Side-effects (when the embedding service wiring is present):
  ///
  ///   1. Kicks off [EmbeddingService.probe] in the background to
  ///      detect whether this provider supports /embeddings. On
  ///      success writes `embedding_capability='yes'` plus the
  ///      discovered model name, then triggers
  ///      [EmbeddingFanoutQueue.backfillProvider] to compute vectors
  ///      for all existing saved_items. Only after backfill finishes
  ///      does the HealthMonitor admit the provider into the query
  ///      pool — keeping recall results consistent.
  ///
  ///   2. On capability=='no', leaves the column so queries go to
  ///      other providers.
  Future<String> addProvider({
    required String kind,
    required String displayName,
    required String baseUrl,
    required String defaultModel,
    required String apiKey,
  }) async {
    final id = _uuid.v4();
    final keyLast4 = apiKey.length >= 4
        ? apiKey.substring(apiKey.length - 4)
        : apiKey;
    await _db.into(_db.providerConfigs).insert(
          ProviderConfigsCompanion.insert(
            id: id,
            kind: kind,
            displayName: displayName,
            baseUrl: baseUrl,
            keyLast4: Value(keyLast4),
            defaultModel: Value(defaultModel),
            createdAt: DateTime.now(),
          ),
        );
    await SecureKeyStore.instance.writeApiKey(id, apiKey);

    // First provider becomes the default automatically.
    if (defaultProviderId == null) {
      await _writeSetting(SettingsKeys.defaultProviderId, id);
      defaultProviderId = id;
      this.defaultModel = defaultModel;
      await _writeSetting(SettingsKeys.defaultModel, defaultModel);
    }

    providers = await _db.select(_db.providerConfigs).get();
    ModelService.startBackgroundRefresh(providers);
    _healthMonitor?.setProviders(providers);
    notifyListeners();

    // Fire-and-forget embedding capability probe + backfill. Runs
    // after addProvider returns so the Settings UI doesn't block
    // on the network round-trip.
    unawaited(_detectAndWireEmbedding(id));

    return id;
  }

  /// Background task: probe a freshly-added provider for embedding
  /// support, persist the result, and run the per-provider backfill
  /// if supported. Safe to call on providers that are already
  /// wired (no-op when capability is already 'yes').
  Future<void> _detectAndWireEmbedding(String providerId) async {
    final service = _embeddingService;
    final monitor = _healthMonitor;
    if (service == null || monitor == null) return;

    final provider =
        providers.firstWhere((p) => p.id == providerId, orElse: () {
      // Race: provider deleted between addProvider returning and this
      // running. Nothing to do.
      return _nullProvider;
    });
    if (provider.id.isEmpty) return;
    if (provider.embeddingCapability == EmbeddingCapability.yes) return;

    final result = await service.probe(provider);
    if (result.capability == EmbeddingCapability.yes && result.model != null) {
      await (_db.update(_db.providerConfigs)
            ..where((p) => p.id.equals(providerId)))
          .write(ProviderConfigsCompanion(
              embeddingCapability: Value(EmbeddingCapability.yes),
              embeddingModel: Value(result.model)));

      // Reload providers so the next step sees the updated row.
      providers = await _db.select(_db.providerConfigs).get();
      monitor.setProviders(providers);
      notifyListeners();

      // Seed the monitor with the probe latency so the freshly
      // added provider isn't permanently at "infinite latency"
      // until the first 10-minute probe tick fires.
      if (result.latency != null) {
        monitor.recordSuccess(providerId, result.latency!);
      }
      monitor.addProvider(providers.firstWhere((p) => p.id == providerId));

      // Run backfill in the background. When it finishes the
      // provider's embedding_backfilled_at gets set, which is the
      // signal the HealthMonitor uses to admit it into the query
      // pool.
      final queue = embeddingFanoutQueue;
      if (queue != null) {
        unawaited(queue
            .backfillProvider(
                providers.firstWhere((p) => p.id == providerId))
            .then((_) async {
          providers = await _db.select(_db.providerConfigs).get();
          monitor.setProviders(providers);
          notifyListeners();
        }));
      }
    } else {
      await (_db.update(_db.providerConfigs)
            ..where((p) => p.id.equals(providerId)))
          .write(ProviderConfigsCompanion(
              embeddingCapability: Value(result.capability)));
      providers = await _db.select(_db.providerConfigs).get();
      monitor.setProviders(providers);
      notifyListeners();
    }
  }

  /// Sentinel used by [_detectAndWireEmbedding] to detect "provider
  /// was deleted mid-flight" without needing exceptions.
  static final _nullProvider = ProviderConfig(
    id: '',
    kind: '',
    displayName: '',
    baseUrl: '',
    keyLast4: '',
    defaultModel: '',
    embeddingCapability: EmbeddingCapability.unknown,
    createdAt: DateTime.fromMillisecondsSinceEpoch(0),
  );

  Future<void> deleteProvider(String providerId) async {
    await SecureKeyStore.instance.deleteApiKey(providerId);
    await (_db.delete(_db.providerConfigs)
          ..where((t) => t.id.equals(providerId)))
        .go();
    // NOTE: item_embeddings rows are intentionally NOT deleted. Per
    // the design decision (see docs/plans/implementation-plan.md
    // §10 decision #7), re-adding the same provider later should
    // reuse its existing vectors instead of re-running backfill.

    if (defaultProviderId == providerId) {
      providers = await _db.select(_db.providerConfigs).get();
      final next = providers.isNotEmpty ? providers.first.id : null;
      await _writeSetting(SettingsKeys.defaultProviderId, next ?? '');
      defaultProviderId = next;
    } else {
      providers = await _db.select(_db.providerConfigs).get();
    }
    ModelService.startBackgroundRefresh(providers);
    _healthMonitor?.removeProvider(providerId);
    _healthMonitor?.setProviders(providers);
    notifyListeners();
  }

  Future<void> setDefaultProvider(String providerId) async {
    defaultProviderId = providerId;
    await _writeSetting(SettingsKeys.defaultProviderId, providerId);
    notifyListeners();
  }

  Future<String?> readApiKey(String providerId) =>
      SecureKeyStore.instance.readApiKey(providerId);

  // ----- Onboarding -----

  Future<void> markOnboardingDone() async {
    onboardingDone = true;
    await _writeSetting(SettingsKeys.hasCompletedOnboarding, '1');
    notifyListeners();
  }

  // ----- HTTP proxy -----

  /// Persist the proxy setting and apply it to all HTTP clients in
  /// the isolate. Pass empty string to clear.
  Future<void> setHttpProxy(String value) async {
    final normalized = value.trim();
    httpProxy = normalized;
    await _writeSetting(SettingsKeys.httpProxy, normalized);
    _applyHttpProxy(normalized);
    notifyListeners();
  }

  // ----- internal -----

  /// Merge rows that share the same `(kind, baseUrl)` — i.e. the same
  /// upstream endpoint. Keeps the "best" row and deletes the rest.
  ///
  /// Ranking for the keeper (most preferred first):
  ///   1. `embeddingCapability == yes` — embedding probe succeeded
  ///   2. row has a real API key (`keyLast4` non-empty)
  ///   3. most recently created
  ///
  /// If `default_provider_id` pointed at a deleted row, it's repointed
  /// at the keeper so the user's choice is preserved.
  Future<void> _dedupeProviders() async {
    if (providers.length < 2) return;

    final groups = <String, List<ProviderConfig>>{};
    for (final p in providers) {
      groups.putIfAbsent('${p.kind}|${p.baseUrl}', () => []).add(p);
    }

    final duplicates =
        groups.values.where((rows) => rows.length > 1).toList();
    if (duplicates.isEmpty) return;

    // Load the saved default_provider_id so we can migrate it if
    // it happens to point at a row we're about to delete. load()
    // reads the settings map *after* this step, so we go direct.
    final defaultRow = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(SettingsKeys.defaultProviderId)))
        .getSingleOrNull();
    var currentDefault = defaultRow?.value;

    final toDelete = <String>[];
    for (final rows in duplicates) {
      rows.sort((a, b) {
        final aYes = a.embeddingCapability == EmbeddingCapability.yes ? 1 : 0;
        final bYes = b.embeddingCapability == EmbeddingCapability.yes ? 1 : 0;
        if (aYes != bYes) return bYes - aYes;
        final aKey = a.keyLast4.isNotEmpty ? 1 : 0;
        final bKey = b.keyLast4.isNotEmpty ? 1 : 0;
        if (aKey != bKey) return bKey - aKey;
        return b.createdAt.compareTo(a.createdAt);
      });
      final keeper = rows.first;
      for (final dup in rows.skip(1)) {
        toDelete.add(dup.id);
        if (currentDefault == dup.id) {
          currentDefault = keeper.id;
          await _writeSetting(SettingsKeys.defaultProviderId, keeper.id);
        }
      }
    }

    for (final id in toDelete) {
      await SecureKeyStore.instance.deleteApiKey(id);
      await (_db.delete(_db.providerConfigs)..where((t) => t.id.equals(id)))
          .go();
    }
    providers = await _db.select(_db.providerConfigs).get();
  }

  /// Last-4 of the dev-bundled Qwen key that prior builds auto-seeded.
  /// Rows matching both this last-4 and `kind='qwen'` are the legacy
  /// seed and are deleted on startup so the user goes through the
  /// normal onboarding flow with their own API key.
  static const _legacySeedQwenKeyLast4 = 'cd0a';

  Future<void> _purgeLegacySeedQwen() async {
    // One-shot: after the first successful purge we mark ourselves
    // done. Any Qwen the user adds later — even one whose key happens
    // to end in `cd0a` — is safe from this cleanup.
    final marker = await (_db.select(_db.appSettings)
          ..where((t) => t.key.equals(SettingsKeys.legacySeedPurged)))
        .getSingleOrNull();
    if (marker?.value == '1') return;

    final legacy = await (_db.select(_db.providerConfigs)
          ..where((t) =>
              t.kind.equals(ProviderKinds.qwen) &
              t.keyLast4.equals(_legacySeedQwenKeyLast4)))
        .get();

    if (legacy.isNotEmpty) {
      final defaultRow = await (_db.select(_db.appSettings)
            ..where((t) => t.key.equals(SettingsKeys.defaultProviderId)))
          .getSingleOrNull();
      final currentDefault = defaultRow?.value;

      for (final row in legacy) {
        await SecureKeyStore.instance.deleteApiKey(row.id);
        await (_db.delete(_db.providerConfigs)
              ..where((t) => t.id.equals(row.id)))
            .go();
        if (currentDefault == row.id) {
          await _writeSetting(SettingsKeys.defaultProviderId, '');
        }
      }

      providers = await _db.select(_db.providerConfigs).get();

      // With the seed gone, if the user now has no providers at all,
      // re-open onboarding so they can add one of their own.
      if (providers.isEmpty) {
        await _writeSetting(SettingsKeys.hasCompletedOnboarding, '');
      }
    }

    // Mark the migration done regardless of whether anything matched:
    // on fresh installs there's nothing to delete, but we still want
    // to skip this probe on every subsequent launch.
    await _writeSetting(SettingsKeys.legacySeedPurged, '1');
  }

  Future<void> _writeSetting(String key, String value) async {
    await _db
        .into(_db.appSettings)
        .insertOnConflictUpdate(AppSetting(key: key, value: value));
  }
}

/// Install (or remove) a global HTTP proxy for every dart:io HttpClient
/// created from now on. `value` may be `host:port` or a full URL
/// (`http://host:port`). Empty string resets to direct connection.
///
/// Required because dart:io's HttpClient does NOT honor macOS / iOS
/// system proxy settings — users running Clash / Surge in system-proxy
/// (not TUN) mode would otherwise bypass the proxy and hit region-
/// blocked endpoints directly.
void _applyHttpProxy(String value) {
  if (value.isEmpty) {
    HttpOverrides.global = null;
    return;
  }
  final normalized = value.contains('://') ? value : 'http://$value';
  final uri = Uri.tryParse(normalized);
  final authority = uri?.hasAuthority == true ? uri!.authority : value;
  HttpOverrides.global = _ProxyOverrides(authority);
}

class _ProxyOverrides extends HttpOverrides {
  final String proxyAuthority; // host:port
  _ProxyOverrides(this.proxyAuthority);

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..findProxy = (uri) => 'PROXY $proxyAuthority';
  }
}
