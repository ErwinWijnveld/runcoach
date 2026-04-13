import 'package:freezed_annotation/freezed_annotation.dart';

part 'race.freezed.dart';
part 'race.g.dart';

@freezed
sealed class Race with _$Race {
  const factory Race({
    required int id,
    required String name,
    required String distance,
    @JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,
    @JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,
    @JsonKey(name: 'race_date') required String raceDate,
    required String status,
  }) = _Race;

  factory Race.fromJson(Map<String, dynamic> json) => _$RaceFromJson(json);
}
