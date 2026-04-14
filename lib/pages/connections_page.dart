import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/db/database.dart';
import '../services/library_provider.dart';
import '../widgets/shared.dart';
import 'saved_item_detail_page.dart';

/// Knowledge discovery page — surfaces insights about the user's
/// knowledge base: most connected hub items, isolated knowledge
/// that might need reinforcement, and tag-based exploration.
class ConnectionsPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final bool embedded;
  const ConnectionsPage({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.embedded = false,
  });

  @override
  State<ConnectionsPage> createState() => _ConnectionsPageState();
}

class _ConnectionsPageState extends State<ConnectionsPage> {
  _DiscoveryData? _data;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final library = context.read<LibraryProvider>();
    final data = await _computeDiscovery(library);
    if (!mounted) return;
    setState(() {
      _data = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        title: Text(l10n.connections,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: l10n.refresh,
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _data == null || _data!.isEmpty
              ? _buildEmpty(cs, l10n)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    children: [
                      if (_data!.hubs.isNotEmpty) ...[
                        SectionHeader(l10n.knowledgeHubs),
                        const SizedBox(height: 4),
                        ..._data!.hubs.map((h) => _HubTile(hub: h)),
                        const SizedBox(height: 20),
                      ],
                      if (_data!.topTags.isNotEmpty) ...[
                        SectionHeader(l10n.topTags),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _data!.topTags
                              .map((t) => _TagChip(tag: t.tag, count: t.count))
                              .toList(),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_data!.isolated.isNotEmpty) ...[
                        SectionHeader(l10n.isolatedKnowledge),
                        const SizedBox(height: 4),
                        ..._data!.isolated.map((item) => _ItemTile(item: item)),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.hub_rounded,
              size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(l10n.noConnectionsYet,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(l10n.saveMoreForConnections,
              style: TextStyle(
                  fontSize: 12,
                  color: cs.onSurface.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

// ============================================================
// Data model
// ============================================================

class _HubItem {
  final SavedItem item;
  final int connectionCount;
  final List<String> topRelatedTags;
  _HubItem(this.item, this.connectionCount, this.topRelatedTags);
}

class _TagCount {
  final String tag;
  final int count;
  _TagCount(this.tag, this.count);
}

class _DiscoveryData {
  final List<_HubItem> hubs;
  final List<_TagCount> topTags;
  final List<SavedItem> isolated;

  _DiscoveryData({
    required this.hubs,
    required this.topTags,
    required this.isolated,
  });

  bool get isEmpty => hubs.isEmpty && topTags.isEmpty && isolated.isEmpty;
}

Future<_DiscoveryData?> _computeDiscovery(LibraryProvider library) async {
  final clusters = await library.buildClusters();

  // Count connections per item (how many other items share tags).
  final connectionCounts = <String, int>{};
  final itemMap = <String, SavedItem>{};
  final itemTagsFromClusters = <String, Set<String>>{};

  for (final cluster in clusters) {
    for (final item in cluster.items) {
      itemMap[item.id] = item;
      connectionCounts[item.id] =
          (connectionCounts[item.id] ?? 0) + cluster.items.length - 1;
      final tags = CairnMeta.decodeTags(item.tags).toSet();
      if (item.entity != null && item.entity!.isNotEmpty) {
        tags.add(item.entity!.toLowerCase());
      }
      (itemTagsFromClusters[item.id] ??= {}).addAll(tags);
    }
  }

  // Hub items: most connected, top 5.
  final hubEntries = connectionCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  final hubs = hubEntries.take(5).map((e) {
    final item = itemMap[e.key]!;
    final tags = (itemTagsFromClusters[e.key] ?? {}).take(3).toList();
    return _HubItem(item, e.value, tags);
  }).toList();

  // Top tags across all clustered items.
  final tagCounts = <String, int>{};
  for (final tags in itemTagsFromClusters.values) {
    for (final t in tags) {
      tagCounts[t] = (tagCounts[t] ?? 0) + 1;
    }
  }
  final topTags = (tagCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value)))
      .take(12)
      .map((e) => _TagCount(e.key, e.value))
      .toList();

  // Isolated items: in library, have entity/tags, but NOT in any cluster.
  final clusteredIds = itemMap.keys.toSet();
  final allItems = library.items;
  final isolated = allItems
      .where((i) =>
          !clusteredIds.contains(i.id) &&
          ((i.entity != null && i.entity!.isNotEmpty) ||
              (i.tags != null && i.tags!.isNotEmpty)))
      .take(10)
      .toList();

  return _DiscoveryData(hubs: hubs, topTags: topTags, isolated: isolated);
}

// ============================================================
// Widgets
// ============================================================

class _HubTile extends StatelessWidget {
  final _HubItem hub;
  const _HubTile({required this.hub});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entity = hub.item.entity ?? hub.item.title;

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SavedItemDetailPage(item: hub.item)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text('${hub.connectionCount}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: cs.primary)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
                      if (hub.topRelatedTags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            hub.topRelatedTags.join(', '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                color:
                                    cs.onSurface.withValues(alpha: 0.5)),
                          ),
                        ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded,
                    size: 18, color: cs.onSurface.withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  final String tag;
  final int count;
  const _TagChip({required this.tag, required this.count});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text('#$tag  $count',
          style: TextStyle(
              fontSize: 12,
              color: cs.onSurface.withValues(alpha: 0.65))),
    );
  }
}

class _ItemTile extends StatelessWidget {
  final SavedItem item;
  const _ItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final entity = item.entity ?? item.title;
    final summary = item.summary ?? '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SavedItemDetailPage(item: item)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(Icons.circle_outlined,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.25)),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(entity,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500)),
                      if (summary.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(summary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.5))),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
