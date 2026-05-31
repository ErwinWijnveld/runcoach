// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_evaluation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PlanEvaluation _$PlanEvaluationFromJson(Map<String, dynamic> json) =>
    _PlanEvaluation(
      id: (json['id'] as num).toInt(),
      userId: (json['user_id'] as num).toInt(),
      goalId: (json['goal_id'] as num).toInt(),
      trainingWeekId: (json['training_week_id'] as num?)?.toInt(),
      scheduledFor: json['scheduled_for'] as String,
      status: json['status'] as String,
      reportMarkdown: json['report_markdown'] as String?,
      proposalId: (json['proposal_id'] as num?)?.toInt(),
      notificationId: (json['notification_id'] as num?)?.toInt(),
      triggeredAt: json['triggered_at'] as String?,
      completedAt: json['completed_at'] as String?,
      proposal: json['proposal'] as Map<String, dynamic>?,
    );

Map<String, dynamic> _$PlanEvaluationToJson(_PlanEvaluation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'user_id': instance.userId,
      'goal_id': instance.goalId,
      'training_week_id': instance.trainingWeekId,
      'scheduled_for': instance.scheduledFor,
      'status': instance.status,
      'report_markdown': instance.reportMarkdown,
      'proposal_id': instance.proposalId,
      'notification_id': instance.notificationId,
      'triggered_at': instance.triggeredAt,
      'completed_at': instance.completedAt,
      'proposal': instance.proposal,
    };
