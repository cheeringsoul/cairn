import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/chat_provider.dart';
import '../services/db/conversation_dao.dart' show ChatSearchResult;
import '../services/library_export.dart';
import '../services/library_provider.dart';
import '../services/markdown_import.dart';
import '../services/model_service.dart';
import '../services/persona_provider.dart';
import '../services/review_provider.dart';
import '../services/settings_provider.dart';
import '../services/theme_provider.dart';
import '../services/db/database.dart';
import '../widgets/message_bubble.dart';
import '../widgets/persona_editor_sheet.dart';
import '../widgets/shared.dart';
import 'connections_page.dart';
import 'library_page.dart';
import 'profile_page.dart';
import 'providers_page.dart';
import 'report_page.dart';
import 'review_page.dart';

/// macOS desktop shell — three-pane layout inspired by Evernote:
///   [Sidebar nav] | [Conversation list] | [Chat + composer]
class MacDesktopShell extends StatefulWidget {
  const MacDesktopShell({super.key});

  @override
  State<MacDesktopShell> createState() => _MacDesktopShellState();
}

enum _OverlayKind { history, library, review, connections, report }

/// Hairline vertical divider used between the three panes and between
/// the overlay pane and the chat. Using theme's dividerColor keeps it
/// consistent across light/dark modes.
Widget _vDivider(BuildContext context) {
  return Container(
    width: 1,
    color: Theme.of(context).dividerColor.withValues(alpha: 0.07),
  );
}

class _MacDesktopShellState extends State<MacDesktopShell> {
  _OverlayKind? _overlay;
  // Ordered history of conversation ids the user has selected from the
  // overlay. `_back` is the undo stack, `_forward` is the redo stack.
  // When both are empty and overlay is open, `<` collapses the pane.
  final List<String> _back = [];
  final List<String> _forward = [];

  bool get canGoBack => _overlay != null && (_back.isNotEmpty);
  bool get canGoForward => _overlay != null && _forward.isNotEmpty;
  // Back is always clickable when overlay is open — empty stack means
  // the click collapses the pane instead of navigating.
  bool get backEnabled => _overlay != null;

  void goBack() {
    if (_overlay == null) return;
    if (_back.isNotEmpty) {
      final current = context.read<ChatProvider>().currentConversationId;
      final prev = _back.removeLast();
      setState(() {
        if (current != null) _forward.add(current);
      });
      context.read<ChatProvider>().openConversation(prev);
    } else {
      setState(() {
        _overlay = null;
        _forward.clear();
      });
    }
  }

  void goForward() {
    if (!canGoForward) return;
    final current = context.read<ChatProvider>().currentConversationId;
    final next = _forward.removeLast();
    setState(() {
      if (current != null) _back.add(current);
    });
    context.read<ChatProvider>().openConversation(next);
  }

  void recordHistoryPick(String newId) {
    final current = context.read<ChatProvider>().currentConversationId;
    if (current == null || current == newId) return;
    setState(() {
      _back.add(current);
      _forward.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      if (!mounted) return;
      context.read<ChatProvider>().loadConversations();
      // Seed the default provider/model on first launch so the picker
      // opens with a visible selection instead of an empty state.
      final settings = context.read<SettingsProvider>();
      if (settings.providers.isNotEmpty) {
        if (settings.defaultProviderId == null ||
            !settings.providers.any((p) => p.id == settings.defaultProviderId)) {
          settings.setDefaultProvider(settings.providers.first.id);
        }
        if (settings.defaultModel.isEmpty) {
          final p = settings.providers.firstWhere(
            (p) => p.id == settings.defaultProviderId,
            orElse: () => settings.providers.first,
          );
          final cached = ModelService.getCachedModels(p);
          final pick = cached.isNotEmpty ? cached.first : p.defaultModel;
          if (pick.isNotEmpty) settings.setDefaultModel(pick);
        }
      }
    });
  }

  void _select(_OverlayKind? kind) {
    setState(() {
      _overlay = _overlay == kind ? null : kind;
      if (_overlay == null) {
        _back.clear();
        _forward.clear();
      }
    });
  }

