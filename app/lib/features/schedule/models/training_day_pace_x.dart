import 'package:app/features/schedule/models/training_day.dart';

/// Pace accessors for [TrainingDay] that the schedule UI calls into when
/// rendering "what pace was planned" — keeps the JSON model class
/// (Freezed-generated) free of derived logic.
///
/// **Interval contract (mirror of `api/CLAUDE.md` → "Interval pace
/// contract"):** the day-level `targetPaceSecondsPerKm` is null on
/// interval sessions by design — pace lives per work segment inside
/// [TrainingDay.intervals]. [workSetAveragePaceSecondsPerKm] surfaces the
/// unweighted mean across `kind=work` segments so callers can render a
/// single "X:YY/km" label without poking inside the segment list.
extension TrainingDayPaceX on TrainingDay {
  /// Average target pace across the working sets of an interval session.
  /// Returns null for non-interval days, sessions without intervals, or
  /// sessions where no work segment carries a target pace.
  int? get workSetAveragePaceSecondsPerKm {
    if (type != 'interval') return null;
    final segments = intervals;
    if (segments == null || segments.isEmpty) return null;
    final paces = segments
        .where((s) => s.kind == 'work' && (s.targetPaceSecondsPerKm ?? 0) > 0)
        .map((s) => s.targetPaceSecondsPerKm!)
        .toList(growable: false);
    if (paces.isEmpty) return null;
    final sum = paces.fold<int>(0, (a, b) => a + b);
    return (sum / paces.length).round();
  }

  /// The pace value the UI should show as "target". For intervals this is
  /// the work-set average (the day-level field is always null there); for
  /// every other type it's the day-level target. Returns null when neither
  /// is set (e.g. a freshly-added day a coach hasn't filled in yet).
  int? get displayPaceSecondsPerKm =>
      type == 'interval' ? workSetAveragePaceSecondsPerKm : targetPaceSecondsPerKm;
}
