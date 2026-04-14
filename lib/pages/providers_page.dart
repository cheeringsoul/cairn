import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../widgets/shared.dart';

import '../l10n/app_localizations.dart';
import '../services/constants.dart';
import '../services/db/database.dart';
import '../services/embedding/fanout_queue.dart';
import '../services/llm/anthropic_provider.dart';
import '../services/llm/llm_provider.dart';
import '../services/llm/openai_provider.dart';
import '../services/settings_provider.dart';

/// Providers page — API usage stats on top, provider list + add below.
class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  /// provider_id → total tokens (input + output)
  Map<String, int> _tokensByProvider = {};

  @override
  void initState() {
    super.initState();
    _loadProviderTokens();
  }

  Future<void> _loadProviderTokens() async {
    final db = context.read<AppDatabase>();
    final rows = await db.customSelect(
      'SELECT provider_id, SUM(input_tokens + output_tokens) AS total '
      'FROM usage_records GROUP BY provider_id',
    ).get();
    if (!mounted) return;
    setState(() {
      _tokensByProvider = {
        for (final r in rows)
          r.data['provider_id'] as String: (r.data['total'] as num).toInt(),
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.providers,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ---- API usage ----
          SectionHeader(l10n.apiUsage),
          const SizedBox(height: 10),
          Row(
            children: [
              _StatCard(
                icon: Icons.api_rounded,
                label: l10n.apiCalls,
                value: _formatCount(settings.totalApiCalls),
                cs: cs,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.arrow_upward_rounded,
                label: l10n.inputTokens,
                value: _formatCount(settings.totalInputTokens),
                cs: cs,
              ),
              const SizedBox(width: 10),
              _StatCard(
                icon: Icons.arrow_downward_rounded,
                label: l10n.outputTokens,
                value: _formatCount(settings.totalOutputTokens),
                cs: cs,
              ),
            ],
          ),

          // ---- Provider list ----
          const SizedBox(height: 12),
          SectionHeader(l10n.providers),
          const SizedBox(height: 6),
          ...settings.providers.map((p) => _ProviderTile(
                config: p,
                totalTokens: _tokensByProvider[p.id] ?? 0,
              )),
          ListTile(
            leading: const Icon(Icons.add),
            title: Text(l10n.addProvider),
            onTap: () => _showAddProviderSheet(context),
          ),
        ],
      ),
    );
  }
}

// ---- Helpers ----

String _formatCount(int n) {
  if (n < 1000) return '$n';
  if (n < 1000000) return '${(n / 1000).toStringAsFixed(n < 10000 ? 1 : 0)}k';
  return '${(n / 1000000).toStringAsFixed(1)}M';
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final ColorScheme cs;
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: cs.primary.withValues(alpha: 0.7)),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 11,
                    color: cs.onSurface.withValues(alpha: 0.5))),
          ],
        ),
      ),
    );
  }
}

// ---- Provider tile ----

class _ProviderTile extends StatelessWidget {
  final ProviderConfig config;
  final int totalTokens;
  const _ProviderTile({required this.config, required this.totalTokens});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final queue = context.read<EmbeddingFanoutQueue>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final isDefault = settings.defaultProviderId == config.id;
    return ListTile(
      leading: const Icon(Icons.cloud_outlined),
      title: Row(
        children: [
          Flexible(child: Text(config.displayName, overflow: TextOverflow.ellipsis)),
          if (totalTokens > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                l10n.tokensCount(_formatCount(totalTokens)),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.primary),
              ),
            ),
          ],
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${config.defaultModel} • key ••••${config.keyLast4}${isDefault ? ' • default' : ''}',
            style: const TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 2),
          _EmbeddingStatusLine(config: config, queue: queue, cs: cs),
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) async {
          if (v == 'default') {
            await settings.setDefaultProvider(config.id);
          } else if (v == 'delete') {
            final ok = await showDialog<bool>(
              context: context,
              builder: (_) => AlertDialog(
                title: Text(l10n.deleteProvider),
                content:
                    Text(l10n.removeProviderMessage(config.displayName)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(l10n.cancel)),
                  FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(l10n.delete)),
                ],
              ),
            );
            if (ok == true) await settings.deleteProvider(config.id);
          }
        },
        itemBuilder: (_) => [
          if (!isDefault)
            PopupMenuItem(
                value: 'default', child: Text(l10n.setAsDefault)),
          PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
        ],
      ),
    );
  }
}

/// Single-line footer shown under each provider tile that surfaces
/// the provider's current embedding status:
///
///   * "语义检索: 准备就绪"          — capability=yes, backfill done
///   * "语义检索: 正在建立索引 X/Y"  — backfill in flight (polled from
///                                     EmbeddingFanoutQueue)
///   * "语义检索: 探测中…"          — capability=unknown
///   * "语义检索: 不支持"           — capability=no
///   * "语义检索: 暂时不可用"       — capability=rate_limited
///
/// Uses its own 1-second polling Timer to pick up progress updates
/// from [EmbeddingFanoutQueue.backfillProgressFor] — the queue
/// itself isn't a ChangeNotifier, so we can't provider-watch it.
class _EmbeddingStatusLine extends StatefulWidget {
  final ProviderConfig config;
  final EmbeddingFanoutQueue queue;
  final ColorScheme cs;

  const _EmbeddingStatusLine({
    required this.config,
    required this.queue,
    required this.cs,
  });

  @override
  State<_EmbeddingStatusLine> createState() => _EmbeddingStatusLineState();
}