  void _closeOverlay() {
    if (_overlay != null) {
      setState(() {
        _overlay = null;
        _back.clear();
        _forward.clear();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Desktop needs a layered surface palette so the three panes read
    // as distinct depths. Rather than hard-code neutral gray ramps
    // (which stripped Pink of its hue and pushed Dark away from its
    // near-black identity), derive each step by tinting the active
    // theme's `surface` with its own `onSurface` ink. That keeps the
    // theme's hue while providing the depth cues the shell layout
    // needs.
    final base = Theme.of(context);
    final cs = base.colorScheme;
    // Use scaffoldBackgroundColor (Pink's faint pink, Dark's near-black,
    // Light's soft gray) as the canvas for layered tints so each theme's
    // hue is retained in the resulting surface palette.
    final canvas = base.scaffoldBackgroundColor;
    Color step(double alpha) =>
        Color.alphaBlend(cs.onSurface.withValues(alpha: alpha), canvas);
    final tuned = base.copyWith(
      colorScheme: cs.copyWith(
        surfaceContainerLow: step(0.03),
        surfaceContainer: step(0.06),
        surfaceContainerHigh: step(0.09),
        surfaceContainerHighest: step(0.12),
      ),
      // Scaffold & appBar come from the base theme — preserving Pink's
      // faint pink scaffold, Dark's near-black, and Light's soft gray.
      dividerColor: cs.onSurface.withValues(alpha: 0.06),
      scrollbarTheme: ScrollbarThemeData(
        thumbVisibility: WidgetStateProperty.all(true),
        thickness: WidgetStateProperty.all(4),
        radius: const Radius.circular(4),
        thumbColor: WidgetStateProperty.all(
          cs.onSurface.withValues(alpha: 0.22),
        ),
        trackVisibility: WidgetStateProperty.all(false),
      ),
    );
    return Theme(
      data: tuned,
      child: Builder(builder: (context) => _buildShell(context)),
    );
  }

  Widget _buildShell(BuildContext context) {
    const overlayWidth = 360.0;
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Sidebar flows under the transparent macOS titlebar; its top
          // padding already clears the traffic-light buttons.
          SizedBox(
            width: 220,
            child: _Sidebar(
              current: _overlay,
              onSelect: _select,
              onNewChat: () {
                _closeOverlay();
                context.read<ChatProvider>().startNewConversation();
              },
            ),
          ),
          _vDivider(context),
          // Right area holds the shared top bar; below it, an optional
          // slide-out pane (library / review / …) appears to the left
          // of the chat, shrinking the chat without resizing the window.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _TopBar(
                  canBack: _overlay != null,
                  canForward: _overlay != null && _forward.isNotEmpty,
                  onBack: goBack,
                  onForward: goForward,
                ),
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        width: _overlay == null ? 0 : overlayWidth,
                        child: _overlay == null
                            ? const SizedBox.shrink()
                            : ClipRect(
                                child: OverflowBox(
                                  alignment: Alignment.centerLeft,
                                  minWidth: overlayWidth,
                                  maxWidth: overlayWidth,
                                  // Key on the kind so switching between
                                  // Library/Review/… rebuilds the pane's
                                  // nested Navigator with the new page.
                                  child: _OverlayPane(
                                    key: ValueKey(_overlay),
                                    kind: _overlay!,
                                    onClose: _closeOverlay,
                                  ),
                                ),
                              ),
                      ),
                      if (_overlay != null) _vDivider(context),
                      const Expanded(child: _ChatPane()),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Left sidebar ────────────────────────────────────────────────────

class _Sidebar extends StatelessWidget {
  final _OverlayKind? current;
  final ValueChanged<_OverlayKind?> onSelect;
  final VoidCallback onNewChat;
  const _Sidebar({
    required this.current,
    required this.onSelect,
    required this.onNewChat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accents =
        theme.extension<NavAccents>() ?? _fallbackAccents(cs);
    final l10n = AppLocalizations.of(context)!;
    final review = context.watch<ReviewProvider>();

    return Container(
      color: cs.surfaceContainerLow,
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Match the height of the middle+right top bar so the sidebar
            // content starts on the same baseline without any padding hack.
            const SizedBox(height: 44),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: _NewChatButton(
                label: l10n.newChat,
                onTap: onNewChat,
              ),
            ),
            _SidebarItem(
              icon: Icons.history_rounded,
              label: l10n.chatHistory,
              selected: current == _OverlayKind.history,
              iconColor: accents.history,
              onTap: () => onSelect(_OverlayKind.history),
            ),
            // Mobile drawer order: Library → Connections → Review →
            // Report. Desktop mirrors that order, prepending the
            // desktop-only History entry above.
            _SidebarItem(
              icon: Icons.bookmark_rounded,
              label: l10n.library,
              selected: current == _OverlayKind.library,
              iconColor: accents.library,
              onTap: () => onSelect(_OverlayKind.library),
            ),
            _SidebarItem(
              icon: Icons.hub_rounded,
              label: l10n.connections,
              selected: current == _OverlayKind.connections,
              iconColor: accents.connections,
              onTap: () => onSelect(_OverlayKind.connections),
            ),
            _SidebarItem(
              icon: Icons.school_rounded,
              label: l10n.review,
              selected: current == _OverlayKind.review,
              badge: review.dueCount > 0 ? '${review.dueCount}' : null,
              iconColor: accents.review,
              onTap: () => onSelect(_OverlayKind.review),
            ),
            _SidebarItem(
              icon: Icons.insights_rounded,
              label: l10n.knowledgeReport,
              selected: current == _OverlayKind.report,
              iconColor: accents.report,
              onTap: () => onSelect(_OverlayKind.report),
            ),
            const Spacer(),
          ],
        ),
    );
  }
}

/// Safety net used if a theme forgets to attach NavAccents — falls back
/// to the Material color scheme so the sidebar still renders.
NavAccents _fallbackAccents(ColorScheme cs) => NavAccents(
      library: cs.primary,
      review: cs.tertiary,
      report: cs.secondary,
      connections: cs.primary,
      history: cs.outline,
    );

class _NewChatButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _NewChatButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: cs.onPrimary),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showProfileDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    // Listen to ThemeProvider so the dialog rebuilds (and re-applies
    // its surface/text colors) the moment the user toggles the theme
    // from inside the profile page.
    builder: (ctx) => Consumer<ThemeProvider>(
      builder: (ctx, themeProvider, _) => Theme(
        // Force the dialog subtree to use the freshly-selected theme.
        // The root MaterialApp theme swap doesn't always propagate
        // through the dialog's nested Navigator, so we override it
        // explicitly on every ThemeProvider notification.
        data: themeProvider.themeData,
        child: Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            // Caps at 420×680 on large windows; shrinks to fit on
            // smaller ones thanks to Dialog's own insetPadding.
            constraints: const BoxConstraints(maxWidth: 420, maxHeight: 680),
            child: Navigator(
              // Keying on the theme forces the nested route to rebuild
              // so every descendant picks up the new palette.
              key: ValueKey(themeProvider.theme),
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const ProfilePage(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

class _AvatarBtn extends StatelessWidget {
  final int badge;
  const _AvatarBtn({required this.badge});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    return GestureDetector(
      onTap: () => _showProfileDialog(context),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            FutureBuilder<String>(
              future: settings.resolveAvatarPath(),
              builder: (context, snap) {
                final path = snap.data ?? '';
                final file = path.isNotEmpty ? File(path) : null;
                final hasImage = file != null && file.existsSync();
                return CircleAvatar(
                  radius: 16,
                  backgroundColor: cs.primaryContainer,
                  backgroundImage: hasImage ? FileImage(file) : null,
                  child: hasImage
                      ? null
                      : Icon(Icons.person_rounded,
                          size: 18, color: cs.onPrimaryContainer),
                );
              },
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: Colors.orange,
                    shape: BoxShape.circle,
                  ),
                  constraints:
                      const BoxConstraints(minWidth: 16, minHeight: 16),
                  child: Text(
                    '$badge',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final String? badge;
  final VoidCallback onTap;
  /// Accent color used for the icon when the row is NOT selected.
  /// Mirrors the mobile drawer's quick-icon coloring so the two
  /// shells feel like the same product. Selected rows ignore this
  /// and tint to [ColorScheme.primary] like before.
  final Color? iconColor;
  const _SidebarItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.selected = false,
    this.badge,
    this.iconColor,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.14)
        : _hover
            ? Colors.black.withValues(alpha: 0.04)
            : null;
    final fg = widget.selected ? cs.primary : cs.onSurface;
    final iconFg = widget.selected
        ? cs.primary
        : (widget.iconColor ?? cs.onSurface);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: iconFg.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(widget.icon, size: 15, color: iconFg),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.selected ? FontWeight.w600 : FontWeight.w500,
                    color: fg,
                  ),
                ),
              ),
              if (widget.badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    widget.badge!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Slide-out overlay pane ──────────────────────────────────────────

class _OverlayPane extends StatefulWidget {
  final _OverlayKind kind;
  final VoidCallback onClose;
  const _OverlayPane({super.key, required this.kind, required this.onClose});

  @override
  State<_OverlayPane> createState() => _OverlayPaneState();
}

class _OverlayPaneState extends State<_OverlayPane> {
  final _searchCtrl = TextEditingController();
  String _historyQuery = '';
  List<Conversation>? _titleResults;
  List<ChatSearchResult>? _contentResults;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _runHistorySearch(String raw) {
    final value = raw.trim();
    setState(() => _historyQuery = raw);
    if (value.isEmpty) {
      setState(() {
        _titleResults = null;
        _contentResults = null;
      });
      return;
    }
    final chat = context.read<ChatProvider>();
    chat.searchConversations(value).then((titles) {
      if (!mounted || _historyQuery.trim() != value) return;
      setState(() => _titleResults = titles);
    });
    chat.searchMessageContent(value).then((contents) {
      if (!mounted || _historyQuery.trim() != value) return;
      final titleIds = _titleResults?.map((c) => c.id).toSet() ?? {};
      setState(() => _contentResults =
          contents.where((r) => !titleIds.contains(r.conversationId)).toList());
    });
  }

  bool get _showSearch =>
      widget.kind == _OverlayKind.history ||
      widget.kind == _OverlayKind.library;

  String _searchHint(AppLocalizations l10n) {
    switch (widget.kind) {
      case _OverlayKind.history:
        return l10n.searchConversations;
      case _OverlayKind.library:
        return l10n.searchHint;
      default:
        return '';
    }
  }

  void _onSearchChanged(String v) {
    switch (widget.kind) {
      case _OverlayKind.history:
        _runHistorySearch(v);
        break;
      case _OverlayKind.library:
        context.read<LibraryProvider>().setSearch(v);
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    // Hosts a nested Navigator so pushed detail pages (saved item view,
    // etc.) stay inside the overlay instead of covering the whole shell.
    return Container(
      color: cs.surface,
      child: Column(
        children: [
          if (_showSearch)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 6, 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: _onSearchChanged,
                        decoration: InputDecoration(
                          hintText: _searchHint(l10n),
                          prefixIcon:
                              const Icon(Icons.search_rounded, size: 18),
                          prefixIconConstraints: const BoxConstraints(
                              minWidth: 36, minHeight: 36),
                          isDense: true,
                          filled: true,
                          fillColor: cs.onSurface.withValues(alpha: 0.04),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  if (widget.kind == _OverlayKind.library)
                    _LibraryActionsMenu(l10n: l10n),
                ],
              ),
            ),
          Expanded(
            child: Navigator(
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => _buildPage(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage() {
    switch (widget.kind) {
      case _OverlayKind.history:
        return _HistoryPane(
          query: _historyQuery,
          titleResults: _titleResults,
          contentResults: _contentResults,
        );
      case _OverlayKind.library:
        return LibraryPage(
            currentIndex: -1, onNavigate: (_) {}, embedded: true);
      case _OverlayKind.review:
        return ReviewPage(
            currentIndex: -1, onNavigate: (_) {}, embedded: true);
      case _OverlayKind.connections:
        return ConnectionsPage(
            currentIndex: -1, onNavigate: (_) {}, embedded: true);
      case _OverlayKind.report:
        return const ReportPage(embedded: true);
    }
  }
}

/// Import / export actions for the desktop Library overlay. Mirrors the
/// PopupMenuButton in the mobile Library AppBar (see library_page.dart).
class _LibraryActionsMenu extends StatelessWidget {
  final AppLocalizations l10n;
  const _LibraryActionsMenu({required this.l10n});

  Future<void> _import(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    try {
      final imported = await MarkdownImport(library).pickAndImport();
      if (imported.isEmpty) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importedCount(imported.length))),
      );
      library.analyzeItems(imported);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed('$e'))),
      );
    }
  }

  Future<void> _export(BuildContext context, String format) async {
    final library = context.read<LibraryProvider>();
    await exportLibraryItems(
      context: context,
      items: library.items,
      format: format,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded,
          size: 20, color: cs.onSurface.withValues(alpha: 0.55)),
      tooltip: '',
      onSelected: (v) {
        if (v == 'import') _import(context);
        if (v == 'export_md') _export(context, 'md');
        if (v == 'export_json') _export(context, 'json');
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'import',
          child: Row(
            children: [
              const Icon(Icons.file_download_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.importMarkdown),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_md',
          child: Row(
            children: [
              const Icon(Icons.file_upload_outlined, size: 18),
              const SizedBox(width: 10),
              Text(l10n.exportAsMarkdown),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'export_json',
          child: Row(
            children: [
              const Icon(Icons.data_object_rounded, size: 18),
              const SizedBox(width: 10),
              Text(l10n.exportAsJson),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistoryPane extends StatelessWidget {
  final String query;
  final List<Conversation>? titleResults;
  final List<ChatSearchResult>? contentResults;
  const _HistoryPane({
    this.query = '',
    this.titleResults,
    this.contentResults,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final chat = context.watch<ChatProvider>();
    final searching = query.trim().isNotEmpty;
    return Scaffold(
      backgroundColor: cs.surface,
      body: searching
          ? _buildSearchResults(context, cs, l10n, chat)
          : _buildConversationList(context, cs, l10n, chat),
    );
  }

  Widget _buildConversationList(BuildContext context, ColorScheme cs,
      AppLocalizations l10n, ChatProvider chat) {
    final conversations = chat.conversations;
    if (conversations.isEmpty) {
      return Center(
        child: Text(
          l10n.noConversationsYet,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: conversations.length,
      itemBuilder: (_, i) {
        final c = conversations[i];
        final selected = c.id == chat.currentConversationId;
        return _HistoryTile(
          conversation: c,
          selected: selected,
          onTap: () {
            context
                .findAncestorStateOfType<_MacDesktopShellState>()
                ?.recordHistoryPick(c.id);
            chat.openConversation(c.id);
          },
          onDelete: () => _confirmDelete(context, chat, c),
        );
      },
    );
  }

  Widget _buildSearchResults(BuildContext context, ColorScheme cs,
      AppLocalizations l10n, ChatProvider chat) {
    final titles = titleResults ?? const [];
    final contents = contentResults ?? const [];
    if (titleResults == null && contentResults == null) {
      return const SizedBox.shrink();
    }
    if (titles.isEmpty && contents.isEmpty) {
      return Center(
        child: Text(
          l10n.noMatches,
          style: TextStyle(color: cs.onSurface.withValues(alpha: 0.5)),
        ),
      );
    }
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 12),
      children: [
        for (final c in titles)
          ListTile(
            dense: true,
            leading: Icon(Icons.chat_rounded,
                size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
            title: Text(
              c.title.isEmpty ? '(untitled)' : c.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(formatRelativeDate(c.updatedAt, l10n),
                style: const TextStyle(fontSize: 11)),
            onTap: () {
              context
                  .findAncestorStateOfType<_MacDesktopShellState>()
                  ?.recordHistoryPick(c.id);
              chat.openConversation(c.id);
            },
          ),
        if (contents.isNotEmpty) ...[
          if (titles.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                l10n.messageMatches,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.4),
                ),
              ),
            ),
          for (final r in contents)
            ListTile(
              dense: true,
              leading: Icon(Icons.format_quote_rounded,
                  size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
              title: Text(
                r.conversationTitle.isEmpty
                    ? '(untitled)'
                    : r.conversationTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                r.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
              onTap: () {
                context
                    .findAncestorStateOfType<_MacDesktopShellState>()
                    ?.recordHistoryPick(r.conversationId);
                chat.navigateToMessage(r.conversationId, r.matchedMessageId);
              },
            ),
        ],
      ],
    );
  }

  void _confirmDelete(
      BuildContext context, ChatProvider chat, Conversation c) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.delete),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              chat.hideConversation(c.id);
            },
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _HistoryTile extends StatefulWidget {
  final Conversation conversation;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  const _HistoryTile({
    required this.conversation,
    required this.selected,
    required this.onTap,
    required this.onDelete,
  });
  @override
  State<_HistoryTile> createState() => _HistoryTileState();
}

class _HistoryTileState extends State<_HistoryTile> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final c = widget.conversation;
    final title = c.title.isEmpty ? '(untitled)' : c.title;
    final bg = widget.selected
        ? cs.primary.withValues(alpha: 0.12)
        : _hover
            ? Colors.black.withValues(alpha: 0.03)
            : null;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        onSecondaryTap: widget.onDelete,
        behavior: HitTestBehavior.opaque,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatRelativeDate(c.updatedAt, l10n),
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Right: chat pane ────────────────────────────────────────────────

class _ChatPane extends StatefulWidget {
  const _ChatPane();
  @override
  State<_ChatPane> createState() => _ChatPaneState();
}

class _ChatPaneState extends State<_ChatPane> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _inputFocus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    _inputCtrl.clear();
    try {
      await context.read<ChatProvider>().sendMessage(text);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollCtrl.hasClients) {
          _scrollCtrl.animateTo(
            _scrollCtrl.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();

    final shell = context.findAncestorStateOfType<_MacDesktopShellState>();
    final overlayOpen = shell?._overlay != null;
    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: overlayOpen ? () => shell?._closeOverlay() : null,
            child: chat.messages.isEmpty
                ? const _EmptyChat()
                : _MessageList(
                    controller: _scrollCtrl,
                    messages: chat.messages,
                  ),
          ),
        ),
        const _PersonaStrip(),
        _Composer(
          controller: _inputCtrl,
          focusNode: _inputFocus,
          sending: _sending,
          onSend: _send,
        ),
      ],
    );
  }
}

class _TopBar extends StatelessWidget {
  final bool canBack;
  final bool canForward;
  final VoidCallback onBack;
  final VoidCallback onForward;
  const _TopBar({
    required this.canBack,
    required this.canForward,
    required this.onBack,
    required this.onForward,
  });

  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewProvider>();
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.07),
          ),
        ),
      ),
      child: Row(
        children: [
          _NavArrowBtn(
            icon: Icons.chevron_left_rounded,
            tooltip: MaterialLocalizations.of(context).backButtonTooltip,
            enabled: canBack,
            onTap: onBack,
          ),
          const SizedBox(width: 4),
          _NavArrowBtn(
            icon: Icons.chevron_right_rounded,
            tooltip: 'Forward',
            enabled: canForward,
            onTap: onForward,
          ),
          const Spacer(),
          _AvatarBtn(badge: review.dueCount),
        ],
      ),
    );
  }
}

class _NavArrowBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool enabled;
  const _NavArrowBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.enabled = true,
  });
  @override
  State<_NavArrowBtn> createState() => _NavArrowBtnState();
}

class _NavArrowBtnState extends State<_NavArrowBtn> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final enabled = widget.enabled;
    final iconColor = enabled
        ? cs.onSurface.withValues(alpha: 0.6)
        : cs.onSurface.withValues(alpha: 0.25);
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      onEnter: (_) {
        if (enabled) setState(() => _hover = true);
      },
      onExit: (_) {
        if (enabled) setState(() => _hover = false);
      },
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: enabled ? widget.onTap : null,
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: (_hover && enabled)
                  ? Colors.black.withValues(alpha: 0.05)
                  : null,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(widget.icon, size: 20, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  final ScrollController controller;
  final List<Message> messages;
  const _MessageList({required this.controller, required this.messages});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      itemCount: messages.length,
      itemBuilder: (ctx, i) {
        final m = messages[i];
        return MessageBubble(
          message: m,
          isLastAssistant:
              i == messages.length - 1 && m.role == 'assistant',
        );
      },
    );
  }
}

