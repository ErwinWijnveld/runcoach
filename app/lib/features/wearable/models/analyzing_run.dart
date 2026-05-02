import 'package:freezed_annotation/freezed_annotation.dart';

part 'analyzing_run.freezed.dart';
part 'analyzing_run.g.dart';

/// Backend status of the post-ingest pipeline for a single run.
enum AnalyzingRunStatus {
  @JsonValue('pending')
  pending,

  @JsonValue('matched')
  matched,

  @JsonValue('analyzed')
  analyzed,

  @JsonValue('unmatched')
  unmatched,
}

@freezed
sealed class AnalyzingRun with _$AnalyzingRun {
  const factory AnalyzingRun({
    required int wearableActivityId,
    required AnalyzingRunStatus status,
    required DateTime startedAt,
    int? trainingDayId,
    int? trainingResultId,
    double? complianceScore,
    double? actualKm,
    String? aiFeedback,
  }) = _AnalyzingRun;

  factory AnalyzingRun.fromJson(Map<String, dynamic> json) =>
      _$AnalyzingRunFromJson(json);
}
