import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'strava_activity_summary.freezed.dart';
part 'strava_activity_summary.g.dart';

/// Compact view of a Strava run persisted locally in the `strava_activities`
/// table. Eager-loaded onto `TrainingResult.stravaActivity` when the backend
/// returns a completed training day — gives us a run name, start time,
/// duration and HR without hitting the Strava API again.
///
/// The `raw_data` column (full Strava JSON) is hidden server-side and never
/// arrives over the wire.
@freezed
sealed class StravaActivitySummary with _$StravaActivitySummary {
  const factory StravaActivitySummary({
    required int id,
    @JsonKey(name: 'strava_id', fromJson: toInt) required int stravaId,
    required String type,
    required String name,
    @JsonKey(name: 'distance_meters', fromJson: toInt)
    required int distanceMeters,
    @JsonKey(name: 'moving_time_seconds', fromJson: toInt)
    required int movingTimeSeconds,
    @JsonKey(name: 'elapsed_time_seconds', fromJson: toInt)
    required int elapsedTimeSeconds,
    @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)
    double? averageHeartrate,
    @JsonKey(name: 'average_speed', fromJson: toDoubleOrNull)
    double? averageSpeed,
    @JsonKey(name: 'start_date') required String startDate,
    @JsonKey(name: 'summary_polyline') String? summaryPolyline,
  }) = _StravaActivitySummary;

  factory StravaActivitySummary.fromJson(Map<String, dynamic> json) =>
      _$StravaActivitySummaryFromJson(json);
}
