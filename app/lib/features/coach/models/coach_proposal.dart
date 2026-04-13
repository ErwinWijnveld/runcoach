import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_proposal.freezed.dart';
part 'coach_proposal.g.dart';

@freezed
sealed class CoachProposal with _$CoachProposal {
  const factory CoachProposal({
    required int id,
    required String type,
    required Map<String, dynamic> payload,
    required String status,
    @JsonKey(name: 'applied_at') String? appliedAt,
  }) = _CoachProposal;

  factory CoachProposal.fromJson(Map<String, dynamic> json) =>
      _$CoachProposalFromJson(json);
}
