import 'dart:math';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';

import 'db/database.dart';
import 'db/saved_item_dao.dart';
import 'notification_service.dart';

/// User's self-assessment after revealing a review card.
enum ReviewGrade { forgot, hard, good, easy }

/// Tuning knobs for the simplified FSRS scheduler.
class _FsrsParams {
  // Difficulty adjustments per grade (added/subtracted, clamped 0–1).
  static const forgotDifficultyDelta = 0.2;
  static const hardDifficultyDelta = 0.05;
  static const goodDifficultyDelta = 0.05;
  static const easyDifficultyDelta = 0.15;

  // Stability multipliers per grade.
  static const forgotStabilityRetention = 0.3; // retain 30% on forget
  static const hardStabilityMultiplier = 1.2;
  static const goodStabilityMultiplier = 2.5;
  static const easyStabilityMultiplier = 3.5;
  static const difficultyPenaltyHard = 0.3;
  static const difficultyPenaltyGoodEasy = 0.5;

  // Bounds.
  static const minStability = 1.0; // days
  static const maxStability = 365.0; // days
  static const safetyMargin = 0.9; // interval = stability * this

  // Graduation: auto-graduate if stability exceeds this on an "easy" rating.
  static const graduationStabilityThreshold = 180.0; // days
}

/// Per-type review policy. Controls whether items auto-enroll and when
/// they graduate (stop being scheduled).
class ReviewPolicy {
  final bool autoEnroll;
  final int? maxReviews; // null = never graduate by count alone

  const ReviewPolicy({required this.autoEnroll, this.maxReviews});
}

/// Type → policy mapping. All types auto-enroll by default.
const Map<String, ReviewPolicy> reviewPolicies = {
  'vocab':      ReviewPolicy(autoEnroll: true, maxReviews: null),
  'expression': ReviewPolicy(autoEnroll: true, maxReviews: 10),
  'insight':    ReviewPolicy(autoEnroll: true, maxReviews: 5),
  'concept':    ReviewPolicy(autoEnroll: true, maxReviews: 6),
  'fact':       ReviewPolicy(autoEnroll: true, maxReviews: 3),
  'question':   ReviewPolicy(autoEnroll: true, maxReviews: 3),
  'action':     ReviewPolicy(autoEnroll: true, maxReviews: null),
  'reference':  ReviewPolicy(autoEnroll: true, maxReviews: null),
  'recipe':     ReviewPolicy(autoEnroll: true, maxReviews: null),
};

const _defaultPolicy = ReviewPolicy(autoEnroll: true, maxReviews: 5);

ReviewPolicy policyForType(String? type) {
  if (type == null || type.isEmpty) return _defaultPolicy;
  return reviewPolicies[type.toLowerCase()] ?? _defaultPolicy;
}

/// Manages spaced repetition review scheduling using a simplified FSRS
/// algorithm with type-based policies and graduation.
///
/// Core idea (based on Ebbinghaus / FSRS):
///   - Each item has a *stability* (how many days the memory lasts)
///     and a *difficulty* (0–1, how hard it is to remember).
///   - After each review the user rates: forgot / hard / good / easy.
///   - Stability and difficulty are updated based on the rating.
///   - Next interval = stability * a small multiplier for safety margin.
///   - Items graduate (stop being reviewed) after enough successful
///     reviews, controlled by the type-based policy.
class ReviewProvider extends ChangeNotifier {
  final AppDatabase _db;
  final SavedItemDao _dao;

  ReviewProvider(this._db) : _dao = SavedItemDao(_db);

  List<SavedItem> dueItems = const [];
  bool loading = false;

  int get dueCount => dueItems.length;

  Future<void> loadDueItems() async {
    loading = true;
    notifyListeners();

    dueItems = await _dao.dueForReview(DateTime.now());

    loading = false;
    notifyListeners();
    _scheduleNotification();
  }

  void _scheduleNotification() {
    NotificationService.scheduleInactivityReminder(
      dueCount: dueItems.length,
    );
  }

  Future<void> enableReview(String itemId) async {
    final nextReview = DateTime.now().add(const Duration(days: 1));
    await _dao.updateFields(
        itemId, SavedItemsCompanion(nextReviewAt: Value(nextReview)));
    await loadDueItems();
  }