class _EmbeddingStatusLineState extends State<_EmbeddingStatusLine> {
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    // Start a 1Hz poll so we pick up progress updates while the
    // user has the page open. Cheap — only running while this
    // tile is visible.
    _poll = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cfg = widget.config;
    final cs = widget.cs;

    String text;
    IconData icon;
    Color color;

    final progress = widget.queue.backfillProgressFor(cfg.id);
    if (progress != null) {
      text = '语义检索: 正在建立索引 ${progress.completed}/${progress.total}';
      icon = Icons.sync_rounded;
      color = cs.primary;
    } else {
      switch (cfg.embeddingCapability) {
        case EmbeddingCapability.yes:
          if (cfg.embeddingBackfilledAt != null) {
            text = '语义检索: 准备就绪';
            icon = Icons.check_circle_outline_rounded;
            color = cs.primary;
          } else {
            text = '语义检索: 正在初始化…';
            icon = Icons.sync_rounded;
            color = cs.primary;
          }
          break;
        case EmbeddingCapability.no:
          text = '语义检索: 不支持';
          icon = Icons.block_rounded;
          color = cs.onSurface.withValues(alpha: 0.4);
          break;
        case EmbeddingCapability.rateLimited:
          text = '语义检索: 暂时不可用';
          icon = Icons.pause_circle_outline_rounded;
          color = cs.onSurface.withValues(alpha: 0.5);
          break;
        case EmbeddingCapability.unknown:
        default:
          text = '语义检索: 探测中…';
          icon = Icons.radio_button_unchecked_rounded;
          color = cs.onSurface.withValues(alpha: 0.5);
      }
    }

    return Row(
      children: [
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ---- Add provider sheet ----

void _showAddProviderSheet(BuildContext context) {
  showAdaptiveSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _AddProviderSheet(),
  );
}

class _AddProviderSheet extends StatefulWidget {
  const _AddProviderSheet();

  @override
  State<_AddProviderSheet> createState() => _AddProviderSheetState();
}

class _AddProviderSheetState extends State<_AddProviderSheet> {
  ({String kind, String label, String baseUrl, String defaultModel}) _picked =
      ProviderKinds.catalog.first;
  final _keyController = TextEditingController();
  final _baseUrlController = TextEditingController();
  final _nameController = TextEditingController();
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _applyPicked(_picked);
  }

  void _applyPicked(
      ({String kind, String label, String baseUrl, String defaultModel}) p) {
    _picked = p;
    _baseUrlController.text = p.baseUrl;
    _nameController.text = p.label;
  }

  @override
  void dispose() {
    _keyController.dispose();
    _baseUrlController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showKindPicker(BuildContext context, AppLocalizations l10n) {
    final cs = Theme.of(context).colorScheme;
    showAdaptiveSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          // Column + Flexible-wrapped ListView: the header stays
          // pinned while the (potentially tall) provider list scrolls
          // inside the sheet's bounded height. Without this wrap,
          // entries past the viewport on desktop (showDialog capped
          // at ~680px) get clipped — hiding Gemini / Mistral / Groq /
          // Custom which sit in the back half of the catalog.
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Text(l10n.kind,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface)),
              ),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in ProviderKinds.catalog)
                      ListTile(
                        title:
                            Text(p.label, style: const TextStyle(fontSize: 14)),
                        subtitle: p.baseUrl.isNotEmpty
                            ? Text(p.baseUrl,
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                        cs.onSurface.withValues(alpha: 0.45)))
                            : null,
                        trailing: p.label == _picked.label
                            ? Icon(Icons.check_rounded, color: cs.primary)
                            : null,
                        onTap: () {
                          setState(() => _applyPicked(p));
                          Navigator.pop(ctx);
                        },
                      ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _save() async {
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
      _saving = true;
      _error = null;
    });

    // Validate by sending a short test message.
    try {
      final LlmProvider testProvider;
      final model = _picked.defaultModel;
      if (_picked.kind == ProviderKinds.anthropic) {
        testProvider = AnthropicProvider(baseUrl: baseUrl, apiKey: key);
      } else {
        testProvider = OpenAiProvider(baseUrl: baseUrl, apiKey: key);
      }
      final stream = testProvider.streamChat(
        messages: [const LlmMessage(role: 'user', content: 'Hi')],
        model: model,
      );
      // Consume the stream with a timeout — we only need to confirm it works.
      await stream.first.timeout(const Duration(seconds: 15));
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _error = l10n.connectionTimedOut;
          _saving = false;
        });
      }
      return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = l10n.validationFailed(e.toString());
          _saving = false;
        });
      }
      return;
    }

    // Validation passed — save the provider.
    if (!mounted) return;
    try {
      final settings = context.read<SettingsProvider>();
      await settings.addProvider(
            kind: _picked.kind,
            displayName: _nameController.text.trim().isEmpty
                ? _picked.label
                : _nameController.text.trim(),
            baseUrl: baseUrl,
            defaultModel: _picked.defaultModel,
            apiKey: key,
          );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = '$e';
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(bottom: insets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.addProvider,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => _showKindPicker(context, l10n),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: l10n.kind,
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.arrow_drop_down_rounded),
                ),
                child: Text(_picked.label,
                    style: const TextStyle(fontSize: 16)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: l10n.displayName,
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
            const SizedBox(height: 12),
            TextField(
              controller: _keyController,
              obscureText: true,
              decoration: InputDecoration(
                labelText: l10n.apiKey,
                border: const OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                      fontSize: 13)),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white)),
                          const SizedBox(width: 10),
                          Text(l10n.validating,
                              style: const TextStyle(color: Colors.white)),
                        ],
                      )
                    : Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
