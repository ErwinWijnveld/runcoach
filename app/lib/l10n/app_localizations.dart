import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('nl'),
  ];

  /// Application title — used in window title, sharing intents, etc.
  ///
  /// In en, this message translates to:
  /// **'RunCoach'**
  String get appTitle;

  /// Label for English in a language picker.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label for Dutch in a language picker — always shown in Dutch (Nederlands) regardless of UI locale, by convention.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// Welcome screen — small uppercase label above the logo.
  ///
  /// In en, this message translates to:
  /// **'YOUR AI RUNCOACH'**
  String get authWelcomeEyebrow;

  /// Welcome screen — first line of the two-line tagline.
  ///
  /// In en, this message translates to:
  /// **'Train Smarter,'**
  String get authWelcomeHeadlineLine1;

  /// Welcome screen — second line of the tagline (rendered italic).
  ///
  /// In en, this message translates to:
  /// **'Not Harder'**
  String get authWelcomeHeadlineLine2;

  /// Welcome screen — primary CTA. Triggers the native Apple Sign-In flow.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH APPLE'**
  String get authWelcomeSignInButton;

  /// Nav bar title on the Apple sign-in screen.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authAppleScreenTitle;

  /// Apple sign-in error shown when iOS doesn't return a JWT (rare — usually a configuration issue).
  ///
  /// In en, this message translates to:
  /// **'Apple did not return an identity token.'**
  String get authAppleErrorNoIdentityToken;

  /// Apple sign-in error shown when the backend rejects the Apple JWT (audience/issuer mismatch, expired).
  ///
  /// In en, this message translates to:
  /// **'Backend rejected the Apple identity token.'**
  String get authAppleErrorBackendRejected;

  /// Apple sign-in error shown when the backend reply parsed cleanly but no user is in scope. Almost always a misconfigured API base URL.
  ///
  /// In en, this message translates to:
  /// **'Auth state is empty after successful sign-in. Check the API base URL and backend logs.'**
  String get authAppleErrorAuthEmpty;

  /// Heading above the Apple sign-in error message + Try again button.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get authAppleErrorTitle;

  /// Retry button below the Apple sign-in error message.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get authAppleErrorRetry;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
