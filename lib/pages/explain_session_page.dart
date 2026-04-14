import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/db/database.dart';
import '../services/explain_controller.dart';
import '../services/library_provider.dart';
import '../services/model_service.dart';
import '../services/settings_provider.dart';
import '../widgets/markdown_view.dart';
import '../widgets/shared.dart';
import 'saved_item_detail_page.dart';

/// Modal page that owns a single [ExplainController].
///
/// Opens when the user taps "🤖 AI 详细释义 →" on a word lookup. Streams
/// the initial explain prompt, lets the user ask follow-ups in the same
/// conversation, and offers a prominent "Save to Library" action that
/// writes the latest answer into the Vocab folder with the source_*
/// fields inherited from the origin chat and explain_conv_id pointing
/// at this session's conversation.
class ExplainSessionPage extends StatefulWidget {
  final String word;
  final String? originConvId;
  final String? originMsgId;
  final String? originHighlight;

  const ExplainSessionPage({
    super.key,
    required this.word,
    this.originConvId,
    this.originMsgId,
    this.originHighlight,
  });

  @override
  State<ExplainSessionPage> createState() => _ExplainSessionPageState();
}

class _ExplainSessionPageState extends State<ExplainSessionPage> {
  late final ExplainController _controller;
  final _followUpController = TextEditingController();
  final _scrollController = ScrollController();
  final Set<String> _savedMsgIds = {};

  @override
  void initState() {
    super.initState();
    _controller = ExplainController(
      db: context.read<AppDatabase>(),
      settings: context.read<SettingsProvider>(),
      library: context.read<LibraryProvider>(),
      word: widget.word,
      originConvId: widget.originConvId,
      originMsgId: widget.originMsgId,
      originHighlight: widget.originHighlight,
    );
    _controller.addListener(_onChange);
    Future.microtask(() => _controller.start());
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    Future.delayed(const Duration(milliseconds: 50), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.removeListener(_onChange);
    _controller.dispose();
    _followUpController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _askFollowUp() async {
    final text = _followUpController.text.trim();
    if (text.isEmpty) return;
    _followUpController.clear();
    await _controller.askFollowUp(text);
  }

  Future<void> _saveMessage(Message msg) async {
    if (msg.content.trim().isEmpty) return;
    final parsed = parseCairnMeta(msg.content);
    final library = context.read<LibraryProvider>();
    final savedItem = await library.saveItem(
      title: widget.word,
      body: parsed.body,
      sourceConvId: widget.originConvId,
      sourceMsgId: widget.originMsgId,
      sourceHighlight: widget.originHighlight,
      explainConvId: _controller.conversationId,
      meta: parsed.meta,
      titleLocked: true,
    );
    if (!mounted) return;
    setState(() => _savedMsgIds.add(msg.id));
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.savedToLibrary),
        action: SnackBarAction(
          label: l10n.view,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedItemDetailPage(item: savedItem),
              ),
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text('🔍 ${widget.word}')),
      body: Column(
        children: [
          if (_controller.lastError != null)
            Container(
              width: double.infinity,
              color: cs.errorContainer,
              padding: const EdgeInsets.all(10),
              child: Text(_controller.lastError!,
                  style: TextStyle(
                      fontSize: 12, color: cs.onErrorContainer)),
            ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
              itemCount: _controller.messages.length,
              itemBuilder: (_, i) {
                final msg = _controller.messages[i];
                final isUser = msg.role == 'user';
                final saved = _savedMsgIds.contains(msg.id);
                final isInitialPrompt =
                    msg.id == _controller.initialPromptMsgId;
                return _MessageItem(
                  message: msg,
                  isUser: isUser,
                  displayText: isInitialPrompt ? '🔍 ${widget.word}' : null,
                  canSave: !isUser &&
                      msg.content.trim().isNotEmpty &&
                      !_controller.sending,
                  isSaved: saved,
                  onSave: () => _saveMessage(msg),
                );
              },
            ),
          ),
          _buildInputBar(cs),
        ],
      ),
    );
  }

  void _showModelPicker() {
    final l10n = AppLocalizations.of(context)!;
    final settings = context.read<SettingsProvider>();
    final currentProvider = settings.providers.firstWhere(
        (p) => p.id == settings.defaultProviderId,
        orElse: () => settings.providers.first);
    final currentProviderId = currentProvider.id;
    final currentModel = settings.defaultModel.isNotEmpty
        ? settings.defaultModel
        : currentProvider.defaultModel;

    showAdaptiveSheet(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: ValueListenableBuilder<int>(
            valueListenable: ModelService.cacheVersion,
            builder: (ctx, _, __) {
              final providerModels = [
                for (final p in settings.providers)
                  ProviderModels(
                      provider: p,
                      models: ModelService.getCachedModels(p)),
              ];
              // Same visual-fallback rule as chat_page._showModelPicker:
              // scope the ✓ to the active provider's section, and fall
              // back to that provider's first model when the stored
              // [currentModel] isn't in the API-fetched list.
              int? checkedProviderIndex;
              String? checkedModel;
              for (int i = 0; i < providerModels.length; i++) {
                if (providerModels[i].provider.id == currentProviderId) {
                  checkedProviderIndex = i;
                  final list = providerModels[i].models;
                  if (list.contains(currentModel)) {
                    checkedModel = currentModel;
                  } else if (list.isNotEmpty) {
                    checkedModel = list.first;
                  }
                  break;
                }
              }
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(l10n.selectModel,
                              style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface)),
                        ),
                        RefreshModelsButton(colorScheme: cs),
                      ],
                    ),
                  ),
                  Flexible(
                    child: ListView(
                      shrinkWrap: true,
                      children: [
                        for (int pi = 0; pi < providerModels.length; pi++) ...[
                          if (pi > 0)
                            Divider(
                                height: 1,
                                color: cs.onSurface.withValues(alpha: 0.08)),
                          Padding(
                            padding:
                                const EdgeInsets.fromLTRB(20, 12, 20, 4),
                            child: Text(
                              providerModels[pi].provider.displayName,
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: cs.onSurface.withValues(alpha: 0.45)),
                            ),
                          ),
                          for (final model in providerModels[pi].models)
                            ListTile(
                              title: Text(model,
                                  style: const TextStyle(fontSize: 14)),
                              trailing: (pi == checkedProviderIndex &&
                                      model == checkedModel)
                                  ? Icon(Icons.check_rounded,
                                      color: cs.primary)
                                  : null,
                              onTap: () {
                                final provider =
                                    providerModels[pi].provider;
                                settings.setDefaultProvider(provider.id);
                                settings.setDefaultModel(model);
                                Navigator.pop(ctx);
                              },
                            ),
                        ],
                        Divider(height: 20,
                            color: cs.onSurface.withValues(alpha: 0.08)),
                        ListTile(
                          leading: const Icon(Icons.edit_rounded, size: 20),
                          title: Text(l10n.customModel,
                              style: const TextStyle(fontSize: 14)),
                          onTap: () {
                            Navigator.pop(ctx);
                            _showCustomModelInput(currentModel);
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _showCustomModelInput(String currentModel) {
    final controller = TextEditingController(text: currentModel);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.customModel),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'e.g. gpt-4o-mini',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(AppLocalizations.of(ctx)!.cancel)),
          FilledButton(
              onPressed: () {
                final model = controller.text.trim();
                if (model.isNotEmpty) {
                  context.read<SettingsProvider>().setDefaultModel(model);
                }
                Navigator.pop(ctx);
              },
              child: Text(AppLocalizations.of(ctx)!.save)),
        ],
      ),
    );
  }

  Widget _buildInputBar(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border:
            Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: _showModelPicker,
            style: IconButton.styleFrom(
              backgroundColor: cs.surfaceContainerHighest,
            ),
            icon: Icon(Icons.tune_rounded,
                size: 20, color: cs.onSurface.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: TextField(
              controller: _followUpController,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _askFollowUp(),
              minLines: 1,
              maxLines: 4,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.askFollowUp,
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _controller.sending ? null : _askFollowUp,
            style: IconButton.styleFrom(
              backgroundColor: _controller.sending
                  ? cs.onSurface.withValues(alpha: 0.1)
                  : cs.primary,
              foregroundColor: cs.onPrimary,
            ),
            icon: const Icon(Icons.arrow_upward_rounded, size: 22),
          ),
        ],
      ),
    );
  }
}

