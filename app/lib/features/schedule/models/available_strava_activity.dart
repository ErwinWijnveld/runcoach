import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'available_strava_activity.freezed.dart';
part 'available_strava_activity.g.dart';

/// One recent Strava run exposed by
/// GET /training-days/{id}/available-activities. Used by the "Select Strava
/// run" modal as a fallback when the webhook didn't auto-sync a run.
@freezed
sealed class AvailableStravaActivity with _$AvailableStravaActivity {
  const factory AvailableStravaActivity({
    @JsonKey(name: 'strava_activity_id') required int stravaActivityId,
    required String name,
    @JsonKey(name: 'start_date') String? startDate,
    @JsonKey(name: 'distance_km', fromJson: toDouble) required double distanceKm,
    @JsonKey(name: 'moving_time_seconds', fromJson: toInt)
    required int movingTimeSeconds,
    @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)
    int? averagePaceSecondsPerKm,
    @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)
    double? averageHeartRate,

    /// Non-null if this Strava run is already matched to a training day
    /// (the current day OR any other day). Used to render a "synced" badge
    /// and make the row non-selectable.
    @JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId,
  }) = _AvailableStravaActivity;

  factory AvailableStravaActivity.fromJson(Map<String, dynamic> json) =>
      _$AvailableStravaActivityFromJson(json);
}
