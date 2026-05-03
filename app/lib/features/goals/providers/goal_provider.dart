import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/goals/data/goal_api.dart';
import 'package:app/features/goals/models/goal.dart';
import 'package:app/features/schedule/providers/plan_version_provider.dart';

part 'goal_provider.g.dart';

@riverpod
Future<List<Goal>> goals(Ref ref) async {
  ref.watch(planVersionProvider);
  final api = ref.watch(goalApiProvider);
  final data = await api.getGoals();
  final list = data['data'] as List;
  return list.map((e) => Goal.fromJson(e as Map<String, dynamic>)).toList();
}

@riverpod
Future<Goal> goalDetail(Ref ref, int id) async {
  ref.watch(planVersionProvider);
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
    final api = ref.read(goalApiProvider);
    final planVersion = ref.read(planVersionProvider.notifier);
    state = const AsyncValue.loading();
    try {
      await api.createGoal({
        'name': name,
        'type': type,
        'distance': ?distance,
        'target_date': ?targetDate,
        'goal_time_seconds': ?goalTimeSeconds,
      });
      // Provider may have auto-disposed while the request was in flight
      // (the form screen unmounts on navigation). `state =` on a disposed
      // notifier throws — bail before touching it. The captured `planVersion`
      // is still safe because `PlanVersion` is `keepAlive: true`.
      if (!ref.mounted) return;
      planVersion.bump();
      state = const AsyncValue.data(null);
    } catch (e, st) {
      if (!ref.mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> deleteGoal(int id) async {
    final api = ref.read(goalApiProvider);
    final planVersion = ref.read(planVersionProvider.notifier);
    await api.deleteGoal(id);
    planVersion.bump();
  }

  Future<void> activateGoal(int id) async {
    final api = ref.read(goalApiProvider);
    final planVersion = ref.read(planVersionProvider.notifier);
    await api.activateGoal(id);
    planVersion.bump();
  }
}