class _EmptyChat extends StatelessWidget {
  const _EmptyChat();
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              'C',
              style: TextStyle(
                color: cs.primary,
                fontSize: 30,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            l10n.welcomeToCairn,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            l10n.typeMessageBelow,
            style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Persona strip ───────────────────────────────────────────────────

class _PersonaStrip extends StatelessWidget {
  const _PersonaStrip();
  @override
  Widget build(BuildContext context) {
    final personas = context.watch<PersonaProvider>().personas;
    if (personas.isEmpty) return const SizedBox.shrink();
    final chat = context.watch<ChatProvider>();
    final selected = chat.selectedPersonaId ?? personas.first.id;
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final p in personas) ...[
              _PersonaChip(
                icon: p.icon,
                label: p.name,
                selected: p.id == selected,
                onTap: () => context.read<ChatProvider>().selectPersona(p.id),
                activeColor: cs.primary,
              ),
              const SizedBox(width: 6),
            ],
            _AddPersonaChip(onTap: () => showPersonaEditorSheet(context)),
          ],
        ),
      ),
    );
  }
}

class _PersonaChip extends StatelessWidget {
  final String icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color activeColor;
  const _PersonaChip({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? activeColor.withValues(alpha: 0.12) : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? activeColor.withValues(alpha: 0.5)
                : Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(icon, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? activeColor : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddPersonaChip extends StatelessWidget {
  final VoidCallback onTap;
  const _AddPersonaChip({required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
        child: Icon(Icons.add, size: 16,
            color: cs.onSurface.withValues(alpha: 0.6)),
      ),
    );
  }
}

// ─── Composer ────────────────────────────────────────────────────────

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final VoidCallback onSend;
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.12),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Shortcuts(
          // Shift+Enter inserts a newline; bare Enter still fires
          // `onSubmitted` → send.
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.enter, shift: true):
                _InsertNewlineIntent(),
          },
          child: Actions(
            actions: {
              _InsertNewlineIntent:
                  CallbackAction<_InsertNewlineIntent>(onInvoke: (_) {
                final sel = controller.selection;
                final text = controller.text;
                final start = sel.start < 0 ? text.length : sel.start;
                final end = sel.end < 0 ? text.length : sel.end;
                controller.value = TextEditingValue(
                  text: text.replaceRange(start, end, '\n'),
                  selection: TextSelection.collapsed(offset: start + 1),
                );
                return null;
              }),
            },
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const _ModelPickerIconBtn(),
                const SizedBox(width: 4),
                Expanded(
                  child: Scrollbar(
                    thumbVisibility: false,
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      maxLines: 4,
                      minLines: 1,
                      textInputAction: TextInputAction.send,
                      decoration: InputDecoration(
                        hintText: l10n.messageHint,
                        border: InputBorder.none,
                        isCollapsed: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 8),
                      ),
                      onSubmitted: (_) => onSend(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _SendButton(sending: sending, onTap: onSend),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InsertNewlineIntent extends Intent {
  const _InsertNewlineIntent();
}

class _SendButton extends StatelessWidget {
  final bool sending;
  final VoidCallback onTap;
  const _SendButton({required this.sending, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: sending ? null : onTap,
      child: MouseRegion(
        cursor:
            sending ? SystemMouseCursors.basic : SystemMouseCursors.click,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: sending ? cs.surfaceContainerHighest : cs.primary,
            borderRadius: BorderRadius.circular(10),
          ),
          child: sending
              ? SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: cs.onSurfaceVariant,
                  ),
                )
              : Icon(Icons.arrow_upward_rounded,
                  size: 18, color: cs.onPrimary),
        ),
      ),
    );
  }
}

