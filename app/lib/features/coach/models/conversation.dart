import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
sealed class Conversation with _$Conversation {
  const factory Conversation({
    required String id,
    required String title,
    @JsonKey(name: 'race_id') int? raceId,
    @JsonKey(name: 'created_at') required String createdAt,
    List<CoachMessage>? messages,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
