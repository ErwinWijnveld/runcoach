import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_interval.dart';
import 'package:app/features/schedule/models/training_week.dart';

/// Convert a [Goal] + its [TrainingWeek]s into the same map shape that
/// `CoachProposal.payload` carries, so the shared `PlanContent` widget can
/// render an inactive-goal preview without a separate widget tree.
///
/// Only the fields `PlanContent` actually reads are emitted — `ambition` and
/// `diff` are intentionally omitted (saved goals don't carry feasibility
/// analysis, and a goal preview is never a revision).
Map<String, dynamic> goalToPlanPayload(Goal goal, List<TrainingWeek> weeks) {
  return {
    'goal_name': goal.name,
    'target_date': goal.targetDate,
    'schedule': {
      'weeks': weeks.map(_weekToMap).toList(),
    },
  };
}

Map<String, dynamic> _weekToMap(TrainingWeek week) {
  return {
    'week_number': week.weekNumber,
    'focus': week.focus,
    'total_km': week.totalKm,
    'days': (week.trainingDays ?? const <TrainingDay>[])
        .map(_dayToMap)
        .toList(),
  };
}

Map<String, dynamic> _dayToMap(TrainingDay day) {
  // PlanContent expects `day_of_week` (1=Mon..7=Sun). TrainingDay carries
  // a date string — derive DOW from that. Falls back to TrainingDay.order
  // (also seeded with the iso weekday by the backend) if parsing fails.
  final parsed = DateTime.tryParse(day.date);
  final dow = parsed?.weekday ?? day.order;

  final intervals = day.intervals;

  return {
    'day_of_week': dow,
    'type': day.type,
    'title': day.title,
    'target_km': day.targetKm,
    'target_pace_seconds_per_km': day.targetPaceSecondsPerKm,
    if (intervals != null && intervals.isNotEmpty)
      'intervals': intervals.map(_intervalToMap).toList(),
  };
}

Map<String, dynamic> _intervalToMap(TrainingInterval interval) {
  return {
    'kind': interval.kind,
    'label': interval.label,
    'distance_m': interval.distanceM,
    'duration_seconds': interval.durationSeconds,
    'target_pace_seconds_per_km': interval.targetPaceSecondsPerKm,
  };
}
