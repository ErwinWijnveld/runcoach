import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/models/available_activity.dart';
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

/// Wearable activities the runner has synced near a training day's date,
/// each flagged with whether they're already matched. Feeds the
/// "Pick activity" modal on the day detail screen.
@riverpod
Future<List<AvailableActivity>> availableActivities(Ref ref, int dayId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getAvailableActivities(dayId);
  final list = data['data'] as List? ?? [];
  return list
      .map((e) => AvailableActivity.fromJson(Map<String, dynamic>.from(e as Map)))
      .toList(growable: false);
}

/// Manually match (or unlink) a wearable activity for a training day.
@riverpod
class ManualMatchActivity extends _$ManualMatchActivity {
  @override
  void build() {}

  Future<TrainingResult> match({
    required int dayId,
    required int wearableActivityId,
  }) async {
    final api = ref.read(scheduleApiProvider);
    final response = await api.matchActivity(
      dayId,
      {'wearable_activity_id': wearableActivityId},
    );
    return TrainingResult.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }

  /// Removes the TrainingResult for a day so the wearable run is un-matched.
  /// The WearableActivity row stays so the run can be re-matched.
  Future<void> unlink({required int dayId}) async {
    final api = ref.read(scheduleApiProvider);
    await api.unlinkActivity(dayId);
  }
}

/// Move a training day to a new date. The backend re-assigns the day to the
/// matching training week if the new date crosses a week boundary.
@riverpod
class RescheduleDay extends _$RescheduleDay {
  @override
  void build() {}

  Future<TrainingDay> reschedule({
    required int dayId,
    required DateTime date,
  }) async {
    final api = ref.read(scheduleApiProvider);
    final ymd =
        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final response = await api.updateTrainingDay(dayId, {'date': ymd});
    return TrainingDay.fromJson(
      Map<String, dynamic>.from(response['data'] as Map),
    );
  }
}

/// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
/// then yields the text and closes. Yields `null` while pending so the UI can
/// keep the spinner on screen. Auto-disposes when the screen leaves.
@riverpod
Stream<String?> trainingDayAiFeedback(Ref ref, int dayId) async* {
  final api = ref.read(scheduleApiProvider);
  while (true) {
    final data = await api.getTrainingResult(dayId);
    final feedback = (data['data'] as Map?)?['ai_feedback'] as String?;
    yield feedback;
    if (feedback != null) {
      ref.invalidate(trainingDayDetailProvider(dayId));
      ref.invalidate(trainingDayResultProvider(dayId));
      return;
    }
    await Future.delayed(const Duration(seconds: 5));
  }
}
