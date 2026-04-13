import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_result.freezed.dart';
part 'training_result.g.dart';

@freezed
sealed class TrainingResult with _$TrainingResult {
  const factory TrainingResult({
    required int id,
    @JsonKey(name: 'compliance_score') required double complianceScore,
    @JsonKey(name: 'actual_km') required double actualKm,
    @JsonKey(name: 'actual_pace_seconds_per_km') required int actualPaceSecondsPerKm,
    @JsonKey(name: 'actual_avg_heart_rate') double? actualAvgHeartRate,
    @JsonKey(name: 'pace_score') required double paceScore,
    @JsonKey(name: 'distance_score') required double distanceScore,
    @JsonKey(name: 'heart_rate_score') double? heartRateScore,
    @JsonKey(name: 'ai_feedback') String? aiFeedback,
  }) = _TrainingResult;

  factory TrainingResult.fromJson(Map<String, dynamic> json) =>
      _$TrainingResultFromJson(json);
}
