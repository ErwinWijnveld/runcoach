import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';

part 'hr_zone.freezed.dart';
part 'hr_zone.g.dart';

@freezed
sealed class HrZone with _$HrZone {
  const factory HrZone({
    @JsonKey(fromJson: toInt) required int min,
    // Zone 5's max is `-1` by convention (open-ended).
    @JsonKey(fromJson: toInt) required int max,
  }) = _HrZone;

  factory HrZone.fromJson(Map<String, dynamic> json) => _$HrZoneFromJson(json);
}
