import 'package:flutter/painting.dart';
import 'package:app/core/theme/app_theme.dart';

/// Single source of truth for compliance-score → color mapping. Used by:
///   - `training_result_screen` (overall + per-section bars)
///   - `training_day_stat_tiles` (per-section coloring of actual values)
///   - `coach_analysis_card` (ring around the % indicator)
///
/// Thresholds operate on a 0–1 normalized scale. The `*Score10` helpers
/// take the raw 0–10 score that `ComplianceScoringService` writes to
/// `TrainingResult` and clamp into the same buckets.
///
/// Bucket cutoffs (inclusive lower-bound):
///   ≥ 0.80 → success green
///   ≥ 0.50 → secondary gold
///    < 0.50 → danger red
class ComplianceColors {
  static const goodThreshold = 0.80;
  static const okThreshold = 0.50;

  static const good = Color(0xFF34C759);
  static const ok = AppColors.secondary;
  static const bad = AppColors.danger;

  /// Color for a 0–1 normalized compliance score.
  static Color forScore01(double score01) {
    final clamped = score01.clamp(0.0, 1.0);
    if (clamped >= goodThreshold) return good;
    if (clamped >= okThreshold) return ok;
    return bad;
  }

  /// Convenience for the raw 0–10 scale stored on `TrainingResult`.
  /// Nullable input mirrors `heartRateScore` which is null when the run
  /// had no HR data — caller decides what to render in that case.
  static Color? forScore10(double? score10) {
    if (score10 == null) return null;
    return forScore01((score10 / 10).clamp(0.0, 1.0));
  }
}
