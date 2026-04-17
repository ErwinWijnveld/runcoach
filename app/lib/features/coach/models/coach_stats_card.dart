import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_stats_card.freezed.dart';
part 'coach_stats_card.g.dart';

@freezed
sealed class CoachStatsCard with _$CoachStatsCard {
  const factory CoachStatsCard({
    required Map<String, dynamic> metrics,
  }) = _CoachStatsCard;

  factory CoachStatsCard.fromJson(Map<String, dynamic> json) =>
      _$CoachStatsCardFromJson(json);
}
