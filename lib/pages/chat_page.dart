import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/chat_provider.dart';
import '../services/constants.dart';
import '../services/db/database.dart';
import '../services/library_provider.dart';
import '../services/title_deriver.dart';
import '../services/model_service.dart';
import '../services/persona_provider.dart';
import '../services/review_provider.dart';
import '../services/settings_provider.dart';
import '../services/theme_provider.dart';
import '../widgets/app_nav_drawer.dart';
import '../widgets/message_bubble.dart';
import '../widgets/persona_editor_sheet.dart';
import '../widgets/shared.dart';
import 'providers_page.dart';
import 'review_page.dart';
import 'saved_item_detail_page.dart';

/// Main chat page.
///
/// - Left drawer: recent conversations.
/// - Top-right "+" starts a fresh conversation.
/// - Long-press any message for copy / edit / regenerate / delete.
class ChatPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  const ChatPage({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

/// Max length for save-item titles derived from message text.

class _ChatPageState extends State<ChatPage> {
  final _controller = TextEditingController();
  final _composerFocus = FocusNode();
  final _scrollController = ScrollController();
  final Set<String> _savedMsgIds = {};
  final Map<String, GlobalKey> _messageKeys = {};
  bool _initialized = false;
  bool _showScrollToBottom = false;
  String? _lastConvId;
  bool _hasSeenConvState = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final provider = context.read<ChatProvider>();
      Future.microtask(() => provider.loadConversations());
    }
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final pos = _scrollController.position;

    // Show "scroll to bottom" button when scrolled up more than
    // half the viewport height — works across screen sizes/densities.
    final distFromBottom = pos.maxScrollExtent - pos.pixels;
    final threshold = pos.viewportDimension * 0.5;
    final shouldShow = distFromBottom > threshold;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }

    // Trigger load-more when near the top — use 25% of viewport
    // so the prefetch distance scales with screen size.
    final loadMoreThreshold = pos.viewportDimension * 0.25;
    if (pos.pixels > loadMoreThreshold) return;
    if (pos.outOfRange) return;

    final provider = context.read<ChatProvider>();
    if (!provider.hasMoreOlderMessages) return;
    if (provider.loadingMoreMessages) return;

    _triggerLoadMoreWithScrollCompensation(provider);
  }

  /// Load the next older page while keeping the currently-visible
  /// messages pinned in place. Flutter's default behavior when new
  /// items are prepended to a ListView.builder is to shift the
  /// viewport — from the user's perspective the content jumps
  /// downward by however many pixels of new content were inserted
  /// above. Not what we want in a chat UI.
  ///
  /// Fix: capture [maxScrollExtent] before loading, wait a frame
  /// for the new items to lay out, then jump by the delta so the
  /// user's finger stays on the same message it was tracking.
  Future<void> _triggerLoadMoreWithScrollCompensation(
    ChatProvider provider,
  ) async {
    final preExtent = _scrollController.hasClients
        ? _scrollController.position.maxScrollExtent
        : 0.0;
    final prePixels = _scrollController.hasClients
        ? _scrollController.position.pixels
        : 0.0;

    await provider.loadMoreMessages();
    if (!mounted) return;

    // Let the ListView rebuild and lay out the new items before
    // measuring the new extent. Two post-frame callbacks is the
    // reliable way to run "after the next paint".
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final postExtent = _scrollController.position.maxScrollExtent;
      final delta = postExtent - preExtent;
      if (delta > 0) {
        _scrollController.jumpTo(prePixels + delta);
      }
    });
  }

  Future<void> _saveToLibrary(Message msg) async {
    final l10n = AppLocalizations.of(context)!;
    final library = context.read<LibraryProvider>();
    // Capture the provider eagerly so post-await we never touch
    // BuildContext — avoids the use_build_context_synchronously lint.
    final chatProvider = context.read<ChatProvider>();

    // If the chat auto-save already wrote a row for this message (with
    // in_library = false), promote it instead of inserting a duplicate.
    final existing = await library.findBySourceMsgId(msg.id);
    SavedItem savedItem;
    if (existing != null) {
      if (!existing.inLibrary) {
        await library.addToLibrary(existing.id);
      }
      savedItem = (await library.findBySourceMsgId(msg.id))!;
    } else {
      // No row yet — parse meta from the assistant reply and insert.
      final parsed = parseCairnMeta(msg.content);
      final msgs = chatProvider.messages;
      final idx = msgs.indexWhere((m) => m.id == msg.id);
      String? precedingQuestion;
      if (idx > 0 && msgs[idx - 1].role == MessageRole.user) {
        precedingQuestion = msgs[idx - 1].content.trim();
      }
      final title = parsed.meta?.title ??
          TitleDeriver.fromChatContext(
            precedingUserQuestion: precedingQuestion,
            body: parsed.body,
            emptyFallback: l10n.untitled,
          );
      savedItem = await library.saveItem(
        title: title,
        body: parsed.body,
        sourceConvId: msg.conversationId,
        sourceMsgId: msg.id,
        meta: parsed.meta,
      );
    }

    if (!mounted) return;
    setState(() => _savedMsgIds.add(msg.id));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.savedToLibrary),
        duration: const Duration(milliseconds: 1500),
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

  /// Remove a message from the user-facing Library. This does NOT wipe
  /// the underlying saved_item row — the auto-captured knowledge and
  /// its embeddings (when Phase 2 lands) survive for recall purposes.
  /// Only the `in_library` flag flips back to false.
  Future<void> _removeFromLibrary(Message msg) async {
    final library = context.read<LibraryProvider>();
    final existing = await library.findBySourceMsgId(msg.id);
    if (existing == null) {
      // Nothing on disk — just clear the transient UI state.
      if (!mounted) return;
      setState(() => _savedMsgIds.remove(msg.id));
      context.read<ChatProvider>().autoSavedMsgIds.remove(msg.id);
      return;
    }

    await library.removeFromLibrary(existing.id);
    if (!mounted) return;
    setState(() => _savedMsgIds.remove(msg.id));
    context.read<ChatProvider>().autoSavedMsgIds.remove(msg.id);
  }

  /// Drop focus from the composer and proactively hide the soft
  /// keyboard. Calling [FocusNode.unfocus] alone isn't always enough
  /// on Android — if focus moved while the keyboard was up (e.g. a
  /// reply stream started, the user tapped the drawer hamburger)
  /// the IME can linger or reappear when a new route is pushed.
  /// [SystemChannels.textInput] closes the IME regardless of which
  /// node Flutter currently tracks as focused.
  void _dismissKeyboard() {
    _composerFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    SystemChannels.textInput.invokeMethod('TextInput.hide');
  }

  void _send() {
    final provider = context.read<ChatProvider>();
    // While the assistant is replying, new sends are blocked — the
    // user must tap stop first. Keeps the reply/send flow linear so
    // queued messages can't race a mid-stream abort.
    if (provider.sending) return;
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    _dismissKeyboard();
    provider.sendMessage(text);
    _scrollToBottom();
  }

  void _scrollToMessage(String msgId, ChatProvider provider) {
    final key = _messageKeys[msgId];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.0, // place at top of viewport
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 80), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _controller.dispose();
    _composerFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  /// Pop the soft keyboard on first entry to a fresh chat screen, and
  /// whenever the user returns to the empty composer state (tap "new
  /// conversation", drawer's new-chat action, context-pressure tag).
  /// Skipped once a conversation has any messages so the keyboard
  /// doesn't re-open during streaming or after a history rebuild.
  void _maybeFocusComposerForNewConversation(ChatProvider provider) {
    if (provider.loading) return;
    final isFreshComposer =
        provider.currentConversationId == null && provider.messages.isEmpty;
    final firstTime = !_hasSeenConvState;
    final justReset = _hasSeenConvState && _lastConvId != null;
    if (isFreshComposer && (firstTime || justReset)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _composerFocus.requestFocus();
      });
    }
    _lastConvId = provider.currentConversationId;
    _hasSeenConvState = true;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();
    final cs = Theme.of(context).colorScheme;
    if (provider.sending) _scrollToBottom();
    _maybeFocusComposerForNewConversation(provider);

    // Handle scroll-to-message requests (e.g. from Source link in detail page).
    if (provider.scrollToMessageId != null && !provider.loading) {
      final targetId = provider.scrollToMessageId!;
      provider.scrollToMessageId = null;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToMessage(targetId, provider);
      });
    }

    // Surface error state once per change.
    if (provider.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final err = provider.lastError;
        if (err == null) return;
        provider.lastError = null;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      });
    }

    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu_rounded),
            onPressed: () {
              // Hide the IME before the drawer animation starts —
              // if focus is still on the composer TextField when a
              // new route is pushed, Flutter re-asserts focus once
              // the drawer lays out and the soft keyboard pops.
              _dismissKeyboard();
              Scaffold.of(ctx).openDrawer();
            },
          ),
        ),
        title: Text(l10n.appName,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          _ReviewIndicator(),
          IconButton(
            tooltip: l10n.newConversation,
            icon: const Icon(Icons.add_rounded),
            onPressed: () => provider.startNewConversation(),
          ),
        ],
      ),
      onDrawerChanged: (isOpened) {
        // Covers the edge-swipe path (bypasses the leading icon) and
        // the close direction — restoring focus to the composer when
        // a route pops would pop the keyboard back up.
        _dismissKeyboard();
      },
      drawer: AppNavDrawer(
        currentIndex: widget.currentIndex,
        onSelect: widget.onNavigate,
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
        children: [
          const _EmbeddingMissingBanner(),
          Expanded(
            child: provider.loading
                ? const Center(child: CircularProgressIndicator())
                : provider.messages.isEmpty
                    ? _EmptyState()
                    : Stack(
                        children: [
                          _buildMessageList(provider),
                          if (_showScrollToBottom)
                            Positioned(
                              bottom: 12,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: _ScrollToBottomButton(
                                  onTap: _scrollToBottom,
                                ),
                              ),
                            ),
                        ],
                      ),
          ),
          _buildToolStatus(provider),
          if (provider.contextPressureWarn) _ContextPressureTag(provider: provider),
          _buildPersonaSelector(cs, provider),
          _buildInputBar(cs, provider),
        ],
      )),
    );
  }

  Widget _buildToolStatus(ChatProvider provider) {
    final status = provider.activeToolStatus;
    if (status == null) return const SizedBox.shrink();
    // Look up display labels from the registry.
    final labels = status.toolNames;
    final text = labels.isNotEmpty ? labels.join(', ') : '…';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// Build the message list with a "load more" header row pinned
  /// to the top whenever [ChatProvider.hasMoreOlderMessages] is
  /// true. The header is just a bit of vertical padding with an
  /// optional spinner — the actual load is triggered by the scroll
  /// listener set up in [initState], not by a user tap.
  Widget _buildMessageList(ChatProvider provider) {
    final showHeader = provider.hasMoreOlderMessages;
    final headerCount = showHeader ? 1 : 0;

    return ListView.builder(
      controller: _scrollController,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      itemCount: provider.messages.length + headerCount,
      itemBuilder: (_, i) {
        if (showHeader && i == 0) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: provider.loadingMoreMessages
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox.shrink(),
            ),
          );
        }
        final msgIndex = i - headerCount;
        final msg = provider.messages[msgIndex];
        final isLastAssistant = msg.role == 'assistant' &&
            msgIndex == provider.messages.length - 1 &&
            !provider.sending;
        final key = _messageKeys.putIfAbsent(msg.id, () => GlobalKey());
        final isSaved = _savedMsgIds.contains(msg.id) ||
            provider.autoSavedMsgIds.contains(msg.id);
        final showRetry = provider.failedUserMsgId == msg.id;
        if (showRetry) {
          return Column(
            key: key,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              MessageBubble(
                message: msg,
                isLastAssistant: isLastAssistant,
                isSaved: isSaved,
                onDelete: () => provider.deleteMessage(msg.id),
                onEdit: msg.role == 'user'
                    ? (text) => provider.editUserMessage(msg.id, text)
                    : null,
                onRegenerate: null,
                onSave: null,
                onRemoveSave: null,
              ),
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 4, bottom: 4),
                child: TextButton.icon(
                  onPressed: provider.sending
                      ? null
                      : () => provider.retryFailedSend(),
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text('重试', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor:
                        Theme.of(context).colorScheme.error,
                  ),
                ),
              ),
            ],
          );
        }
        return MessageBubble(
          key: key,
          message: msg,
          isLastAssistant: isLastAssistant,
          isSaved: isSaved,
          onDelete: () => provider.deleteMessage(msg.id),
          onEdit: msg.role == 'user'
              ? (text) => provider.editUserMessage(msg.id, text)
              : null,
          onRegenerate:
              isLastAssistant ? () => provider.regenerateLast() : null,
          onSave: msg.role == 'assistant' ? () => _saveToLibrary(msg) : null,
          onRemoveSave: msg.role == 'assistant'
              ? () => _removeFromLibrary(msg)
              : null,
        );
      },
    );
  }

  Widget _buildPersonaSelector(ColorScheme cs, ChatProvider provider) {
    final personas = context.watch<PersonaProvider>().personas;
    if (personas.isEmpty) return const SizedBox.shrink();
    final selected = provider.selectedPersonaId ?? personas.first.id;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ...personas.map((p) {
              final isSelected = p.id == selected;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Text(p.icon, style: const TextStyle(fontSize: 14)),
                  label: Text(p.name),
                  selected: isSelected,
                  showCheckmark: false,
                  onSelected: (_) => provider.selectPersona(p.id),
                  selectedColor: cs.primaryContainer,
                  labelStyle: TextStyle(
                    fontSize: 13,
                    color: isSelected ? cs.onPrimaryContainer : cs.onSurface,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
              );
            }),
            ActionChip(
              avatar: Icon(Icons.add, size: 18,
                  color: cs.onSurface.withValues(alpha: 0.6)),
              label: const SizedBox.shrink(),
              labelPadding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () => showPersonaEditorSheet(context),
            ),
          ],
        ),
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
              // Decide which row gets the ✓. Only the active provider's
              // section shows one. If [currentModel] exists in its cached
              // list → check that row; otherwise fall back to the first
              // model so the picker never appears empty when the provider's
              // /v1/models response doesn't include the catalog alias
              // (e.g. Anthropic returning dated ids like
              // `claude-sonnet-4-5-20250929`).
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
                        for (int pi = 0; pi < providerModels.length; pi++)
                          Theme(
                            // Kill ExpansionTile's default split-lines so
                            // it sits cleanly between sheet sections.
                            data: Theme.of(ctx)
                                .copyWith(dividerColor: Colors.transparent),
                            child: ExpansionTile(
                              tilePadding: const EdgeInsets.symmetric(
                                  horizontal: 20),
                              childrenPadding: EdgeInsets.zero,
                              // Auto-open the provider that owns the
                              // current selection so the user sees their
                              // active choice without an extra tap.
                              initiallyExpanded: pi == checkedProviderIndex,
                              title: Text(
                                providerModels[pi].provider.displayName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                              subtitle: pi == checkedProviderIndex &&
                                      checkedModel != null
                                  ? Text(
                                      checkedModel,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: cs.primary
                                              .withValues(alpha: 0.85)),
                                    )
                                  : Text(
                                      '${providerModels[pi].models.length} models',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.45)),
                                    ),
                              children: [
                                for (final model
                                    in providerModels[pi].models)
                                  ListTile(
                                    dense: true,
                                    contentPadding: const EdgeInsets.only(
                                        left: 40, right: 20),
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
                            ),
                          ),
                        Divider(
                            height: 20,
                            color: cs.onSurface.withValues(alpha: 0.08)),
                        ListTile(
                          leading: const Icon(Icons.add, size: 20),
                          title: Text(l10n.addProvider,
                              style: const TextStyle(fontSize: 14)),
                          onTap: () {
                            Navigator.pop(ctx);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const ProvidersPage()),
                            );
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

  Widget _buildInputBar(ColorScheme cs, ChatProvider provider) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border(top: BorderSide(color: cs.onSurface.withValues(alpha: 0.06))),
      ),
      padding: EdgeInsets.only(
        left: 8,
        right: 8,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
        Row(
        children: [
          // Model selector button
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
              controller: _controller,
              focusNode: _composerFocus,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _send(),
              minLines: 1,
              maxLines: 4,
              style: TextStyle(fontSize: 15, color: cs.onSurface),
              decoration: InputDecoration(
                hintText: l10n.messageHint,
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.35)),
                filled: true,
                fillColor: cs.surfaceContainerHighest,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: provider.sending
                ? provider.abortCurrentReply
                : _send,
            style: IconButton.styleFrom(
              backgroundColor: provider.sending
                  ? cs.surfaceContainerHighest
                  : cs.primary,
              foregroundColor: provider.sending
                  ? cs.onSurface
                  : cs.onPrimary,
            ),
            icon: Icon(
              provider.sending
                  ? Icons.stop_rounded
                  : Icons.arrow_upward_rounded,
              size: 22,
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(l10n.welcomeToCairn,
              style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 17,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(l10n.typeMessageBelow,
              style: TextStyle(
                  color: cs.onSurface.withValues(alpha: 0.45), fontSize: 12)),
        ],
      ),
    );
  }
}

