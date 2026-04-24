import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/chat_provider.dart';
import '../services/db/database.dart';
import '../services/library_provider.dart';
import '../widgets/markdown_view.dart';

/// Detail view for a single saved item.
///
/// Layout mirrors REQUIREMENTS "条目详情页(统一布局)":
///   - editable title
///   - markdown body (rendered as plain text for now)
///   - "My notes" textarea (always visible, encourages the user to
///     add their own commentary)
///   - optional "Source" block when source_conv_id / source_highlight
///     are present
class SavedItemDetailPage extends StatefulWidget {
  final SavedItem item;
  const SavedItemDetailPage({super.key, required this.item});

  @override
  State<SavedItemDetailPage> createState() => _SavedItemDetailPageState();
}

class _SavedItemDetailPageState extends State<SavedItemDetailPage> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  bool _dirty = false;
  bool _editingNotes = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.item.title);
    _notesController = TextEditingController(text: widget.item.userNotes);
    _editingNotes = widget.item.userNotes.isEmpty;
    _titleController.addListener(() => setState(() => _dirty = true));
    _notesController.addListener(() => setState(() => _dirty = true));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    await context.read<LibraryProvider>().updateItem(
          widget.item.id,
          title: _titleController.text.trim(),
          userNotes: _notesController.text,
        );
    if (!mounted) return;
    setState(() {
      _dirty = false;
      // Collapse notes back to display mode so the user immediately sees
      // what they just wrote rendered on the page.
      if (_notesController.text.trim().isNotEmpty) _editingNotes = false;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.saved)));
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final hasSource =
        item.sourceConvId != null || (item.sourceHighlight?.isNotEmpty ?? false);

    return Scaffold(
      appBar: AppBar(
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) async {
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final library = context.read<LibraryProvider>();
              final currentL10n = AppLocalizations.of(context)!;
              if (v == 'copy') {
                final md = '# ${_titleController.text}\n\n${item.body}\n'
                    '${_notesController.text.isEmpty ? '' : '\n---\n${_notesController.text}\n'}';
                await Clipboard.setData(ClipboardData(text: md));
                messenger.showSnackBar(
                    SnackBar(content: Text(currentL10n.copiedToClipboard)));
              } else if (v == 'share') {
                final md = '# ${_titleController.text}\n\n${item.body}\n'
                    '${_notesController.text.isEmpty ? '' : '\n---\n${_notesController.text}\n'}';
                // Capture origin rect before any await — after the
                // gap the BuildContext may no longer be mounted.
                final box = context.findRenderObject() as RenderBox?;
                try {
                  final dir = await getTemporaryDirectory();
                  final safeName = _titleController.text
                      .replaceAll(RegExp(r'[/\\:*?"<>|]'), '')
                      .replaceAll(RegExp(r'\s+'), '_')
                      .trim();
                  final file = File(
                      '${dir.path}/${safeName.isEmpty ? 'export' : safeName}.md');
                  await file.writeAsString(md);
                  await Share.shareXFiles(
                    [XFile(file.path)],
                    sharePositionOrigin: box != null
                        ? box.localToGlobal(Offset.zero) & box.size
                        : Rect.zero,
                  );
                } catch (e) {
                  messenger.showSnackBar(
                      SnackBar(content: Text('Share failed: $e')));
                }
              } else if (v == 'delete') {
                final ok = await showDialog<bool>(
                  context: context,
                  builder: (dctx) {
                    final dL10n = AppLocalizations.of(dctx)!;
                    return AlertDialog(
                      title: Text(dL10n.deleteItem),
                      content: Text(dL10n.cannotBeUndone),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(dctx, false),
                            child: Text(dL10n.cancel)),
                        FilledButton(
                            onPressed: () => Navigator.pop(dctx, true),
                            child: Text(dL10n.delete)),
                      ],
                    );
                  },
                );
                if (ok == true) {
                  await library.deleteItem(item.id);
                  navigator.pop();
                }
              }
            },
            itemBuilder: (_) => [
              PopupMenuItem(value: 'copy', child: Text(l10n.copyAsMarkdown)),
              PopupMenuItem(value: 'share', child: Text(l10n.shareAsFile)),
              PopupMenuItem(value: 'delete', child: Text(l10n.delete)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: l10n.title,
            ),
            maxLines: null,
          ),
          Divider(height: 20,
              color: cs.onSurface.withValues(alpha: 0.08)),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: LookupSelectableMarkdown(
              data: item.body,
              baseFontSize: 14,
              originConvId: item.sourceConvId,
              originMsgId: item.sourceMsgId,
            ),
          ),
          const SizedBox(height: 16),
          _MetaChips(item: item),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
              const SizedBox(width: 6),
              Text(l10n.myNotes,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface.withValues(alpha: 0.6))),
              const Spacer(),
              if (!_editingNotes && _notesController.text.trim().isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _editingNotes = true),
                  icon: const Icon(Icons.edit_rounded, size: 14),
                  label: Text(l10n.edit),
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (_editingNotes)
            TextField(
              controller: _notesController,
              autofocus: widget.item.userNotes.isNotEmpty,
              maxLines: null,
              minLines: 3,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: l10n.addNotesHint,
                hintStyle:
                    TextStyle(color: cs.onSurface.withValues(alpha: 0.4)),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
                border: Border(
                  left: BorderSide(color: cs.primary, width: 3),
                ),
              ),
              child: MarkdownBody(
                data: _notesController.text,
                selectable: false,
                styleSheet: buildMarkdownStyle(context, baseFontSize: 14),
                builders: markdownBuilders,
              ),
            ),
          if (hasSource) ...[
            const SizedBox(height: 20),
            _SourceBlock(item: item),
          ],
          const SizedBox(height: 20),
          _RelatedKnowledge(itemId: item.id),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _dirty ? _save : null,
              child: Text(l10n.saveChanges),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Renders the cairn-meta type badge + tag chips if the item has any.
