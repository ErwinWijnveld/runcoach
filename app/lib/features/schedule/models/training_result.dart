import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/wearable_activity_summary.dart';

part 'training_result.freezed.dart';
part 'training_result.g.dart';

@freezed
sealed class TrainingResult with _$TrainingResult {
  const factory TrainingResult({
    required int id,
    @JsonKey(name: 'compliance_score', fromJson: toDouble)
    required double complianceScore,
    @JsonKey(name: 'actual_km', fromJson: toDouble) required double actualKm,
    @JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt)
    required int actualPaceSecondsPerKm,
    @JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull)
    double? actualAvgHeartRate,
    @JsonKey(name: 'pace_score', fromJson: toDouble) required double paceScore,
    @JsonKey(name: 'distance_score', fromJson: toDouble)
    required double distanceScore,
    @JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull)
    double? heartRateScore,
    @JsonKey(name: 'ai_feedback') String? aiFeedback,

    /// Locally-persisted wearable run that was matched to this training day.
    /// Eager-loaded by the backend on `showDay`, `dayResult`, and
    /// `matchActivityToDay`. Null for older results where we didn't load it.
    @JsonKey(name: 'wearable_activity') WearableActivitySummary? wearableActivity,
  }) = _TrainingResult;

  factory TrainingResult.fromJson(Map<String, dynamic> json) =>
      _$TrainingResultFromJson(json);
}
