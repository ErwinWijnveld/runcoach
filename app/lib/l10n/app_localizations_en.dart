// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'RunCoach';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageDutch => 'Nederlands';

  @override
  String get authWelcomeEyebrow => 'YOUR AI RUNCOACH';

  @override
  String get authWelcomeHeadlineLine1 => 'Train Smarter,';

  @override
  String get authWelcomeHeadlineLine2 => 'Not Harder';

  @override
  String get authWelcomeSignInButton => 'SIGN IN WITH APPLE';

  @override
  String get authAppleScreenTitle => 'Sign in with Apple';

  @override
  String get authAppleErrorNoIdentityToken =>
      'Apple did not return an identity token.';

  @override
  String get authAppleErrorBackendRejected =>
      'Backend rejected the Apple identity token.';

  @override
  String get authAppleErrorAuthEmpty =>
      'Auth state is empty after successful sign-in. Check the API base URL and backend logs.';

  @override
  String get authAppleErrorTitle => 'Sign in failed';

  @override
  String get authAppleErrorRetry => 'Try again';
}
