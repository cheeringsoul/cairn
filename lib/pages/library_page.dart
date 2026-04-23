import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/constants.dart';
import '../services/db/database.dart';
import '../services/library_export.dart';
import '../services/library_provider.dart';
import '../services/markdown_import.dart';
import '../services/url_extractor.dart';
import '../widgets/shared.dart';

import 'saved_item_detail_page.dart';

/// Library tab — browse folders + saved items.
///
/// Layout:
///   - top: permanent search bar (title / body / user notes LIKE)
///   - horizontal folder chip row (All + each folder + "+ New")
///   - card list of items in the current folder, newest first
///
/// Matches REQUIREMENTS "资料库页(统一)": Notes/表达/单词 are folders,
/// not tables, and the user can create their own folders.
class LibraryPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final bool embedded;
  const LibraryPage({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.embedded = false,
  });

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  final _searchController = TextEditingController();
  bool _initialized = false;
  bool _selectMode = false;
  final Set<String> _selected = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final library = context.read<LibraryProvider>();
      Future.microtask(() => library.load());
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _typeLabel(String type, AppLocalizations l10n) {
    switch (type) {
      case 'vocab':
        return l10n.vocab;
      case 'insight':
        return l10n.insight;
      case 'action':
        return l10n.action;
      case 'fact':
        return l10n.fact;
      case 'question':
        return l10n.question;
      default:
        return type[0].toUpperCase() + type.substring(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final library = context.watch<LibraryProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.embedded && !_selectMode
          ? null
          : _selectMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() {
                  _selectMode = false;
                  _selected.clear();
                }),
              ),
              title: Text(l10n.selectedCount(_selected.length),
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                TextButton(
                  onPressed: () {
                    if (_selected.length == library.items.length) {
                      setState(() => _selected.clear());
                    } else {
                      setState(() => _selected.addAll(
                          library.items.map((i) => i.id)));
                    }
                  },
                  child: Text(
                      _selected.length == library.items.length
                          ? l10n.deselectAll
                          : l10n.selectAll),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded),
                  onPressed: _selected.isEmpty
                      ? null
                      : () => _confirmBatchDelete(context),
                ),
              ],
            )
          : AppBar(
              title: Text(l10n.library,
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              centerTitle: true,
              actions: [
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (v) {
                    if (v == 'import') _importMarkdown(context);
                    if (v == 'export_md') _export(context, 'md');
                    if (v == 'export_json') _export(context, 'json');
                    if (v == 'url') _saveUrl(context);
                    if (v == 'batch_delete') {
                      setState(() => _selectMode = true);
                    }
                  },
                  itemBuilder: (_) => [
                    PopupMenuItem(
                      value: 'url',
                      child: Row(
                        children: [
                          const Icon(Icons.link_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(l10n.saveFromUrl),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'import',
                      child: Row(
                        children: [
                          const Icon(Icons.file_download_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(l10n.importMarkdown),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_md',
                      child: Row(
                        children: [
                          const Icon(Icons.file_upload_outlined, size: 20),
                          const SizedBox(width: 10),
                          Text(l10n.exportAsMarkdown),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'export_json',
                      child: Row(
                        children: [
                          const Icon(Icons.data_object_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(l10n.exportAsJson),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'batch_delete',
                      child: Row(
                        children: [
                          const Icon(Icons.checklist_rounded, size: 20),
                          const SizedBox(width: 10),
                          Text(l10n.batchDelete),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
      floatingActionButton: _selectMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showQuickNoteEditor(context),
              tooltip: l10n.quickNote,
              icon: const Icon(Icons.edit_rounded),
              label: Text(l10n.quickNote),
            ),
      body: Column(
        children: [
          if (!widget.embedded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => library.setSearch(v),
                decoration: InputDecoration(
                  hintText: l10n.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  isDense: true,
                  filled: true,
                  fillColor: cs.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                ),
              ),
            ),
          // Primary filter: item type (vocab / insight / action / …)
          if (library.allTypes.isNotEmpty)
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(l10n.all),
                      selected: library.currentType == null,
                      onSelected: (_) => library.selectType(null),
                    ),
                  ),
                  for (final type in library.allTypes)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        label: Text(_typeLabel(type, l10n)),
                        selected: library.currentType == type,
                        onSelected: (_) => library.selectType(
                            library.currentType == type ? null : type),
                      ),
                    ),
                ],
              ),
            ),
          // Secondary filter: tags
          if (library.allTags.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final tag in library.allTags)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        label: Text('#$tag',
                            style: const TextStyle(fontSize: 11)),
                        selected: library.currentTag == tag,
                        visualDensity: VisualDensity.compact,
                        onSelected: (sel) =>
                            library.selectTag(sel ? tag : null),
                      ),
                    ),
                ],
              ),
            ),
          // Optional: user-created folders (only shown when any exist)
          if (library.folders.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  for (final f in library.folders)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onLongPress: () =>
                            _confirmDeleteFolder(context, f),
                        child: FilterChip(
                          avatar: Text(f.icon, style: const TextStyle(fontSize: 12)),
                          label: Text(f.name,
                              style: const TextStyle(fontSize: 11)),
                          selected: library.currentFolderId == f.id,
                          visualDensity: VisualDensity.compact,
                          onSelected: (sel) =>
                              library.selectFolder(sel ? f.id : null),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 4),
          Expanded(
            child: library.items.isEmpty
                ? _EmptyState(
                    hasSearch: library.search.trim().isNotEmpty,
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 8, 14, 20),
                    itemCount: library.items.length,
                    itemBuilder: (_, i) {
                      final item = library.items[i];
                      if (_selectMode) {
                        final checked = _selected.contains(item.id);
                        return Row(
                          children: [
                            Checkbox(
                              value: checked,
                              onChanged: (_) => setState(() {
                                if (checked) {
                                  _selected.remove(item.id);
                                } else {
                                  _selected.add(item.id);
                                }
                              }),
                            ),
                            Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() {
                                  if (checked) {
                                    _selected.remove(item.id);
                                  } else {
                                    _selected.add(item.id);
                                  }
                                }),
                                child: _ItemCard(item: item),
                              ),
                            ),
                          ],
                        );
                      }
                      return _ItemCard(item: item);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /// Export currently filtered items as markdown or JSON.
  Future<void> _export(BuildContext context, String format) async {
    final library = context.read<LibraryProvider>();
    await exportLibraryItems(
      context: context,
      items: library.items,
      format: format,
    );
  }

  Future<void> _importMarkdown(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    try {
      final imported = await MarkdownImport(library).pickAndImport();
      if (imported.isEmpty) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importedCount(imported.length))),
      );
      // Fire background AI analysis for each imported item.
      library.analyzeItems(imported);
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.importFailed('$e'))),
      );
    }
  }


  Future<void> _confirmBatchDelete(BuildContext context) async {
    final count = _selected.length;
    final library = context.read<LibraryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteCountItems(count)),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(ctx).colorScheme.error),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok != true) return;
    await library.deleteItems(_selected.toList());
    if (!mounted) return;
    setState(() {
      _selected.clear();
      _selectMode = false;
    });
  }

  Future<void> _saveUrl(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    final urlCtrl = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.saveFromUrl),
        content: TextField(
          controller: urlCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'https://...',
            border: OutlineInputBorder(),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.fetch)),
        ],
      ),
    );
    if (confirmed != true) return;
    final url = urlCtrl.text.trim();
    if (url.isEmpty) return;

    messenger.showSnackBar(
        SnackBar(content: Text(l10n.fetchingPage)));
    try {
      final (title, body) = await UrlExtractor.extract(url);
      final item = await library.saveItem(
        title: title,
        body: '$body\n\n[Source]($url)',
        metaStatus: MetaStatus.pending,
      );
      library.analyzeItems([item]);
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.savedTitle(title))));
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
          SnackBar(content: Text(l10n.failedError(e.toString()))));
    }
  }

  Future<void> _showQuickNoteEditor(BuildContext context) async {
    final library = context.read<LibraryProvider>();
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final l10n = AppLocalizations.of(context)!;
    final saved = await showAdaptiveSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final ctxL10n = AppLocalizations.of(ctx)!;
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(ctxL10n.quickNote,
                        style: const TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w600)),
                  ),
                  TextButton(
                    onPressed: () {
                      if (bodyCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx, true);
                    },
                    child: Text(ctxL10n.save),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: titleCtrl,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: ctxL10n.titleOptional,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                textInputAction: TextInputAction.next,
              ),
              const SizedBox(height: 10),
              TextField(
                controller: bodyCtrl,
                decoration: InputDecoration(
                  hintText: ctxL10n.writeYourNote,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 12,
                minLines: 8,
              ),
            ],
          ),
        );
      },
    );

    if (saved != true) return;
    final body = bodyCtrl.text.trim();
    if (body.isEmpty) return;
    final title = titleCtrl.text.trim().isNotEmpty
        ? titleCtrl.text.trim()
        : _deriveNoteTitle(body, l10n);

    if (!mounted) return;
    // User typed a title → lock it; derived title → let AI overwrite.
    final userTypedTitle = titleCtrl.text.trim().isNotEmpty;
    final item = await library.saveItem(
      title: title,
      body: body,
      metaStatus: MetaStatus.pending,
      titleLocked: userTypedTitle,
    );
    library.analyzeItems([item]);
  }

  String _deriveNoteTitle(String body, AppLocalizations l10n) {
    final first = body.split('\n').firstWhere(
        (l) => l.trim().isNotEmpty,
        orElse: () => l10n.untitled);
    final clean = first.trim();
    return clean.length > 60 ? '${clean.substring(0, 60)}…' : clean;
  }

  Future<void> _confirmDeleteFolder(
      BuildContext context, Folder folder) async {
    final library = context.read<LibraryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteFolderTitle(folder.name)),
        content: Text(l10n.deleteFolderMessage),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(l10n.delete)),
        ],
      ),
    );
    if (ok == true) {
      await library.deleteFolder(folder.id);
    }
  }
}

