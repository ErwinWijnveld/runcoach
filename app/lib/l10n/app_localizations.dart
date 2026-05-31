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

  /// No description provided for @runShareSheetCta.
  ///
  /// In en, this message translates to:
  /// **'Share this run'**
  String get runShareSheetCta;

  /// No description provided for @runShareSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Tap to save or share with friends'**
  String get runShareSheetSubtitle;

  /// No description provided for @runShareInlineCta.
  ///
  /// In en, this message translates to:
  /// **'Share this run'**
  String get runShareInlineCta;

  /// No description provided for @runShareBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Run summary'**
  String get runShareBarrierLabel;

  /// No description provided for @runShareKpiDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get runShareKpiDistance;

  /// No description provided for @runShareKpiTime.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get runShareKpiTime;

  /// No description provided for @runShareKpiAvgPace.
  ///
  /// In en, this message translates to:
  /// **'AVG PACE'**
  String get runShareKpiAvgPace;

  /// No description provided for @runShareKpiAvgHr.
  ///
  /// In en, this message translates to:
  /// **'AVG BPM'**
  String get runShareKpiAvgHr;

  /// No description provided for @runShareKpiCompliance.
  ///
  /// In en, this message translates to:
  /// **'ON-PLAN'**
  String get runShareKpiCompliance;

  /// No description provided for @runShareIndoorPill.
  ///
  /// In en, this message translates to:
  /// **'INDOOR RUN'**
  String get runShareIndoorPill;

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

  /// No description provided for @onbConnectHealthStageSyncingProgress.
  ///
  /// In en, this message translates to:
  /// **'Syncing {done} of {total} runs…'**
  String onbConnectHealthStageSyncingProgress(int done, int total);

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

  /// No description provided for @schedWeeklyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Weekly Plan'**
  String get schedWeeklyPlanTitle;

  /// No description provided for @schedKmTotal.
  ///
  /// In en, this message translates to:
  /// **'KM TOTAL'**
  String get schedKmTotal;

  /// No description provided for @schedBackToToday.
  ///
  /// In en, this message translates to:
  /// **'Back to today'**
  String get schedBackToToday;

  /// No description provided for @schedNoTrainingWeek.
  ///
  /// In en, this message translates to:
  /// **'No training week found'**
  String get schedNoTrainingWeek;

  /// No description provided for @schedEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No active goal'**
  String get schedEmptyTitle;

  /// No description provided for @schedEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Pick a goal (or ask the coach to build one) to see its schedule here.'**
  String get schedEmptyBody;

  /// No description provided for @schedEmptyCta.
  ///
  /// In en, this message translates to:
  /// **'Go to Goals'**
  String get schedEmptyCta;

  /// No description provided for @scheduleChatBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Schedule week chat'**
  String get scheduleChatBarrierLabel;

  /// No description provided for @scheduleChatViewingWeek.
  ///
  /// In en, this message translates to:
  /// **'Viewing week {weekNumber} · {dateRange}'**
  String scheduleChatViewingWeek(int weekNumber, String dateRange);

  /// No description provided for @scheduleChatTitle.
  ///
  /// In en, this message translates to:
  /// **'Week {weekNumber} ({dateRange})'**
  String scheduleChatTitle(int weekNumber, String dateRange);

  /// No description provided for @scheduleChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this week'**
  String get scheduleChatEmptyTitle;

  /// No description provided for @scheduleChatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Anything goes — pace, intensity, swaps, recovery.'**
  String get scheduleChatEmptySubtitle;

  /// No description provided for @weekChatSuggestionIntervalPace.
  ///
  /// In en, this message translates to:
  /// **'How should I pace the intervals on {dayName}?'**
  String weekChatSuggestionIntervalPace(String dayName);

  /// No description provided for @weekChatSuggestionIntervalPaceSub.
  ///
  /// In en, this message translates to:
  /// **'Set the right effort for each rep.'**
  String get weekChatSuggestionIntervalPaceSub;

  /// No description provided for @weekChatSuggestionLongRunPace.
  ///
  /// In en, this message translates to:
  /// **'How should I pace the long run on {dayName}?'**
  String weekChatSuggestionLongRunPace(String dayName);

  /// No description provided for @weekChatSuggestionLongRunPaceSub.
  ///
  /// In en, this message translates to:
  /// **'Stay aerobic, finish strong.'**
  String get weekChatSuggestionLongRunPaceSub;

  /// No description provided for @weekChatSuggestionDeloadWhy.
  ///
  /// In en, this message translates to:
  /// **'Why is this week lighter?'**
  String get weekChatSuggestionDeloadWhy;

  /// No description provided for @weekChatSuggestionDeloadWhySub.
  ///
  /// In en, this message translates to:
  /// **'Recovery weeks and how they help.'**
  String get weekChatSuggestionDeloadWhySub;

  /// No description provided for @weekChatSuggestionRaceDayPrep.
  ///
  /// In en, this message translates to:
  /// **'What should I do the day before the race?'**
  String get weekChatSuggestionRaceDayPrep;

  /// No description provided for @weekChatSuggestionRaceDayPrepSub.
  ///
  /// In en, this message translates to:
  /// **'Pre-race routine, food, sleep.'**
  String get weekChatSuggestionRaceDayPrepSub;

  /// No description provided for @weekChatSuggestionTooHard.
  ///
  /// In en, this message translates to:
  /// **'Is this week too hard for me?'**
  String get weekChatSuggestionTooHard;

  /// No description provided for @weekChatSuggestionTooHardSub.
  ///
  /// In en, this message translates to:
  /// **'Get an honest read on the load.'**
  String get weekChatSuggestionTooHardSub;

  /// No description provided for @weekChatSuggestionSwapInterval.
  ///
  /// In en, this message translates to:
  /// **'Can we swap an interval for a long run?'**
  String get weekChatSuggestionSwapInterval;

  /// No description provided for @weekChatSuggestionSwapIntervalSub.
  ///
  /// In en, this message translates to:
  /// **'Adjust this week\'s structure.'**
  String get weekChatSuggestionSwapIntervalSub;

  /// No description provided for @schedDayTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get schedDayTarget;

  /// No description provided for @schedDayActual.
  ///
  /// In en, this message translates to:
  /// **'ACTUAL'**
  String get schedDayActual;

  /// No description provided for @schedDayDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get schedDayDistance;

  /// No description provided for @schedDayPace.
  ///
  /// In en, this message translates to:
  /// **'PACE'**
  String get schedDayPace;

  /// No description provided for @schedDayPaceField.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get schedDayPaceField;

  /// No description provided for @schedDayDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get schedDayDuration;

  /// No description provided for @schedDayHr.
  ///
  /// In en, this message translates to:
  /// **'HEART'**
  String get schedDayHr;

  /// No description provided for @schedDayHrZone.
  ///
  /// In en, this message translates to:
  /// **'HR ZONE'**
  String get schedDayHrZone;

  /// No description provided for @schedDayAvgHr.
  ///
  /// In en, this message translates to:
  /// **'AVG HR'**
  String get schedDayAvgHr;

  /// No description provided for @schedDayHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get schedDayHeartRate;

  /// No description provided for @schedDayRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get schedDayRecovery;

  /// No description provided for @schedDayPaceCheckTitle.
  ///
  /// In en, this message translates to:
  /// **'Pace check'**
  String get schedDayPaceCheckTitle;

  /// No description provided for @schedDaySendToWatch.
  ///
  /// In en, this message translates to:
  /// **'SEND TO WATCH'**
  String get schedDaySendToWatch;

  /// No description provided for @schedDaySendingToWatch.
  ///
  /// In en, this message translates to:
  /// **'Sending to your watch…'**
  String get schedDaySendingToWatch;

  /// No description provided for @schedDayAdjustWorkout.
  ///
  /// In en, this message translates to:
  /// **'Adjust this workout'**
  String get schedDayAdjustWorkout;

  /// No description provided for @schedDayPickActivity.
  ///
  /// In en, this message translates to:
  /// **'Pick activity'**
  String get schedDayPickActivity;

  /// No description provided for @schedDayUnlinkActivity.
  ///
  /// In en, this message translates to:
  /// **'Unlink activity'**
  String get schedDayUnlinkActivity;

  /// No description provided for @schedDayUnlinkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink activity?'**
  String get schedDayUnlinkConfirmTitle;

  /// No description provided for @schedDayUnlinkAction.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get schedDayUnlinkAction;

  /// No description provided for @schedDayMoveItAction.
  ///
  /// In en, this message translates to:
  /// **'Move it'**
  String get schedDayMoveItAction;

  /// No description provided for @schedDayRescheduleAction.
  ///
  /// In en, this message translates to:
  /// **'Reschedule'**
  String get schedDayRescheduleAction;

  /// No description provided for @schedDayCouldNotReschedule.
  ///
  /// In en, this message translates to:
  /// **'Could not reschedule'**
  String get schedDayCouldNotReschedule;

  /// No description provided for @commonOk.
  ///
  /// In en, this message translates to:
  /// **'OK'**
  String get commonOk;

  /// No description provided for @commonCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get commonCancel;

  /// No description provided for @commonClose.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get commonClose;

  /// No description provided for @schedSectionIntervals.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get schedSectionIntervals;

  /// No description provided for @schedSectionNotes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get schedSectionNotes;

  /// No description provided for @schedWatchNoDistanceBody.
  ///
  /// In en, this message translates to:
  /// **'This workout has no distance set, so it can\'t be scheduled on the watch.'**
  String get schedWatchNoDistanceBody;

  /// No description provided for @schedWatchNoStepsBody.
  ///
  /// In en, this message translates to:
  /// **'This interval session has no work reps to send to the watch.'**
  String get schedWatchNoStepsBody;

  /// No description provided for @schedWatchSentTitle.
  ///
  /// In en, this message translates to:
  /// **'Sent to your watch'**
  String get schedWatchSentTitle;

  /// No description provided for @schedWatchSentBody.
  ///
  /// In en, this message translates to:
  /// **'Open the Fitness app on your iPhone or Apple Watch to start it.'**
  String get schedWatchSentBody;

  /// No description provided for @schedWatchDuplicateTitle.
  ///
  /// In en, this message translates to:
  /// **'Already scheduled'**
  String get schedWatchDuplicateTitle;

  /// No description provided for @schedWatchDuplicateBody.
  ///
  /// In en, this message translates to:
  /// **'You already have a workout planned for this day in the Fitness app.'**
  String get schedWatchDuplicateBody;

  /// No description provided for @schedWatchPermissionTitle.
  ///
  /// In en, this message translates to:
  /// **'Permission needed'**
  String get schedWatchPermissionTitle;

  /// No description provided for @schedWatchPermissionBody.
  ///
  /// In en, this message translates to:
  /// **'Allow workout scheduling in Settings → RunCoach to send this run to your watch.'**
  String get schedWatchPermissionBody;

  /// No description provided for @schedWatchUnavailableTitle.
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get schedWatchUnavailableTitle;

  /// No description provided for @schedWatchUnavailableBody.
  ///
  /// In en, this message translates to:
  /// **'Sending workouts to the Apple Watch needs iOS 17 or newer.'**
  String get schedWatchUnavailableBody;

  /// No description provided for @schedWatchGenericError.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Try again.'**
  String get schedWatchGenericError;

  /// No description provided for @schedWatchNothingToSendTitle.
  ///
  /// In en, this message translates to:
  /// **'Nothing to send'**
  String get schedWatchNothingToSendTitle;

  /// No description provided for @schedWatchInvalidDateBody.
  ///
  /// In en, this message translates to:
  /// **'This training day has an invalid date — try refreshing the schedule.'**
  String get schedWatchInvalidDateBody;

  /// No description provided for @schedWatchFailedTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send'**
  String get schedWatchFailedTitle;

  /// No description provided for @commonDelete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get commonDelete;

  /// No description provided for @commonNo.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get commonNo;

  /// No description provided for @goalsListYourGoals.
  ///
  /// In en, this message translates to:
  /// **'Your goals'**
  String get goalsListYourGoals;

  /// No description provided for @goalsListOtherGoals.
  ///
  /// In en, this message translates to:
  /// **'Other goals'**
  String get goalsListOtherGoals;

  /// No description provided for @goalsListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No goals yet'**
  String get goalsListEmptyTitle;

  /// No description provided for @goalsListEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Ask the coach below to build your first training plan.'**
  String get goalsListEmptyBody;

  /// No description provided for @goalsCardActive.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get goalsCardActive;

  /// No description provided for @goalsCardDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get goalsCardDistance;

  /// No description provided for @goalsCardGoalTime.
  ///
  /// In en, this message translates to:
  /// **'GOAL TIME'**
  String get goalsCardGoalTime;

  /// No description provided for @goalsCardTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get goalsCardTarget;

  /// No description provided for @goalsCardDaysLeft.
  ///
  /// In en, this message translates to:
  /// **'DAYS LEFT'**
  String get goalsCardDaysLeft;

  /// No description provided for @goalsCardPast.
  ///
  /// In en, this message translates to:
  /// **'PAST'**
  String get goalsCardPast;

  /// No description provided for @goalsCardRaceDay.
  ///
  /// In en, this message translates to:
  /// **'RACE DAY'**
  String get goalsCardRaceDay;

  /// No description provided for @goalsCardDaysToGo.
  ///
  /// In en, this message translates to:
  /// **'{days} DAYS TO GO'**
  String goalsCardDaysToGo(int days);

  /// No description provided for @goalsCardSwitch.
  ///
  /// In en, this message translates to:
  /// **'Switch'**
  String get goalsCardSwitch;

  /// No description provided for @goalsSwitchTitle.
  ///
  /// In en, this message translates to:
  /// **'Switch active goal?'**
  String get goalsSwitchTitle;

  /// No description provided for @goalsSwitchBody.
  ///
  /// In en, this message translates to:
  /// **'Make \"{name}\" your active goal. Your current active goal will be paused.'**
  String goalsSwitchBody(String name);

  /// No description provided for @goalsSwitchToThis.
  ///
  /// In en, this message translates to:
  /// **'Switch to this goal'**
  String get goalsSwitchToThis;

  /// No description provided for @goalsSwitchToThisBody.
  ///
  /// In en, this message translates to:
  /// **'Your current active goal will be paused.'**
  String get goalsSwitchToThisBody;

  /// No description provided for @goalsDeleteGoal.
  ///
  /// In en, this message translates to:
  /// **'Delete goal'**
  String get goalsDeleteGoal;

  /// No description provided for @goalsDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete \"{name}\"?'**
  String goalsDeleteConfirmBody(String name);

  /// No description provided for @goalsScheduleRowTitle.
  ///
  /// In en, this message translates to:
  /// **'Training schedule'**
  String get goalsScheduleRowTitle;

  /// No description provided for @goalsScheduleRowSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Open your weekly plan'**
  String get goalsScheduleRowSubtitle;

  /// No description provided for @goalsScheduleRowSubtitlePreview.
  ///
  /// In en, this message translates to:
  /// **'Preview the plan for this goal'**
  String get goalsScheduleRowSubtitlePreview;

  /// No description provided for @commonError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get commonError;

  /// No description provided for @commonDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get commonDone;

  /// No description provided for @orgConnectionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get orgConnectionsTitle;

  /// No description provided for @orgSearchPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Search gyms or clubs'**
  String get orgSearchPlaceholder;

  /// No description provided for @orgAllOrganizations.
  ///
  /// In en, this message translates to:
  /// **'All organizations'**
  String get orgAllOrganizations;

  /// No description provided for @orgResults.
  ///
  /// In en, this message translates to:
  /// **'Results'**
  String get orgResults;

  /// No description provided for @orgNoResults.
  ///
  /// In en, this message translates to:
  /// **'No organizations match.'**
  String get orgNoResults;

  /// No description provided for @orgSectionActive.
  ///
  /// In en, this message translates to:
  /// **'Active membership'**
  String get orgSectionActive;

  /// No description provided for @orgSectionPendingInvites.
  ///
  /// In en, this message translates to:
  /// **'Pending invitations'**
  String get orgSectionPendingInvites;

  /// No description provided for @orgSectionPendingRequests.
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get orgSectionPendingRequests;

  /// No description provided for @orgLeaveConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Leave organization?'**
  String get orgLeaveConfirmTitle;

  /// No description provided for @orgLeaveConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'You will lose access to your coach and any plans they created.'**
  String get orgLeaveConfirmBody;

  /// No description provided for @orgLeaveAction.
  ///
  /// In en, this message translates to:
  /// **'Leave'**
  String get orgLeaveAction;

  /// No description provided for @orgLeaveButton.
  ///
  /// In en, this message translates to:
  /// **'Leave organization'**
  String get orgLeaveButton;

  /// No description provided for @orgLeftSuccess.
  ///
  /// In en, this message translates to:
  /// **'Left organization'**
  String get orgLeftSuccess;

  /// No description provided for @orgRequestSent.
  ///
  /// In en, this message translates to:
  /// **'Request sent to {name}'**
  String orgRequestSent(String name);

  /// No description provided for @orgFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Organization'**
  String get orgFallbackName;

  /// No description provided for @orgRoleLine.
  ///
  /// In en, this message translates to:
  /// **'Role: {role}'**
  String orgRoleLine(String role);

  /// No description provided for @orgCoachLine.
  ///
  /// In en, this message translates to:
  /// **'Coach: {name}'**
  String orgCoachLine(String name);

  /// No description provided for @orgInvitedAs.
  ///
  /// In en, this message translates to:
  /// **'Invited as {role}'**
  String orgInvitedAs(String role);

  /// No description provided for @orgAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept'**
  String get orgAccept;

  /// No description provided for @orgReject.
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get orgReject;

  /// No description provided for @orgAwaitingApproval.
  ///
  /// In en, this message translates to:
  /// **'Awaiting approval'**
  String get orgAwaitingApproval;

  /// No description provided for @orgJoin.
  ///
  /// In en, this message translates to:
  /// **'Join'**
  String get orgJoin;

  /// No description provided for @orgInviteTitle.
  ///
  /// In en, this message translates to:
  /// **'You\'ve been invited'**
  String get orgInviteTitle;

  /// No description provided for @orgInviteBody.
  ///
  /// In en, this message translates to:
  /// **'Tap accept to join the organization. You can review your active membership in Connections.'**
  String get orgInviteBody;

  /// No description provided for @orgInviteAccept.
  ///
  /// In en, this message translates to:
  /// **'Accept invitation'**
  String get orgInviteAccept;

  /// No description provided for @orgInviteLater.
  ///
  /// In en, this message translates to:
  /// **'Not now'**
  String get orgInviteLater;

  /// No description provided for @coachChatListTitle.
  ///
  /// In en, this message translates to:
  /// **'Coach chat'**
  String get coachChatListTitle;

  /// No description provided for @coachChatListEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No conversations yet'**
  String get coachChatListEmptyTitle;

  /// No description provided for @coachChatListEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Start a chat with your AI coach'**
  String get coachChatListEmptySubtitle;

  /// No description provided for @coachChatNewTitle.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get coachChatNewTitle;

  /// No description provided for @coachChatDeleteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not delete chat'**
  String get coachChatDeleteErrorTitle;

  /// No description provided for @coachChatDeleteErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again.'**
  String get coachChatDeleteErrorBody;

  /// No description provided for @coachThinking.
  ///
  /// In en, this message translates to:
  /// **'Thinking'**
  String get coachThinking;

  /// No description provided for @coachAskFullCoach.
  ///
  /// In en, this message translates to:
  /// **'Ask the full coach'**
  String get coachAskFullCoach;

  /// No description provided for @coachProposalRevisionEyebrow.
  ///
  /// In en, this message translates to:
  /// **'PLAN REVISION'**
  String get coachProposalRevisionEyebrow;

  /// No description provided for @coachProposalChanges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change to your plan} other{{count} changes to your plan}}'**
  String coachProposalChanges(int count);

  /// No description provided for @coachProposalRevisionBody.
  ///
  /// In en, this message translates to:
  /// **'Tap below to review what changed before applying.'**
  String get coachProposalRevisionBody;

  /// No description provided for @coachProposalWeeklyKm.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY KM'**
  String get coachProposalWeeklyKm;

  /// No description provided for @coachProposalWeeklyRuns.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY RUNS'**
  String get coachProposalWeeklyRuns;

  /// No description provided for @coachProposalViewChanges.
  ///
  /// In en, this message translates to:
  /// **'VIEW CHANGES'**
  String get coachProposalViewChanges;

  /// No description provided for @coachProposalViewDetails.
  ///
  /// In en, this message translates to:
  /// **'VIEW DETAILS'**
  String get coachProposalViewDetails;

  /// No description provided for @coachProposalAccepted.
  ///
  /// In en, this message translates to:
  /// **'Plan accepted.'**
  String get coachProposalAccepted;

  /// No description provided for @coachProposalRejected.
  ///
  /// In en, this message translates to:
  /// **'Rejected.'**
  String get coachProposalRejected;

  /// No description provided for @coachNewPlanCardCta.
  ///
  /// In en, this message translates to:
  /// **'Start a fresh training plan'**
  String get coachNewPlanCardCta;

  /// No description provided for @coachNewPlanCardEyebrow.
  ///
  /// In en, this message translates to:
  /// **'NEW PLAN'**
  String get coachNewPlanCardEyebrow;

  /// No description provided for @coachNewPlanCardBody.
  ///
  /// In en, this message translates to:
  /// **'I\'ll walk you through your goal, target date, and weekly cadence — your synced run history is already there.'**
  String get coachNewPlanCardBody;

  /// No description provided for @coachNewPlanCardButton.
  ///
  /// In en, this message translates to:
  /// **'START NEW PLAN'**
  String get coachNewPlanCardButton;

  /// No description provided for @coachSuggestionCreatePlan.
  ///
  /// In en, this message translates to:
  /// **'Create a training plan'**
  String get coachSuggestionCreatePlan;

  /// No description provided for @coachSuggestionCreatePlanSub.
  ///
  /// In en, this message translates to:
  /// **'For an upcoming race or new goal.'**
  String get coachSuggestionCreatePlanSub;

  /// No description provided for @coachSuggestionAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust my schedule'**
  String get coachSuggestionAdjust;

  /// No description provided for @coachSuggestionAnalyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze my progress'**
  String get coachSuggestionAnalyze;

  /// No description provided for @coachSuggestionAnalyzeSub.
  ///
  /// In en, this message translates to:
  /// **'How am I trending lately?'**
  String get coachSuggestionAnalyzeSub;

  /// No description provided for @coachSuggestionAnalyzePrompt.
  ///
  /// In en, this message translates to:
  /// **'How is my training going? Give me an analysis of my progress.'**
  String get coachSuggestionAnalyzePrompt;

  /// No description provided for @coachSuggestionAdvice.
  ///
  /// In en, this message translates to:
  /// **'Training advice'**
  String get coachSuggestionAdvice;

  /// No description provided for @coachSuggestionAdviceSub.
  ///
  /// In en, this message translates to:
  /// **'Pacing, recovery, nutrition, gear.'**
  String get coachSuggestionAdviceSub;

  /// No description provided for @coachSuggestionAdvicePrompt.
  ///
  /// In en, this message translates to:
  /// **'Got any running advice for me today?'**
  String get coachSuggestionAdvicePrompt;

  /// No description provided for @coachSuggestionCreatePlanPrompt.
  ///
  /// In en, this message translates to:
  /// **'I want to create a training plan for an upcoming race'**
  String get coachSuggestionCreatePlanPrompt;

  /// No description provided for @coachSuggestionAdjustSub.
  ///
  /// In en, this message translates to:
  /// **'Tweak this week\'s plan.'**
  String get coachSuggestionAdjustSub;

  /// No description provided for @coachSuggestionAdjustPrompt.
  ///
  /// In en, this message translates to:
  /// **'Can you adjust this week\'s training schedule?'**
  String get coachSuggestionAdjustPrompt;

  /// No description provided for @coachEmptyStateTitle.
  ///
  /// In en, this message translates to:
  /// **'What can I help you with?'**
  String get coachEmptyStateTitle;

  /// No description provided for @coachEmptyStateSubtitle.
  ///
  /// In en, this message translates to:
  /// **'I know your training history and can manage your schedule.'**
  String get coachEmptyStateSubtitle;

  /// No description provided for @workoutChatAdjust.
  ///
  /// In en, this message translates to:
  /// **'Adjust this workout'**
  String get workoutChatAdjust;

  /// No description provided for @workoutChatAdjustSub.
  ///
  /// In en, this message translates to:
  /// **'Distance, pace, intervals.'**
  String get workoutChatAdjustSub;

  /// No description provided for @workoutChatWhatPlan.
  ///
  /// In en, this message translates to:
  /// **'What\'s the plan'**
  String get workoutChatWhatPlan;

  /// No description provided for @workoutChatWhatPlanSub.
  ///
  /// In en, this message translates to:
  /// **'Why this workout, why today.'**
  String get workoutChatWhatPlanSub;

  /// No description provided for @workoutChatPaceCheckSub.
  ///
  /// In en, this message translates to:
  /// **'Is the target pace right for me?'**
  String get workoutChatPaceCheckSub;

  /// No description provided for @workoutChatMoveIt.
  ///
  /// In en, this message translates to:
  /// **'Move it'**
  String get workoutChatMoveIt;

  /// No description provided for @workoutChatMoveItSub.
  ///
  /// In en, this message translates to:
  /// **'Reschedule to another day.'**
  String get workoutChatMoveItSub;

  /// No description provided for @trainingResultUnlinkErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unlink the activity. Please try again.'**
  String get trainingResultUnlinkErrorBody;

  /// No description provided for @intervalKindWarmup.
  ///
  /// In en, this message translates to:
  /// **'Warm up'**
  String get intervalKindWarmup;

  /// No description provided for @intervalKindWork.
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get intervalKindWork;

  /// No description provided for @intervalKindRecovery.
  ///
  /// In en, this message translates to:
  /// **'Recovery'**
  String get intervalKindRecovery;

  /// No description provided for @intervalKindCooldown.
  ///
  /// In en, this message translates to:
  /// **'Cool down'**
  String get intervalKindCooldown;

  /// No description provided for @coachRoleYou.
  ///
  /// In en, this message translates to:
  /// **'You'**
  String get coachRoleYou;

  /// No description provided for @coachRoleAssistant.
  ///
  /// In en, this message translates to:
  /// **'RunCore AI Coach'**
  String get coachRoleAssistant;

  /// No description provided for @coachMessageRetry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get coachMessageRetry;

  /// No description provided for @coachStatsWeeklyAvgKm.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY\nAVG. KM'**
  String get coachStatsWeeklyAvgKm;

  /// No description provided for @coachStatsWeeklyAvgRuns.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY\nAVG. RUNS'**
  String get coachStatsWeeklyAvgRuns;

  /// No description provided for @coachStatsAvgPace.
  ///
  /// In en, this message translates to:
  /// **'AVG PACE'**
  String get coachStatsAvgPace;

  /// No description provided for @coachStatsSessionAvgTime.
  ///
  /// In en, this message translates to:
  /// **'SESSION\nAVG. TIME'**
  String get coachStatsSessionAvgTime;

  /// No description provided for @coachRevisionGoal.
  ///
  /// In en, this message translates to:
  /// **'GOAL'**
  String get coachRevisionGoal;

  /// No description provided for @coachRevisionWeek.
  ///
  /// In en, this message translates to:
  /// **'WEEK {number}'**
  String coachRevisionWeek(String number);

  /// No description provided for @coachRevisionChangeCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 change to your plan} other{{count} changes to your plan}}'**
  String coachRevisionChangeCount(int count);

  /// No description provided for @coachRevisionDayFallback.
  ///
  /// In en, this message translates to:
  /// **'Day'**
  String get coachRevisionDayFallback;

  /// No description provided for @coachRevisionAddedOn.
  ///
  /// In en, this message translates to:
  /// **'Added on {day}'**
  String coachRevisionAddedOn(String day);

  /// No description provided for @coachRevisionRemovedSession.
  ///
  /// In en, this message translates to:
  /// **'Removed {day} session'**
  String coachRevisionRemovedSession(String day);

  /// No description provided for @coachRevisionMovedTo.
  ///
  /// In en, this message translates to:
  /// **'Moved to {day}'**
  String coachRevisionMovedTo(String day);

  /// No description provided for @coachRevisionWasOn.
  ///
  /// In en, this message translates to:
  /// **'Was on {day}'**
  String coachRevisionWasOn(String day);

  /// No description provided for @coachRevisionUpdatedDay.
  ///
  /// In en, this message translates to:
  /// **'Updated {day}'**
  String coachRevisionUpdatedDay(String day);

  /// No description provided for @coachRevisionGoalUpdated.
  ///
  /// In en, this message translates to:
  /// **'Goal details updated'**
  String get coachRevisionGoalUpdated;

  /// No description provided for @coachRevisionGoalFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name: {value}'**
  String coachRevisionGoalFieldName(String value);

  /// No description provided for @coachRevisionGoalFieldDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance: {value}'**
  String coachRevisionGoalFieldDistance(String value);

  /// No description provided for @coachRevisionGoalFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date: {value}'**
  String coachRevisionGoalFieldDate(String value);

  /// No description provided for @coachRevisionGoalFieldGoalTime.
  ///
  /// In en, this message translates to:
  /// **'Goal time: {value}'**
  String coachRevisionGoalFieldGoalTime(String value);

  /// No description provided for @coachRevisionGoalFieldDays.
  ///
  /// In en, this message translates to:
  /// **'Days: {value}'**
  String coachRevisionGoalFieldDays(String value);

  /// No description provided for @coachRevisionRunFallback.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get coachRevisionRunFallback;

  /// No description provided for @coachChipOrTypeOwn.
  ///
  /// In en, this message translates to:
  /// **'or type your own'**
  String get coachChipOrTypeOwn;

  /// No description provided for @trainingResultHeader.
  ///
  /// In en, this message translates to:
  /// **'Training result'**
  String get trainingResultHeader;

  /// No description provided for @trainingResultEyebrowCompliance.
  ///
  /// In en, this message translates to:
  /// **'COMPLIANCE'**
  String get trainingResultEyebrowCompliance;

  /// No description provided for @trainingResultEyebrowTargetVsActual.
  ///
  /// In en, this message translates to:
  /// **'TARGET VS ACTUAL'**
  String get trainingResultEyebrowTargetVsActual;

  /// No description provided for @trainingResultEyebrowCoachFeedback.
  ///
  /// In en, this message translates to:
  /// **'COACH FEEDBACK'**
  String get trainingResultEyebrowCoachFeedback;

  /// No description provided for @trainingResultCompTarget.
  ///
  /// In en, this message translates to:
  /// **'TARGET'**
  String get trainingResultCompTarget;

  /// No description provided for @trainingResultCompActual.
  ///
  /// In en, this message translates to:
  /// **'ACTUAL'**
  String get trainingResultCompActual;

  /// No description provided for @trainingResultRowDistance.
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get trainingResultRowDistance;

  /// No description provided for @trainingResultRowPace.
  ///
  /// In en, this message translates to:
  /// **'Pace'**
  String get trainingResultRowPace;

  /// No description provided for @trainingResultRowHeartRate.
  ///
  /// In en, this message translates to:
  /// **'Heart rate'**
  String get trainingResultRowHeartRate;

  /// No description provided for @trainingResultHrZoneTarget.
  ///
  /// In en, this message translates to:
  /// **'Zone {zone}'**
  String trainingResultHrZoneTarget(int zone);

  /// No description provided for @trainingResultUnlinkConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Unlink activity?'**
  String get trainingResultUnlinkConfirmTitle;

  /// No description provided for @trainingResultUnlinkConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'The run stays in Apple Health; it just stops being matched to this training day.'**
  String get trainingResultUnlinkConfirmBody;

  /// No description provided for @trainingResultUnlinkAction.
  ///
  /// In en, this message translates to:
  /// **'Unlink'**
  String get trainingResultUnlinkAction;

  /// No description provided for @trainingResultUnlinkButton.
  ///
  /// In en, this message translates to:
  /// **'Unlink activity'**
  String get trainingResultUnlinkButton;

  /// No description provided for @trainingResultUnlinkErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t unlink'**
  String get trainingResultUnlinkErrorTitle;

  /// No description provided for @coachAnalysisEyebrow.
  ///
  /// In en, this message translates to:
  /// **'COACH ANALYSIS'**
  String get coachAnalysisEyebrow;

  /// No description provided for @coachAnalysisCompliance.
  ///
  /// In en, this message translates to:
  /// **'Compliance'**
  String get coachAnalysisCompliance;

  /// No description provided for @coachAnalysisOpenCta.
  ///
  /// In en, this message translates to:
  /// **'OPEN ANALYSIS'**
  String get coachAnalysisOpenCta;

  /// No description provided for @coachAnalysisAnalysing.
  ///
  /// In en, this message translates to:
  /// **'Analysing your run…'**
  String get coachAnalysisAnalysing;

  /// No description provided for @selectActivityTitle.
  ///
  /// In en, this message translates to:
  /// **'Pick an activity'**
  String get selectActivityTitle;

  /// No description provided for @selectActivitySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Runs from the last week, synced from Apple Health.'**
  String get selectActivitySubtitle;

  /// No description provided for @selectActivityLoadError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t load your activities.'**
  String get selectActivityLoadError;

  /// No description provided for @selectActivityNoneRecent.
  ///
  /// In en, this message translates to:
  /// **'No recent activities'**
  String get selectActivityNoneRecent;

  /// No description provided for @selectActivityMatchErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t match that run'**
  String get selectActivityMatchErrorTitle;

  /// No description provided for @selectActivitySyncedBadge.
  ///
  /// In en, this message translates to:
  /// **'SYNCED'**
  String get selectActivitySyncedBadge;

  /// No description provided for @selectActivityNoneRecentDetail.
  ///
  /// In en, this message translates to:
  /// **'Nothing synced from Apple Health in the past week.'**
  String get selectActivityNoneRecentDetail;

  /// No description provided for @rescheduleConfirmErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Could not reschedule'**
  String get rescheduleConfirmErrorTitle;

  /// No description provided for @rescheduleMoveTo.
  ///
  /// In en, this message translates to:
  /// **'Move to {date}'**
  String rescheduleMoveTo(String date);

  /// No description provided for @wearableSummaryDistance.
  ///
  /// In en, this message translates to:
  /// **'DISTANCE'**
  String get wearableSummaryDistance;

  /// No description provided for @wearableSummaryDuration.
  ///
  /// In en, this message translates to:
  /// **'DURATION'**
  String get wearableSummaryDuration;

  /// No description provided for @wearableSummaryAvgHr.
  ///
  /// In en, this message translates to:
  /// **'AVG HR'**
  String get wearableSummaryAvgHr;

  /// No description provided for @workoutChatEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Ask about this workout'**
  String get workoutChatEmptyTitle;

  /// No description provided for @workoutChatEmptySubtitle.
  ///
  /// In en, this message translates to:
  /// **'I know your target stats, splits, and how it fits this week.'**
  String get workoutChatEmptySubtitle;

  /// No description provided for @workoutChatAdjustPrompt.
  ///
  /// In en, this message translates to:
  /// **'Can we tweak this workout? I\'d like to '**
  String get workoutChatAdjustPrompt;

  /// No description provided for @workoutChatWhatPlanPrompt.
  ///
  /// In en, this message translates to:
  /// **'What\'s the purpose of this workout and what should I focus on?'**
  String get workoutChatWhatPlanPrompt;

  /// No description provided for @workoutChatPaceCheck.
  ///
  /// In en, this message translates to:
  /// **'Pace check'**
  String get workoutChatPaceCheck;

  /// No description provided for @workoutChatPaceCheckPrompt.
  ///
  /// In en, this message translates to:
  /// **'Is the target pace realistic based on my recent runs?'**
  String get workoutChatPaceCheckPrompt;

  /// No description provided for @workoutChatMoveItPrompt.
  ///
  /// In en, this message translates to:
  /// **'Can we move this workout to '**
  String get workoutChatMoveItPrompt;

  /// No description provided for @planDetailsGoalFallback.
  ///
  /// In en, this message translates to:
  /// **'Your training plan'**
  String get planDetailsGoalFallback;

  /// No description provided for @planDetailsEyebrowRevision.
  ///
  /// In en, this message translates to:
  /// **'PLAN REVISION'**
  String get planDetailsEyebrowRevision;

  /// No description provided for @planDetailsEyebrowRecommended.
  ///
  /// In en, this message translates to:
  /// **'RECOMMENDED PLAN'**
  String get planDetailsEyebrowRecommended;

  /// No description provided for @planDetailsRevisionTitle.
  ///
  /// In en, this message translates to:
  /// **'Review your changes'**
  String get planDetailsRevisionTitle;

  /// No description provided for @planDetailsBreakdownLabel.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY BREAKDOWN'**
  String get planDetailsBreakdownLabel;

  /// No description provided for @planDetailsStatWeeks.
  ///
  /// In en, this message translates to:
  /// **'WEEKS'**
  String get planDetailsStatWeeks;

  /// No description provided for @planDetailsStatAvgKm.
  ///
  /// In en, this message translates to:
  /// **'AVG KM / WEEK'**
  String get planDetailsStatAvgKm;

  /// No description provided for @planDetailsStatRunsPerWeek.
  ///
  /// In en, this message translates to:
  /// **'RUNS / WEEK'**
  String get planDetailsStatRunsPerWeek;

  /// No description provided for @planDetailsWeekLabel.
  ///
  /// In en, this message translates to:
  /// **'Week {number}'**
  String planDetailsWeekLabel(int number);

  /// No description provided for @planDetailsWeekFallback.
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get planDetailsWeekFallback;

  /// No description provided for @planDetailsKmTotal.
  ///
  /// In en, this message translates to:
  /// **'KM TOTAL'**
  String get planDetailsKmTotal;

  /// No description provided for @planDetailsDayRun.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get planDetailsDayRun;

  /// No description provided for @planDetailsFooterClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get planDetailsFooterClose;

  /// No description provided for @planDetailsFooterAdjust.
  ///
  /// In en, this message translates to:
  /// **'ADJUST'**
  String get planDetailsFooterAdjust;

  /// No description provided for @planDetailsFooterApplyChanges.
  ///
  /// In en, this message translates to:
  /// **'APPLY CHANGES'**
  String get planDetailsFooterApplyChanges;

  /// No description provided for @planDetailsFooterAcceptPlan.
  ///
  /// In en, this message translates to:
  /// **'ACCEPT PLAN'**
  String get planDetailsFooterAcceptPlan;

  /// No description provided for @planDetailsFooterAdjustGoal.
  ///
  /// In en, this message translates to:
  /// **'ADJUST GOAL FOR REALISTIC PLAN'**
  String get planDetailsFooterAdjustGoal;

  /// No description provided for @planDetailsFooterAcceptAnyway.
  ///
  /// In en, this message translates to:
  /// **'Accept anyway'**
  String get planDetailsFooterAcceptAnyway;

  /// No description provided for @planDetailsVolumeEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEEKLY VOLUME'**
  String get planDetailsVolumeEyebrow;

  /// No description provided for @planDetailsVolumePeak.
  ///
  /// In en, this message translates to:
  /// **'Peak {km} km · W{week}'**
  String planDetailsVolumePeak(String km, int week);

  /// No description provided for @planDetailsFeasibilityUnrealistic.
  ///
  /// In en, this message translates to:
  /// **'Unrealistic'**
  String get planDetailsFeasibilityUnrealistic;

  /// No description provided for @planDetailsFeasibilityStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get planDetailsFeasibilityStretch;

  /// No description provided for @planDetailsFeasibilityOk.
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get planDetailsFeasibilityOk;

  /// No description provided for @commonSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get commonSave;

  /// No description provided for @commonConfirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get commonConfirm;

  /// No description provided for @commonRunnerFallback.
  ///
  /// In en, this message translates to:
  /// **'Runner'**
  String get commonRunnerFallback;

  /// No description provided for @profileMenuConnections.
  ///
  /// In en, this message translates to:
  /// **'Connections'**
  String get profileMenuConnections;

  /// No description provided for @profileMenuAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileMenuAccount;

  /// No description provided for @profileMenuHrZones.
  ///
  /// In en, this message translates to:
  /// **'HR Zones'**
  String get profileMenuHrZones;

  /// No description provided for @profileMenuPrivacy.
  ///
  /// In en, this message translates to:
  /// **'Privacy'**
  String get profileMenuPrivacy;

  /// No description provided for @profileMenuAbout.
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get profileMenuAbout;

  /// No description provided for @profileMenuDeleteData.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get profileMenuDeleteData;

  /// No description provided for @profileMenuLogout.
  ///
  /// In en, this message translates to:
  /// **'Log out'**
  String get profileMenuLogout;

  /// No description provided for @profileMenuDeleteConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete data'**
  String get profileMenuDeleteConfirmTitle;

  /// No description provided for @profileMenuDeleteConfirmBody.
  ///
  /// In en, this message translates to:
  /// **'This deletes your account, goals, schedule, and chats. Cannot be undone.'**
  String get profileMenuDeleteConfirmBody;

  /// No description provided for @profileMenuDeleteConfirmAction.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get profileMenuDeleteConfirmAction;

  /// No description provided for @profileMenuDeleteErrorTitle.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t delete'**
  String get profileMenuDeleteErrorTitle;

  /// No description provided for @profileMenuDeleteErrorBody.
  ///
  /// In en, this message translates to:
  /// **'Please try again. ({error})'**
  String profileMenuDeleteErrorBody(String error);

  /// No description provided for @profileMenuAccountTitle.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get profileMenuAccountTitle;

  /// No description provided for @profileMenuFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get profileMenuFieldName;

  /// No description provided for @profileMenuFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get profileMenuFieldEmail;

  /// No description provided for @profileMenuFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'Your name'**
  String get profileMenuFieldNameHint;

  /// No description provided for @profileMenuFieldNameEmptyError.
  ///
  /// In en, this message translates to:
  /// **'Name cannot be empty'**
  String get profileMenuFieldNameEmptyError;

  /// No description provided for @coachPromptBarPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'Ask your coach...'**
  String get coachPromptBarPlaceholder;

  /// No description provided for @birthDatePickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Date of birth'**
  String get birthDatePickerTitle;

  /// No description provided for @birthDatePickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get birthDatePickerDone;

  /// No description provided for @lockedFieldFromSource.
  ///
  /// In en, this message translates to:
  /// **'From {source}'**
  String lockedFieldFromSource(String source);

  /// No description provided for @lockedFieldEditedByYou.
  ///
  /// In en, this message translates to:
  /// **'Edited by you'**
  String get lockedFieldEditedByYou;

  /// No description provided for @lockedFieldOverrideTitle.
  ///
  /// In en, this message translates to:
  /// **'Override Apple Health data?'**
  String get lockedFieldOverrideTitle;

  /// No description provided for @lockedFieldOverrideBody.
  ///
  /// In en, this message translates to:
  /// **'These values are calculated from your synced run history and are likely the most accurate signal we have. Editing them may result in a less accurate training plan.'**
  String get lockedFieldOverrideBody;

  /// No description provided for @lockedFieldEditAnyway.
  ///
  /// In en, this message translates to:
  /// **'Edit anyway'**
  String get lockedFieldEditAnyway;

  /// No description provided for @paceWheelPickerTitle.
  ///
  /// In en, this message translates to:
  /// **'Easy pace'**
  String get paceWheelPickerTitle;

  /// No description provided for @paceWheelPickerDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get paceWheelPickerDone;

  /// No description provided for @hrZonesSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'HR Zones'**
  String get hrZonesSheetTitle;

  /// No description provided for @hrZonesSheetIntro.
  ///
  /// In en, this message translates to:
  /// **'Edit Max HR to recompute every zone, or change a boundary to update the adjacent zone.'**
  String get hrZonesSheetIntro;

  /// No description provided for @hrZonesMaxHrLabel.
  ///
  /// In en, this message translates to:
  /// **'Max HR'**
  String get hrZonesMaxHrLabel;

  /// No description provided for @hrZonesRecomputeBusy.
  ///
  /// In en, this message translates to:
  /// **'Recomputing…'**
  String get hrZonesRecomputeBusy;

  /// No description provided for @hrZonesRecomputeCta.
  ///
  /// In en, this message translates to:
  /// **'Recompute from your runs'**
  String get hrZonesRecomputeCta;

  /// No description provided for @hrZonesErrorMaxHrRange.
  ///
  /// In en, this message translates to:
  /// **'Max HR must be between 100 and 250 bpm.'**
  String get hrZonesErrorMaxHrRange;

  /// No description provided for @hrZonesErrorInvalidBpm.
  ///
  /// In en, this message translates to:
  /// **'Enter valid bpm values (0-250).'**
  String get hrZonesErrorInvalidBpm;

  /// No description provided for @hrZonesErrorNotAscending.
  ///
  /// In en, this message translates to:
  /// **'Zones must be in ascending order.'**
  String get hrZonesErrorNotAscending;

  /// No description provided for @hrZonesErrorSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save: {error}'**
  String hrZonesErrorSaveFailed(String error);

  /// No description provided for @hrZonesUpdatedCorrected.
  ///
  /// In en, this message translates to:
  /// **'Updated — max ~{maxHr} bpm (age + your hardest recent runs).'**
  String hrZonesUpdatedCorrected(int maxHr);

  /// No description provided for @hrZonesUpdatedDerivedAge.
  ///
  /// In en, this message translates to:
  /// **'Updated — max ~{maxHr} bpm (estimated from age {age}).'**
  String hrZonesUpdatedDerivedAge(int maxHr, int age);

  /// No description provided for @hrZonesUpdatedGenericAge.
  ///
  /// In en, this message translates to:
  /// **'Updated from your age.'**
  String get hrZonesUpdatedGenericAge;

  /// No description provided for @notificationsSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'NOTIFICATIONS'**
  String get notificationsSheetTitle;

  /// No description provided for @notificationsSheetLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load notifications.\n{error}'**
  String notificationsSheetLoadError(String error);

  /// No description provided for @notificationsSheetEmpty.
  ///
  /// In en, this message translates to:
  /// **'You\'re all caught up.'**
  String get notificationsSheetEmpty;

  /// No description provided for @notificationsCardDismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get notificationsCardDismiss;

  /// No description provided for @notificationsCardApply.
  ///
  /// In en, this message translates to:
  /// **'APPLY'**
  String get notificationsCardApply;

  /// No description provided for @notificationsCardViewEvaluation.
  ///
  /// In en, this message translates to:
  /// **'View your check-in'**
  String get notificationsCardViewEvaluation;

  /// No description provided for @notificationsTypePlanEvaluation.
  ///
  /// In en, this message translates to:
  /// **'2-WEEK CHECK-IN'**
  String get notificationsTypePlanEvaluation;

  /// No description provided for @evaluationCardEyebrow.
  ///
  /// In en, this message translates to:
  /// **'CHECK-IN'**
  String get evaluationCardEyebrow;

  /// No description provided for @evaluationCardScheduledFor.
  ///
  /// In en, this message translates to:
  /// **'Scheduled for {date}'**
  String evaluationCardScheduledFor(String date);

  /// No description provided for @evaluationCardWeekTitle.
  ///
  /// In en, this message translates to:
  /// **'Week {week} check-in'**
  String evaluationCardWeekTitle(int week);

  /// No description provided for @evaluationCardStatusPending.
  ///
  /// In en, this message translates to:
  /// **'Up next'**
  String get evaluationCardStatusPending;

  /// No description provided for @evaluationCardStatusProcessing.
  ///
  /// In en, this message translates to:
  /// **'Working on it…'**
  String get evaluationCardStatusProcessing;

  /// No description provided for @evaluationCardStatusReady.
  ///
  /// In en, this message translates to:
  /// **'Report ready'**
  String get evaluationCardStatusReady;

  /// No description provided for @evaluationCardStatusNoChange.
  ///
  /// In en, this message translates to:
  /// **'No changes needed'**
  String get evaluationCardStatusNoChange;

  /// No description provided for @evaluationCardStatusAccepted.
  ///
  /// In en, this message translates to:
  /// **'Applied'**
  String get evaluationCardStatusAccepted;

  /// No description provided for @evaluationCardStatusDismissed.
  ///
  /// In en, this message translates to:
  /// **'Dismissed'**
  String get evaluationCardStatusDismissed;

  /// No description provided for @evaluationCardCtaView.
  ///
  /// In en, this message translates to:
  /// **'Open'**
  String get evaluationCardCtaView;

  /// No description provided for @evaluationDetailTitle.
  ///
  /// In en, this message translates to:
  /// **'2-week check-in'**
  String get evaluationDetailTitle;

  /// No description provided for @evaluationDetailReportHeader.
  ///
  /// In en, this message translates to:
  /// **'Your coach\'s take'**
  String get evaluationDetailReportHeader;

  /// No description provided for @evaluationDetailProposalHeader.
  ///
  /// In en, this message translates to:
  /// **'Suggested adjustment'**
  String get evaluationDetailProposalHeader;

  /// No description provided for @evaluationDetailApply.
  ///
  /// In en, this message translates to:
  /// **'APPLY ADJUSTMENT'**
  String get evaluationDetailApply;

  /// No description provided for @evaluationDetailDismiss.
  ///
  /// In en, this message translates to:
  /// **'DISMISS'**
  String get evaluationDetailDismiss;

  /// No description provided for @evaluationDetailClose.
  ///
  /// In en, this message translates to:
  /// **'CLOSE'**
  String get evaluationDetailClose;

  /// No description provided for @evaluationDetailNoReport.
  ///
  /// In en, this message translates to:
  /// **'No report available yet.'**
  String get evaluationDetailNoReport;

  /// No description provided for @evaluationDetailLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load this evaluation.\n{error}'**
  String evaluationDetailLoadError(String error);

  /// No description provided for @hrZoneNameZ1.
  ///
  /// In en, this message translates to:
  /// **'Endurance'**
  String get hrZoneNameZ1;

  /// No description provided for @hrZoneNameZ2.
  ///
  /// In en, this message translates to:
  /// **'Moderate'**
  String get hrZoneNameZ2;

  /// No description provided for @hrZoneNameZ3.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get hrZoneNameZ3;

  /// No description provided for @hrZoneNameZ4.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get hrZoneNameZ4;

  /// No description provided for @hrZoneNameZ5.
  ///
  /// In en, this message translates to:
  /// **'Anaerobic'**
  String get hrZoneNameZ5;

  /// No description provided for @hrZoneBpm.
  ///
  /// In en, this message translates to:
  /// **'bpm'**
  String get hrZoneBpm;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// No description provided for @settingsLanguageTitle.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguageTitle;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Choose how RunCoach speaks to you.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageAuto.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageAuto;

  /// No description provided for @settingsLanguageAutoSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Follows your device language settings.'**
  String get settingsLanguageAutoSubtitle;

  /// No description provided for @settingsLanguageEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get settingsLanguageEnglish;

  /// No description provided for @settingsLanguageDutch.
  ///
  /// In en, this message translates to:
  /// **'Nederlands'**
  String get settingsLanguageDutch;

  /// No description provided for @settingsLanguageActiveBadge.
  ///
  /// In en, this message translates to:
  /// **'ACTIVE'**
  String get settingsLanguageActiveBadge;

  /// No description provided for @weeklyPlanWeekRange.
  ///
  /// In en, this message translates to:
  /// **'{start} – {end}'**
  String weeklyPlanWeekRange(String start, String end);

  /// No description provided for @weeklyPlanDayCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 run} other{{count} runs}}'**
  String weeklyPlanDayCount(int count);

  /// No description provided for @bootPopupTitle.
  ///
  /// In en, this message translates to:
  /// **'Action required'**
  String get bootPopupTitle;

  /// No description provided for @bootPopupBody.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{You have 1 pending suggestion that needs your attention.} other{You have {count} pending suggestions that need your attention.}}'**
  String bootPopupBody(int count);

  /// No description provided for @bootPopupLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get bootPopupLater;

  /// No description provided for @bootPopupView.
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get bootPopupView;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabSchedule.
  ///
  /// In en, this message translates to:
  /// **'Schedule'**
  String get tabSchedule;

  /// No description provided for @tabChat.
  ///
  /// In en, this message translates to:
  /// **'Chat'**
  String get tabChat;

  /// No description provided for @tabGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get tabGoals;

  /// No description provided for @trainingStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'MARKED AS MISSED'**
  String get trainingStatusMissed;

  /// No description provided for @trainingStatusSynced.
  ///
  /// In en, this message translates to:
  /// **'ACTIVITY SYNCED'**
  String get trainingStatusSynced;

  /// No description provided for @trainingStatusAwaitingSync.
  ///
  /// In en, this message translates to:
  /// **'AWAITING SYNC'**
  String get trainingStatusAwaitingSync;

  /// No description provided for @trainingStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'RUN IS UPCOMING'**
  String get trainingStatusUpcoming;

  /// No description provided for @trainingDayStatusMissed.
  ///
  /// In en, this message translates to:
  /// **'MISSED'**
  String get trainingDayStatusMissed;

  /// No description provided for @trainingDayStatusCompleted.
  ///
  /// In en, this message translates to:
  /// **'COMPLETED'**
  String get trainingDayStatusCompleted;

  /// No description provided for @trainingDayStatusUpcoming.
  ///
  /// In en, this message translates to:
  /// **'UPCOMING'**
  String get trainingDayStatusUpcoming;

  /// No description provided for @workoutChatBarrierLabel.
  ///
  /// In en, this message translates to:
  /// **'Close workout chat'**
  String get workoutChatBarrierLabel;

  /// No description provided for @trainingDayWatchCouldNotSend.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send'**
  String get trainingDayWatchCouldNotSend;

  /// No description provided for @analyzingChipSyncingTitle.
  ///
  /// In en, this message translates to:
  /// **'Syncing your runs'**
  String get analyzingChipSyncingTitle;

  /// No description provided for @analyzingChipSyncingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pulling new runs from Apple Health…'**
  String get analyzingChipSyncingSubtitle;

  /// No description provided for @analyzingChipMatchingTitle.
  ///
  /// In en, this message translates to:
  /// **'Matching to your training plan'**
  String get analyzingChipMatchingTitle;

  /// No description provided for @analyzingChipMatchingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Just a moment…'**
  String get analyzingChipMatchingSubtitle;

  /// No description provided for @analyzingChipAnalysingTitle.
  ///
  /// In en, this message translates to:
  /// **'AI is analyzing your run'**
  String get analyzingChipAnalysingTitle;

  /// No description provided for @analyzingChipAnalysingSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Generating personalized feedback…'**
  String get analyzingChipAnalysingSubtitle;

  /// No description provided for @analyzingChipReadyTitle.
  ///
  /// In en, this message translates to:
  /// **'Analysis ready'**
  String get analyzingChipReadyTitle;

  /// No description provided for @analyzingChipReadyComplianceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Compliance {score}/10'**
  String analyzingChipReadyComplianceSubtitle(String score);

  /// No description provided for @analyzingChipReadyTapToView.
  ///
  /// In en, this message translates to:
  /// **'Tap to view'**
  String get analyzingChipReadyTapToView;

  /// No description provided for @analyzingChipLoggedTitle.
  ///
  /// In en, this message translates to:
  /// **'Run logged'**
  String get analyzingChipLoggedTitle;

  /// No description provided for @analyzingChipLoggedNoMatch.
  ///
  /// In en, this message translates to:
  /// **'No matching training day'**
  String get analyzingChipLoggedNoMatch;

  /// No description provided for @trainingResultNoResultYet.
  ///
  /// In en, this message translates to:
  /// **'No result recorded yet.'**
  String get trainingResultNoResultYet;

  /// No description provided for @goalDetailSectionTraining.
  ///
  /// In en, this message translates to:
  /// **'Training'**
  String get goalDetailSectionTraining;

  /// No description provided for @goalDetailSectionNotActive.
  ///
  /// In en, this message translates to:
  /// **'Not active'**
  String get goalDetailSectionNotActive;

  /// No description provided for @chatErrorConnectionInterrupted.
  ///
  /// In en, this message translates to:
  /// **'Connection interrupted. Tap retry.'**
  String get chatErrorConnectionInterrupted;

  /// No description provided for @chatErrorRequestTimedOut.
  ///
  /// In en, this message translates to:
  /// **'Request timed out'**
  String get chatErrorRequestTimedOut;

  /// No description provided for @chatErrorCannotReachServer.
  ///
  /// In en, this message translates to:
  /// **'Cannot reach server'**
  String get chatErrorCannotReachServer;

  /// No description provided for @chatErrorServerStatus.
  ///
  /// In en, this message translates to:
  /// **'Server error ({status})'**
  String chatErrorServerStatus(String status);

  /// No description provided for @chatErrorUnknown.
  ///
  /// In en, this message translates to:
  /// **'Unknown error'**
  String get chatErrorUnknown;

  /// No description provided for @watchOnlyOnIos.
  ///
  /// In en, this message translates to:
  /// **'Sending workouts to your watch is only available on iOS.'**
  String get watchOnlyOnIos;

  /// No description provided for @watchNativeBridgeError.
  ///
  /// In en, this message translates to:
  /// **'Native bridge error.'**
  String get watchNativeBridgeError;

  /// No description provided for @watchRecomputeFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recompute: {error}'**
  String watchRecomputeFailed(String error);

  /// No description provided for @toolIndicatorDefault.
  ///
  /// In en, this message translates to:
  /// **'Working on it…'**
  String get toolIndicatorDefault;

  /// No description provided for @toolIndicatorGetRecentRuns.
  ///
  /// In en, this message translates to:
  /// **'Looking up your recent runs…'**
  String get toolIndicatorGetRecentRuns;

  /// No description provided for @toolIndicatorSearchActivities.
  ///
  /// In en, this message translates to:
  /// **'Looking up your activities…'**
  String get toolIndicatorSearchActivities;

  /// No description provided for @toolIndicatorGetActivityDetails.
  ///
  /// In en, this message translates to:
  /// **'Digging into that run…'**
  String get toolIndicatorGetActivityDetails;

  /// No description provided for @toolIndicatorGetCurrentSchedule.
  ///
  /// In en, this message translates to:
  /// **'Loading your schedule…'**
  String get toolIndicatorGetCurrentSchedule;

  /// No description provided for @toolIndicatorGetGoalInfo.
  ///
  /// In en, this message translates to:
  /// **'Checking your goal…'**
  String get toolIndicatorGetGoalInfo;

  /// No description provided for @toolIndicatorGetComplianceReport.
  ///
  /// In en, this message translates to:
  /// **'Reviewing compliance…'**
  String get toolIndicatorGetComplianceReport;

  /// No description provided for @toolIndicatorCreateSchedule.
  ///
  /// In en, this message translates to:
  /// **'Building your training plan…'**
  String get toolIndicatorCreateSchedule;

  /// No description provided for @toolIndicatorEditSchedule.
  ///
  /// In en, this message translates to:
  /// **'Revising your plan…'**
  String get toolIndicatorEditSchedule;

  /// No description provided for @toolIndicatorModifySchedule.
  ///
  /// In en, this message translates to:
  /// **'Adjusting your schedule…'**
  String get toolIndicatorModifySchedule;

  /// No description provided for @toolIndicatorGetCurrentProposal.
  ///
  /// In en, this message translates to:
  /// **'Reviewing the proposal…'**
  String get toolIndicatorGetCurrentProposal;

  /// No description provided for @toolIndicatorGetRunningProfile.
  ///
  /// In en, this message translates to:
  /// **'Analysing your running history…'**
  String get toolIndicatorGetRunningProfile;

  /// No description provided for @toolIndicatorPresentRunningStats.
  ///
  /// In en, this message translates to:
  /// **'Preparing your stats…'**
  String get toolIndicatorPresentRunningStats;

  /// No description provided for @toolIndicatorOfferChoices.
  ///
  /// In en, this message translates to:
  /// **'Preparing options…'**
  String get toolIndicatorOfferChoices;

  /// No description provided for @toolIndicatorEditWorkout.
  ///
  /// In en, this message translates to:
  /// **'Adjusting this workout…'**
  String get toolIndicatorEditWorkout;

  /// No description provided for @toolIndicatorRescheduleWorkout.
  ///
  /// In en, this message translates to:
  /// **'Moving this workout…'**
  String get toolIndicatorRescheduleWorkout;

  /// No description provided for @toolIndicatorEscalateToCoach.
  ///
  /// In en, this message translates to:
  /// **'Routing to your coach…'**
  String get toolIndicatorEscalateToCoach;

  /// No description provided for @choiceGroupOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get choiceGroupOther;

  /// No description provided for @orgJoinedSnack.
  ///
  /// In en, this message translates to:
  /// **'Joined organization'**
  String get orgJoinedSnack;

  /// No description provided for @newChatTitle.
  ///
  /// In en, this message translates to:
  /// **'New Chat'**
  String get newChatTitle;

  /// No description provided for @trainingCoachSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Move this run to tomorrow…'**
  String get trainingCoachSuggestion1;

  /// No description provided for @trainingCoachSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Make this easier, I feel tired…'**
  String get trainingCoachSuggestion2;

  /// No description provided for @trainingCoachSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Why is today\'s pace so fast?'**
  String get trainingCoachSuggestion3;

  /// No description provided for @trainingCoachSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Swap for a rest day instead…'**
  String get trainingCoachSuggestion4;

  /// No description provided for @trainingCoachSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Shorten this to 5km…'**
  String get trainingCoachSuggestion5;

  /// No description provided for @trainingCoachSuggestion6.
  ///
  /// In en, this message translates to:
  /// **'What if I skip the intervals?'**
  String get trainingCoachSuggestion6;

  /// No description provided for @trainingCoachSuggestion7.
  ///
  /// In en, this message translates to:
  /// **'Can I do this on the treadmill?'**
  String get trainingCoachSuggestion7;

  /// No description provided for @trainingCoachSuggestion8.
  ///
  /// In en, this message translates to:
  /// **'Explain the goal of this session…'**
  String get trainingCoachSuggestion8;

  /// No description provided for @scheduleCoachSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Change the easy run to interval...'**
  String get scheduleCoachSuggestion1;

  /// No description provided for @scheduleCoachSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Move Monday workouts to Thursday...'**
  String get scheduleCoachSuggestion2;

  /// No description provided for @scheduleCoachSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'Am I improving at the right pace?'**
  String get scheduleCoachSuggestion3;

  /// No description provided for @scheduleCoachSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'Swap my long run to Saturday...'**
  String get scheduleCoachSuggestion4;

  /// No description provided for @scheduleCoachSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Make this week a recovery week...'**
  String get scheduleCoachSuggestion5;

  /// No description provided for @scheduleCoachSuggestion6.
  ///
  /// In en, this message translates to:
  /// **'Should I push harder this week?'**
  String get scheduleCoachSuggestion6;

  /// No description provided for @scheduleCoachSuggestion7.
  ///
  /// In en, this message translates to:
  /// **'What\'s the goal of Wednesday\'s run?'**
  String get scheduleCoachSuggestion7;

  /// No description provided for @scheduleCoachSuggestion8.
  ///
  /// In en, this message translates to:
  /// **'Cut one easy run, I need rest...'**
  String get scheduleCoachSuggestion8;

  /// No description provided for @scheduleCoachSuggestion9.
  ///
  /// In en, this message translates to:
  /// **'Am I on track for my race?'**
  String get scheduleCoachSuggestion9;

  /// No description provided for @scheduleCoachSuggestion10.
  ///
  /// In en, this message translates to:
  /// **'Explain the tempo session to me...'**
  String get scheduleCoachSuggestion10;

  /// No description provided for @scheduleCoachSuggestion11.
  ///
  /// In en, this message translates to:
  /// **'Can we add a hill session?'**
  String get scheduleCoachSuggestion11;

  /// No description provided for @scheduleCoachSuggestion12.
  ///
  /// In en, this message translates to:
  /// **'I felt wrecked yesterday, adjust...'**
  String get scheduleCoachSuggestion12;

  /// No description provided for @goalCoachSuggestion1.
  ///
  /// In en, this message translates to:
  /// **'Train me for a marathon...'**
  String get goalCoachSuggestion1;

  /// No description provided for @goalCoachSuggestion2.
  ///
  /// In en, this message translates to:
  /// **'Help me get faster at 10k...'**
  String get goalCoachSuggestion2;

  /// No description provided for @goalCoachSuggestion3.
  ///
  /// In en, this message translates to:
  /// **'I have a half marathon in May...'**
  String get goalCoachSuggestion3;

  /// No description provided for @goalCoachSuggestion4.
  ///
  /// In en, this message translates to:
  /// **'What\'s a realistic PR goal?'**
  String get goalCoachSuggestion4;

  /// No description provided for @goalCoachSuggestion5.
  ///
  /// In en, this message translates to:
  /// **'Build a fitness plan for me...'**
  String get goalCoachSuggestion5;

  /// No description provided for @goalCoachSuggestion6.
  ///
  /// In en, this message translates to:
  /// **'I want to break 45 at 10k...'**
  String get goalCoachSuggestion6;

  /// No description provided for @goalCoachSuggestion7.
  ///
  /// In en, this message translates to:
  /// **'Get me race-ready in 12 weeks...'**
  String get goalCoachSuggestion7;

  /// No description provided for @goalCoachSuggestion8.
  ///
  /// In en, this message translates to:
  /// **'Can we target a sub-4 marathon?'**
  String get goalCoachSuggestion8;

  /// No description provided for @goalCoachSuggestion9.
  ///
  /// In en, this message translates to:
  /// **'Design a base-building block...'**
  String get goalCoachSuggestion9;

  /// No description provided for @goalCoachSuggestion10.
  ///
  /// In en, this message translates to:
  /// **'Plan my next training cycle...'**
  String get goalCoachSuggestion10;

  /// No description provided for @wearableActivityFallbackName.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get wearableActivityFallbackName;

  /// No description provided for @trainingTypeEasy.
  ///
  /// In en, this message translates to:
  /// **'Easy'**
  String get trainingTypeEasy;

  /// No description provided for @trainingTypeTempo.
  ///
  /// In en, this message translates to:
  /// **'Tempo'**
  String get trainingTypeTempo;

  /// No description provided for @trainingTypeInterval.
  ///
  /// In en, this message translates to:
  /// **'Intervals'**
  String get trainingTypeInterval;

  /// No description provided for @trainingTypeLongRun.
  ///
  /// In en, this message translates to:
  /// **'Long run'**
  String get trainingTypeLongRun;

  /// No description provided for @trainingTypeThreshold.
  ///
  /// In en, this message translates to:
  /// **'Threshold'**
  String get trainingTypeThreshold;

  /// No description provided for @paywallEyebrow.
  ///
  /// In en, this message translates to:
  /// **'YOUR PLAN'**
  String get paywallEyebrow;

  /// No description provided for @paywallPreviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Your training plan'**
  String get paywallPreviewTitle;

  /// No description provided for @paywallUnlockCta.
  ///
  /// In en, this message translates to:
  /// **'UNLOCK RUNCOACH PRO'**
  String get paywallUnlockCta;

  /// No description provided for @paywallNoDaysPlaceholder.
  ///
  /// In en, this message translates to:
  /// **'No sessions this week.'**
  String get paywallNoDaysPlaceholder;

  /// No description provided for @paywallLockedHint.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get paywallLockedHint;

  /// No description provided for @paywallWeekEyebrow.
  ///
  /// In en, this message translates to:
  /// **'WEEK {weekNumber}'**
  String paywallWeekEyebrow(int weekNumber);

  /// No description provided for @paywallWeekTotalKm.
  ///
  /// In en, this message translates to:
  /// **'{km} km total'**
  String paywallWeekTotalKm(String km);

  /// No description provided for @paywallManageSubscription.
  ///
  /// In en, this message translates to:
  /// **'Manage subscription'**
  String get paywallManageSubscription;

  /// No description provided for @paywallProBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO'**
  String get paywallProBadge;

  /// No description provided for @paywallProTrialBadge.
  ///
  /// In en, this message translates to:
  /// **'PRO · TRIAL'**
  String get paywallProTrialBadge;
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
