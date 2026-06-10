import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/interval_blueprint.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'training_day.freezed.dart';
part 'training_day.g.dart';

@freezed
sealed class TrainingDay with _$TrainingDay {
  const factory TrainingDay({
    required int id,
    required String date,
    required String type,
    required String title,
    String? description,
    @JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? targetKm,
    @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)
    int? targetPaceSecondsPerKm,
    @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull)
    int? targetHeartRateZone,

    /// Structured interval session (grouped blueprint) — present for
    /// `type == 'interval'` days. Null for easy/tempo/long/recovery runs.
    @JsonKey(name: 'intervals_json', fromJson: _intervalsFromJson)
    IntervalBlueprint? intervals,
    @JsonKey(fromJson: toInt) required int order,
    TrainingResult? result,

    /// Server-side `updated_at` (ISO-8601). The watch auto-sync compares
    /// this against a locally-stored `lastSyncedAt` to decide which days
    /// to re-ship on app foreground (coach-driven edits).
    @JsonKey(name: 'updated_at') DateTime? updatedAt,
  }) = _TrainingDay;

  factory TrainingDay.fromJson(Map<String, dynamic> json) =>
      _$TrainingDayFromJson(json);
}

IntervalBlueprint? _intervalsFromJson(Object? raw) {
  // Canonical: a grouped Map ({warmup_seconds, steps, cooldown_seconds}).
  // Legacy rows (pre-migration) may still be a flat segment List — fold
  // those so they keep rendering. Anything else → no intervals.
  if (raw is Map && raw['steps'] is List) {
    final bp = IntervalBlueprint.fromJson(Map<String, dynamic>.from(raw));
    return bp.isEmpty ? null : bp;
  }
  if (raw is List) {
    final bp = IntervalBlueprint.fromFlatSegments(raw);
    return bp.isEmpty ? null : bp;
  }
  return null;
}
