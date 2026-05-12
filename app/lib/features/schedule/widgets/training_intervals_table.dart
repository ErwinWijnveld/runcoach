import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/training_interval.dart';
import 'package:app/l10n/app_localizations.dart';

/// Visualisation of a structured interval session in two stacked views:
/// 1. A Zwift-style effort-curve bar chart at the top — each segment is one
///    bar; horizontal width is proportional to that segment's duration and
///    vertical height is proportional to its pace intensity (faster = taller).
/// 2. A compact text breakdown below where consecutive identical
///    (work, recovery) pairs are collapsed into one block: "10× 800m @ 4:30 /
///    90s recovery", so a 10-rep session is two rows instead of twenty.
class TrainingIntervalsTable extends StatelessWidget {
  final List<TrainingInterval> intervals;

  const TrainingIntervalsTable({super.key, required this.intervals});

  @override
  Widget build(BuildContext context) {
    final groups = _groupIntervals(intervals);

    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _IntervalEffortChart(intervals: intervals),
          const SizedBox(height: 20),
          for (var i = 0; i < groups.length; i++) ...[
            _GroupRow(group: groups[i]),
            if (i < groups.length - 1) const _TimelineConnector(),
          ],
        ],
      ),
    );
  }
}

class _TimelineConnector extends StatelessWidget {
  const _TimelineConnector();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 14,
      child: Center(
        child: Container(
          width: 2,
          color: AppColors.lightTan,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Effort-curve chart (Zwift-style)
// ---------------------------------------------------------------------------

class _IntervalEffortChart extends StatelessWidget {
  final List<TrainingInterval> intervals;
  const _IntervalEffortChart({required this.intervals});

  @override
  Widget build(BuildContext context) {
    final durations = intervals.map(_durationSecondsOf).toList();
    final totalDuration =
        durations.fold<int>(0, (sum, d) => sum + d).clamp(1, 1 << 30);

    final paces = intervals
        .map((s) => s.targetPaceSecondsPerKm)
        .whereType<int>()
        .where((p) => p > 0)
        .toList();
    final paceRange = paces.isEmpty
        ? const _PaceRange(min: 240, max: 600)
        : _PaceRange(
            min: paces.reduce((a, b) => a < b ? a : b),
            max: paces.reduce((a, b) => a > b ? a : b),
          );

    return SizedBox(
      height: 80,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < intervals.length; i++)
            Expanded(
              flex: durations[i] == 0
                  ? 1
                  : ((durations[i] / totalDuration) * 1000).round().clamp(
                        1,
                        1000,
                      ),
              child: Padding(
                padding: EdgeInsets.only(
                  left: i == 0 ? 0 : 1.5,
                  right: i == intervals.length - 1 ? 0 : 1.5,
                ),
                child: _EffortBar(
                  interval: intervals[i],
                  paceRange: paceRange,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _EffortBar extends StatelessWidget {
  final TrainingInterval interval;
  final _PaceRange paceRange;
  const _EffortBar({required this.interval, required this.paceRange});

  @override
  Widget build(BuildContext context) {
    final intensity = _intensityFor(interval, paceRange);
    // Single gold across every bar; opacity scales with speed so the
    // fastest segment is fully saturated and slower ones fade — never
    // below 50% so warmup / recovery stay legible.
    final opacity = (0.5 + intensity * 0.5).clamp(0.5, 1.0);

    return FractionallySizedBox(
      heightFactor: intensity,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.secondary.withValues(alpha: opacity),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ),
      ),
    );
  }
}

class _PaceRange {
  final int min;
  final int max;
  const _PaceRange({required this.min, required this.max});
}

/// Map (segment, pace range) → bar height factor in [0.18, 1.0].
/// Faster paces (lower seconds-per-km) yield taller bars. Segments with no
/// target pace fall back to a kind-based default so the bars still convey
/// the warmup → work → recovery → cooldown rhythm.
double _intensityFor(TrainingInterval s, _PaceRange range) {
  final pace = s.targetPaceSecondsPerKm;
  if (pace != null && pace > 0 && range.max > range.min) {
    final t = (range.max - pace) / (range.max - range.min);
    return (0.25 + t * 0.75).clamp(0.18, 1.0);
  }
  return switch (s.kind) {
    'work' => 0.95,
    'recovery' => 0.35,
    'warmup' || 'cooldown' => 0.45,
    _ => 0.5,
  };
}

Color _kindColor(String kind) => switch (kind) {
      'work' => AppColors.secondary,
      'recovery' => AppColors.lightTan,
      'warmup' || 'cooldown' => AppColors.inkMuted,
      _ => AppColors.primary,
    };

int _durationSecondsOf(TrainingInterval s) {
  if (s.durationSeconds != null && s.durationSeconds! > 0) {
    return s.durationSeconds!;
  }
  final dist = s.distanceM ?? 0;
  final pace = s.targetPaceSecondsPerKm ?? 0;
  if (dist > 0 && pace > 0) {
    return (dist / 1000 * pace).round();
  }
  return 0;
}

// ---------------------------------------------------------------------------
// Grouped breakdown rows
// ---------------------------------------------------------------------------

sealed class _IntervalGroup {
  const _IntervalGroup();
}

class _SingleStep extends _IntervalGroup {
  final TrainingInterval step;
  const _SingleStep(this.step);
}

class _RepBlock extends _IntervalGroup {
  final int reps;
  final TrainingInterval work;
  final TrainingInterval? recovery;
  const _RepBlock({
    required this.reps,
    required this.work,
    required this.recovery,
  });
}

/// Greedy parser: collapses consecutive uniform (work, recovery?) pairs into
/// a single rep block. Mixed pyramids and one-off steps stay as singles.
List<_IntervalGroup> _groupIntervals(List<TrainingInterval> intervals) {
  final out = <_IntervalGroup>[];
  var i = 0;
  while (i < intervals.length) {
    final current = intervals[i];
    if (current.kind == 'work') {
      final next = i + 1 < intervals.length ? intervals[i + 1] : null;
      final hasRecovery = next != null && next.kind == 'recovery';
      final pairLen = hasRecovery ? 2 : 1;

      var reps = 1;
      var j = i + pairLen;
      while (j + pairLen - 1 < intervals.length &&
          _shapeEquals(intervals[j], current) &&
          (!hasRecovery || _shapeEquals(intervals[j + 1], next))) {
        reps++;
        j += pairLen;
      }

      if (reps > 1) {
        out.add(_RepBlock(
          reps: reps,
          work: current,
          recovery: hasRecovery ? next : null,
        ));
        i = j;
        continue;
      }
    }
    out.add(_SingleStep(current));
    i++;
  }
  return out;
}

bool _shapeEquals(TrainingInterval a, TrainingInterval b) =>
    a.kind == b.kind &&
    a.distanceM == b.distanceM &&
    a.durationSeconds == b.durationSeconds &&
    a.targetPaceSecondsPerKm == b.targetPaceSecondsPerKm;

class _GroupRow extends StatelessWidget {
  final _IntervalGroup group;
  const _GroupRow({required this.group});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return switch (group) {
      _SingleStep(:final step) => _Block(
          eyebrow: _kindLabel(l10n, step.kind).toUpperCase(),
          eyebrowColor: _kindColor(step.kind),
          measure: _formatMeasure(step),
          pace: _formatPace(step),
        ),
      _RepBlock(:final reps, :final work, :final recovery) => _Block(
          eyebrow: _kindLabel(l10n, work.kind).toUpperCase(),
          eyebrowColor: _kindColor(work.kind),
          reps: reps,
          measure: _formatMeasure(work),
          pace: _formatPace(work),
          subRow: recovery == null
              ? null
              : _SubRow(
                  label: l10n.intervalKindRecovery,
                  measure: _formatMeasure(recovery),
                  pace: _formatPace(recovery),
                ),
        ),
    };
  }
}

class _SubRow {
  final String label;
  final String measure;
  final String pace;
  const _SubRow({
    required this.label,
    required this.measure,
    required this.pace,
  });
}

class _Block extends StatelessWidget {
  final String eyebrow;
  final Color eyebrowColor;
  final int? reps;
  final String measure;
  final String pace;
  final _SubRow? subRow;

  const _Block({
    required this.eyebrow,
    required this.eyebrowColor,
    this.reps,
    required this.measure,
    required this.pace,
    this.subRow,
  });

  @override
  Widget build(BuildContext context) {
    final mainStyle = GoogleFonts.publicSans(
      fontSize: 17,
      fontWeight: FontWeight.w600,
      color: AppColors.primaryInk,
      height: 1.1,
    );
    final subStyle = GoogleFonts.publicSans(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      color: AppColors.inkMuted,
      height: 1.2,
    );

    // Stack-based layout: the colored kind stripe is positioned on the left
    // edge of the card and stretches to its natural height, avoiding the
    // sub-pixel overflow that an IntrinsicHeight + Row(stretch) layout
    // introduces with baseline-aligned text rows.
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(
            left: 0,
            right: null,
            child: Container(width: 4, color: eyebrowColor),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (reps != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: eyebrowColor,
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        '$reps× $eyebrow',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: CupertinoColors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Text(
                    eyebrow,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: eyebrowColor,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(child: Text(measure, style: mainStyle)),
                    if (pace.isNotEmpty) Text(pace, style: mainStyle),
                  ],
                ),
                if (subRow != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${subRow!.label} · ${subRow!.measure}',
                          style: subStyle,
                        ),
                      ),
                      if (subRow!.pace.isNotEmpty)
                        Text(subRow!.pace, style: subStyle),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _kindLabel(AppLocalizations l, String kind) => switch (kind) {
      'warmup' => l.intervalKindWarmup,
      'work' => l.intervalKindWork,
      'recovery' => l.intervalKindRecovery,
      'cooldown' => l.intervalKindCooldown,
      _ => kind,
    };

String _formatMeasure(TrainingInterval s) {
  final parts = <String>[];
  final dist = s.distanceM;
  if (dist != null && dist > 0) {
    if (dist >= 1000 && dist % 100 == 0) {
      parts.add('${(dist / 1000).toStringAsFixed(dist % 1000 == 0 ? 0 : 1)}km');
    } else {
      parts.add('${dist}m');
    }
  }
  final secs = s.durationSeconds;
  if (secs != null && secs > 0) {
    final mm = secs ~/ 60;
    final ss = secs % 60;
    if (mm == 0) {
      parts.add('${ss}s');
    } else if (ss == 0) {
      parts.add('${mm}min');
    } else {
      parts.add('$mm:${ss.toString().padLeft(2, '0')}');
    }
  }
  return parts.isEmpty ? '-' : parts.join(' · ');
}

String _formatPace(TrainingInterval s) {
  final secs = s.targetPaceSecondsPerKm;
  if (secs == null || secs <= 0) return '';
  final mm = secs ~/ 60;
  final ss = secs % 60;
  return "$mm:${ss.toString().padLeft(2, '0')}/km";
}