class _ItemCard extends StatelessWidget {
  final SavedItem item;
  const _ItemCard({required this.item});

  Future<void> _confirmDeleteItem(
      BuildContext context, SavedItem item) async {
    final library = context.read<LibraryProvider>();
    final l10n = AppLocalizations.of(context)!;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.deleteItem),
        content: Text(l10n.cannotBeUndone),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (ok == true) {
      // FK cascades drop item_tags + item_embeddings; review columns live
      // on saved_items itself, so a single row delete clears everything.
      await library.deleteItem(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final preview = item.body.replaceAll(RegExp(r'\s+'), ' ').trim();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SavedItemDetailPage(item: item)),
            );
          },
          onLongPress: () => _confirmDeleteItem(context, item),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (item.itemType != null &&
                        item.itemType!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.itemType!.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Text(
                        formatRelativeDate(item.updatedAt, l10n),
                        style: TextStyle(
                            fontSize: 11,
                            color: cs.onSurface.withValues(alpha: 0.4)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w600),
                ),
                if (preview.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    preview,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.6),
                        height: 1.4),
                  ),
                ],
                _buildTagsOrAnalyzing(context, cs, l10n),
                if (item.userNotes.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.edit_note_rounded,
                          size: 14,
                          color: cs.onSurface.withValues(alpha: 0.45)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.userNotes,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontSize: 11,
                              fontStyle: FontStyle.italic,
                              color: cs.onSurface.withValues(alpha: 0.5)),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTagsOrAnalyzing(BuildContext context, ColorScheme cs, AppLocalizations l10n) {
    final library = context.watch<LibraryProvider>();
    if (library.isAnalyzing(item.id)) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              l10n.analyzing,
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
          ],
        ),
      );
    }
    final tags = CairnMeta.decodeTags(item.tags);
    if (tags.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 4,
        runSpacing: 4,
        children: [
          for (final tag in tags.take(4))
            Text(
              '#$tag',
              style: TextStyle(
                fontSize: 10,
                color: cs.onSurface.withValues(alpha: 0.5),
              ),
            ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final bool hasSearch;
  const _EmptyState({required this.hasSearch});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bookmark_border_rounded,
              size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            hasSearch ? l10n.noMatches : l10n.nothingSavedYet,
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.7)),
          ),
          const SizedBox(height: 4),
          Text(
            hasSearch
                ? l10n.tryDifferentKeyword
                : l10n.longPressToSave,
            style: TextStyle(
                fontSize: 12, color: cs.onSurface.withValues(alpha: 0.45)),
          ),
        ],
      ),
    );
  }
}