/// Soft warning bar shown at the top of [ChatPage] when the user
/// has no embedding-capable provider configured (or none of them
/// have finished their initial backfill yet). In that state the
/// chat still works, but cross-conversation memory — the
/// differentiating "second brain" feature — is silently disabled.
///
/// Keeping the user informed is important: without this banner it
/// would look like the app is just "an LLM client", and the
/// embedding pipeline would never get tested because the user
/// wouldn't know to add another provider.
class _EmbeddingMissingBanner extends StatefulWidget {
  const _EmbeddingMissingBanner();

  @override
  State<_EmbeddingMissingBanner> createState() =>
      _EmbeddingMissingBannerState();
}

class _EmbeddingMissingBannerState extends State<_EmbeddingMissingBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final settings = context.watch<SettingsProvider>();
    final anyReady = settings.providers.any((p) =>
        p.embeddingCapability == EmbeddingCapability.yes &&
        p.embeddingBackfilledAt != null);
    if (anyReady) return const SizedBox.shrink();

    final anyCapable = settings.providers
        .any((p) => p.embeddingCapability == EmbeddingCapability.yes);
    // Distinguish "no capable provider at all" from "capable provider
    // is still backfilling". The second case is transient; the first
    // needs user action.
    final message = anyCapable
        ? '正在为知识库建立语义索引，跨对话记忆稍后可用…'
        : '跨对话记忆未启用 — 添加一个支持 embedding 的 provider（OpenAI / Qwen / Gemini 等）即可开启';

    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.tertiary.withValues(alpha: 0.08),
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded,
              size: 16, color: cs.onSurface.withValues(alpha: 0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.75),
              ),
            ),
          ),
          if (!anyCapable)
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProvidersPage()),
                );
              },
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('设置', style: TextStyle(fontSize: 12)),
            ),
          IconButton(
            icon: const Icon(Icons.close_rounded, size: 16),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}

