import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/auth/models/hr_zone.dart';

part 'derived_zones.freezed.dart';
part 'derived_zones.g.dart';

/// Result of POST /profile/heart-rate-zones/derive.
///
/// Drives the subtitle on the onboarding zones screen + the toast/feedback
/// after pressing "Recompute" in the menu sheet:
///
///   - `derived_empirical` + `sampleCount=23` + `maxHr=191` →
///     "Based on your last 23 runs, your max HR is around 191 bpm."
///   - `derived_age` + `age=47`               →
///     "Estimated from your age (47 years). Sync more runs with HR for
///      more accurate zones."
///   - `default`                             →
///     "We couldn't pull HR data — please verify these defaults."
@freezed
sealed class DerivedZones with _$DerivedZones {
  const factory DerivedZones({
    required List<HrZone> zones,
    required String source,
    @JsonKey(name: 'max_hr', fromJson: toIntOrNull) int? maxHr,
    @JsonKey(name: 'sample_count', fromJson: toInt) required int sampleCount,
    @JsonKey(fromJson: toIntOrNull) int? age,
    @JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) int? restingHeartRate,
  }) = _DerivedZones;

  factory DerivedZones.fromJson(Map<String, dynamic> json) =>
      _$DerivedZonesFromJson(json);
}
