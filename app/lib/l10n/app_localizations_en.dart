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
  String get commonContinue => 'Continue';

  @override
  String get commonTryAgain => 'Try again';

  @override
  String get commonRetry => 'Retry';

  @override
  String get commonSkip => 'Skip';

  @override
  String get commonRequired => 'Required';

  @override
  String get commonSaving => 'Saving…';

  @override
  String get commonOpenSettings => 'Open Settings';

  @override
  String get commonAppleHealth => 'Apple Health';

  @override
  String get commonEditedByYou => 'Edited by you';

  @override
  String commonFromSource(String source) {
    return 'From $source';
  }

  @override
  String get commonEditZones => 'Edit zones';

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

  @override
  String get onbConnectHealthIntroTitle => 'Connect Apple Health';

  @override
  String get onbConnectHealthIntroBody =>
      'We read your running workouts, heart-rate data, age, and resting heart rate so we can score your training and personalise your zones.';

  @override
  String get onbConnectHealthConnectCta => 'Connect Apple Health';

  @override
  String get onbConnectHealthSkipCta => 'Continue without syncing';

  @override
  String get onbConnectHealthFooter =>
      'Garmin, Polar and Strava are coming soon.';

  @override
  String get onbConnectHealthEmptyTitle => 'No runs found yet';

  @override
  String get onbConnectHealthEmptyBody =>
      'We couldn\'t read any running workouts from Apple Health. Either there aren\'t any in the last 12 months, or read access wasn\'t granted.';

  @override
  String get onbConnectHealthEmptyHint =>
      'If you DO have runs, open Settings → Health → Data Access & Devices → RunCoach and turn on Workouts + Heart Rate.';

  @override
  String get onbConnectHealthStageRequesting => 'Asking Apple Health…';

  @override
  String get onbConnectHealthStageRequestingSub =>
      'Tap \"Allow\" on the system prompt.';

  @override
  String get onbConnectHealthStageSyncing => 'Pulling your runs…';

  @override
  String get onbConnectHealthStageSyncingSub =>
      'Reading the last 12 months from Apple Health.';

  @override
  String onbConnectHealthStageDone(int count) {
    return 'Synced $count runs';
  }

  @override
  String get onbConnectHealthStageDoneSub => 'Building your profile…';

  @override
  String get onbConnectHealthErrorPermission =>
      'Couldn\'t reach Apple Health. Try again?';

  @override
  String get onbConnectHealthErrorRead =>
      'Couldn\'t read your runs from Apple Health. Try again?';

  @override
  String get onbConnectHealthErrorSync =>
      'We couldn\'t sync your runs to the server. Check your connection and try again.';

  @override
  String get onbConnectHealthErrorSettings =>
      'Couldn\'t open Settings automatically. Go to Settings → Health → Data Access & Devices → RunCoach.';

  @override
  String get onbOverviewTitlePrefilled => 'Your running baseline';

  @override
  String get onbOverviewTitleEmpty => 'Tell us about your running';

  @override
  String get onbOverviewSubtitlePrefilled =>
      'We use these to calibrate your training plan.';

  @override
  String get onbOverviewSubtitleEmpty =>
      'We need two numbers to build an accurate plan.';

  @override
  String get onbOverviewKmLabel => 'Average weekly km (last 4 weeks)';

  @override
  String get onbOverviewPaceLabel => 'Easy run pace';

  @override
  String get onbOverviewPaceTapPrompt => 'Tap to choose';

  @override
  String get onbOverviewLoadingTitle => 'Loading your baseline…';

  @override
  String get onbOverviewErrorTitle => 'We couldn\'t load your data.';

  @override
  String get onbZonesTitle => 'Your training zones';

  @override
  String onbZonesSubtitleDerivedCorrected(int maxHr) {
    return 'Based on your age and your hardest recent runs, your max heart rate looks to be around $maxHr bpm. We\'ve split that into 5 training zones.';
  }

  @override
  String onbZonesSubtitleDerivedBasic(int age, int maxHr) {
    return 'Estimated from your age ($age) — max around $maxHr bpm. After a few hard sessions or a race we\'ll refine these automatically.';
  }

  @override
  String get onbZonesSubtitleDerivedGeneric =>
      'Estimated from your age. Tap \"Edit zones\" if you know your true max HR.';

  @override
  String get onbZonesSubtitleManual =>
      'Your previously-saved zones. They\'ll be used to score every run.';

  @override
  String get onbZonesSubtitleDefault =>
      'We couldn\'t compute your zones automatically — please set your max HR before continuing.';

  @override
  String get onbZonesConfirmCta => 'Looks right';

  @override
  String get onbZonesDobLabel => 'Date of birth';

  @override
  String get onbZonesDobBody =>
      'We use your age to estimate heart-rate ranges for training feedback. You can fine-tune later from the menu.';

  @override
  String get onbZonesNoDobBody =>
      'To estimate your heart-rate ranges we just need your birth date. It gives us a rough max HR — accurate enough for daily training and easy to fine-tune later.';

  @override
  String get onbZonesShowAdvanced => 'Show zones (advanced)';

  @override
  String get onbZonesPickDobCta => 'Pick your birth date';

  @override
  String get onbGeneratingTitle => 'Building your plan';

  @override
  String get onbGeneratingStageAnalyzing => 'Analyzing your run history…';

  @override
  String get onbGeneratingStageStructuring =>
      'Designing your weekly structure…';

  @override
  String get onbGeneratingStagePlacing => 'Placing training sessions…';

  @override
  String get onbGeneratingStageFinalizing => 'Finalizing your plan…';

  @override
  String get onbGeneratingFooter =>
      'This can take a few minutes. Feel free to close the app — we\'ll send you a notification when your plan is ready.';

  @override
  String get onbGeneratingLoadingNext => 'Loading your plan…';

  @override
  String get onbGeneratingErrorTitle => 'Plan generation failed';

  @override
  String get onbGeneratingErrorNetwork =>
      'Couldn\'t reach the server. Check your connection.';

  @override
  String get onbGeneratingErrorLost =>
      'Lost track of the generation. Try again?';

  @override
  String get onbGeneratingErrorGeneric => 'Generation failed.';

  @override
  String get onbGeneratingErrorMissingId =>
      'Plan ready but conversation id missing.';

  @override
  String get onbGeneratingBackCta => 'Back to form';
}
