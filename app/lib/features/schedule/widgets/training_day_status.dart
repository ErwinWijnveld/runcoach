import 'package:flutter/painting.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/l10n/app_localizations.dart';

/// Derived UI state for a training day. A training day is always in exactly
/// one of these four states based on its date vs. today and whether a
/// `TrainingResult` exists.
enum TrainingDayStatus {
  /// Date is in the past, no result was ever recorded → user missed it.
  missed,

  /// Any day with a `TrainingResult` (matched wearable run).
  completed,

  /// Date == today, no result yet → awaiting the next wearable sync.
  today,

  /// Date is in the future, nothing done yet.
  upcoming;

  static TrainingDayStatus from(TrainingDay day, {DateTime? now}) {
    if (day.result != null) {
      return TrainingDayStatus.completed;
    }

    // Compare by LOCAL calendar date on both sides so users near midnight
    // don't see yesterday-local runs classified as "today" (and vice-versa).
    // `day.date` arrives as `YYYY-MM-DDT00:00:00Z` from Eloquent's date cast
    // — we only care about the Y-M-D prefix, NOT the UTC time.
    final today = now ?? DateTime.now();
    final todayLocal = DateTime(today.year, today.month, today.day);
    final dayLocal = _parseYmdOrNull(day.date);

    if (dayLocal == null) return TrainingDayStatus.upcoming; // safe fallback
    if (dayLocal.isBefore(todayLocal)) return TrainingDayStatus.missed;
    if (dayLocal.isAtSameMomentAs(todayLocal)) return TrainingDayStatus.today;
    return TrainingDayStatus.upcoming;
  }

  static DateTime? _parseYmdOrNull(String input) {
    if (input.length < 10) return null;
    try {
      final ymd = input.substring(0, 10).split('-');
      if (ymd.length != 3) return null;
      return DateTime(
        int.parse(ymd[0]),
        int.parse(ymd[1]),
        int.parse(ymd[2]),
      );
    } catch (_) {
      return null;
    }
  }

  String pillLabel(AppLocalizations l10n) => switch (this) {
        TrainingDayStatus.missed => l10n.trainingDayStatusMissed,
        TrainingDayStatus.completed => l10n.trainingDayStatusCompleted,
        TrainingDayStatus.today => l10n.commonTodayUpper,
        TrainingDayStatus.upcoming => l10n.trainingDayStatusUpcoming,
      };

  String subtitle(AppLocalizations l10n) => switch (this) {
        TrainingDayStatus.missed => l10n.trainingStatusMissed,
        TrainingDayStatus.completed => l10n.trainingStatusSynced,
        TrainingDayStatus.today => l10n.trainingStatusAwaitingSync,
        TrainingDayStatus.upcoming => l10n.trainingStatusUpcoming,
      };

  Color get pillColor => switch (this) {
        TrainingDayStatus.missed => AppColors.danger,
        TrainingDayStatus.completed => const Color(0xFF34C759),
        TrainingDayStatus.today => AppColors.secondary,
        TrainingDayStatus.upcoming => AppColors.tertiary,
      };

  bool get showSelectActivity =>
      this == TrainingDayStatus.missed ||
      this == TrainingDayStatus.today ||
      this == TrainingDayStatus.upcoming;
}
