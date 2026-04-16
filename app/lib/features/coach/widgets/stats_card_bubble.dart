import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// Stats card rendered inside the bot-message bubble. 2x2 grid of metric tiles.
class StatsCardBubble extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const StatsCardBubble({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      _Tile(
        label: 'WEEKLY\nAVG. KM',
        value: _formatKm(metrics['weekly_avg_km']),
      ),
      _Tile(
        label: 'WEEKLY\nAVG. RUNS',
        value: '${metrics['weekly_avg_runs'] ?? 0}',
      ),
      _Tile(
        label: 'AVG PACE',
        value: _formatPace(metrics['avg_pace_seconds_per_km']),
      ),
      _Tile(
        label: 'SESSION\nAVG. TIME',
        value: _formatDuration(metrics['session_avg_duration_seconds']),
      ),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: _metric(tiles[0])),
          const SizedBox(width: 8),
          Expanded(child: _metric(tiles[1])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _metric(tiles[2])),
          const SizedBox(width: 8),
          Expanded(child: _metric(tiles[3])),
        ]),
      ],
    );
  }

  Widget _metric(_Tile t) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightTan,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF817662),
                letterSpacing: 0.96,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKm(dynamic v) => v == null ? '0' : (v is num ? v.toStringAsFixed(1) : '$v');

  String _formatPace(dynamic seconds) {
    if (seconds == null || seconds is! num || seconds == 0) return '—';
    final s = seconds.toInt();
    final mins = s ~/ 60;
    final secs = s % 60;
    return "$mins'${secs.toString().padLeft(2, '0')}\"";
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds is! num || seconds == 0) return '—';
    final s = seconds.toInt();
    final mins = s ~/ 60;
    final secs = s % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}

class _Tile {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});
}
