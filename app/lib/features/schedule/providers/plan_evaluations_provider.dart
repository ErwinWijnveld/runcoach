import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/schedule/data/plan_evaluations_api.dart';
import 'package:app/features/schedule/models/plan_evaluation.dart';

part 'plan_evaluations_provider.g.dart';

/// All `PlanEvaluation`s attached to the runner's currently active goal.
/// The schedule UI interleaves these as cards inside the week grid.
@Riverpod(keepAlive: true)
class PlanEvaluations extends _$PlanEvaluations {
  @override
  Future<List<PlanEvaluation>> build() async {
    final api = ref.watch(planEvaluationsApiProvider);
    final data = await api.listForActiveGoal();
    final list = (data['data'] as List).cast<Map<String, dynamic>>();
    return list.map(PlanEvaluation.fromJson).toList();
  }
}

/// Single-evaluation lookup for the detail screen. `keepAlive: true` so a
/// brief detail-screen pop + re-push doesn't refetch and re-flash the
/// loading state. The accept/dismiss flow explicitly invalidates this
/// provider when it needs to refresh.
@Riverpod(keepAlive: true)
Future<PlanEvaluation?> planEvaluation(Ref ref, int id) async {
  final api = ref.watch(planEvaluationsApiProvider);
  final data = await api.show(id);
  final map = (data['data'] as Map).cast<String, dynamic>();
  return PlanEvaluation.fromJson(map);
}