/// Older saved items (pre cairn-meta) simply render nothing.
class _MetaChips extends StatelessWidget {
  final SavedItem item;
  const _MetaChips({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final library = context.watch<LibraryProvider>();
    if (library.isAnalyzing(item.id)) {
      return Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          children: [
            SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              l10n.aiAnalyzingTags,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ],
        ),
      );
    }
    final tags = CairnMeta.decodeTags(item.tags);
    final type = item.itemType;
    final entity = item.entity;
    if ((type == null || type.isEmpty) &&
        (entity == null || entity.isEmpty) &&
        tags.isEmpty) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          if (type != null && type.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                type.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: cs.primary,
                ),
              ),
            ),
          if (entity != null && entity.isNotEmpty)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.tertiary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                entity,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: cs.tertiary,
                ),
              ),
            ),
          for (final tag in tags)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                    color: cs.onSurface.withValues(alpha: 0.08)),
              ),
              child: Text(
                '#$tag',
                style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SourceBlock extends StatelessWidget {
  final SavedItem item;
  const _SourceBlock({required this.item});

  void _navigateToSource(BuildContext context) {
    final convId = item.sourceConvId;
    if (convId == null) return;
    final chat = context.read<ChatProvider>();
    // Pop all pushed routes (detail page, etc.) back to the root shell.
    Navigator.of(context).popUntil((route) => route.isFirst);
    // Open the conversation and scroll to the source message.
    chat.navigateToMessage(convId, item.sourceMsgId);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final tappable = item.sourceConvId != null;
    return GestureDetector(
      onTap: tappable ? () => _navigateToSource(context) : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: cs.onSurface.withValues(alpha: 0.15)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.link_rounded,
                    size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
                const SizedBox(width: 6),
                Text(l10n.source,
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface.withValues(alpha: 0.6))),
                const Spacer(),
                if (tappable)
                  Icon(Icons.open_in_new_rounded,
                      size: 14, color: cs.primary.withValues(alpha: 0.7)),
              ],
            ),
            const SizedBox(height: 8),
            if (item.sourceHighlight != null &&
                item.sourceHighlight!.isNotEmpty) ...[
              Text('"${item.sourceHighlight}"',
                  style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: cs.onSurface.withValues(alpha: 0.8))),
              const SizedBox(height: 6),
            ],
            if (item.sourceConvId != null)
              Text(l10n.tapToOpenSource,
                  style: TextStyle(
                      fontSize: 11,
                      color: cs.primary.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _RelatedKnowledge extends StatefulWidget {
  final String itemId;
  const _RelatedKnowledge({required this.itemId});

  @override
  State<_RelatedKnowledge> createState() => _RelatedKnowledgeState();
}

class _RelatedKnowledgeState extends State<_RelatedKnowledge> {
  List<({SavedItem item, double score})>? _related;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final library = context.read<LibraryProvider>();
    final results = await library.findRelatedItems(widget.itemId);
    if (!mounted) return;
    setState(() {
      _related = results;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    if (_related == null || _related!.isEmpty) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.hub_rounded,
                size: 16, color: cs.onSurface.withValues(alpha: 0.6)),
            const SizedBox(width: 6),
            Text(l10n.relatedKnowledge,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.6))),
          ],
        ),
        const SizedBox(height: 8),
        ...(_related!.map((r) => _RelatedItemTile(
              item: r.item,
              score: r.score,
            ))),
      ],
    );
  }
}

class _RelatedItemTile extends StatelessWidget {
  final SavedItem item;
  final double score;
  const _RelatedItemTile({required this.item, required this.score});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final percent = (score * 100).round().clamp(0, 100);
    final entity = item.entity ?? item.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => SavedItemDetailPage(item: item),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      if (item.summary != null && item.summary!.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(item.summary!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface.withValues(alpha: 0.5))),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(l10n.similarityPercent(percent),
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: cs.primary)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
