import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'wearable_activity_summary.freezed.dart';
part 'wearable_activity_summary.g.dart';

/// Compact view of a wearable run persisted locally in `wearable_activities`.
/// Eager-loaded onto `TrainingResult.wearableActivity` when the backend
/// returns a completed training day — gives us a run name, start time,
/// duration and HR without re-querying the source.
///
/// `raw_data` is hidden server-side and never arrives over the wire.
@freezed
sealed class WearableActivitySummary with _$WearableActivitySummary {
  const factory WearableActivitySummary({
    required int id,
    /// Source provider: 'apple_health', 'strava', 'garmin', 'polar', etc.
    required String source,
    @JsonKey(name: 'source_activity_id') required String sourceActivityId,
    required String type,
    String? name,
    @JsonKey(name: 'distance_meters', fromJson: toInt)
    required int distanceMeters,
    @JsonKey(name: 'duration_seconds', fromJson: toInt)
    required int durationSeconds,
    @JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull)
    int? elapsedSeconds,
    @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt)
    required int averagePaceSecondsPerKm,
    @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)
    double? averageHeartrate,
    @JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull)
    double? maxHeartrate,
    @JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull)
    int? elevationGainMeters,
    @JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) int? caloriesKcal,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'end_date') String? endDate,
  }) = _WearableActivitySummary;

  factory WearableActivitySummary.fromJson(Map<String, dynamic> json) =>
      _$WearableActivitySummaryFromJson(json);
}
