/// Mutable BCP-47 language tag for the app's currently active locale.
///
/// Read by the Dio `LocaleInterceptor` (which can't be a Riverpod consumer
/// — Dio is a singleton, not a widget). Written by [AppLocale] whenever
/// the runner's locale resolves or changes.
///
/// Mirrors the long-standing `appDateLocale` mutable global in
/// `core/utils/date_formatter.dart` for consistency.
String currentAppLocaleTag = 'en';
