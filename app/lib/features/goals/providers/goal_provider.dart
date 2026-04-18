import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/goals/data/goal_api.dart';
import 'package:app/features/goals/models/goal.dart';

part 'goal_provider.g.dart';

@riverpod
Future<List<Goal>> goals(Ref ref) async {
  final api = ref.watch(goalApiProvider);
  final data = await api.getGoals();
  final list = data['data'] as List;
  return list.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<Goal> goalDetail(Ref ref, int id) async {
  final api = ref.watch(goalApiProvider);
  final data = await api.getGoal(id);
  return Goal.fromJson(data['data'] as Map<String, dynamic>);
}

@riverpod
class GoalActions extends _$GoalActions {
  @override
  AsyncValue<void> build() => const AsyncValue.data(null);

  Future<void> createGoal({
    required String name,
    required String type,
    String? distance,
    String? targetDate,
    int? goalTimeSeconds,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(goalApiProvider);
      await api.createGoal({
        'name': name,
        'type': type,
        'distance': ?distance,
        'target_date': ?targetDate,
        'goal_time_seconds': ?goalTimeSeconds,
      });
      ref.invalidate(goalsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(int id) async {
    final api = ref.read(goalApiProvider);
    await api.deleteGoal(id);
    ref.invalidate(goalsProvider);
  }

  Future<void> activateGoal(int id) async {
    final api = ref.read(goalApiProvider);
    await api.activateGoal(id);
    ref.invalidate(goalsProvider);
    ref.invalidate(dashboardProvider);
  }
}
