import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'available_activity.freezed.dart';
part 'available_activity.g.dart';

/// One synced wearable run exposed by
/// GET /training-days/{id}/available-activities. Used by the "Pick activity"
/// modal on the training day detail screen.
@freezed
sealed class AvailableActivity with _$AvailableActivity {
  const factory AvailableActivity({
    @JsonKey(name: 'wearable_activity_id') required int wearableActivityId,
    required String source,
    required String name,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'distance_km', fromJson: toDouble) required double distanceKm,
    @JsonKey(name: 'duration_seconds', fromJson: toInt)
    required int durationSeconds,
    @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)
    int? averagePaceSecondsPerKm,
    @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)
    double? averageHeartRate,

    /// Non-null if this run is already matched to a training day. Used to
    /// render a "synced" badge and disable the row.
    @JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId,
  }) = _AvailableActivity;

  factory AvailableActivity.fromJson(Map<String, dynamic> json) =>
      _$AvailableActivityFromJson(json);
}
