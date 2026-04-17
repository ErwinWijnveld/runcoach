import 'package:freezed_annotation/freezed_annotation.dart';

part 'goal.freezed.dart';
part 'goal.g.dart';

@freezed
sealed class Goal with _$Goal {
  const factory Goal({
    required int id,
    required String type,
    required String name,
    String? distance,
    @JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,
    @JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,
    @JsonKey(name: 'target_date') String? targetDate,
    required String status,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
