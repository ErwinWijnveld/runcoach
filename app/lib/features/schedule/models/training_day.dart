import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/training_interval.dart';
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
    @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)
    int? targetPaceSecondsPerKm,
    @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull)
    int? targetHeartRateZone,

    /// Structured interval session — present for `type == 'interval'` days.
    /// Null for easy/tempo/long/recovery runs.
    @JsonKey(name: 'intervals_json', fromJson: _intervalsFromJson)
    List<TrainingInterval>? intervals,
    @JsonKey(fromJson: toInt) required int order,
    TrainingResult? result,
  }) = _TrainingDay;

  factory TrainingDay.fromJson(Map<String, dynamic> json) =>
      _$TrainingDayFromJson(json);
}

List<TrainingInterval>? _intervalsFromJson(Object? raw) {
  // Current shape: JSON array of segment objects. Legacy rows pre-rewrite
  // may have stored a flat Map — silently treat those as "no intervals"
  // rather than crashing; user can regenerate the plan.
  if (raw is! List) return null;
  final segments = raw
      .whereType<Map>()
      .map(
        (m) => TrainingInterval.fromJson(Map<String, dynamic>.from(m)),
      )
      .toList(growable: false);
  return segments.isEmpty ? null : segments;
}
