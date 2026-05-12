// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'RunCoach';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get authWelcomeEyebrow => 'JOUW AI-HARDLOOPCOACH';

  @override
  String get authWelcomeHeadlineLine1 => 'Slimmer trainen,';

  @override
  String get authWelcomeHeadlineLine2 => 'Niet zwaarder';

  @override
  String get authWelcomeSignInButton => 'INLOGGEN MET APPLE';

  @override
  String get authAppleScreenTitle => 'Inloggen met Apple';

  @override
  String get authAppleErrorNoIdentityToken =>
      'Apple gaf geen identity-token terug.';

  @override
  String get authAppleErrorBackendRejected =>
      'De backend wees het Apple identity-token af.';

  @override
  String get authAppleErrorAuthEmpty =>
      'Authenticatie is leeg na succesvol inloggen. Controleer de API-URL en backend-logs.';

  @override
  String get authAppleErrorTitle => 'Inloggen mislukt';

  @override
  String get authAppleErrorRetry => 'Probeer opnieuw';
}
