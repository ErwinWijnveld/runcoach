import 'package:intl/intl.dart';

/// App-wide locale for date formatting. Swap to `'nl'`, `'de'`, etc. when i18n
/// is introduced (or derive from `Platform.localeName` / user settings).
///
/// For non-English locales the date-symbol data must be initialised first —
/// add `initializeDateFormatting(appDateLocale)` in `main.dart` when you
/// switch. The default `'en'` works without initialization.
String appDateLocale = 'en';

/// Formats a [DateTime] as a short human-readable date in the current app
/// locale (e.g. "May 17, 2026" / "17 mei 2026").
///
/// [pattern] values:
/// - `'short'`   → `DateFormat.yMMMd` (default): "May 17, 2026" / "17 mei 2026"
/// - `'long'`    → `DateFormat.yMMMMEEEEd`: "Sunday, May 17, 2026"
/// - `'numeric'` → `DateFormat.yMd`: "5/17/2026" / "17-5-2026"
/// - anything else is treated as a raw [DateFormat] pattern string.
String formatDate(DateTime date, {String? locale, String pattern = 'short'}) {
  final loc = locale ?? appDateLocale;
  return switch (pattern) {
    'short' => DateFormat.yMMMd(loc).format(date),
    'long' => DateFormat.yMMMMEEEEd(loc).format(date),
    'numeric' => DateFormat.yMd(loc).format(date),
    _ => DateFormat(pattern, loc).format(date),
  };
}

/// Parse an ISO date/datetime string from the API and format it for display.
/// Returns [fallback] (default empty) if the value is null/unparseable.
///
/// The parsed instant is normalised to the user's local timezone before
/// formatting, so a UTC `2026-05-17T00:00:00Z` renders as May 17 in CET and
/// May 16 in PST — which is the behaviour you want for a race date the user
/// entered in their own timezone.
String formatDateString(
  String? iso, {
  String? locale,
  String pattern = 'short',
  String fallback = '',
}) {
  if (iso == null || iso.isEmpty) return fallback;
  final parsed = DateTime.tryParse(iso);
  if (parsed == null) return fallback;
  return formatDate(parsed.toLocal(), locale: locale, pattern: pattern);
}
