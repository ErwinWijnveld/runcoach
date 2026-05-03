// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserNotification _$UserNotificationFromJson(Map<String, dynamic> json) =>
    _UserNotification(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      actionData: json['action_data'] as Map<String, dynamic>?,
      status: json['status'] as String,
    );

Map<String, dynamic> _$UserNotificationToJson(_UserNotification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'title': instance.title,
      'body': instance.body,
      'action_data': instance.actionData,
      'status': instance.status,
    };