class _ModelPickerIconBtn extends StatefulWidget {
  const _ModelPickerIconBtn();

  @override
  State<_ModelPickerIconBtn> createState() => _ModelPickerIconBtnState();
}

class _ModelPickerIconBtnState extends State<_ModelPickerIconBtn> {
  final _overlayController = OverlayPortalController();
  final _link = LayerLink();

  void _toggle() {
    if (_overlayController.isShowing) {
      _overlayController.hide();
    } else {
      _overlayController.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: ModelService.cacheVersion,
      builder: (ctx, _, __) {
        final settings = context.watch<SettingsProvider>();
        if (settings.providers.isEmpty) return const SizedBox.shrink();
        final current = settings.providers.firstWhere(
          (p) => p.id == settings.defaultProviderId,
          orElse: () => settings.providers.first,
        );
        final currentModel = settings.defaultModel.isNotEmpty
            ? settings.defaultModel
            : current.defaultModel;
        final cs = Theme.of(ctx).colorScheme;
        final l10n = AppLocalizations.of(ctx)!;

        return CompositedTransformTarget(
          link: _link,
          child: OverlayPortal(
            controller: _overlayController,
            overlayChildBuilder: (_) => _ModelPopover(
              link: _link,
              providers: settings.providers,
              currentProviderId: current.id,
              currentModel: currentModel,
              onSelect: (providerId, model) {
                settings.setDefaultProvider(providerId);
                settings.setDefaultModel(model);
                _overlayController.hide();
              },
              onAddProvider: () {
                _overlayController.hide();
                _showProvidersDialog(context);
              },
              onDismiss: () => _overlayController.hide(),
              l10n: l10n,
            ),
            child: Tooltip(
              message: '${current.displayName} · $currentModel',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggle,
                child: Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.tune_rounded,
                    size: 18,
                    color: cs.onSurface.withValues(alpha: 0.55),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ModelPopover extends StatefulWidget {
  final LayerLink link;
  final List<ProviderConfig> providers;
  final String currentProviderId;
  final String currentModel;
  final void Function(String providerId, String model) onSelect;
  final VoidCallback onAddProvider;
  final VoidCallback onDismiss;
  final AppLocalizations l10n;

  const _ModelPopover({
    required this.link,
    required this.providers,
    required this.currentProviderId,
    required this.currentModel,
    required this.onSelect,
    required this.onAddProvider,
    required this.onDismiss,
    required this.l10n,
  });

  @override
  State<_ModelPopover> createState() => _ModelPopoverState();
}

class _ModelPopoverState extends State<_ModelPopover> {
  late Set<String> _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = {widget.currentProviderId};
  }

  void _toggleSection(String id) {
    setState(() {
      if (_expanded.contains(id)) {
        _expanded.remove(id);
      } else {
        _expanded.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onDismiss,
          ),
        ),
        CompositedTransformFollower(
          link: widget.link,
          targetAnchor: Alignment.topLeft,
          followerAnchor: Alignment.bottomLeft,
          offset: const Offset(0, -8),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 280, maxHeight: 400),
            child: Material(
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              color: cs.surfaceContainerLow,
              child: ValueListenableBuilder<int>(
                valueListenable: ModelService.cacheVersion,
                builder: (ctx, _, __) => Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 2, 4, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          RefreshModelsButton(colorScheme: cs),
                        ],
                      ),
                    ),
                    Flexible(
                      child: ListView(
                        padding: const EdgeInsets.only(bottom: 4),
                        shrinkWrap: true,
                        children: [
                          for (final p in widget.providers) ...[
                            _ProviderHeader(
                              name: p.displayName,
                              isActive: p.id == widget.currentProviderId,
                              expanded: _expanded.contains(p.id),
                              cs: cs,
                              onTap: () => _toggleSection(p.id),
                            ),
                            if (_expanded.contains(p.id))
                              ..._buildModels(p, cs),
                          ],
                        ],
                      ),
                    ),
                    Divider(
                        height: 1,
                        color: cs.onSurface.withValues(alpha: 0.08)),
                    _AddProviderRow(
                      cs: cs,
                      label: widget.l10n.addProvider,
                      onTap: widget.onAddProvider,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildModels(ProviderConfig p, ColorScheme cs) {
    final cached = ModelService.getCachedModels(p);
    final models = cached.isEmpty ? [p.defaultModel] : cached;
    return [
      for (final m in models)
        _ModelRow(
          model: m,
          isActive:
              p.id == widget.currentProviderId && m == widget.currentModel,
          cs: cs,
          onTap: () => widget.onSelect(p.id, m),
        ),
    ];
  }
}

class _ProviderHeader extends StatefulWidget {
  final String name;
  final bool isActive;
  final bool expanded;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _ProviderHeader({
    required this.name,
    required this.isActive,
    required this.expanded,
    required this.cs,
    required this.onTap,
  });

  @override
  State<_ProviderHeader> createState() => _ProviderHeaderState();
}

class _ProviderHeaderState extends State<_ProviderHeader> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: _hover
                ? widget.cs.onSurface.withValues(alpha: 0.05)
                : null,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Icon(
                widget.expanded
                    ? Icons.expand_more_rounded
                    : Icons.chevron_right_rounded,
                size: 16,
                color: widget.cs.onSurface.withValues(alpha: 0.45),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  widget.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: widget.isActive
                        ? widget.cs.primary
                        : widget.cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModelRow extends StatefulWidget {
  final String model;
  final bool isActive;
  final ColorScheme cs;
  final VoidCallback onTap;
  const _ModelRow({
    required this.model,
    required this.isActive,
    required this.cs,
    required this.onTap,
  });

  @override
  State<_ModelRow> createState() => _ModelRowState();
}

class _ModelRowState extends State<_ModelRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final bg = widget.isActive
        ? widget.cs.primary.withValues(alpha: 0.1)
        : _hover
            ? widget.cs.onSurface.withValues(alpha: 0.05)
            : null;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          padding: const EdgeInsets.only(left: 32, right: 10, top: 6, bottom: 6),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.model,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        widget.isActive ? FontWeight.w600 : FontWeight.w400,
                    color: widget.isActive
                        ? widget.cs.primary
                        : widget.cs.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.isActive)
                Icon(Icons.check_rounded,
                    size: 14, color: widget.cs.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddProviderRow extends StatefulWidget {
  final ColorScheme cs;
  final String label;
  final VoidCallback onTap;
  const _AddProviderRow({
    required this.cs,
    required this.label,
    required this.onTap,
  });

  @override
  State<_AddProviderRow> createState() => _AddProviderRowState();
}

class _AddProviderRowState extends State<_AddProviderRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: _hover
                ? widget.cs.onSurface.withValues(alpha: 0.05)
                : null,
            borderRadius:
                const BorderRadius.vertical(bottom: Radius.circular(12)),
          ),
          child: Row(
            children: [
              Icon(Icons.add_rounded,
                  size: 16,
                  color: widget.cs.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: TextStyle(
                  fontSize: 13,
                  color: widget.cs.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Open [ProvidersPage] as a centered dialog so the desktop shell's
/// three-pane layout stays intact underneath. Mirrors [_showProfileDialog]
/// exactly — wraps the nested Navigator in a `Consumer<ThemeProvider>`
/// + Theme override so the embedded page inherits the user's current
/// palette instead of falling back to the Material defaults.
void _showProvidersDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (ctx) => Consumer<ThemeProvider>(
      builder: (ctx, themeProvider, _) => Theme(
        data: themeProvider.themeData,
        child: Dialog(
          insetPadding: const EdgeInsets.all(24),
          clipBehavior: Clip.antiAlias,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560, maxHeight: 720),
            child: Navigator(
              key: ValueKey(themeProvider.theme),
              onGenerateRoute: (_) => MaterialPageRoute(
                builder: (_) => const ProvidersPage(),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
