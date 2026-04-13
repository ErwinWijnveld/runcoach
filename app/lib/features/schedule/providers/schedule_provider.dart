import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'schedule_provider.g.dart';

@riverpod
Future<List<TrainingWeek>> schedule(Ref ref, int raceId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getSchedule(raceId);
  final list = data['data'] as List;
  return list.map((e) => TrainingWeek.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<TrainingWeek?> currentWeek(Ref ref, int raceId) async {
  final api = ref.watch(scheduleApiProvider);
  final data = await api.getCurrentWeek(raceId);
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
