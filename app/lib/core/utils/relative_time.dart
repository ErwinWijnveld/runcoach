import 'package:timeago/timeago.dart' as timeago;

/// App-wide locale for `formatRelativeTime`. Swap to `'nl'`, `'de'`, etc.
/// when i18n is added (or derive from the user's settings).
String appRelativeTimeLocale = 'en';

/// "5 minutes ago", "3 days ago", etc. Centralized so the locale can be
/// changed in one place. Pass a [locale] to override for a single call.
String formatRelativeTime(DateTime when, {String? locale}) {
  return timeago.format(
    when,
    locale: locale ?? appRelativeTimeLocale,
    allowFromNow: true,
  );
}

/// Convenience for JSON date strings from the API. Returns `fallback`
/// (default: empty string) if the input can't be parsed.
String formatRelativeTimeString(
  String isoDate, {
  String? locale,
  String fallback = '',
}) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return fallback;
  return formatRelativeTime(parsed.toLocal(), locale: locale);
}
