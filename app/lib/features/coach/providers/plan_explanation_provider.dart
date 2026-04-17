import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/data/coach_api.dart';

part 'plan_explanation_provider.g.dart';

class PlanExplanation {
  final String name;
  final String explanation;

  const PlanExplanation({required this.name, required this.explanation});
}

@riverpod
Future<PlanExplanation> planExplanation(Ref ref, int proposalId) async {
  final api = ref.watch(coachApiProvider);
  final data = await api.getProposalExplanation(proposalId);
  final body = (data['data'] as Map).cast<String, dynamic>();
  return PlanExplanation(
    name: body['name'] as String,
    explanation: body['explanation'] as String,
  );
}
