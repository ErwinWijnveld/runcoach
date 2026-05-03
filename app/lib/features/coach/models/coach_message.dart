import 'dart:convert';

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
    // Set when the workout-scoped agent calls EscalateToCoach. The UI
    // renders a tile under this message that opens a fresh coach chat
    // pre-seeded with this prompt. Not persisted server-side — the SDK
    // stores it in tool_results, but reload doesn't re-display it (the
    // hand-off was a one-shot decision; reopening the workout chat
    // shouldn't keep nagging).
    @JsonKey(includeFromJson: false, includeToJson: false)
    String? handoffPrompt,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);

  /// Hydrate stats card + chips from tool_results when loading historic
  /// messages from the show endpoint.
  ///
  /// The Laravel AI SDK stores tool_results as either a list or a map keyed
  /// by step index (the Anthropic provider uses the latter), and each result
  /// may be a JSON-encoded string — normalise both.
  factory CoachMessage.fromShowJson(Map<String, dynamic> json) {
    final base = CoachMessage.fromJson(json);
    final rawToolResults = json['tool_results'];
    final Iterable toolResults = switch (rawToolResults) {
      List l => l,
      Map m => m.values,
      _ => const [],
    };

    CoachStatsCard? stats;
    List<CoachChip>? chips;
    for (final tr in toolResults) {
      if (tr is! Map) continue;
      var result = tr['result'];
      if (result is String) {
        try {
          result = jsonDecode(result);
        } catch (_) {
          continue;
        }
      }
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
