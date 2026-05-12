import 'package:flutter/cupertino.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/hr_zone_constants.dart';
import 'package:app/features/auth/models/hr_zone.dart';

/// Non-editable rendering of a 5-zone HR table. Shape matches the editable
/// `_ZonesList` inside `heart_rate_zones_sheet.dart` so the runner sees the
/// same visual language across:
///   - the onboarding zones confirmation step,
///   - the menu sheet (post-recalculate preview),
///   - any future "this is what we used to score this run" surface.
///
/// Z5's `max == -1` is rendered as ∞ (open-ended).
class HrZonesReadonlyList extends StatelessWidget {
  final List<HrZone> zones;

  const HrZonesReadonlyList({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    assert(zones.length == 5, 'HR zones must always have 5 entries');
    final names = hrZoneNames(context.l10n);
    final rows = <Widget>[];
    for (var i = 0; i < zones.length; i++) {
      rows.add(_ZoneRow(index: i, zone: zones[i], name: names[i]));
      if (i < zones.length - 1) {
        rows.add(Container(
          margin: const EdgeInsets.only(left: 16),
          height: 0.5,
          color: AppColors.inputBorder,
        ));
      }
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
    );
  }
}

class _ZoneRow extends StatelessWidget {
  final int index;
  final HrZone zone;
  final String name;

  const _ZoneRow({
    required this.index,
    required this.zone,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final upper = zone.max < 0 ? '∞' : '${zone.max}';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text(
              'Z${index + 1}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.warmBrown,
              ),
            ),
          ),
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.primaryInk,
              ),
            ),
          ),
          Text(
            '${zone.min}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkMuted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '–',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ),
          SizedBox(
            width: 56,
            child: Center(
              child: Text(
                upper,
                style: TextStyle(
                  fontSize: zone.max < 0 ? 18 : 14,
                  color: AppColors.inkMuted,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            context.l10n.hrZoneBpm,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
