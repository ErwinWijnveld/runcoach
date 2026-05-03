import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// One tile's worth of data: the planned target value (always shown big),
/// and an optional actual value (rendered small underneath in the per-section
/// compliance color). Pass `actual = null` to hide the second line.
class StatTileData {
  final String? target;
  final String? actual;
  final Color? actualColor;

  const StatTileData({
    required this.target,
    this.actual,
    this.actualColor,
  });
}

/// Row of 3 equal-width stat tiles (DISTANCE / PACE / HR ZONE) inside a
/// single rounded card. Used at the top of the training day detail screen.
/// When the day is completed, the actual value renders below the target in
/// the section's compliance color so the runner sees the gap at a glance.
class TrainingDayStatTiles extends StatelessWidget {
  final StatTileData distance;
  final StatTileData pace;
  final StatTileData hrZone;

  const TrainingDayStatTiles({
    super.key,
    required this.distance,
    required this.pace,
    required this.hrZone,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(color: Color(0x08000000), blurRadius: 16),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: _Tile(label: 'DISTANCE', data: distance)),
            const _Divider(),
            Expanded(child: _Tile(label: 'PACE', data: pace)),
            const _Divider(),
            Expanded(child: _Tile(label: 'HR ZONE', data: hrZone)),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final StatTileData data;
  const _Tile({required this.label, required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: RunCoreText.statLabel()),
        const SizedBox(height: 4),
        Text(
          data.target ?? '-',
          style: RunCoreText.statValue(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (data.actual != null) ...[
          const SizedBox(height: 6),
          Text(
            data.actual!,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: data.actualColor ?? AppColors.tertiary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: SizedBox(
        width: 1,
        child: ColoredBox(color: AppColors.border),
      ),
    );
  }
}
