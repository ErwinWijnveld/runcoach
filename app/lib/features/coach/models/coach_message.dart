import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_chip.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:app/features/coach/models/coach_stats_card.dart';

part 'coach_message.freezed.dart';
part 'coach_message.g.dart';

@freezed
sealed class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
    @JsonKey(includeFromJson: false, includeToJson: false)
    CoachStatsCard? statsCard,
    @JsonKey(includeFromJson: false, includeToJson: false)
    List<CoachChip>? chips,
    @JsonKey(includeFromJson: false, includeToJson: false) String? errorDetail,
    @JsonKey(includeFromJson: false, includeToJson: false)
    @Default(false)
    bool streaming,
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? toolIndicator,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);

  /// Hydrate stats card + chips from tool_results when loading historic
  /// messages from the show endpoint.
  factory CoachMessage.fromShowJson(Map<String, dynamic> json) {
    final base = CoachMessage.fromJson(json);
    final toolResults = (json['tool_results'] as List?) ?? const [];

    CoachStatsCard? stats;
    List<CoachChip>? chips;
    for (final tr in toolResults) {
      final result = (tr as Map)['result'];
      if (result is! Map) continue;
      if (result['display'] == 'stats_card') {
        stats = CoachStatsCard.fromJson(
          Map<String, dynamic>.from(
            result['metrics'] == null
                ? result
                : {'metrics': result['metrics']},
          ),
        );
      }
      if (result['display'] == 'chip_suggestions') {
        final rawChips = (result['chips'] as List?) ?? const [];
        chips = rawChips
            .map(
              (c) => CoachChip.fromJson(Map<String, dynamic>.from(c as Map)),
            )
            .toList();
      }
    }

    return base.copyWith(statsCard: stats, chips: chips);
  }
}
