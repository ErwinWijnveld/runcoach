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

  /// No description provided for @onbFormGoalTypeTitle.
  ///
  /// In en, this message translates to:
  /// **'What are you training for?'**
  String get onbFormGoalTypeTitle;

  /// No description provided for @onbFormGoalTypeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We\'ll tailor the plan around your answer.'**
  String get onbFormGoalTypeSubtitle;

  /// No description provided for @onbFormGoalTypeRaceLabel.
  ///
  /// In en, this message translates to:
  /// **'Train for a race'**
  String get onbFormGoalTypeRaceLabel;

  /// No description provided for @onbFormGoalTypeRaceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve got a specific event on the horizon.'**
  String get onbFormGoalTypeRaceSubtitle;

  /// No description provided for @onbFormGoalTypePrLabel.
  ///
  /// In en, this message translates to:
  /// **'Get faster at a distance'**
  String get onbFormGoalTypePrLabel;

  /// No description provided for @onbFormGoalTypePrSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Go after a personal record.'**
  String get onbFormGoalTypePrSubtitle;

  /// No description provided for @onbFormGoalTypeFitnessLabel.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get onbFormGoalTypeFitnessLabel;

  /// No description provided for @onbFormGoalTypeFitnessSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Run regularly, no specific target.'**
  String get onbFormGoalTypeFitnessSubtitle;

  /// No description provided for @onbFormGoalTypeWeightLossLabel.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get onbFormGoalTypeWeightLossLabel;

  /// No description provided for @onbFormGoalTypeWeightLossSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Consistent running to steadily drop weight.'**
  String get onbFormGoalTypeWeightLossSubtitle;

  /// No description provided for @onbFormGoalTypeOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Describe what you\'re after…'**
  String get onbFormGoalTypeOtherHint;

  /// No description provided for @onbFormDistanceTitle.
  ///
  /// In en, this message translates to:
  /// **'What distance?'**
  String get onbFormDistanceTitle;

  /// No description provided for @onbFormDistanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick the race or target distance.'**
  String get onbFormDistanceSubtitle;

  /// No description provided for @onbFormDistance5k.
  ///
  /// In en, this message translates to:
  /// **'5K'**
  String get onbFormDistance5k;

  /// No description provided for @onbFormDistance10k.
  ///
  /// In en, this message translates to:
  /// **'10K'**
  String get onbFormDistance10k;

  /// No description provided for @onbFormDistanceHalf.
  ///
  /// In en, this message translates to:
  /// **'Half marathon'**
  String get onbFormDistanceHalf;

  /// No description provided for @onbFormDistanceMarathon.
  ///
  /// In en, this message translates to:
  /// **'Marathon'**
  String get onbFormDistanceMarathon;

  /// No description provided for @onbFormDistanceOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Distance in kilometers'**
  String get onbFormDistanceOtherHint;

  /// No description provided for @onbFormRaceNameTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s the race called?'**
  String get onbFormRaceNameTitle;

  /// No description provided for @onbFormRaceNameSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anything goes, we just use it as a label.'**
  String get onbFormRaceNameSubtitle;

  /// No description provided for @onbFormRaceNameHint.
  ///
  /// In en, this message translates to:
  /// **'Rotterdam Marathon'**
  String get onbFormRaceNameHint;

  /// No description provided for @onbFormRaceDateTitle.
  ///
  /// In en, this message translates to:
  /// **'When\'s race day?'**
  String get onbFormRaceDateTitle;

  /// No description provided for @onbFormRaceDateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'We need at least a couple weeks to build a proper plan.'**
  String get onbFormRaceDateSubtitle;

  /// No description provided for @onbFormGoalTimeTitle.
  ///
  /// In en, this message translates to:
  /// **'What goal time or pace are you aiming for?'**
  String get onbFormGoalTimeTitle;

  /// No description provided for @onbFormGoalTimeSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Enter it however feels natural, we parse it.'**
  String get onbFormGoalTimeSubtitle;

  /// No description provided for @onbFormGoalTimeHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1:45:00, 25:30, or 5:30/km'**
  String get onbFormGoalTimeHint;

  /// No description provided for @onbFormPrTitle.
  ///
  /// In en, this message translates to:
  /// **'What\'s your current PR?'**
  String get onbFormPrTitle;

  /// No description provided for @onbFormPrSubtitlePrefilled.
  ///
  /// In en, this message translates to:
  /// **'Pre-filled from your fastest matching run in Apple Health. Adjust if needed.'**
  String get onbFormPrSubtitlePrefilled;

  /// No description provided for @onbFormPrSubtitleOptional.
  ///
  /// In en, this message translates to:
  /// **'Optional, helps us gauge a realistic target.'**
  String get onbFormPrSubtitleOptional;

  /// No description provided for @onbFormPrHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. 1:52:00 or 5:45/km'**
  String get onbFormPrHint;

  /// No description provided for @onbFormGoalTimeParseError.
  ///
  /// In en, this message translates to:
  /// **'Didn\'t quite catch that. Try 1:45:00 or 5:30/km.'**
  String get onbFormGoalTimeParseError;

  /// No description provided for @onbFormGoalTimePreview.
  ///
  /// In en, this message translates to:
  /// **'≈ {total} total{paceSuffix}'**
  String onbFormGoalTimePreview(String total, String paceSuffix);

  /// No description provided for @onbFormGoalTimePreviewPaceSuffix.
  ///
  /// In en, this message translates to:
  /// **' ({pace}/km)'**
  String onbFormGoalTimePreviewPaceSuffix(String pace);

  /// No description provided for @onbFormDaysTitle.
  ///
  /// In en, this message translates to:
  /// **'How many days per week?'**
  String get onbFormDaysTitle;

  /// No description provided for @onbFormDaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Be realistic. The plan is only as good as your consistency.'**
  String get onbFormDaysSubtitle;

  /// No description provided for @onbFormDays1Label.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get onbFormDays1Label;

  /// No description provided for @onbFormDays1Sub.
  ///
  /// In en, this message translates to:
  /// **'Keeps the habit alive.'**
  String get onbFormDays1Sub;

  /// No description provided for @onbFormDays2Label.
  ///
  /// In en, this message translates to:
  /// **'2 days'**
  String get onbFormDays2Label;

  /// No description provided for @onbFormDays2Sub.
  ///
  /// In en, this message translates to:
  /// **'Minimal but consistent.'**
  String get onbFormDays2Sub;

  /// No description provided for @onbFormDays3Label.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get onbFormDays3Label;

  /// No description provided for @onbFormDays3Sub.
  ///
  /// In en, this message translates to:
  /// **'A solid base to build on.'**
  String get onbFormDays3Sub;

  /// No description provided for @onbFormDays4Label.
  ///
  /// In en, this message translates to:
  /// **'4 days'**
  String get onbFormDays4Label;

  /// No description provided for @onbFormDays4Sub.
  ///
  /// In en, this message translates to:
  /// **'Great balance for most runners.'**
  String get onbFormDays4Sub;

  /// No description provided for @onbFormDays5Label.
  ///
  /// In en, this message translates to:
  /// **'5 days'**
  String get onbFormDays5Label;

  /// No description provided for @onbFormDays5Sub.
  ///
  /// In en, this message translates to:
  /// **'Solid block for serious goals.'**
  String get onbFormDays5Sub;

  /// No description provided for @onbFormDays6Label.
  ///
  /// In en, this message translates to:
  /// **'6 days'**
  String get onbFormDays6Label;

  /// No description provided for @onbFormDays6Sub.
  ///
  /// In en, this message translates to:
  /// **'High volume, for experienced runners.'**
  String get onbFormDays6Sub;

  /// No description provided for @onbFormDays7Label.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get onbFormDays7Label;

  /// No description provided for @onbFormDays7Sub.
  ///
  /// In en, this message translates to:
  /// **'Every day, only if recovery is dialed in.'**
  String get onbFormDays7Sub;

  /// No description provided for @onbFormDaysOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Tell me about your schedule…'**
  String get onbFormDaysOtherHint;

  /// No description provided for @onbFormWeekdaysTitle.
  ///
  /// In en, this message translates to:
  /// **'Which weekdays can you run?'**
  String get onbFormWeekdaysTitle;

  /// No description provided for @onbFormWeekdaysSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional — pick the days that work for you.'**
  String get onbFormWeekdaysSubtitle;

  /// No description provided for @onbFormWeekdaysHintEnough.
  ///
  /// In en, this message translates to:
  /// **'Leave empty if any day works.'**
  String get onbFormWeekdaysHintEnough;

  /// No description provided for @onbFormWeekdaysHintShort.
  ///
  /// In en, this message translates to:
  /// **'Pick at least {required} days (you chose {count}).'**
  String onbFormWeekdaysHintShort(int required, int count);

  /// No description provided for @weekdayMon.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMon;

  /// No description provided for @weekdayTue.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTue;

  /// No description provided for @weekdayWed.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWed;

  /// No description provided for @weekdayThu.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThu;

  /// No description provided for @weekdayFri.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFri;

  /// No description provided for @weekdaySat.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySat;

  /// No description provided for @weekdaySun.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySun;

  /// No description provided for @weekdayMonShort.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get weekdayMonShort;

  /// No description provided for @weekdayTueShort.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get weekdayTueShort;

  /// No description provided for @weekdayWedShort.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get weekdayWedShort;

  /// No description provided for @weekdayThuShort.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get weekdayThuShort;

  /// No description provided for @weekdayFriShort.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get weekdayFriShort;

  /// No description provided for @weekdaySatShort.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get weekdaySatShort;

  /// No description provided for @weekdaySunShort.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get weekdaySunShort;

  /// No description provided for @onbFormRankTitle.
  ///
  /// In en, this message translates to:
  /// **'Rank your favourite runs'**
  String get onbFormRankTitle;

  /// No description provided for @onbFormRankSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder. Top ones get featured more, bottom ones less.'**
  String get onbFormRankSubtitle;

  /// No description provided for @onbFormRankFooter.
  ///
  /// In en, this message translates to:
  /// **'Long runs stay in the plan. Ranking them last just keeps them shorter.'**
  String get onbFormRankFooter;

  /// No description provided for @runTypeEasyLabel.
  ///
  /// In en, this message translates to:
  /// **'Easy runs'**
  String get runTypeEasyLabel;

  /// No description provided for @runTypeEasySub.
  ///
  /// In en, this message translates to:
  /// **'Conversational pace, weekly bulk.'**
  String get runTypeEasySub;

  /// No description provided for @runTypeTempoLabel.
  ///
  /// In en, this message translates to:
  /// **'Tempo runs'**
  String get runTypeTempoLabel;

  /// No description provided for @runTypeTempoSub.
  ///
  /// In en, this message translates to:
  /// **'Sustained, comfortably hard effort.'**
  String get runTypeTempoSub;

  /// No description provided for @runTypeIntervalLabel.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get runTypeIntervalLabel;

  /// No description provided for @runTypeIntervalSub.
  ///
  /// In en, this message translates to:
  /// **'Short hard reps with recovery.'**
  String get runTypeIntervalSub;

  /// No description provided for @runTypeLongRunLabel.
  ///
  /// In en, this message translates to:
  /// **'Long runs'**
  String get runTypeLongRunLabel;

  /// No description provided for @runTypeLongRunSub.
  ///
  /// In en, this message translates to:
  /// **'Weekly endurance, builds stamina.'**
  String get runTypeLongRunSub;

  /// No description provided for @onbFormCoachStyleTitle.
  ///
  /// In en, this message translates to:
  /// **'How should I coach you?'**
  String get onbFormCoachStyleTitle;

  /// No description provided for @onbFormCoachStyleSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This shapes the tone of the plan and how I push you.'**
  String get onbFormCoachStyleSubtitle;

  /// No description provided for @coachStyleBalancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Balanced'**
  String get coachStyleBalancedLabel;

  /// No description provided for @coachStyleBalancedSub.
  ///
  /// In en, this message translates to:
  /// **'Structure, but with room to adapt.'**
  String get coachStyleBalancedSub;

  /// No description provided for @coachStyleStrictLabel.
  ///
  /// In en, this message translates to:
  /// **'Strict'**
  String get coachStyleStrictLabel;

  /// No description provided for @coachStyleStrictSub.
  ///
  /// In en, this message translates to:
  /// **'Hold me to it. Don\'t soften the plan.'**
  String get coachStyleStrictSub;

  /// No description provided for @coachStyleFlexibleLabel.
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get coachStyleFlexibleLabel;

  /// No description provided for @coachStyleFlexibleSub.
  ///
  /// In en, this message translates to:
  /// **'Adapt to my life when things slip.'**
  String get coachStyleFlexibleSub;

  /// No description provided for @onbFormCoachStyleOtherHint.
  ///
  /// In en, this message translates to:
  /// **'Describe how you want to be coached…'**
  String get onbFormCoachStyleOtherHint;

  /// No description provided for @onbFormRunnerLevelTitle.
  ///
  /// In en, this message translates to:
  /// **'How would you describe your running?'**
  String get onbFormRunnerLevelTitle;

  /// No description provided for @onbFormRunnerLevelSubtitle.
  ///
  /// In en, this message translates to:
  /// **'This helps us tailor how we explain things.'**
  String get onbFormRunnerLevelSubtitle;

  /// No description provided for @runnerLevelBeginnerLabel.
  ///
  /// In en, this message translates to:
  /// **'Beginner'**
  String get runnerLevelBeginnerLabel;

  /// No description provided for @runnerLevelBeginnerSub.
  ///
  /// In en, this message translates to:
  /// **'Just started or returning'**
  String get runnerLevelBeginnerSub;

  /// No description provided for @runnerLevelIntermediateLabel.
  ///
  /// In en, this message translates to:
  /// **'Intermediate'**
  String get runnerLevelIntermediateLabel;

  /// No description provided for @runnerLevelIntermediateSub.
  ///
  /// In en, this message translates to:
  /// **'Run regularly, race occasionally'**
  String get runnerLevelIntermediateSub;

  /// No description provided for @runnerLevelAdvancedLabel.
  ///
  /// In en, this message translates to:
  /// **'Advanced'**
  String get runnerLevelAdvancedLabel;

  /// No description provided for @runnerLevelAdvancedSub.
  ///
  /// In en, this message translates to:
  /// **'Know your zones, race seriously'**
  String get runnerLevelAdvancedSub;

  /// No description provided for @runnerLevelSubEliteLabel.
  ///
  /// In en, this message translates to:
  /// **'Sub-Elite'**
  String get runnerLevelSubEliteLabel;

  /// No description provided for @runnerLevelSubEliteSub.
  ///
  /// In en, this message translates to:
  /// **'Structured training, competitive'**
  String get runnerLevelSubEliteSub;

  /// No description provided for @runnerLevelEliteLabel.
  ///
  /// In en, this message translates to:
  /// **'Elite'**
  String get runnerLevelEliteLabel;

  /// No description provided for @runnerLevelEliteSub.
  ///
  /// In en, this message translates to:
  /// **'Sponsored or top-level competing'**
  String get runnerLevelEliteSub;

  /// No description provided for @onbFormIntensityTitle.
  ///
  /// In en, this message translates to:
  /// **'How hard do you want this?'**
  String get onbFormIntensityTitle;

  /// No description provided for @onbFormIntensitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Bump up or down if you feel different — Standard matches what your goal calls for.'**
  String get onbFormIntensitySubtitle;

  /// No description provided for @onbFormIntensityEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY KM'**
  String get onbFormIntensityEyebrow;

  /// No description provided for @onbFormIntensityCaptionEasy.
  ///
  /// In en, this message translates to:
  /// **'Gentler bumps, lower peak. Sustainable.'**
  String get onbFormIntensityCaptionEasy;

  /// No description provided for @onbFormIntensityCaptionStandard.
  ///
  /// In en, this message translates to:
  /// **'Steady weekly progression. Auto-picked.'**
  String get onbFormIntensityCaptionStandard;

  /// No description provided for @onbFormIntensityCaptionHarder.
  ///
  /// In en, this message translates to:
  /// **'Steeper ramp, higher peak. Stay sharp.'**
  String get onbFormIntensityCaptionHarder;

  /// No description provided for @intensityBiasEasyLabel.
  ///
  /// In en, this message translates to:
  /// **'Take it easy'**
  String get intensityBiasEasyLabel;

  /// No description provided for @intensityBiasStandardLabel.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get intensityBiasStandardLabel;

  /// No description provided for @intensityBiasHarderLabel.
  ///
  /// In en, this message translates to:
  /// **'Push me harder'**
  String get intensityBiasHarderLabel;

  /// No description provided for @intensityBiasEasyShort.
  ///
  /// In en, this message translates to:
  /// **'Easier'**
  String get intensityBiasEasyShort;

  /// No description provided for @intensityBiasStandardShort.
  ///
  /// In en, this message translates to:
  /// **'Standard'**
  String get intensityBiasStandardShort;

  /// No description provided for @intensityBiasHarderShort.
  ///
  /// In en, this message translates to:
  /// **'Harder'**
  String get intensityBiasHarderShort;

  /// No description provided for @intensityBiasAutoPick.
  ///
  /// In en, this message translates to:
  /// **'(auto-pick)'**
  String get intensityBiasAutoPick;

  /// No description provided for @onbFormReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Ready to build your plan?'**
  String get onbFormReviewTitle;

  /// No description provided for @onbFormReviewSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Quick recap. I\'ll take it from here.'**
  String get onbFormReviewSubtitle;

  /// No description provided for @onbFormReviewCreateCta.
  ///
  /// In en, this message translates to:
  /// **'CREATE MY PLAN'**
  String get onbFormReviewCreateCta;

  /// No description provided for @onbFormReviewExtraNotesLabel.
  ///
  /// In en, this message translates to:
  /// **'Anything else for your coach?'**
  String get onbFormReviewExtraNotesLabel;

  /// No description provided for @onbFormReviewExtraNotesHint.
  ///
  /// In en, this message translates to:
  /// **'Injuries, schedule quirks, anything to consider…'**
  String get onbFormReviewExtraNotesHint;

  /// No description provided for @reviewRowGoal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get reviewRowGoal;

  /// No description provided for @reviewRowDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get reviewRowDistance;

  /// No description provided for @reviewRowRace.
  ///
  /// In en, this message translates to:
  /// **'Race'**
  String get reviewRowRace;

  /// No description provided for @reviewRowRaceDay.
  ///
  /// In en, this message translates to:
  /// **'Race day'**
  String get reviewRowRaceDay;

  /// No description provided for @reviewRowGoalTime.
  ///
  /// In en, this message translates to:
  /// **'Goal time'**
  String get reviewRowGoalTime;

  /// No description provided for @reviewRowCurrentPr.
  ///
  /// In en, this message translates to:
  /// **'Current PR'**
  String get reviewRowCurrentPr;

  /// No description provided for @reviewRowDaysPerWeek.
  ///
  /// In en, this message translates to:
  /// **'Days / week'**
  String get reviewRowDaysPerWeek;

  /// No description provided for @reviewRowPreferredDays.
  ///
  /// In en, this message translates to:
  /// **'Preferred days'**
  String get reviewRowPreferredDays;

  /// No description provided for @reviewRowCoachStyle.
  ///
  /// In en, this message translates to:
  /// **'Coach style'**
  String get reviewRowCoachStyle;

  /// No description provided for @reviewRowRunnerLevel.
  ///
  /// In en, this message translates to:
  /// **'Running level'**
  String get reviewRowRunnerLevel;

  /// No description provided for @reviewRowIntensity.
  ///
  /// In en, this message translates to:
  /// **'Intensity'**
  String get reviewRowIntensity;

  /// No description provided for @reviewRowNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get reviewRowNotes;

  /// No description provided for @reviewGoalTypeRaceShort.
  ///
  /// In en, this message translates to:
  /// **'Train for a race'**
  String get reviewGoalTypeRaceShort;

  /// No description provided for @reviewGoalTypePrShort.
  ///
  /// In en, this message translates to:
  /// **'Chase a PR'**
  String get reviewGoalTypePrShort;

  /// No description provided for @reviewGoalTypeFitnessShort.
  ///
  /// In en, this message translates to:
  /// **'General fitness'**
  String get reviewGoalTypeFitnessShort;

  /// No description provided for @reviewGoalTypeWeightLossShort.
  ///
  /// In en, this message translates to:
  /// **'Weight loss'**
  String get reviewGoalTypeWeightLossShort;

  /// No description provided for @commonErrorWithMessage.
  ///
  /// In en, this message translates to:
  /// **'Error: {message}'**
  String commonErrorWithMessage(String message);

  /// No description provided for @commonToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get commonToday;

  /// No description provided for @commonTodayUpper.
  ///
  /// In en, this message translates to:
  /// **'TODAY'**
  String get commonTodayUpper;

  /// No description provided for @commonTomorrow.
  ///
  /// In en, this message translates to:
  /// **'Tomorrow'**
  String get commonTomorrow;

  /// No description provided for @dashNoUpcomingRunEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NO UPCOMING RUN'**
  String get dashNoUpcomingRunEyebrow;

  /// No description provided for @dashNoUpcomingTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan complete'**
  String get dashNoUpcomingTitle;

  /// No description provided for @dashNoUpcomingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'All training days are logged.'**
  String get dashNoUpcomingSubtitle;

  /// No description provided for @dashThisWeekEyebrow.
  ///
  /// In en, this message translates to:
  /// **'THIS WEEK'**
  String get dashThisWeekEyebrow;

  /// No description provided for @dashWeeksMatrixEyebrow.
  ///
  /// In en, this message translates to:
  /// **'{total} WEEKS'**
  String dashWeeksMatrixEyebrow(int total);

  /// No description provided for @dashRaceDayLabel.
  ///
  /// In en, this message translates to:
  /// **'Race day · {raceName}'**
  String dashRaceDayLabel(String raceName);

  /// No description provided for @dashDaysToGoLabel.
  ///
  /// In en, this message translates to:
  /// **'{days}d · {raceName}'**
  String dashDaysToGoLabel(int days, String raceName);

  /// No description provided for @dashWeeklySplitSuffix.
  ///
  /// In en, this message translates to:
  /// **' / {planned} km'**
  String dashWeeklySplitSuffix(String planned);

  /// No description provided for @dashLegendDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get dashLegendDone;

  /// No description provided for @dashLegendMissed.
  ///
  /// In en, this message translates to:
  /// **'Missed'**
  String get dashLegendMissed;

  /// No description provided for @dashLegendUpcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get dashLegendUpcoming;

  /// No description provided for @dashEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active plan'**
  String get dashEmptyTitle;

  /// No description provided for @dashEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a goal (or ask the coach to build one) to see your training on the dashboard.'**
  String get dashEmptyBody;

  /// No description provided for @dashEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Go to Goals'**
  String get dashEmptyCta;
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
