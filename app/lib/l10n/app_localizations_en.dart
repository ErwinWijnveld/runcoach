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

  @override
  String get onbFormGoalTypeTitle => 'What are you training for?';

  @override
  String get onbFormGoalTypeSubtitle =>
      'We\'ll tailor the plan around your answer.';

  @override
  String get onbFormGoalTypeRaceLabel => 'Train for a race';

  @override
  String get onbFormGoalTypeRaceSubtitle =>
      'You\'ve got a specific event on the horizon.';

  @override
  String get onbFormGoalTypePrLabel => 'Get faster at a distance';

  @override
  String get onbFormGoalTypePrSubtitle => 'Go after a personal record.';

  @override
  String get onbFormGoalTypeFitnessLabel => 'General fitness';

  @override
  String get onbFormGoalTypeFitnessSubtitle =>
      'Run regularly, no specific target.';

  @override
  String get onbFormGoalTypeWeightLossLabel => 'Weight loss';

  @override
  String get onbFormGoalTypeWeightLossSubtitle =>
      'Consistent running to steadily drop weight.';

  @override
  String get onbFormGoalTypeOtherHint => 'Describe what you\'re after…';

  @override
  String get onbFormDistanceTitle => 'What distance?';

  @override
  String get onbFormDistanceSubtitle => 'Pick the race or target distance.';

  @override
  String get onbFormDistance5k => '5K';

  @override
  String get onbFormDistance10k => '10K';

  @override
  String get onbFormDistanceHalf => 'Half marathon';

  @override
  String get onbFormDistanceMarathon => 'Marathon';

  @override
  String get onbFormDistanceOtherHint => 'Distance in kilometers';

  @override
  String get onbFormRaceNameTitle => 'What\'s the race called?';

  @override
  String get onbFormRaceNameSubtitle =>
      'Anything goes, we just use it as a label.';

  @override
  String get onbFormRaceNameHint => 'Rotterdam Marathon';

  @override
  String get onbFormRaceDateTitle => 'When\'s race day?';

  @override
  String get onbFormRaceDateSubtitle =>
      'We need at least a couple weeks to build a proper plan.';

  @override
  String get onbFormGoalTimeTitle =>
      'What goal time or pace are you aiming for?';

  @override
  String get onbFormGoalTimeSubtitle =>
      'Enter it however feels natural, we parse it.';

  @override
  String get onbFormGoalTimeHint => 'e.g. 1:45:00, 25:30, or 5:30/km';

  @override
  String get onbFormPrTitle => 'What\'s your current PR?';

  @override
  String get onbFormPrSubtitlePrefilled =>
      'Pre-filled from your fastest matching run in Apple Health. Adjust if needed.';

  @override
  String get onbFormPrSubtitleOptional =>
      'Optional, helps us gauge a realistic target.';

  @override
  String get onbFormPrHint => 'e.g. 1:52:00 or 5:45/km';

  @override
  String get onbFormGoalTimeParseError =>
      'Didn\'t quite catch that. Try 1:45:00 or 5:30/km.';

  @override
  String onbFormGoalTimePreview(String total, String paceSuffix) {
    return '≈ $total total$paceSuffix';
  }

  @override
  String onbFormGoalTimePreviewPaceSuffix(String pace) {
    return ' ($pace/km)';
  }

  @override
  String get onbFormDaysTitle => 'How many days per week?';

  @override
  String get onbFormDaysSubtitle =>
      'Be realistic. The plan is only as good as your consistency.';

  @override
  String get onbFormDays1Label => '1 day';

  @override
  String get onbFormDays1Sub => 'Keeps the habit alive.';

  @override
  String get onbFormDays2Label => '2 days';

  @override
  String get onbFormDays2Sub => 'Minimal but consistent.';

  @override
  String get onbFormDays3Label => '3 days';

  @override
  String get onbFormDays3Sub => 'A solid base to build on.';

  @override
  String get onbFormDays4Label => '4 days';

  @override
  String get onbFormDays4Sub => 'Great balance for most runners.';

  @override
  String get onbFormDays5Label => '5 days';

  @override
  String get onbFormDays5Sub => 'Solid block for serious goals.';

  @override
  String get onbFormDays6Label => '6 days';

  @override
  String get onbFormDays6Sub => 'High volume, for experienced runners.';

  @override
  String get onbFormDays7Label => '7 days';

  @override
  String get onbFormDays7Sub => 'Every day, only if recovery is dialed in.';

  @override
  String get onbFormDaysOtherHint => 'Tell me about your schedule…';

  @override
  String get onbFormWeekdaysTitle => 'Which weekdays can you run?';

  @override
  String get onbFormWeekdaysSubtitle =>
      'Optional — pick the days that work for you.';

  @override
  String get onbFormWeekdaysHintEnough => 'Leave empty if any day works.';

  @override
  String onbFormWeekdaysHintShort(int required, int count) {
    return 'Pick at least $required days (you chose $count).';
  }

  @override
  String get weekdayMon => 'Monday';

  @override
  String get weekdayTue => 'Tuesday';

  @override
  String get weekdayWed => 'Wednesday';

  @override
  String get weekdayThu => 'Thursday';

  @override
  String get weekdayFri => 'Friday';

  @override
  String get weekdaySat => 'Saturday';

  @override
  String get weekdaySun => 'Sunday';

  @override
  String get weekdayMonShort => 'Mon';

  @override
  String get weekdayTueShort => 'Tue';

  @override
  String get weekdayWedShort => 'Wed';

  @override
  String get weekdayThuShort => 'Thu';

  @override
  String get weekdayFriShort => 'Fri';

  @override
  String get weekdaySatShort => 'Sat';

  @override
  String get weekdaySunShort => 'Sun';

  @override
  String get onbFormRankTitle => 'Rank your favourite runs';

  @override
  String get onbFormRankSubtitle =>
      'Drag to reorder. Top ones get featured more, bottom ones less.';

  @override
  String get onbFormRankFooter =>
      'Long runs stay in the plan. Ranking them last just keeps them shorter.';

  @override
  String get runTypeEasyLabel => 'Easy runs';

  @override
  String get runTypeEasySub => 'Conversational pace, weekly bulk.';

  @override
  String get runTypeTempoLabel => 'Tempo runs';

  @override
  String get runTypeTempoSub => 'Sustained, comfortably hard effort.';

  @override
  String get runTypeIntervalLabel => 'Intervals';

  @override
  String get runTypeIntervalSub => 'Short hard reps with recovery.';

  @override
  String get runTypeLongRunLabel => 'Long runs';

  @override
  String get runTypeLongRunSub => 'Weekly endurance, builds stamina.';

  @override
  String get onbFormCoachStyleTitle => 'How should I coach you?';

  @override
  String get onbFormCoachStyleSubtitle =>
      'This shapes the tone of the plan and how I push you.';

  @override
  String get coachStyleBalancedLabel => 'Balanced';

  @override
  String get coachStyleBalancedSub => 'Structure, but with room to adapt.';

  @override
  String get coachStyleStrictLabel => 'Strict';

  @override
  String get coachStyleStrictSub => 'Hold me to it. Don\'t soften the plan.';

  @override
  String get coachStyleFlexibleLabel => 'Flexible';

  @override
  String get coachStyleFlexibleSub => 'Adapt to my life when things slip.';

  @override
  String get onbFormCoachStyleOtherHint =>
      'Describe how you want to be coached…';

  @override
  String get onbFormRunnerLevelTitle => 'How would you describe your running?';

  @override
  String get onbFormRunnerLevelSubtitle =>
      'This helps us tailor how we explain things.';

  @override
  String get runnerLevelBeginnerLabel => 'Beginner';

  @override
  String get runnerLevelBeginnerSub => 'Just started or returning';

  @override
  String get runnerLevelIntermediateLabel => 'Intermediate';

  @override
  String get runnerLevelIntermediateSub => 'Run regularly, race occasionally';

  @override
  String get runnerLevelAdvancedLabel => 'Advanced';

  @override
  String get runnerLevelAdvancedSub => 'Know your zones, race seriously';

  @override
  String get runnerLevelSubEliteLabel => 'Sub-Elite';

  @override
  String get runnerLevelSubEliteSub => 'Structured training, competitive';

  @override
  String get runnerLevelEliteLabel => 'Elite';

  @override
  String get runnerLevelEliteSub => 'Sponsored or top-level competing';

  @override
  String get onbFormIntensityTitle => 'How hard do you want this?';

  @override
  String get onbFormIntensitySubtitle =>
      'Bump up or down if you feel different — Standard matches what your goal calls for.';

  @override
  String get onbFormIntensityEyebrow => 'WEEKLY KM';

  @override
  String get onbFormIntensityCaptionEasy =>
      'Gentler bumps, lower peak. Sustainable.';

  @override
  String get onbFormIntensityCaptionStandard =>
      'Steady weekly progression. Auto-picked.';

  @override
  String get onbFormIntensityCaptionHarder =>
      'Steeper ramp, higher peak. Stay sharp.';

  @override
  String get intensityBiasEasyLabel => 'Take it easy';

  @override
  String get intensityBiasStandardLabel => 'Standard';

  @override
  String get intensityBiasHarderLabel => 'Push me harder';

  @override
  String get intensityBiasEasyShort => 'Easier';

  @override
  String get intensityBiasStandardShort => 'Standard';

  @override
  String get intensityBiasHarderShort => 'Harder';

  @override
  String get intensityBiasAutoPick => '(auto-pick)';

  @override
  String get onbFormReviewTitle => 'Ready to build your plan?';

  @override
  String get onbFormReviewSubtitle => 'Quick recap. I\'ll take it from here.';

  @override
  String get onbFormReviewCreateCta => 'CREATE MY PLAN';

  @override
  String get onbFormReviewExtraNotesLabel => 'Anything else for your coach?';

  @override
  String get onbFormReviewExtraNotesHint =>
      'Injuries, schedule quirks, anything to consider…';

  @override
  String get reviewRowGoal => 'Goal';

  @override
  String get reviewRowDistance => 'Distance';

  @override
  String get reviewRowRace => 'Race';

  @override
  String get reviewRowRaceDay => 'Race day';

  @override
  String get reviewRowGoalTime => 'Goal time';

  @override
  String get reviewRowCurrentPr => 'Current PR';

  @override
  String get reviewRowDaysPerWeek => 'Days / week';

  @override
  String get reviewRowPreferredDays => 'Preferred days';

  @override
  String get reviewRowCoachStyle => 'Coach style';

  @override
  String get reviewRowRunnerLevel => 'Running level';

  @override
  String get reviewRowIntensity => 'Intensity';

  @override
  String get reviewRowNotes => 'Notes';

  @override
  String get reviewGoalTypeRaceShort => 'Train for a race';

  @override
  String get reviewGoalTypePrShort => 'Chase a PR';

  @override
  String get reviewGoalTypeFitnessShort => 'General fitness';

  @override
  String get reviewGoalTypeWeightLossShort => 'Weight loss';
}
