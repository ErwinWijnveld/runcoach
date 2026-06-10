import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/core/utils/json_converters.dart';
import 'package:app/features/schedule/models/training_interval.dart';

part 'interval_blueprint.freezed.dart';
part 'interval_blueprint.g.dart';

/// The canonical grouped interval session, mirroring the backend
/// `IntervalBlueprint`: an optional time-based warmup, an ordered list of
/// steps (loops / single reps / rests), and a required time-based cooldown.
/// "4×800m w/ 2min, then 4×400m w/ 1min" is two [IntervalStep] blocks.
@freezed
sealed class IntervalBlueprint with _$IntervalBlueprint {
  const factory IntervalBlueprint({
    @JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) int? warmupSeconds,
    @Default(<IntervalStep>[]) List<IntervalStep> steps,
    @JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) int? cooldownSeconds,
  }) = _IntervalBlueprint;

  factory IntervalBlueprint.fromJson(Map<String, dynamic> json) =>
      _$IntervalBlueprintFromJson(json);

  /// Fold a legacy FLAT segment list (`[{kind, distance_m, ...}]`) into the
  /// grouped form. Mirrors the backend `IntervalBlueprint::collapse` greedy
  /// matcher so rows written before the grouped migration still render.
  factory IntervalBlueprint.fromFlatSegments(List<dynamic> flat) {
    final segments = flat.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();

    int? warmup;
    int? cooldown;
    final middle = <Map<String, dynamic>>[];
    for (final s in segments) {
      final kind = (s['kind'] ?? 'work').toString();
      if (kind == 'warmup' && warmup == null) {
        warmup = (s['duration_seconds'] as num?)?.toInt() ?? 60;
      } else if (kind == 'cooldown') {
        cooldown = (s['duration_seconds'] as num?)?.toInt() ?? 300;
      } else {
        middle.add(s);
      }
    }

    int? distOf(Map<String, dynamic> w) => (w['distance_m'] as num?)?.toInt();
    int? durOf(Map<String, dynamic> w) => (w['duration_seconds'] as num?)?.toInt();
    int? paceOf(Map<String, dynamic> w) => (w['target_pace_seconds_per_km'] as num?)?.toInt();
    bool workEq(Map<String, dynamic> a, Map<String, dynamic> b) =>
        distOf(a) == distOf(b) && durOf(a) == durOf(b) && paceOf(a) == paceOf(b);

    final steps = <IntervalStep>[];
    var i = 0;
    while (i < middle.length) {
      final cur = middle[i];
      if ((cur['kind'] ?? 'work') == 'recovery') {
        steps.add(IntervalStep(type: 'rest', durationSeconds: durOf(cur) ?? 90));
        i++;
        continue;
      }
      final next = i + 1 < middle.length ? middle[i + 1] : null;
      if (next == null || (next['kind'] ?? '') != 'recovery') {
        steps.add(IntervalStep(
          type: 'rep',
          workDistanceM: distOf(cur),
          workDurationSeconds: durOf(cur),
          workPaceSecondsPerKm: paceOf(cur),
        ));
        i++;
        continue;
      }
      var reps = 1;
      var j = i + 2;
      while (j + 1 < middle.length &&
          (middle[j]['kind'] ?? '') == 'work' &&
          (middle[j + 1]['kind'] ?? '') == 'recovery' &&
          workEq(middle[j], cur) &&
          durOf(middle[j + 1]) == durOf(next)) {
        reps++;
        j += 2;
      }
      steps.add(IntervalStep(
        type: 'block',
        reps: reps,
        workDistanceM: distOf(cur),
        workDurationSeconds: durOf(cur),
        workPaceSecondsPerKm: paceOf(cur),
        recoverySeconds: durOf(next) ?? 90,
      ));
      i = j;
    }

    return IntervalBlueprint(warmupSeconds: warmup, steps: steps, cooldownSeconds: cooldown ?? 300);
  }

  const IntervalBlueprint._();

  /// Estimator constants — MUST stay in sync with the backend
  /// `IntervalBlueprint::ESTIMATE_*` constants; the shared unit-test vectors
  /// in `interval_blueprint_estimate_test.dart` pin both sides together.
  static const int estimateJogOffsetFromWork = 100;
  static const int estimateFallbackJogPaceSeconds = 360;
  static const int estimateJogPaceMinSeconds = 180;
  static const int estimateJogPaceMaxSeconds = 720;

  bool get isEmpty => steps.isEmpty;

  bool get isNotEmpty => steps.isNotEmpty;

  /// Estimated TOTAL session distance (km, 1 decimal) — Dart port of the
  /// backend `IntervalBlueprint::estimateTotalKm`, used for the live
  /// "Distance (auto)" preview in the interval editor. The server remains
  /// the source of truth (its saving hook derives the stored `target_km`);
  /// this mirror only exists so the preview matches what will be stored.
  /// Assumes canonical (server-normalized or editor-built) steps; returns
  /// null when there's nothing to estimate.
  double? estimateTotalKm() {
    if (steps.isEmpty) return null;

    final workPaces = steps
        .where((s) => s.type != 'rest' && (s.workPaceSecondsPerKm ?? 0) > 0)
        .map((s) => s.workPaceSecondsPerKm!)
        .toList(growable: false);
    final avgWorkPace = workPaces.isEmpty
        ? null
        : (workPaces.reduce((a, b) => a + b) / workPaces.length).round();
    final jogPace = avgWorkPace == null
        ? estimateFallbackJogPaceSeconds
        : (avgWorkPace + estimateJogOffsetFromWork)
            .clamp(estimateJogPaceMinSeconds, estimateJogPaceMaxSeconds);

    var meters = 0.0;
    if ((warmupSeconds ?? 0) > 0) {
      meters += warmupSeconds! / jogPace * 1000;
    }
    for (final s in steps) {
      if (s.type == 'rest') {
        meters += (s.durationSeconds ?? 0) / jogPace * 1000;
        continue;
      }
      final reps = s.type == 'block' ? (s.reps ?? 1) : 1;
      if ((s.workDistanceM ?? 0) > 0) {
        meters += reps * s.workDistanceM!;
      } else if ((s.workDurationSeconds ?? 0) > 0) {
        final workPace = s.workPaceSecondsPerKm ?? avgWorkPace ?? jogPace;
        meters += reps * (s.workDurationSeconds! / workPace * 1000);
      }
      if (s.type == 'block') {
        meters += reps * ((s.recoverySeconds ?? 0) / jogPace * 1000);
      }
    }
    meters += (cooldownSeconds ?? 0) / jogPace * 1000;

    return (meters / 100).round() / 10;
  }

  /// Unroll into a flat segment list (warmup + each block's reps × work+
  /// recovery + cooldown). Lets the existing flat-based widgets (effort
  /// chart, send-to-watch) and the legacy renderers keep working unchanged.
  List<TrainingInterval> expand() {
    final out = <TrainingInterval>[];
    if (warmupSeconds != null) {
      out.add(TrainingInterval(kind: 'warmup', label: 'Warm up', durationSeconds: warmupSeconds));
    }
    for (final s in steps) {
      if (s.type == 'rest') {
        out.add(TrainingInterval(kind: 'recovery', label: 'Rest', durationSeconds: s.durationSeconds));
        continue;
      }
      final reps = s.type == 'block' ? (s.reps ?? 1) : 1;
      final label = s.workDistanceM != null ? '${s.workDistanceM}m rep' : '${s.workDurationSeconds}s rep';
      for (var r = 0; r < reps; r++) {
        out.add(TrainingInterval(
          kind: 'work',
          label: label,
          distanceM: s.workDistanceM,
          durationSeconds: s.workDurationSeconds,
          targetPaceSecondsPerKm: s.workPaceSecondsPerKm,
        ));
        if (s.type == 'block') {
          out.add(TrainingInterval(kind: 'recovery', label: 'Recovery', durationSeconds: s.recoverySeconds));
        }
      }
    }
    if (cooldownSeconds != null) {
      out.add(TrainingInterval(kind: 'cooldown', label: 'Cool down', durationSeconds: cooldownSeconds));
    }
    return out;
  }
}

/// One step of an interval session. `type` is `block` (N×(work+recovery)),
/// `rep` (single work, no recovery), or `rest` (standalone recovery).
@freezed
sealed class IntervalStep with _$IntervalStep {
  const factory IntervalStep({
    required String type,
    @JsonKey(fromJson: toIntOrNull) int? reps,
    @JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) int? workDistanceM,
    @JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) int? workDurationSeconds,
    @JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) int? workPaceSecondsPerKm,
    @JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) int? recoverySeconds,
    @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? durationSeconds,
  }) = _IntervalStep;

  factory IntervalStep.fromJson(Map<String, dynamic> json) => _$IntervalStepFromJson(json);
}
