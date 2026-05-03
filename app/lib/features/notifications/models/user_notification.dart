import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_notification.freezed.dart';
part 'user_notification.g.dart';

@freezed
sealed class UserNotification with _$UserNotification {
  const factory UserNotification({
    required int id,
    required String type,
    required String title,
    required String body,
    @JsonKey(name: 'action_data') Map<String, dynamic>? actionData,
    required String status,
  }) = _UserNotification;

  factory UserNotification.fromJson(Map<String, dynamic> json) =>
      _$UserNotificationFromJson(json);
}