  /// Enable review for all non-graduated items that aren't already scheduled.
  Future<void> enableReviewForAll() async {
    final nextReview = DateTime.now().add(const Duration(days: 1));
    await _db.customStatement(
      '''
      UPDATE saved_items SET next_review_at = ?
      WHERE next_review_at IS NULL
        AND graduated = 0
      ''',
      [nextReview.millisecondsSinceEpoch ~/ 1000],
    );
    await loadDueItems();
  }

  /// Rate a review card. This is the main FSRS scheduling entry point.
  Future<void> rateReview(String itemId, ReviewGrade grade) async {
    final item = await _dao.getByIdOrNull(itemId);
    if (item == null) return;

    final now = DateTime.now();
    final newCount = item.reviewCount + 1;

    double s = item.stability;
    double d = item.difficulty;

    (d, s) = _applyFsrs(grade, d, s);

    final intervalDays = max(1, (s * _FsrsParams.safetyMargin).round());

    // Check graduation.
    final policy = policyForType(item.itemType);
    final shouldGraduate = _shouldGraduate(
      grade: grade,
      reviewCount: newCount,
      stability: s,
      policy: policy,
    );

    await _dao.updateFields(
      itemId,
      SavedItemsCompanion(
        lastReviewedAt: Value(now),
        reviewCount: Value(newCount),
        stability: Value(s),
        difficulty: Value(d),
        nextReviewAt: Value(
          shouldGraduate ? null : now.add(Duration(days: intervalDays)),
        ),
        graduated: Value(shouldGraduate),
      ),
    );

    dueItems = dueItems.where((i) => i.id != itemId).toList();
    notifyListeners();
  }

  /// Preview the next interval for each grade without committing.
  /// Returns a map of grade → days until next review.
  Map<ReviewGrade, int> previewIntervals(SavedItem item) {
    final result = <ReviewGrade, int>{};
    for (final grade in ReviewGrade.values) {
      final (_, s) = _applyFsrs(grade, item.difficulty, item.stability);
      result[grade] = max(1, (s * _FsrsParams.safetyMargin).round());
    }
    return result;
  }

  bool _shouldGraduate({
    required ReviewGrade grade,
    required int reviewCount,
    required double stability,
    required ReviewPolicy policy,
  }) {
    // Never graduate on a "forgot".
    if (grade == ReviewGrade.forgot) return false;
    // Check max review count.
    if (policy.maxReviews != null && reviewCount >= policy.maxReviews!) {
      return true;
    }
    // Also graduate if stability is very high and the user rated easy.
    if (stability > _FsrsParams.graduationStabilityThreshold &&
        grade == ReviewGrade.easy) {
      return true;
    }
    return false;
  }

  /// Legacy method — kept for backward compat. Delegates to rateReview
  /// with grade=good.
  Future<void> markReviewed(String itemId) async {
    await rateReview(itemId, ReviewGrade.good);
  }

  Future<void> skipItem(String itemId) async {
    dueItems = dueItems.where((i) => i.id != itemId).toList();
    notifyListeners();
  }

  Future<void> disableReview(String itemId) async {
    await _dao.clearReviewSchedule(itemId);
    dueItems = dueItems.where((i) => i.id != itemId).toList();
    notifyListeners();
  }

  /// Pure function: compute updated (difficulty, stability) for a given grade.
  static (double difficulty, double stability) _applyFsrs(
      ReviewGrade grade, double d, double s) {
    switch (grade) {
      case ReviewGrade.forgot:
        d = min(1.0, d + _FsrsParams.forgotDifficultyDelta);
        s = max(_FsrsParams.minStability, s * _FsrsParams.forgotStabilityRetention);
      case ReviewGrade.hard:
        d = min(1.0, d + _FsrsParams.hardDifficultyDelta);
        s = s * (_FsrsParams.hardStabilityMultiplier - _FsrsParams.difficultyPenaltyHard * d);
      case ReviewGrade.good:
        d = max(0.0, d - _FsrsParams.goodDifficultyDelta);
        s = s * (_FsrsParams.goodStabilityMultiplier - _FsrsParams.difficultyPenaltyGoodEasy * d);
      case ReviewGrade.easy:
        d = max(0.0, d - _FsrsParams.easyDifficultyDelta);
        s = s * (_FsrsParams.easyStabilityMultiplier - _FsrsParams.difficultyPenaltyGoodEasy * d);
    }
    s = s.clamp(_FsrsParams.minStability, _FsrsParams.maxStability);
    return (d, s);
  }
}
