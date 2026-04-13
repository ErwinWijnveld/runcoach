// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_proposal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CoachProposal _$CoachProposalFromJson(Map<String, dynamic> json) =>
    _CoachProposal(
      id: (json['id'] as num).toInt(),
      type: json['type'] as String,
      payload: json['payload'] as Map<String, dynamic>,
      status: json['status'] as String,
      appliedAt: json['applied_at'] as String?,
    );

Map<String, dynamic> _$CoachProposalToJson(_CoachProposal instance) =>
    <String, dynamic>{
      'id': instance.id,
      'type': instance.type,
      'payload': instance.payload,
      'status': instance.status,
      'applied_at': instance.appliedAt,
    };
