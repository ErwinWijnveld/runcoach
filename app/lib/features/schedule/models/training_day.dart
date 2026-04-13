import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'training_day.freezed.dart';
part 'training_day.g.dart';

@freezed
sealed class TrainingDay with _$TrainingDay {
  const factory TrainingDay({
    required int id,
    required String date,
    required String type,
    required String title,
    String? description,
    @JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? targetKm,
    @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? targetPaceSecondsPerKm,
    @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) int? targetHeartRateZone,
    @JsonKey(name: 'intervals_json') Map<String, dynamic>? intervalsJson,
    @JsonKey(fromJson: toInt) required int order,
    TrainingResult? result,
  }) = _TrainingDay;

  factory TrainingDay.fromJson(Map<String, dynamic> json) =>
      _$TrainingDayFromJson(json);
}
