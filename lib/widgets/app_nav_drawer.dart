import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../pages/connections_page.dart';
import '../pages/library_page.dart';
import '../pages/profile_page.dart';
import '../pages/report_page.dart';
import '../pages/review_page.dart';
import '../services/chat_provider.dart';
import '../services/db/conversation_dao.dart';
import '../services/db/database.dart';
import '../services/review_provider.dart';
import '../services/settings_provider.dart';
import '../services/theme_provider.dart';
import 'shared.dart';

/// Shared left-drawer navigation.
///
/// Layout (matching ChatGPT style):
///   Top bar: "Cairn" title left, search + avatar right.
///   Nav row: Chat / Library icons.
///   Section header: "Recent".
///   Conversation list.
///   Bottom-right: floating "new chat" capsule.
class AppNavDrawer extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onSelect;

  const AppNavDrawer({
    super.key,
    required this.currentIndex,
    required this.onSelect,
  });

  @override
  State<AppNavDrawer> createState() => _AppNavDrawerState();
}

class _AppNavDrawerState extends State<AppNavDrawer> {
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();
  String _query = '';
  List<Conversation>? _titleResults;
  List<ChatSearchResult>? _contentResults;

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    if (value.trim().isEmpty) {
      setState(() {
        _titleResults = null;
        _contentResults = null;
      });
      return;
    }
    final chat = context.read<ChatProvider>();
    final trimmed = value.trim();
    chat.searchConversations(trimmed).then((results) {
      if (mounted && _query == value) {
        setState(() => _titleResults = results);
      }
    });
    chat.searchMessageContent(trimmed).then((results) {
      if (mounted && _query == value) {
        // Filter out conversations already shown in title results.
        final titleIds = _titleResults?.map((c) => c.id).toSet() ?? {};
        setState(() => _contentResults =
            results.where((r) => !titleIds.contains(r.conversationId)).toList());
      }
    });
  }

  void _showAbout(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    showAdaptiveSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.75,
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 28,
              bottom: MediaQuery.of(ctx).padding.bottom + 28,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildAboutBody(l10n.aboutCairnBody, cs),
                const SizedBox(height: 24),
                Text(l10n.madeWithLove,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: cs.onSurface.withValues(alpha: 0.35))),
              ],
            ),
          ),
        );
      },
    );
  }

  /// Renders the about body with the first sentence of each paragraph bolded.
  Widget _buildAboutBody(String body, ColorScheme cs) {
    final paragraphs = body.split('\n\n');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < paragraphs.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _buildParagraph(paragraphs[i], cs, isIntro: i == 0),
        ],
      ],
    );
  }

  Widget _buildParagraph(String text, ColorScheme cs, {bool isIntro = false}) {
    if (isIntro) {
      return Text(text,
          style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: cs.onSurface.withValues(alpha: 0.8)));
    }
    // Bold the leading sentence (up to first period/。) as a heading.
    final match = RegExp(r'^(.+?[.。])(.*)$', dotAll: true).firstMatch(text);
    if (match == null) {
      return Text(text,
          style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: cs.onSurface.withValues(alpha: 0.8)));
    }
    return Text.rich(
      TextSpan(children: [
        TextSpan(
          text: match.group(1),
          style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              fontWeight: FontWeight.w700,
              color: cs.onSurface),
        ),
        TextSpan(
          text: match.group(2),
          style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: cs.onSurface.withValues(alpha: 0.8)),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    final review = context.watch<ReviewProvider>();
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final accents = theme.extension<NavAccents>();
    final l10n = AppLocalizations.of(context)!;

    // Use search results when searching, otherwise show all.
    final conversations = _titleResults ?? chat.conversations;

    return Drawer(
      width: MediaQuery.of(context).size.width,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ---- Top bar: Cairn + capsule (search / avatar) ----
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  // Cairn title – hidden when searching
                  if (!_searching)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _showAbout(context),
                        child: Text(
                          l10n.appName,
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  // Animated capsule
                  Expanded(
                    flex: _searching ? 1 : 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      height: 40,
                      padding: const EdgeInsets.only(left: 6, right: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Search icon / close
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _searching = !_searching;
                                if (_searching) {
                                  _searchFocus.requestFocus();
                                } else {
                                  _searchCtrl.clear();
                                  _query = '';
                                  _titleResults = null;
                                  _contentResults = null;
                                }
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Icon(
                                _searching
                                    ? Icons.close_rounded
                                    : Icons.search_rounded,
                                size: 20,
                                color: cs.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ),
                          // Inline search field
                          if (_searching)
                            Expanded(
                              child: TextField(
                                controller: _searchCtrl,
                                focusNode: _searchFocus,
                                onChanged: _onSearchChanged,
                                style: const TextStyle(fontSize: 14),
                                decoration: InputDecoration(
                                  hintText: l10n.searchConversations,
                                  hintStyle: TextStyle(
                                    fontSize: 14,
                                    color: cs.onSurface.withValues(alpha: 0.4),
                                  ),
                                  isDense: true,
                                  border: InputBorder.none,
                                  contentPadding: const EdgeInsets.symmetric(
                                      vertical: 10),
                                ),
                              ),
                            ),
                          if (!_searching) const SizedBox(width: 8),
                          // Avatar
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const ProfilePage()),
                              );
                            },
                            child: _MiniAvatar(
                              badge: review.dueCount,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_searching) ...[
              // ---- Search results ----
              Expanded(
                child: _query.isEmpty
                    ? Center(
                        child: Text(l10n.searchConversations,
                            style: TextStyle(
                                color: cs.onSurface.withValues(alpha: 0.4))),
                      )
                    : (_titleResults?.isEmpty ?? true) &&
                            (_contentResults?.isEmpty ?? true)
                        ? Center(
                            child: Text(l10n.noMatches,
                                style: TextStyle(
                                    color:
                                        cs.onSurface.withValues(alpha: 0.5))),
                          )
                        : ListView(
                            padding: const EdgeInsets.only(top: 8),
                            children: [
                              // Title matches.
                              if (_titleResults != null &&
                                  _titleResults!.isNotEmpty)
                                ...(_titleResults!.map((c) => ListTile(
                                      leading: Icon(Icons.chat_rounded,
                                          size: 18,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4)),
                                      title: Text(
                                        c.title.isEmpty
                                            ? '(untitled)'
                                            : c.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(
                                          formatRelativeDate(
                                              c.updatedAt, l10n),
                                          style:
                                              const TextStyle(fontSize: 11)),
                                      onTap: () {
                                        chat.openConversation(c.id);
                                        Navigator.pop(context);
                                        if (widget.currentIndex != 0) {
                                          widget.onSelect(0);
                                        }
                                      },
                                    ))),
                              // Content matches.
                              if (_contentResults != null &&
                                  _contentResults!.isNotEmpty) ...[
                                if (_titleResults != null &&
                                    _titleResults!.isNotEmpty)
                                  Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 12, 16, 4),
                                    child: Text(
                                      l10n.messageMatches,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4)),
                                    ),
                                  ),
                                ...(_contentResults!.map((r) => ListTile(
                                      leading: Icon(
                                          Icons.format_quote_rounded,
                                          size: 18,
                                          color: cs.onSurface
                                              .withValues(alpha: 0.4)),
                                      title: Text(
                                        r.conversationTitle.isEmpty
                                            ? '(untitled)'
                                            : r.conversationTitle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: Text(r.snippet,
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                              fontSize: 12,
                                              color: cs.onSurface
                                                  .withValues(alpha: 0.5))),
                                      onTap: () {
                                        chat.navigateToMessage(
                                            r.conversationId,
                                            r.matchedMessageId);
                                        Navigator.pop(context);
                                        if (widget.currentIndex != 0) {
                                          widget.onSelect(0);
                                        }
                                      },
                                    ))),
                              ],
                            ],
                          ),
              ),
            ] else ...[
              // ---- Quick-access row ----
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: _DrawerQuickIcon(
                        icon: Icons.bookmark_rounded,
                        label: l10n.library,
                        color: accents?.library ?? cs.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => LibraryPage(
                                currentIndex: -1,
                                onNavigate: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _DrawerQuickIcon(
                        icon: Icons.hub_rounded,
                        label: l10n.connections,
                        color: accents?.connections ?? cs.primary,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ConnectionsPage(
                                currentIndex: -1,
                                onNavigate: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _DrawerQuickIcon(
                        icon: Icons.school_rounded,
                        label: l10n.review,
                        color: accents?.review ?? Colors.orange,
                        badge: review.dueCount > 0 ? '${review.dueCount}' : null,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ReviewPage(
                                currentIndex: -1,
                                onNavigate: (_) {},
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      child: _DrawerQuickIcon(
                        icon: Icons.insights_rounded,
                        label: l10n.knowledgeReport,
                        color: accents?.report ?? Colors.teal,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const ReportPage()),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              Divider(height: 20, indent: 20, endIndent: 20,
                  color: cs.onSurface.withValues(alpha: 0.08)),
              // ---- Section header ----
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 16, 4),
                child: Text(l10n.recent,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ),
              // ---- Conversation list ----
              Expanded(
                child: Stack(
                  children: [
                    if (conversations.isEmpty)
                      Center(
                        child: Text(l10n.noConversationsYet,
                            style: TextStyle(
                                color:
                                    cs.onSurface.withValues(alpha: 0.5))),
                      )
                    else
                      ListView.builder(
                        padding: const EdgeInsets.only(bottom: 72),
                        itemCount: conversations.length,
                        itemBuilder: (_, i) {
                          final c = conversations[i];
                          final selected = widget.currentIndex == 0 &&
                              c.id == chat.currentConversationId;
                          return ListTile(
                            selected: selected,
                            title: Text(
                              c.title.isEmpty
                                  ? '(untitled)'
                                  : c.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                                formatRelativeDate(c.updatedAt, l10n),
                                style:
                                    const TextStyle(fontSize: 11)),
                            onTap: () {
                              chat.openConversation(c.id);
                              Navigator.pop(context);
                              if (widget.currentIndex != 0) {
                                widget.onSelect(0);
                              }
                            },
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(l10n.delete),
                                  content: Text(l10n.cannotBeUndone),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(ctx),
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
                            },
                          );
                        },
                      ),
                    // ---- Floating new-chat button (always visible) ----
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: _NewChatButton(
                        onTap: () {
                          chat.startNewConversation();
                          Navigator.pop(context);
                          if (widget.currentIndex != 0) {
                            widget.onSelect(0);
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

}

/// Small avatar circle used in the drawer header, with optional badge.
class _MiniAvatar extends StatelessWidget {
  final int badge;
  const _MiniAvatar({required this.badge});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final badgeColor =
        theme.extension<NavAccents>()?.review ?? Colors.orange;
    final settings = context.watch<SettingsProvider>();

    return FutureBuilder<String>(
      future: settings.resolveAvatarPath(),
      builder: (context, snapshot) {
        final resolvedPath = snapshot.data ?? '';
        final file = resolvedPath.isNotEmpty ? File(resolvedPath) : null;
        final hasImage = file != null && file.existsSync();

        return Stack(
          clipBehavior: Clip.none,
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: cs.primaryContainer,
              backgroundImage: hasImage ? FileImage(file) : null,
              child: hasImage
                  ? null
                  : Icon(Icons.person_rounded,
                      size: 18, color: cs.onPrimaryContainer),
            ),
            if (badge > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: badgeColor,
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
                        color: Colors.white),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Floating capsule button for starting a new chat, similar to ChatGPT.
class _NewChatButton extends StatelessWidget {
  final VoidCallback onTap;
  const _NewChatButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Material(
      color: cs.primary,
      borderRadius: BorderRadius.circular(24),
      elevation: 3,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit_outlined, size: 18, color: cs.onPrimary),
              const SizedBox(width: 6),
              Text(l10n.newChat,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: cs.onPrimary)),
            ],
          ),
        ),
      ),
    );
  }
}


/// Compact icon button for the drawer's quick-access row.
class _DrawerQuickIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _DrawerQuickIcon({
    required this.icon,
    required this.label,
    required this.color,
    this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final iconColor = color;
    final bgColor = color.withValues(alpha: 0.1);
    // Badge is only used on the Review tile today; the accent lives in
    // NavAccents so it shifts to match each theme's palette.
    final badgeColor =
        theme.extension<NavAccents>()?.review ?? Colors.orange;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor, size: 28),
              ),
              if (badge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(badge!,
                        style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
