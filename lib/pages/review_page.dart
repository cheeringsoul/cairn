import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_localizations.dart';
import '../services/cairn_meta.dart';
import '../services/chat_provider.dart';
import '../services/db/database.dart';
import '../services/notification_service.dart';
import '../services/review_provider.dart';
import '../widgets/markdown_view.dart';
import 'saved_item_detail_page.dart';

/// Review page — spaced repetition flashcard interface.
class ReviewPage extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onNavigate;
  final bool embedded;
  const ReviewPage({
    super.key,
    required this.currentIndex,
    required this.onNavigate,
    this.embedded = false,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      final review = context.read<ReviewProvider>();
      Future.microtask(() async {
        await NotificationService.requestPermission();
        await review.loadDueItems();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final review = context.watch<ReviewProvider>();
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: widget.embedded ? null : AppBar(
        title: Text(l10n.review,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
        centerTitle: true,
        actions: [
          if (review.dueItems.isNotEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  l10n.remaining(review.dueItems.length),
                  style: TextStyle(
                      fontSize: 13,
                      color: cs.onSurface.withValues(alpha: 0.5)),
                ),
              ),
            ),
        ],
      ),
      body: review.loading
          ? const Center(child: CircularProgressIndicator())
          : review.dueItems.isEmpty
              ? _buildEmpty(cs, review, l10n)
              : _ReviewCard(
                  item: review.dueItems.first,
                  onRate: (grade) =>
                      review.rateReview(review.dueItems.first.id, grade),
                  onSkip: () => review.skipItem(review.dueItems.first.id),
                  onStopReview: () =>
                      review.disableReview(review.dueItems.first.id),
                  intervals: review.previewIntervals(review.dueItems.first),
                  embedded: widget.embedded,
                ),
    );
  }

  Widget _buildEmpty(ColorScheme cs, ReviewProvider review, AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.check_circle_outline_rounded,
              size: 48, color: cs.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(l10n.allCaughtUpTitle,
              style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: cs.onSurface.withValues(alpha: 0.7))),
          const SizedBox(height: 4),
          Text(l10n.noItemsDueForReview,
              style: TextStyle(
                  fontSize: 13,
                  color: cs.onSurface.withValues(alpha: 0.45))),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatefulWidget {
  final SavedItem item;
  final void Function(ReviewGrade grade) onRate;
  final VoidCallback onSkip;
  final VoidCallback onStopReview;
  final Map<ReviewGrade, int> intervals;
  final bool embedded;
  const _ReviewCard({
    required this.item,
    required this.onRate,
    required this.onSkip,
    required this.onStopReview,
    required this.intervals,
    this.embedded = false,
  });

  @override
  State<_ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<_ReviewCard> {
  bool _revealed = false;
  bool _showDetail = false;

  @override
  void didUpdateWidget(covariant _ReviewCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.item.id != widget.item.id) {
      _revealed = false;
      _showDetail = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final item = widget.item;
    final entity = item.entity ?? item.title;
    final summary = item.summary ?? '';
    final tags = CairnMeta.decodeTags(item.tags);

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _revealed = !_revealed),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: cs.primary.withValues(alpha: 0.15)),
                ),
                child: _revealed
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Entity header
                            Text(entity,
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            if (item.itemType != null) ...[
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color:
                                      cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.itemType!.toUpperCase(),
                                  style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: cs.primary),
                                ),
                              ),
                            ],
                            const SizedBox(height: 16),
                            // Full body
                            LookupSelectableMarkdown(
                              data: item.body,
                              baseFontSize: 14,
                              originConvId: item.sourceConvId,
                              originMsgId: item.sourceMsgId,
                            ),
                            if (tags.isNotEmpty) ...[
                              const SizedBox(height: 16),
                              Wrap(
                                spacing: 6,
                                runSpacing: 4,
                                children: tags
                                    .map((t) => Text('#$t',
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.5))))
                                    .toList(),
                              ),
                            ],
                            if (_showDetail) ...[
                              if (item.userNotes.isNotEmpty) ...[
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Icon(Icons.edit_note_rounded,
                                        size: 16,
                                        color: cs.onSurface
                                            .withValues(alpha: 0.6)),
                                    const SizedBox(width: 6),
                                    Text(l10n.myNotes,
                                        style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: cs.onSurface
                                                .withValues(alpha: 0.6))),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border(
                                      left: BorderSide(
                                          color: cs.primary, width: 3),
                                    ),
                                  ),
                                  child: LookupSelectableMarkdown(
                                    data: item.userNotes,
                                    baseFontSize: 14,
                                  ),
                                ),
                              ],
                              if (item.sourceConvId != null ||
                                  (item.sourceHighlight?.isNotEmpty ??
                                      false)) ...[
                                const SizedBox(height: 20),
                                _InlineSourceBlock(item: item),
                              ],
                            ],
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: widget.embedded && !_showDetail
                                  ? TextButton(
                                      onPressed: () => setState(
                                          () => _showDetail = true),
                                      child: Text(l10n.viewFullItem),
                                    )
                                  : widget.embedded
                                      ? const SizedBox.shrink()
                                      : TextButton(
                                          onPressed: () => Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    SavedItemDetailPage(
                                                        item: item)),
                                          ),
                                          child: Text(l10n.viewFullItem),
                                        ),
                            ),
                          ],
                        ),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(entity,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700)),
                          if (summary.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Text(summary,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontSize: 15,
                                    color: cs.onSurface
                                        .withValues(alpha: 0.6))),
                          ],
                          const SizedBox(height: 24),
                          Text(l10n.tapToReveal,
                              style: TextStyle(
                                  fontSize: 13,
                                  color: cs.onSurface
                                      .withValues(alpha: 0.35))),
                        ],
                      ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (!_revealed)
            // Before reveal: just a skip button
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: widget.onSkip,
                icon: const Icon(Icons.skip_next_rounded),
                label: Text(l10n.skip),
              ),
            )
          else
            // After reveal: 4 grade buttons with interval preview
            Row(
              children: [
                _GradeButton(
                  label: l10n.forgot,
                  days: widget.intervals[ReviewGrade.forgot] ?? 1,
                  color: cs.error,
                  onTap: () => widget.onRate(ReviewGrade.forgot),
                  l10n: l10n,
                ),
                const SizedBox(width: 6),
                _GradeButton(
                  label: l10n.hard,
                  days: widget.intervals[ReviewGrade.hard] ?? 1,
                  color: Colors.orange,
                  onTap: () => widget.onRate(ReviewGrade.hard),
                  l10n: l10n,
                ),
                const SizedBox(width: 6),
                _GradeButton(
                  label: l10n.good,
                  days: widget.intervals[ReviewGrade.good] ?? 1,
                  color: cs.primary,
                  onTap: () => widget.onRate(ReviewGrade.good),
                  l10n: l10n,
                ),
                const SizedBox(width: 6),
                _GradeButton(
                  label: l10n.easy,
                  days: widget.intervals[ReviewGrade.easy] ?? 1,
                  color: Colors.teal,
                  onTap: () => widget.onRate(ReviewGrade.easy),
                  l10n: l10n,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: widget.onStopReview,
                icon: Icon(Icons.block_rounded, size: 16,
                    color: cs.onSurface.withValues(alpha: 0.4)),
                label: Text(l10n.stopReview,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.4))),
              ),
            ),
        ],
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  final String label;
  final int days;
  final Color color;
  final VoidCallback onTap;
  final AppLocalizations l10n;

  const _GradeButton({
    required this.label,
    required this.days,
    required this.color,
    required this.onTap,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withValues(alpha: 0.4)),
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(l10n.intervalDays(days),
                style: TextStyle(
                    fontSize: 10,
                    color: color.withValues(alpha: 0.7))),
          ],
        ),
      ),
    );
  }
}

class _InlineSourceBlock extends StatelessWidget {
  final SavedItem item;
  const _InlineSourceBlock({required this.item});

  void _navigateToSource(BuildContext context) {
    final convId = item.sourceConvId;
    if (convId == null) return;
    final chat = context.read<ChatProvider>();
    Navigator.of(context).popUntil((route) => route.isFirst);
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
