import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/schedule/models/training_interval.dart';

/// Renders the structured interval-session plan as a Figma-faithful table
/// (alternating neutral rows), with Distance / Time / Pace columns. The
/// first column is the human label ("Warm up", "Inspanning", "Recovery",
/// "Cool down").
class TrainingIntervalsTable extends StatelessWidget {
  final List<TrainingInterval> intervals;

  const TrainingIntervalsTable({super.key, required this.intervals});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(30),
      ),
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          // Column header — right-aligned over the 3 metric columns
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                const SizedBox(width: 106),
                Expanded(child: _header('Distance')),
                Expanded(child: _header('Time')),
                Expanded(child: _header('Pace')),
              ],
            ),
          ),
          for (var i = 0; i < intervals.length; i++)
            _IntervalRow(interval: intervals[i], striped: i.isEven),
        ],
      ),
    );
  }

  Text _header(String text) => Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.primary,
        ),
      );
}

class _IntervalRow extends StatelessWidget {
  final TrainingInterval interval;
  final bool striped;

  const _IntervalRow({required this.interval, required this.striped});

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.spaceGrotesk(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: AppColors.primary,
    );

    return Container(
      height: 38,
      color: striped ? AppColors.neutral : CupertinoColors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          SizedBox(
            width: 106,
            child: Text(interval.label, style: style),
          ),
          Expanded(child: Text(_formatDistance(interval), style: style)),
          Expanded(child: Text(_formatDuration(interval), style: style)),
          Expanded(child: Text(_formatPace(interval), style: style)),
        ],
      ),
    );
  }

  String _formatDistance(TrainingInterval s) {
    final m = s.distanceM;
    if (m == null || m <= 0) return '-';
    if (m >= 1000 && m % 100 == 0) {
      return '${(m / 1000).toStringAsFixed(m % 1000 == 0 ? 0 : 1)}km';
    }
    return '${m}m';
  }

  String _formatDuration(TrainingInterval s) {
    final secs = s.durationSeconds;
    if (secs == null || secs <= 0) return '-';
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return '$mm:${ss.toString().padLeft(2, '0')}';
  }

  String _formatPace(TrainingInterval s) {
    final secs = s.targetPaceSecondsPerKm;
    if (secs == null || secs <= 0) return '-';
    final mm = secs ~/ 60;
    final ss = secs % 60;
    return "$mm'${ss.toString().padLeft(2, '0')}\"";
  }
}
