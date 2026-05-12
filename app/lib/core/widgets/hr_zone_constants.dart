import 'package:app/l10n/app_localizations.dart';

/// Localized display labels for the five HR zones, in order Z1..Z5.
/// Used by both the editable [HeartRateZonesSheet] and the read-only
/// [HrZonesReadonlyList] so the runner sees the same names everywhere.
///
/// These match the running coach convention (60/70/80/90% of max HR
/// boundaries — see `App\Support\HeartRateZones::ZONE_PCT` on the API
/// side). Don't reorder without updating both renderers.
List<String> hrZoneNames(AppLocalizations l10n) => <String>[
      l10n.hrZoneNameZ1,
      l10n.hrZoneNameZ2,
      l10n.hrZoneNameZ3,
      l10n.hrZoneNameZ4,
      l10n.hrZoneNameZ5,
    ];
