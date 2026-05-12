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

  /// No description provided for @languageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// No description provided for @languageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get languageDutch;

  /// No description provided for @commonContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get commonContinue;

  /// No description provided for @commonTryAgain.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get commonTryAgain;

  /// No description provided for @commonRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get commonRetry;

  /// No description provided for @commonSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get commonSkip;

  /// No description provided for @commonRequired.
  ///
  /// In en, this message translates to:
  /// **'Required'**
  String get commonRequired;

  /// No description provided for @commonSaving.
  ///
  /// In en, this message translates to:
  /// **'Saving…'**
  String get commonSaving;

  /// No description provided for @commonOpenSettings.
  ///
  /// In en, this message translates to:
  /// **'Open Settings'**
  String get commonOpenSettings;

  /// No description provided for @commonAppleHealth.
  ///
  /// In en, this message translates to:
  /// **'Apple Health'**
  String get commonAppleHealth;

  /// No description provided for @commonEditedByYou.
  ///
  /// In en, this message translates to:
  /// **'Edited by you'**
  String get commonEditedByYou;

  /// No description provided for @commonFromSource.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String commonFromSource(String source);

  /// No description provided for @commonEditZones.
  ///
  /// In en, this message translates to:
  /// **'Edit zones'**
  String get commonEditZones;

  /// No description provided for @authWelcomeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR AI RUNCOACH'**
  String get authWelcomeEyebrow;

  /// No description provided for @authWelcomeHeadlineLine1.
  ///
  /// In en, this message translates to:
  /// **'Train Smarter,'**
  String get authWelcomeHeadlineLine1;

  /// No description provided for @authWelcomeHeadlineLine2.
  ///
  /// In en, this message translates to:
  /// **'Not Harder'**
  String get authWelcomeHeadlineLine2;

  /// No description provided for @authWelcomeSignInButton.
  ///
  /// In en, this message translates to:
  /// **'SIGN IN WITH APPLE'**
  String get authWelcomeSignInButton;

  /// No description provided for @authAppleScreenTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in with Apple'**
  String get authAppleScreenTitle;

  /// No description provided for @authAppleErrorNoIdentityToken.
  ///
  /// In en, this message translates to:
  /// **'Apple did not return an identity token.'**
  String get authAppleErrorNoIdentityToken;

  /// No description provided for @authAppleErrorBackendRejected.
  ///
  /// In en, this message translates to:
  /// **'Backend rejected the Apple identity token.'**
  String get authAppleErrorBackendRejected;

  /// No description provided for @authAppleErrorAuthEmpty.
  ///
  /// In en, this message translates to:
  /// **'Auth state is empty after successful sign-in. Check the API base URL and backend logs.'**
  String get authAppleErrorAuthEmpty;

  /// No description provided for @authAppleErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Sign in failed'**
  String get authAppleErrorTitle;

  /// No description provided for @authAppleErrorRetry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get authAppleErrorRetry;

  /// No description provided for @onbConnectHealthIntroTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health'**
  String get onbConnectHealthIntroTitle;

  /// No description provided for @onbConnectHealthIntroBody.
  ///
  /// In en, this message translates to:
  /// **'We read your running workouts, heart-rate data, age, and resting heart rate so we can score your training and personalise your zones.'**
  String get onbConnectHealthIntroBody;

  /// No description provided for @onbConnectHealthConnectCta.
  ///
  /// In en, this message translates to:
  /// **'Connect Apple Health'**
  String get onbConnectHealthConnectCta;

  /// No description provided for @onbConnectHealthSkipCta.
  ///
  /// In en, this message translates to:
  /// **'Continue without syncing'**
  String get onbConnectHealthSkipCta;

  /// No description provided for @onbConnectHealthFooter.
  ///
  /// In en, this message translates to:
  /// **'Garmin, Polar and Strava are coming soon.'**
  String get onbConnectHealthFooter;

  /// No description provided for @onbConnectHealthEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No runs found yet'**
  String get onbConnectHealthEmptyTitle;

  /// No description provided for @onbConnectHealthEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t read any running workouts from Apple Health. Either there aren\'t any in the last 12 months, or read access wasn\'t granted.'**
  String get onbConnectHealthEmptyBody;

  /// No description provided for @onbConnectHealthEmptyHint.
  ///
  /// In en, this message translates to:
  /// **'If you DO have runs, open Settings → Health → Data Access & Devices → RunCoach and turn on Workouts + Heart Rate.'**
  String get onbConnectHealthEmptyHint;

  /// No description provided for @onbConnectHealthStageRequesting.
  ///
  /// In en, this message translates to:
  /// **'Asking Apple Health…'**
  String get onbConnectHealthStageRequesting;

  /// No description provided for @onbConnectHealthStageRequestingSub.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Allow\" on the system prompt.'**
  String get onbConnectHealthStageRequestingSub;

  /// No description provided for @onbConnectHealthStageSyncing.
  ///
  /// In en, this message translates to:
  /// **'Pulling your runs…'**
  String get onbConnectHealthStageSyncing;

  /// No description provided for @onbConnectHealthStageSyncingSub.
  ///
  /// In en, this message translates to:
  /// **'Reading the last 12 months from Apple Health.'**
  String get onbConnectHealthStageSyncingSub;

  /// No description provided for @onbConnectHealthStageDone.
  ///
  /// In en, this message translates to:
  /// **'Synced {count} runs'**
  String onbConnectHealthStageDone(int count);

  /// No description provided for @onbConnectHealthStageDoneSub.
  ///
  /// In en, this message translates to:
  /// **'Building your profile…'**
  String get onbConnectHealthStageDoneSub;

  /// No description provided for @onbConnectHealthErrorPermission.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach Apple Health. Try again?'**
  String get onbConnectHealthErrorPermission;

  /// No description provided for @onbConnectHealthErrorRead.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t read your runs from Apple Health. Try again?'**
  String get onbConnectHealthErrorRead;

  /// No description provided for @onbConnectHealthErrorSync.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t sync your runs to the server. Check your connection and try again.'**
  String get onbConnectHealthErrorSync;

  /// No description provided for @onbConnectHealthErrorSettings.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open Settings automatically. Go to Settings → Health → Data Access & Devices → RunCoach.'**
  String get onbConnectHealthErrorSettings;

  /// No description provided for @onbOverviewTitlePrefilled.
  ///
  /// In en, this message translates to:
  /// **'Your running baseline'**
  String get onbOverviewTitlePrefilled;

  /// No description provided for @onbOverviewTitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Tell us about your running'**
  String get onbOverviewTitleEmpty;

  /// No description provided for @onbOverviewSubtitlePrefilled.
  ///
  /// In en, this message translates to:
  /// **'We use these to calibrate your training plan.'**
  String get onbOverviewSubtitlePrefilled;

  /// No description provided for @onbOverviewSubtitleEmpty.
  ///
  /// In en, this message translates to:
  /// **'We need two numbers to build an accurate plan.'**
  String get onbOverviewSubtitleEmpty;

  /// No description provided for @onbOverviewKmLabel.
  ///
  /// In en, this message translates to:
  /// **'Average weekly km (last 4 weeks)'**
  String get onbOverviewKmLabel;

  /// No description provided for @onbOverviewPaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Easy run pace'**
  String get onbOverviewPaceLabel;

  /// No description provided for @onbOverviewPaceTapPrompt.
  ///
  /// In en, this message translates to:
  /// **'Tap to choose'**
  String get onbOverviewPaceTapPrompt;

  /// No description provided for @onbOverviewLoadingTitle.
  ///
  /// In en, this message translates to:
  /// **'Loading your baseline…'**
  String get onbOverviewLoadingTitle;

  /// No description provided for @onbOverviewErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t load your data.'**
  String get onbOverviewErrorTitle;

  /// No description provided for @onbZonesTitle.
  ///
  /// In en, this message translates to:
  /// **'Your training zones'**
  String get onbZonesTitle;

  /// No description provided for @onbZonesSubtitleDerivedCorrected.
  ///
  /// In en, this message translates to:
  /// **'Based on your age and your hardest recent runs, your max heart rate looks to be around {maxHr} bpm. We\'ve split that into 5 training zones.'**
  String onbZonesSubtitleDerivedCorrected(int maxHr);

  /// No description provided for @onbZonesSubtitleDerivedBasic.
  ///
  /// In en, this message translates to:
  /// **'Estimated from your age ({age}) — max around {maxHr} bpm. After a few hard sessions or a race we\'ll refine these automatically.'**
  String onbZonesSubtitleDerivedBasic(int age, int maxHr);

  /// No description provided for @onbZonesSubtitleDerivedGeneric.
  ///
  /// In en, this message translates to:
  /// **'Estimated from your age. Tap \"Edit zones\" if you know your true max HR.'**
  String get onbZonesSubtitleDerivedGeneric;

  /// No description provided for @onbZonesSubtitleManual.
  ///
  /// In en, this message translates to:
  /// **'Your previously-saved zones. They\'ll be used to score every run.'**
  String get onbZonesSubtitleManual;

  /// No description provided for @onbZonesSubtitleDefault.
  ///
  /// In en, this message translates to:
  /// **'We couldn\'t compute your zones automatically — please set your max HR before continuing.'**
  String get onbZonesSubtitleDefault;

  /// No description provided for @onbZonesConfirmCta.
  ///
  /// In en, this message translates to:
  /// **'Looks right'**
  String get onbZonesConfirmCta;

  /// No description provided for @onbZonesDobLabel.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get onbZonesDobLabel;

  /// No description provided for @onbZonesDobBody.
  ///
  /// In en, this message translates to:
  /// **'We use your age to estimate heart-rate ranges for training feedback. You can fine-tune later from the menu.'**
  String get onbZonesDobBody;

  /// No description provided for @onbZonesNoDobBody.
  ///
  /// In en, this message translates to:
  /// **'To estimate your heart-rate ranges we just need your birth date. It gives us a rough max HR — accurate enough for daily training and easy to fine-tune later.'**
  String get onbZonesNoDobBody;

  /// No description provided for @onbZonesShowAdvanced.
  ///
  /// In en, this message translates to:
  /// **'Show zones (advanced)'**
  String get onbZonesShowAdvanced;

  /// No description provided for @onbZonesPickDobCta.
  ///
  /// In en, this message translates to:
  /// **'Pick your birth date'**
  String get onbZonesPickDobCta;

  /// No description provided for @onbGeneratingTitle.
  ///
  /// In en, this message translates to:
  /// **'Building your plan'**
  String get onbGeneratingTitle;

  /// No description provided for @onbGeneratingStageAnalyzing.
  ///
  /// In en, this message translates to:
  /// **'Analyzing your run history…'**
  String get onbGeneratingStageAnalyzing;

  /// No description provided for @onbGeneratingStageStructuring.
  ///
  /// In en, this message translates to:
  /// **'Designing your weekly structure…'**
  String get onbGeneratingStageStructuring;

  /// No description provided for @onbGeneratingStagePlacing.
  ///
  /// In en, this message translates to:
  /// **'Placing training sessions…'**
  String get onbGeneratingStagePlacing;

  /// No description provided for @onbGeneratingStageFinalizing.
  ///
  /// In en, this message translates to:
  /// **'Finalizing your plan…'**
  String get onbGeneratingStageFinalizing;

  /// No description provided for @onbGeneratingFooter.
  ///
  /// In en, this message translates to:
  /// **'This can take a few minutes. Feel free to close the app — we\'ll send you a notification when your plan is ready.'**
  String get onbGeneratingFooter;

  /// No description provided for @onbGeneratingLoadingNext.
  ///
  /// In en, this message translates to:
  /// **'Loading your plan…'**
  String get onbGeneratingLoadingNext;

  /// No description provided for @onbGeneratingErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan generation failed'**
  String get onbGeneratingErrorTitle;

  /// No description provided for @onbGeneratingErrorNetwork.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t reach the server. Check your connection.'**
  String get onbGeneratingErrorNetwork;

  /// No description provided for @onbGeneratingErrorLost.
  ///
  /// In en, this message translates to:
  /// **'Lost track of the generation. Try again?'**
  String get onbGeneratingErrorLost;

  /// No description provided for @onbGeneratingErrorGeneric.
  ///
  /// In en, this message translates to:
  /// **'Generation failed.'**
  String get onbGeneratingErrorGeneric;

  /// No description provided for @onbGeneratingErrorMissingId.
  ///
  /// In en, this message translates to:
  /// **'Plan ready but conversation id missing.'**
  String get onbGeneratingErrorMissingId;

  /// No description provided for @onbGeneratingBackCta.
  ///
  /// In en, this message translates to:
  /// **'Back to form'**
  String get onbGeneratingBackCta;
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
