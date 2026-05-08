/// Display labels for the five HR zones, in order Z1..Z5. Used by both
/// the editable [HeartRateZonesSheet] and the read-only
/// [HrZonesReadonlyList] so the runner sees the same names everywhere.
///
/// These match the running coach convention (60/70/80/90% of max HR
/// boundaries — see `App\Support\HeartRateZones::ZONE_PCT` on the API
/// side). Don't reorder without updating both renderers.
const kHrZoneNames = <String>[
  'Endurance',
  'Moderate',
  'Tempo',
  'Threshold',
  'Anaerobic',
];
