import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/library_provider.dart';
import '../widgets/shared.dart';

const _typeColors = <String, Color>{
  'vocab': Color(0xFF4CAF50),
  'concept': Color(0xFF42A5F5),
  'insight': Color(0xFFFF9800),
  'fact': Color(0xFF26C6DA),
  'action': Color(0xFFEF5350),
  'recipe': Color(0xFFAB47BC),
  'question': Color(0xFFFFCA28),
  'reference': Color(0xFF78909C),
};

class ReportPage extends StatefulWidget {
  final bool embedded;
  const ReportPage({super.key, this.embedded = false});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  String _range = 'week';
  KnowledgeReport? _report;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final library = context.read<LibraryProvider>();
    final now = DateTime.now();
    final DateTime from;
    switch (_range) {
      case 'week':
        from = now.subtract(const Duration(days: 7));
        break;
      case 'month':
        from = DateTime(now.year, now.month - 1, now.day);
        break;
      default:
        from = DateTime(2000);
    }
    final report = await library.generateReport(from: from, to: now);
    if (!mounted) return;
    setState(() {
      _report = report;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        title: Text(l10n.knowledgeReport,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(value: 'week', label: Text(l10n.week)),
                    ButtonSegment(value: 'month', label: Text(l10n.month)),
                    ButtonSegment(value: 'all', label: Text(l10n.allTime)),
                  ],
                  selected: {_range},
                  onSelectionChanged: (s) {
                    _range = s.first;
                    _load();
                  },
                ),
                const SizedBox(height: 16),
                _buildStatRow(cs, l10n),
                if (_report!.typeCounts.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDonutSection(cs, l10n),
                ],
                if (_report!.topTags.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildTagsSection(cs, l10n),
                ],
                if (_report!.entities.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildEntitiesSection(cs, l10n),
                ],
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  // ---- Top stat cards ----

  Widget _buildStatRow(ColorScheme cs, AppLocalizations l10n) {
    final tagCount = _report!.topTags.length;
    final entityCount = _report!.entities.length;

    return Row(
      children: [
        Expanded(
          child: _MiniStatCard(
            icon: Icons.auto_stories_rounded,
            label: l10n.itemsSaved,
            value: '${_report!.totalItems}',
            color: cs.primary,
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.label_rounded,
            label: l10n.totalTags,
            value: '$tagCount',
            color: const Color(0xFF42A5F5),
            cs: cs,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniStatCard(
            icon: Icons.category_rounded,
            label: l10n.totalEntities,
            value: '$entityCount',
            color: const Color(0xFFFF9800),
            cs: cs,
          ),
        ),
      ],
    );
  }

  // ---- Donut chart ----

  Widget _buildDonutSection(ColorScheme cs, AppLocalizations l10n) {
    final entries = _report!.typeCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.typeDistribution),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 130,
              height: 130,
              child: CustomPaint(
                painter: _DonutPainter(
                  entries: entries,
                  total: total,
                  centerColor: cs.surface,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('$total',
                          style: const TextStyle(
                              fontSize: 22, fontWeight: FontWeight.w700)),
                      Text(l10n.itemsSaved,
                          style: TextStyle(
                              fontSize: 9,
                              color: cs.onSurface.withValues(alpha: 0.5))),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: entries.map((e) {
                  final color = _typeColors[e.key] ?? cs.primary;
                  final pct = total > 0 ? (e.value * 100 / total).round() : 0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${e.key[0].toUpperCase()}${e.key.substring(1)}',
                            style: TextStyle(
                                fontSize: 12,
                                color: cs.onSurface.withValues(alpha: 0.7)),
                          ),
                        ),
                        Text('${e.value}',
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(width: 4),
                        SizedBox(
                          width: 32,
                          child: Text('$pct%',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 10,
                                  color:
                                      cs.onSurface.withValues(alpha: 0.4))),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Top tags ----

  Widget _buildTagsSection(ColorScheme cs, AppLocalizations l10n) {
    final maxVal = _report!.topTags.first.$2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.topTags),
        const SizedBox(height: 8),
        ...List.generate(_report!.topTags.length, (i) {
          final (tag, count) = _report!.topTags[i];
          return Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 18,
                  child: Text('${i + 1}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: i < 3
                              ? cs.primary
                              : cs.onSurface.withValues(alpha: 0.4))),
                ),
                const SizedBox(width: 8),
                Text('#$tag',
                    style: TextStyle(
                        fontSize: 13,
                        color: cs.onSurface.withValues(alpha: 0.7))),
                const SizedBox(width: 10),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: count / maxVal.clamp(1, 999),
                      backgroundColor: cs.primary.withValues(alpha: 0.06),
                      color: cs.primary.withValues(alpha: 0.4),
                      minHeight: 6,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text('$count',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: cs.onSurface.withValues(alpha: 0.5))),
              ],
            ),
          );
        }),
      ],
    );
  }

  // ---- Entities word cloud ----

  Widget _buildEntitiesSection(ColorScheme cs, AppLocalizations l10n) {
    final entities = _report!.entities;
    // Count frequency for font scaling.
    final freq = <String, int>{};
    for (final e in entities) {
      freq[e] = (freq[e] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final maxFreq = sorted.first.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(l10n.entitiesCount(sorted.length)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: sorted.take(40).map((e) {
            final scale = maxFreq > 1
                ? 0.7 + 0.6 * (e.value / maxFreq)
                : 1.0;
            final fontSize = (13.0 * scale).clamp(10.0, 20.0);
            final alpha = (0.4 + 0.5 * (e.value / maxFreq)).clamp(0.4, 0.9);
            return Text(e.key,
                style: TextStyle(
                    fontSize: fontSize,
                    fontWeight:
                        e.value > 1 ? FontWeight.w600 : FontWeight.w400,
                    color: cs.onSurface.withValues(alpha: alpha)));
          }).toList(),
        ),
      ],
    );
  }
}

// ============================================================
// Mini stat card
// ============================================================

class _MiniStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ColorScheme cs;

  const _MiniStatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.cs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(height: 8),
          Text(value,
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  fontSize: 11,
                  color: cs.onSurface.withValues(alpha: 0.5))),
        ],
      ),
    );
  }
}

// ============================================================
// Donut chart painter
// ============================================================

class _DonutPainter extends CustomPainter {
  final List<MapEntry<String, int>> entries;
  final int total;
  final Color centerColor;

  _DonutPainter({
    required this.entries,
    required this.total,
    required this.centerColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    final strokeWidth = radius * 0.35;
    final arcRadius = radius - strokeWidth / 2;

    var startAngle = -math.pi / 2;
    for (final entry in entries) {
      final sweep = total > 0 ? (entry.value / total) * 2 * math.pi : 0.0;
      final color = _typeColors[entry.key] ?? const Color(0xFF90A4AE);

      final paint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: arcRadius),
        startAngle,
        sweep,
        false,
        paint,
      );
      startAngle += sweep;
    }

    // Center fill to create donut hole.
    canvas.drawCircle(
      center,
      arcRadius - strokeWidth / 2,
      Paint()..color = centerColor,
    );
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      entries != old.entries || total != old.total;
}
