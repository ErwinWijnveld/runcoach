import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'coach_message.freezed.dart';
part 'coach_message.g.dart';

@freezed
sealed class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
    @JsonKey(includeFromJson: false, includeToJson: false) String? errorDetail,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}
