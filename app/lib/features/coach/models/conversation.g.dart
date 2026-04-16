// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'conversation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Conversation _$ConversationFromJson(Map<String, dynamic> json) =>
    _Conversation(
      id: json['id'] as String,
      title: json['title'] as String,
      goalId: (json['goal_id'] as num?)?.toInt(),
      createdAt: json['created_at'] as String,
      messages: (json['messages'] as List<dynamic>?)
          ?.map((e) => CoachMessage.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ConversationToJson(_Conversation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'goal_id': instance.goalId,
      'created_at': instance.createdAt,
      'messages': instance.messages,
    };