class _ScrollToBottomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _ScrollToBottomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: cs.surfaceContainer,
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.onSurface.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(Icons.keyboard_arrow_down_rounded,
            size: 22, color: cs.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

class _ReviewIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewProvider>();
    if (review.dueCount == 0) return const SizedBox.shrink();
    final theme = Theme.of(context);
    final accent = theme.extension<NavAccents>()?.review ??
        theme.colorScheme.tertiary;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReviewPage(currentIndex: -1, onNavigate: (_) {}),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.only(right: 2),
        child: Icon(Icons.school_rounded, size: 20, color: accent),
      ),
    );
  }
}

/// Small tag shown just above the composer when the current
/// conversation is approaching the context-window compress threshold
/// AND the user has no embedding-capable provider (so there is no
/// cross-conversation recall to absorb the bloat). Offers a one-tap
/// "新会话" action that both resets the chat and saves a provider
/// round-trip that would otherwise fire the compression summary.
class _ContextPressureTag extends StatelessWidget {
  final ChatProvider provider;
  const _ContextPressureTag({required this.provider});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Material(
          color: cs.tertiary.withValues(alpha: 0.12),
          shape: StadiumBorder(
            side: BorderSide(
              color: cs.tertiary.withValues(alpha: 0.35),
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: provider.startNewConversation,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_toggle_off_rounded,
                      size: 14,
                      color: cs.onSurface.withValues(alpha: 0.75)),
                  const SizedBox(width: 6),
                  Text(
                    '对话较长，建议开启新会话以保持回复质量',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: cs.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '新会话',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: cs.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
