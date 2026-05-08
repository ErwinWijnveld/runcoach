double toDouble(dynamic value) => switch (value) {
  num v => v.toDouble(),
  String v => double.parse(v),
  _ => 0.0,
};

double? toDoubleOrNull(dynamic value) => switch (value) {
  num v => v.toDouble(),
  String v => double.tryParse(v),
  _ => null,
};

int toInt(dynamic value) => switch (value) {
  num v => v.toInt(),
  String v => int.parse(v),
  _ => 0,
};

int? toIntOrNull(dynamic value) => switch (value) {
  num v => v.toInt(),
  String v => int.tryParse(v),
  _ => null,
};

/// Parses a calendar date from JSON. Treats date-only fields (DOB, etc.)
/// as a wall-calendar date — NOT a moment-in-time — so timezone wobbles
/// don't shift them by ±1 day.
///
/// Backend (Eloquent `date` cast) emits ISO 8601 with a Z suffix:
///   `'2026-05-08T00:00:00.000000Z'`
/// `DateTime.parse` would treat that as UTC midnight and convert to
/// local time, which in negative-UTC zones (e.g. `America/Los_Angeles`,
/// −7) lands on the PREVIOUS day. We sidestep that by extracting the
/// date portion directly and constructing a local-midnight DateTime.
/// Round-trip via [dateToJson] re-emits the same `YYYY-MM-DD` string.
DateTime? dateFromJson(dynamic value) {
  if (value == null) return null;
  final s = value.toString();
  if (s.length < 10) return null;
  final year = int.tryParse(s.substring(0, 4));
  final month = int.tryParse(s.substring(5, 7));
  final day = int.tryParse(s.substring(8, 10));
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}

String? dateToJson(DateTime? value) {
  if (value == null) return null;
  final y = value.year.toString().padLeft(4, '0');
  final m = value.month.toString().padLeft(2, '0');
  final d = value.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}
