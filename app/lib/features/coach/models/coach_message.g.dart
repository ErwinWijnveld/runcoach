// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_message.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoachMessage _$CoachMessageFromJson(Map<String, dynamic> json) =>
    _CoachMessage(
      id: json['id'] as String,
      role: json['role'] as String,
      content: json['content'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      messagePayload: json['message_payload'] as Map<String, dynamic>?,
      createdAt: json['created_at'] as String,
      proposal: json['proposal'] == null
          ? null
          : CoachProposal.fromJson(json['proposal'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$CoachMessageToJson(_CoachMessage instance) =>
    <String, dynamic>{
      'id': instance.id,
      'role': instance.role,
      'content': instance.content,
      'message_type': instance.messageType,
      'message_payload': instance.messagePayload,
      'created_at': instance.createdAt,
      'proposal': instance.proposal,
    };