class _MessageItem extends StatelessWidget {
  final Message message;
  final bool isUser;
  final String? displayText;
  final bool canSave;
  final bool isSaved;
  final VoidCallback onSave;
  const _MessageItem({
    required this.message,
    required this.isUser,
    this.displayText,
    required this.canSave,
    required this.isSaved,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bubble = Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.85),
      decoration: BoxDecoration(
        color: isUser ? cs.primary : cs.surfaceContainerHighest,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isUser ? 18 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 18),
        ),
      ),
      child: message.content.isEmpty
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : isUser
              ? SelectableText(
                  displayText ?? message.content,
                  style: TextStyle(
                      fontSize: 15, height: 1.5, color: cs.onPrimary),
                )
              : LookupSelectableMarkdown(
                  data: message.content,
                  baseFontSize: 15,
                  originConvId: message.conversationId,
                  originMsgId: message.id,
                ),
    );

    return Column(
      crossAxisAlignment:
          isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        bubble,
        if (canSave || isSaved)
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: IconButton(
              tooltip: isSaved ? AppLocalizations.of(context)!.saved : AppLocalizations.of(context)!.saveToLibrary,
              icon: Icon(
                  isSaved
                      ? Icons.bookmark_rounded
                      : Icons.bookmark_add_outlined,
                  size: 16),
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 32, minHeight: 32),
              color: isSaved
                  ? cs.onSurface
                  : cs.onSurface.withValues(alpha: 0.55),
              onPressed: isSaved ? null : onSave,
            ),
          ),
      ],
    );
  }
}

