import 'package:flutter/cupertino.dart';
import 'package:app/core/theme/app_theme.dart';

/// Row of 3 equal-width stat tiles (DISTANCE / PACE / HR ZONE). Used at the
/// top of the training day detail screen. Values are pre-formatted strings so
/// the caller decides whether to render target or actual.
class TrainingDayStatTiles extends StatelessWidget {
  final String? distance;
  final String? pace;
  final String? hrZone;

  const TrainingDayStatTiles({
    super.key,
    required this.distance,
    required this.pace,
    required this.hrZone,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: _Tile(label: 'DISTANCE', value: distance ?? '-')),
        const SizedBox(width: 8),
        Expanded(child: _Tile(label: 'PACE', value: pace ?? '-')),
        const SizedBox(width: 8),
        Expanded(child: _Tile(label: 'HR ZONE', value: hrZone ?? '-')),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        decoration: BoxDecoration(
          color: CupertinoColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: RunCoreText.statLabel()),
            const SizedBox(height: 4),
            Text(
              value,
              style: RunCoreText.statValue(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
