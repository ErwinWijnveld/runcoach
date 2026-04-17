import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/models/available_strava_activity.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'schedule_provider.g.dart';

@riverpod
Future<List<TrainingWeek>> schedule(Ref ref, int goalId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getSchedule(goalId);
  final list = data['data'] as List;
  return list
      .map((e) => TrainingWeek.fromJson(e as Map<String, dynamic>))
      .toList();
}

@riverpod
Future<TrainingWeek?> currentWeek(Ref ref, int goalId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getCurrentWeek(goalId);
  final weekData = data['data'];
  if (weekData == null) return null;
  return TrainingWeek.fromJson(weekData as Map<String, dynamic>);
}

@riverpod
Future<TrainingDay> trainingDayDetail(Ref ref, int dayId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getTrainingDay(dayId);
  return TrainingDay.fromJson(data['data'] as Map<String, dynamic>);
}

@riverpod
Future<TrainingResult?> trainingDayResult(Ref ref, int dayId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getTrainingResult(dayId);
  final resultData = data['data'];
  if (resultData == null) return null;
  return TrainingResult.fromJson(resultData as Map<String, dynamic>);
}

/// Result of fetching recent Strava runs for a training day. The backend
/// answers with `data: []` plus a structured `error` code when Strava is
/// unreachable / disconnected / rate-limited, so the UI can render a
/// specific empty state instead of a generic failure.
class AvailableStravaActivitiesResult {
  final List<AvailableStravaActivity> activities;

  /// `null` when the list is authoritative. Otherwise one of:
  /// `strava_disconnected`, `rate_limited`, `strava_unreachable`.
  final String? errorCode;

  const AvailableStravaActivitiesResult({
    required this.activities,
    this.errorCode,
  });

  bool get hasError => errorCode != null;
}

/// Recent Strava runs near a training day's date, with a flag on each
/// indicating whether it's already matched to a training day (same user).
/// Feeds the "Select Strava run" modal.
@riverpod
Future<AvailableStravaActivitiesResult> availableStravaActivities(
  Ref ref,
  int dayId,
) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getAvailableStravaActivities(dayId);
  final list = data['data'] as List? ?? [];
  final activities = list
      .map((e) =>
          AvailableStravaActivity.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
  final error = data['error'] as String?;

  return AvailableStravaActivitiesResult(
    activities: activities,
    errorCode: error,
  );
}

/// Manually match (or unlink) a Strava activity for a training day.
/// The caller invalidates `trainingDayDetailProvider(dayId)` + the weekly
/// schedule providers afterwards to refresh the UI.
@riverpod
class ManualMatchStravaActivity extends _$ManualMatchStravaActivity {
  @override
  void build() {}

  Future<TrainingResult> match({
    required int dayId,
    required int stravaActivityId,
  }) async {
    final api = ref.read(scheduleApiProvider);
    final response = await api.matchStravaActivity(
      dayId,
      {'strava_activity_id': stravaActivityId},
    );
    return TrainingResult.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  /// Removes the TrainingResult for a day so the Strava run is un-synced.
  /// The StravaActivity row stays so the run can be re-matched from the
  /// "Select Strava run" modal.
  Future<void> unlink({required int dayId}) async {
    final api = ref.read(scheduleApiProvider);
    await api.unlinkStravaActivity(dayId);
  }
}
