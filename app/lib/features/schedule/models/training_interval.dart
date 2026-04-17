import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'training_interval.freezed.dart';
part 'training_interval.g.dart';

/// One segment of a structured interval session (warm-up, a work rep, a
/// recovery jog, a cool-down). The full session is the ordered list
/// attached to `TrainingDay.intervals`.
@freezed
sealed class TrainingInterval with _$TrainingInterval {
  const factory TrainingInterval({
    /// `warmup | work | recovery | cooldown` — drives how the row is styled
    /// in the session table.
    required String kind,

    /// Short human label the runner sees ("Warm up", "800m @ 10k pace",
    /// "Recovery jog", "Cool down").
    required String label,

    @JsonKey(name: 'distance_m', fromJson: toIntOrNull) int? distanceM,
    @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)
    int? durationSeconds,
    @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)
    int? targetPaceSecondsPerKm,
  }) = _TrainingInterval;

  factory TrainingInterval.fromJson(Map<String, dynamic> json) =>
      _$TrainingIntervalFromJson(json);
}
