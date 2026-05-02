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
            Expanded(child: _Tile(label: 'DISTANCE', value: distance ?? '-')),
            const _Divider(),
            Expanded(child: _Tile(label: 'PACE', value: pace ?? '-')),
            const _Divider(),
            Expanded(child: _Tile(label: 'HR ZONE', value: hrZone ?? '-')),
          ],
        ),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
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
