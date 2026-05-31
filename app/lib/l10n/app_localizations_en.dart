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
  String get runShareSheetCta => 'Share this run';

  @override
  String get runShareSheetSubtitle => 'Tap to save or share with friends';

  @override
  String get runShareInlineCta => 'Share this run';

  @override
  String get runShareBarrierLabel => 'Run summary';

  @override
  String get runShareKpiDistance => 'DISTANCE';

  @override
  String get runShareKpiTime => 'TIME';

  @override
  String get runShareKpiAvgPace => 'AVG PACE';

  @override
  String get runShareKpiAvgHr => 'AVG BPM';

  @override
  String get runShareKpiCompliance => 'ON-PLAN';

  @override
  String get runShareIndoorPill => 'INDOOR RUN';

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
  String onbConnectHealthStageSyncingProgress(int done, int total) {
    return 'Syncing $done of $total runs…';
  }

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

  @override
  String commonErrorWithMessage(String message) {
    return 'Error: $message';
  }

  @override
  String get commonToday => 'Today';

  @override
  String get commonTodayUpper => 'TODAY';

  @override
  String get commonTomorrow => 'Tomorrow';

  @override
  String get dashNoUpcomingRunEyebrow => 'NO UPCOMING RUN';

  @override
  String get dashNoUpcomingTitle => 'Plan complete';

  @override
  String get dashNoUpcomingSubtitle => 'All training days are logged.';

  @override
  String get dashThisWeekEyebrow => 'THIS WEEK';

  @override
  String dashWeeksMatrixEyebrow(int total) {
    return '$total WEEKS';
  }

  @override
  String dashRaceDayLabel(String raceName) {
    return 'Race day · $raceName';
  }

  @override
  String dashDaysToGoLabel(int days, String raceName) {
    return '${days}d · $raceName';
  }

  @override
  String dashWeeklySplitSuffix(String planned) {
    return ' / $planned km';
  }

  @override
  String get dashLegendDone => 'Done';

  @override
  String get dashLegendMissed => 'Missed';

  @override
  String get dashLegendUpcoming => 'Upcoming';

  @override
  String get dashEmptyTitle => 'No active plan';

  @override
  String get dashEmptyBody =>
      'Pick a goal (or ask the coach to build one) to see your training on the dashboard.';

  @override
  String get dashEmptyCta => 'Go to Goals';

  @override
  String get schedWeeklyPlanTitle => 'Weekly Plan';

  @override
  String get schedKmTotal => 'KM TOTAL';

  @override
  String get schedBackToToday => 'Back to today';

  @override
  String get schedNoTrainingWeek => 'No training week found';

  @override
  String get schedEmptyTitle => 'No active goal';

  @override
  String get schedEmptyBody =>
      'Pick a goal (or ask the coach to build one) to see its schedule here.';

  @override
  String get schedEmptyCta => 'Go to Goals';

  @override
  String get scheduleChatBarrierLabel => 'Schedule week chat';

  @override
  String scheduleChatViewingWeek(int weekNumber, String dateRange) {
    return 'Viewing week $weekNumber · $dateRange';
  }

  @override
  String scheduleChatTitle(int weekNumber, String dateRange) {
    return 'Week $weekNumber ($dateRange)';
  }

  @override
  String get scheduleChatEmptyTitle => 'Ask about this week';

  @override
  String get scheduleChatEmptySubtitle =>
      'Anything goes — pace, intensity, swaps, recovery.';

  @override
  String weekChatSuggestionIntervalPace(String dayName) {
    return 'How should I pace the intervals on $dayName?';
  }

  @override
  String get weekChatSuggestionIntervalPaceSub =>
      'Set the right effort for each rep.';

  @override
  String weekChatSuggestionLongRunPace(String dayName) {
    return 'How should I pace the long run on $dayName?';
  }

  @override
  String get weekChatSuggestionLongRunPaceSub => 'Stay aerobic, finish strong.';

  @override
  String get weekChatSuggestionDeloadWhy => 'Why is this week lighter?';

  @override
  String get weekChatSuggestionDeloadWhySub =>
      'Recovery weeks and how they help.';

  @override
  String get weekChatSuggestionRaceDayPrep =>
      'What should I do the day before the race?';

  @override
  String get weekChatSuggestionRaceDayPrepSub =>
      'Pre-race routine, food, sleep.';

  @override
  String get weekChatSuggestionTooHard => 'Is this week too hard for me?';

  @override
  String get weekChatSuggestionTooHardSub => 'Get an honest read on the load.';

  @override
  String get weekChatSuggestionSwapInterval =>
      'Can we swap an interval for a long run?';

  @override
  String get weekChatSuggestionSwapIntervalSub =>
      'Adjust this week\'s structure.';

  @override
  String get schedDayTarget => 'TARGET';

  @override
  String get schedDayActual => 'ACTUAL';

  @override
  String get schedDayDistance => 'DISTANCE';

  @override
  String get schedDayPace => 'PACE';

  @override
  String get schedDayPaceField => 'Pace';

  @override
  String get schedDayDuration => 'DURATION';

  @override
  String get schedDayHr => 'HEART';

  @override
  String get schedDayHrZone => 'HR ZONE';

  @override
  String get schedDayAvgHr => 'AVG HR';

  @override
  String get schedDayHeartRate => 'Heart rate';

  @override
  String get schedDayRecovery => 'Recovery';

  @override
  String get schedDayPaceCheckTitle => 'Pace check';

  @override
  String get schedDaySendToWatch => 'SEND TO WATCH';

  @override
  String get schedDaySendingToWatch => 'Sending to your watch…';

  @override
  String get schedDayAdjustWorkout => 'Adjust this workout';

  @override
  String get schedDayPickActivity => 'Pick activity';

  @override
  String get schedDayUnlinkActivity => 'Unlink activity';

  @override
  String get schedDayUnlinkConfirmTitle => 'Unlink activity?';

  @override
  String get schedDayUnlinkAction => 'Unlink';

  @override
  String get schedDayMoveItAction => 'Move it';

  @override
  String get schedDayRescheduleAction => 'Reschedule';

  @override
  String get schedDayCouldNotReschedule => 'Could not reschedule';

  @override
  String get commonOk => 'OK';

  @override
  String get commonCancel => 'Cancel';

  @override
  String get commonClose => 'Close';

  @override
  String get schedSectionIntervals => 'Intervals';

  @override
  String get schedSectionNotes => 'Notes';

  @override
  String get schedWatchNoDistanceBody =>
      'This workout has no distance set, so it can\'t be scheduled on the watch.';

  @override
  String get schedWatchNoStepsBody =>
      'This interval session has no work reps to send to the watch.';

  @override
  String get schedWatchSentTitle => 'Sent to your watch';

  @override
  String get schedWatchSentBody =>
      'Open the Fitness app on your iPhone or Apple Watch to start it.';

  @override
  String get schedWatchDuplicateTitle => 'Already scheduled';

  @override
  String get schedWatchDuplicateBody =>
      'You already have a workout planned for this day in the Fitness app.';

  @override
  String get schedWatchPermissionTitle => 'Permission needed';

  @override
  String get schedWatchPermissionBody =>
      'Allow workout scheduling in Settings → RunCoach to send this run to your watch.';

  @override
  String get schedWatchUnavailableTitle => 'Not available';

  @override
  String get schedWatchUnavailableBody =>
      'Sending workouts to the Apple Watch needs iOS 17 or newer.';

  @override
  String get schedWatchGenericError => 'Something went wrong. Try again.';

  @override
  String get schedWatchNothingToSendTitle => 'Nothing to send';

  @override
  String get schedWatchInvalidDateBody =>
      'This training day has an invalid date — try refreshing the schedule.';

  @override
  String get schedWatchFailedTitle => 'Couldn\'t send';

  @override
  String get commonDelete => 'Delete';

  @override
  String get commonNo => 'No';

  @override
  String get goalsListYourGoals => 'Your goals';

  @override
  String get goalsListOtherGoals => 'Other goals';

  @override
  String get goalsListEmptyTitle => 'No goals yet';

  @override
  String get goalsListEmptyBody =>
      'Ask the coach below to build your first training plan.';

  @override
  String get goalsCardActive => 'ACTIVE';

  @override
  String get goalsCardDistance => 'DISTANCE';

  @override
  String get goalsCardGoalTime => 'GOAL TIME';

  @override
  String get goalsCardTarget => 'TARGET';

  @override
  String get goalsCardDaysLeft => 'DAYS LEFT';

  @override
  String get goalsCardPast => 'PAST';

  @override
  String get goalsCardRaceDay => 'RACE DAY';

  @override
  String goalsCardDaysToGo(int days) {
    return '$days DAYS TO GO';
  }

  @override
  String get goalsCardSwitch => 'Switch';

  @override
  String get goalsSwitchTitle => 'Switch active goal?';

  @override
  String goalsSwitchBody(String name) {
    return 'Make \"$name\" your active goal. Your current active goal will be paused.';
  }

  @override
  String get goalsSwitchToThis => 'Switch to this goal';

  @override
  String get goalsSwitchToThisBody =>
      'Your current active goal will be paused.';

  @override
  String get goalsDeleteGoal => 'Delete goal';

  @override
  String goalsDeleteConfirmBody(String name) {
    return 'Are you sure you want to delete \"$name\"?';
  }

  @override
  String get goalsScheduleRowTitle => 'Training schedule';

  @override
  String get goalsScheduleRowSubtitle => 'Open your weekly plan';

  @override
  String get goalsScheduleRowSubtitlePreview =>
      'Preview the plan for this goal';

  @override
  String get commonError => 'Error';

  @override
  String get commonDone => 'Done';

  @override
  String get orgConnectionsTitle => 'Connections';

  @override
  String get orgSearchPlaceholder => 'Search gyms or clubs';

  @override
  String get orgAllOrganizations => 'All organizations';

  @override
  String get orgResults => 'Results';

  @override
  String get orgNoResults => 'No organizations match.';

  @override
  String get orgSectionActive => 'Active membership';

  @override
  String get orgSectionPendingInvites => 'Pending invitations';

  @override
  String get orgSectionPendingRequests => 'Pending requests';

  @override
  String get orgLeaveConfirmTitle => 'Leave organization?';

  @override
  String get orgLeaveConfirmBody =>
      'You will lose access to your coach and any plans they created.';

  @override
  String get orgLeaveAction => 'Leave';

  @override
  String get orgLeaveButton => 'Leave organization';

  @override
  String get orgLeftSuccess => 'Left organization';

  @override
  String orgRequestSent(String name) {
    return 'Request sent to $name';
  }

  @override
  String get orgFallbackName => 'Organization';

  @override
  String orgRoleLine(String role) {
    return 'Role: $role';
  }

  @override
  String orgCoachLine(String name) {
    return 'Coach: $name';
  }

  @override
  String orgInvitedAs(String role) {
    return 'Invited as $role';
  }

  @override
  String get orgAccept => 'Accept';

  @override
  String get orgReject => 'Reject';

  @override
  String get orgAwaitingApproval => 'Awaiting approval';

  @override
  String get orgJoin => 'Join';

  @override
  String get orgInviteTitle => 'You\'ve been invited';

  @override
  String get orgInviteBody =>
      'Tap accept to join the organization. You can review your active membership in Connections.';

  @override
  String get orgInviteAccept => 'Accept invitation';

  @override
  String get orgInviteLater => 'Not now';

  @override
  String get coachChatListTitle => 'Coach chat';

  @override
  String get coachChatListEmptyTitle => 'No conversations yet';

  @override
  String get coachChatListEmptySubtitle => 'Start a chat with your AI coach';

  @override
  String get coachChatNewTitle => 'New Chat';

  @override
  String get coachChatDeleteErrorTitle => 'Could not delete chat';

  @override
  String get coachChatDeleteErrorBody => 'Please try again.';

  @override
  String get coachThinking => 'Thinking';

  @override
  String get coachAskFullCoach => 'Ask the full coach';

  @override
  String get coachProposalRevisionEyebrow => 'PLAN REVISION';

  @override
  String coachProposalChanges(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.compact(
      locale: localeName,
    );
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString changes to your plan',
      one: '1 change to your plan',
    );
    return '$_temp0';
  }

  @override
  String get coachProposalRevisionBody =>
      'Tap below to review what changed before applying.';

  @override
  String get coachProposalWeeklyKm => 'WEEKLY KM';

  @override
  String get coachProposalWeeklyRuns => 'WEEKLY RUNS';

  @override
  String get coachProposalViewChanges => 'VIEW CHANGES';

  @override
  String get coachProposalViewDetails => 'VIEW DETAILS';

  @override
  String get coachProposalAccepted => 'Plan accepted.';

  @override
  String get coachProposalRejected => 'Rejected.';

  @override
  String get coachNewPlanCardCta => 'Start a fresh training plan';

  @override
  String get coachNewPlanCardEyebrow => 'NEW PLAN';

  @override
  String get coachNewPlanCardBody =>
      'I\'ll walk you through your goal, target date, and weekly cadence — your synced run history is already there.';

  @override
  String get coachNewPlanCardButton => 'START NEW PLAN';

  @override
  String get coachSuggestionCreatePlan => 'Create a training plan';

  @override
  String get coachSuggestionCreatePlanSub =>
      'For an upcoming race or new goal.';

  @override
  String get coachSuggestionAdjust => 'Adjust my schedule';

  @override
  String get coachSuggestionAnalyze => 'Analyze my progress';

  @override
  String get coachSuggestionAnalyzeSub => 'How am I trending lately?';

  @override
  String get coachSuggestionAnalyzePrompt =>
      'How is my training going? Give me an analysis of my progress.';

  @override
  String get coachSuggestionAdvice => 'Training advice';

  @override
  String get coachSuggestionAdviceSub => 'Pacing, recovery, nutrition, gear.';

  @override
  String get coachSuggestionAdvicePrompt =>
      'Got any running advice for me today?';

  @override
  String get coachSuggestionCreatePlanPrompt =>
      'I want to create a training plan for an upcoming race';

  @override
  String get coachSuggestionAdjustSub => 'Tweak this week\'s plan.';

  @override
  String get coachSuggestionAdjustPrompt =>
      'Can you adjust this week\'s training schedule?';

  @override
  String get coachEmptyStateTitle => 'What can I help you with?';

  @override
  String get coachEmptyStateSubtitle =>
      'I know your training history and can manage your schedule.';

  @override
  String get workoutChatAdjust => 'Adjust this workout';

  @override
  String get workoutChatAdjustSub => 'Distance, pace, intervals.';

  @override
  String get workoutChatWhatPlan => 'What\'s the plan';

  @override
  String get workoutChatWhatPlanSub => 'Why this workout, why today.';

  @override
  String get workoutChatPaceCheckSub => 'Is the target pace right for me?';

  @override
  String get workoutChatMoveIt => 'Move it';

  @override
  String get workoutChatMoveItSub => 'Reschedule to another day.';

  @override
  String get trainingResultUnlinkErrorBody =>
      'Couldn\'t unlink the activity. Please try again.';

  @override
  String get intervalKindWarmup => 'Warm up';

  @override
  String get intervalKindWork => 'Work';

  @override
  String get intervalKindRecovery => 'Recovery';

  @override
  String get intervalKindCooldown => 'Cool down';

  @override
  String get coachRoleYou => 'You';

  @override
  String get coachRoleAssistant => 'RunCore AI Coach';

  @override
  String get coachMessageRetry => 'Retry';

  @override
  String get coachStatsWeeklyAvgKm => 'WEEKLY\nAVG. KM';

  @override
  String get coachStatsWeeklyAvgRuns => 'WEEKLY\nAVG. RUNS';

  @override
  String get coachStatsAvgPace => 'AVG PACE';

  @override
  String get coachStatsSessionAvgTime => 'SESSION\nAVG. TIME';

  @override
  String get coachRevisionGoal => 'GOAL';

  @override
  String coachRevisionWeek(String number) {
    return 'WEEK $number';
  }

  @override
  String coachRevisionChangeCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count changes to your plan',
      one: '1 change to your plan',
    );
    return '$_temp0';
  }

  @override
  String get coachRevisionDayFallback => 'Day';

  @override
  String coachRevisionAddedOn(String day) {
    return 'Added on $day';
  }

  @override
  String coachRevisionRemovedSession(String day) {
    return 'Removed $day session';
  }

  @override
  String coachRevisionMovedTo(String day) {
    return 'Moved to $day';
  }

  @override
  String coachRevisionWasOn(String day) {
    return 'Was on $day';
  }

  @override
  String coachRevisionUpdatedDay(String day) {
    return 'Updated $day';
  }

  @override
  String get coachRevisionGoalUpdated => 'Goal details updated';

  @override
  String coachRevisionGoalFieldName(String value) {
    return 'Name: $value';
  }

  @override
  String coachRevisionGoalFieldDistance(String value) {
    return 'Distance: $value';
  }

  @override
  String coachRevisionGoalFieldDate(String value) {
    return 'Date: $value';
  }

  @override
  String coachRevisionGoalFieldGoalTime(String value) {
    return 'Goal time: $value';
  }

  @override
  String coachRevisionGoalFieldDays(String value) {
    return 'Days: $value';
  }

  @override
  String get coachRevisionRunFallback => 'Run';

  @override
  String get coachChipOrTypeOwn => 'or type your own';

  @override
  String get trainingResultHeader => 'Training result';

  @override
  String get trainingResultEyebrowCompliance => 'COMPLIANCE';

  @override
  String get trainingResultEyebrowTargetVsActual => 'TARGET VS ACTUAL';

  @override
  String get trainingResultEyebrowCoachFeedback => 'COACH FEEDBACK';

  @override
  String get trainingResultCompTarget => 'TARGET';

  @override
  String get trainingResultCompActual => 'ACTUAL';

  @override
  String get trainingResultRowDistance => 'Distance';

  @override
  String get trainingResultRowPace => 'Pace';

  @override
  String get trainingResultRowHeartRate => 'Heart rate';

  @override
  String trainingResultHrZoneTarget(int zone) {
    return 'Zone $zone';
  }

  @override
  String get trainingResultUnlinkConfirmTitle => 'Unlink activity?';

  @override
  String get trainingResultUnlinkConfirmBody =>
      'The run stays in Apple Health; it just stops being matched to this training day.';

  @override
  String get trainingResultUnlinkAction => 'Unlink';

  @override
  String get trainingResultUnlinkButton => 'Unlink activity';

  @override
  String get trainingResultUnlinkErrorTitle => 'Couldn\'t unlink';

  @override
  String get coachAnalysisEyebrow => 'COACH ANALYSIS';

  @override
  String get coachAnalysisCompliance => 'Compliance';

  @override
  String get coachAnalysisOpenCta => 'OPEN ANALYSIS';

  @override
  String get coachAnalysisAnalysing => 'Analysing your run…';

  @override
  String get selectActivityTitle => 'Pick an activity';

  @override
  String get selectActivitySubtitle =>
      'Runs from the last week, synced from Apple Health.';

  @override
  String get selectActivityLoadError => 'Couldn\'t load your activities.';

  @override
  String get selectActivityNoneRecent => 'No recent activities';

  @override
  String get selectActivityMatchErrorTitle => 'Couldn\'t match that run';

  @override
  String get selectActivitySyncedBadge => 'SYNCED';

  @override
  String get selectActivityNoneRecentDetail =>
      'Nothing synced from Apple Health in the past week.';

  @override
  String get rescheduleConfirmErrorTitle => 'Could not reschedule';

  @override
  String rescheduleMoveTo(String date) {
    return 'Move to $date';
  }

  @override
  String get wearableSummaryDistance => 'DISTANCE';

  @override
  String get wearableSummaryDuration => 'DURATION';

  @override
  String get wearableSummaryAvgHr => 'AVG HR';

  @override
  String get workoutChatEmptyTitle => 'Ask about this workout';

  @override
  String get workoutChatEmptySubtitle =>
      'I know your target stats, splits, and how it fits this week.';

  @override
  String get workoutChatAdjustPrompt =>
      'Can we tweak this workout? I\'d like to ';

  @override
  String get workoutChatWhatPlanPrompt =>
      'What\'s the purpose of this workout and what should I focus on?';

  @override
  String get workoutChatPaceCheck => 'Pace check';

  @override
  String get workoutChatPaceCheckPrompt =>
      'Is the target pace realistic based on my recent runs?';

  @override
  String get workoutChatMoveItPrompt => 'Can we move this workout to ';

  @override
  String get planDetailsGoalFallback => 'Your training plan';

  @override
  String get planDetailsEyebrowRevision => 'PLAN REVISION';

  @override
  String get planDetailsEyebrowRecommended => 'RECOMMENDED PLAN';

  @override
  String get planDetailsRevisionTitle => 'Review your changes';

  @override
  String get planDetailsBreakdownLabel => 'WEEKLY BREAKDOWN';

  @override
  String get planDetailsStatWeeks => 'WEEKS';

  @override
  String get planDetailsStatAvgKm => 'AVG KM / WEEK';

  @override
  String get planDetailsStatRunsPerWeek => 'RUNS / WEEK';

  @override
  String planDetailsWeekLabel(int number) {
    return 'Week $number';
  }

  @override
  String get planDetailsWeekFallback => 'Week';

  @override
  String get planDetailsKmTotal => 'KM TOTAL';

  @override
  String get planDetailsDayRun => 'Run';

  @override
  String get planDetailsFooterClose => 'CLOSE';

  @override
  String get planDetailsFooterAdjust => 'ADJUST';

  @override
  String get planDetailsFooterApplyChanges => 'APPLY CHANGES';

  @override
  String get planDetailsFooterAcceptPlan => 'ACCEPT PLAN';

  @override
  String get planDetailsFooterAdjustGoal => 'ADJUST GOAL FOR REALISTIC PLAN';

  @override
  String get planDetailsFooterAcceptAnyway => 'Accept anyway';

  @override
  String get planDetailsVolumeEyebrow => 'WEEKLY VOLUME';

  @override
  String planDetailsVolumePeak(String km, int week) {
    return 'Peak $km km · W$week';
  }

  @override
  String get planDetailsFeasibilityUnrealistic => 'Unrealistic';

  @override
  String get planDetailsFeasibilityStretch => 'Stretch';

  @override
  String get planDetailsFeasibilityOk => 'Good';

  @override
  String get commonSave => 'Save';

  @override
  String get commonConfirm => 'Confirm';

  @override
  String get commonRunnerFallback => 'Runner';

  @override
  String get profileMenuConnections => 'Connections';

  @override
  String get profileMenuAccount => 'Account';

  @override
  String get profileMenuHrZones => 'HR Zones';

  @override
  String get profileMenuPrivacy => 'Privacy';

  @override
  String get profileMenuAbout => 'About';

  @override
  String get profileMenuDeleteData => 'Delete data';

  @override
  String get profileMenuLogout => 'Log out';

  @override
  String get profileMenuDeleteConfirmTitle => 'Delete data';

  @override
  String get profileMenuDeleteConfirmBody =>
      'This deletes your account, goals, schedule, and chats. Cannot be undone.';

  @override
  String get profileMenuDeleteConfirmAction => 'Delete';

  @override
  String get profileMenuDeleteErrorTitle => 'Couldn\'t delete';

  @override
  String profileMenuDeleteErrorBody(String error) {
    return 'Please try again. ($error)';
  }

  @override
  String get profileMenuAccountTitle => 'Account';

  @override
  String get profileMenuFieldName => 'Name';

  @override
  String get profileMenuFieldEmail => 'Email';

  @override
  String get profileMenuFieldNameHint => 'Your name';

  @override
  String get profileMenuFieldNameEmptyError => 'Name cannot be empty';

  @override
  String get coachPromptBarPlaceholder => 'Ask your coach...';

  @override
  String get birthDatePickerTitle => 'Date of birth';

  @override
  String get birthDatePickerDone => 'Done';

  @override
  String lockedFieldFromSource(String source) {
    return 'From $source';
  }

  @override
  String get lockedFieldEditedByYou => 'Edited by you';

  @override
  String get lockedFieldOverrideTitle => 'Override Apple Health data?';

  @override
  String get lockedFieldOverrideBody =>
      'These values are calculated from your synced run history and are likely the most accurate signal we have. Editing them may result in a less accurate training plan.';

  @override
  String get lockedFieldEditAnyway => 'Edit anyway';

  @override
  String get paceWheelPickerTitle => 'Easy pace';

  @override
  String get paceWheelPickerDone => 'Done';

  @override
  String get hrZonesSheetTitle => 'HR Zones';

  @override
  String get hrZonesSheetIntro =>
      'Edit Max HR to recompute every zone, or change a boundary to update the adjacent zone.';

  @override
  String get hrZonesMaxHrLabel => 'Max HR';

  @override
  String get hrZonesRecomputeBusy => 'Recomputing…';

  @override
  String get hrZonesRecomputeCta => 'Recompute from your runs';

  @override
  String get hrZonesErrorMaxHrRange =>
      'Max HR must be between 100 and 250 bpm.';

  @override
  String get hrZonesErrorInvalidBpm => 'Enter valid bpm values (0-250).';

  @override
  String get hrZonesErrorNotAscending => 'Zones must be in ascending order.';

  @override
  String hrZonesErrorSaveFailed(String error) {
    return 'Could not save: $error';
  }

  @override
  String hrZonesUpdatedCorrected(int maxHr) {
    return 'Updated — max ~$maxHr bpm (age + your hardest recent runs).';
  }

  @override
  String hrZonesUpdatedDerivedAge(int maxHr, int age) {
    return 'Updated — max ~$maxHr bpm (estimated from age $age).';
  }

  @override
  String get hrZonesUpdatedGenericAge => 'Updated from your age.';

  @override
  String get notificationsSheetTitle => 'NOTIFICATIONS';

  @override
  String notificationsSheetLoadError(String error) {
    return 'Could not load notifications.\n$error';
  }

  @override
  String get notificationsSheetEmpty => 'You\'re all caught up.';

  @override
  String get notificationsCardDismiss => 'DISMISS';

  @override
  String get notificationsCardApply => 'APPLY';

  @override
  String get notificationsCardViewEvaluation => 'View your check-in';

  @override
  String get notificationsTypePlanEvaluation => '2-WEEK CHECK-IN';

  @override
  String get evaluationCardEyebrow => 'CHECK-IN';

  @override
  String evaluationCardScheduledFor(String date) {
    return 'Scheduled for $date';
  }

  @override
  String evaluationCardWeekTitle(int week) {
    return 'Week $week check-in';
  }

  @override
  String get evaluationCardStatusPending => 'Up next';

  @override
  String get evaluationCardStatusProcessing => 'Working on it…';

  @override
  String get evaluationCardStatusReady => 'Report ready';

  @override
  String get evaluationCardStatusNoChange => 'No changes needed';

  @override
  String get evaluationCardStatusAccepted => 'Applied';

  @override
  String get evaluationCardStatusDismissed => 'Dismissed';

  @override
  String get evaluationCardCtaView => 'Open';

  @override
  String get evaluationDetailTitle => '2-week check-in';

  @override
  String get evaluationDetailReportHeader => 'Your coach\'s take';

  @override
  String get evaluationDetailProposalHeader => 'Suggested adjustment';

  @override
  String get evaluationDetailApply => 'APPLY ADJUSTMENT';

  @override
  String get evaluationDetailDismiss => 'DISMISS';

  @override
  String get evaluationDetailClose => 'CLOSE';

  @override
  String get evaluationDetailNoReport => 'No report available yet.';

  @override
  String evaluationDetailLoadError(String error) {
    return 'Could not load this evaluation.\n$error';
  }

  @override
  String get hrZoneNameZ1 => 'Endurance';

  @override
  String get hrZoneNameZ2 => 'Moderate';

  @override
  String get hrZoneNameZ3 => 'Tempo';

  @override
  String get hrZoneNameZ4 => 'Threshold';

  @override
  String get hrZoneNameZ5 => 'Anaerobic';

  @override
  String get hrZoneBpm => 'bpm';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingsLanguageTitle => 'Language';

  @override
  String get settingsLanguageSubtitle => 'Choose how RunCoach speaks to you.';

  @override
  String get settingsLanguageAuto => 'System default';

  @override
  String get settingsLanguageAutoSubtitle =>
      'Follows your device language settings.';

  @override
  String get settingsLanguageEnglish => 'English';

  @override
  String get settingsLanguageDutch => 'Nederlands';

  @override
  String get settingsLanguageActiveBadge => 'ACTIVE';

  @override
  String weeklyPlanWeekRange(String start, String end) {
    return '$start – $end';
  }

  @override
  String weeklyPlanDayCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count runs',
      one: '1 run',
    );
    return '$_temp0';
  }

  @override
  String get bootPopupTitle => 'Action required';

  @override
  String bootPopupBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You have $count pending suggestions that need your attention.',
      one: 'You have 1 pending suggestion that needs your attention.',
    );
    return '$_temp0';
  }

  @override
  String get bootPopupLater => 'Later';

  @override
  String get bootPopupView => 'View';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabSchedule => 'Schedule';

  @override
  String get tabChat => 'Chat';

  @override
  String get tabGoals => 'Goals';

  @override
  String get trainingStatusMissed => 'MARKED AS MISSED';

  @override
  String get trainingStatusSynced => 'ACTIVITY SYNCED';

  @override
  String get trainingStatusAwaitingSync => 'AWAITING SYNC';

  @override
  String get trainingStatusUpcoming => 'RUN IS UPCOMING';

  @override
  String get trainingDayStatusMissed => 'MISSED';

  @override
  String get trainingDayStatusCompleted => 'COMPLETED';

  @override
  String get trainingDayStatusUpcoming => 'UPCOMING';

  @override
  String get workoutChatBarrierLabel => 'Close workout chat';

  @override
  String get trainingDayWatchCouldNotSend => 'Couldn\'t send';

  @override
  String get analyzingChipSyncingTitle => 'Syncing your runs';

  @override
  String get analyzingChipSyncingSubtitle =>
      'Pulling new runs from Apple Health…';

  @override
  String get analyzingChipMatchingTitle => 'Matching to your training plan';

  @override
  String get analyzingChipMatchingSubtitle => 'Just a moment…';

  @override
  String get analyzingChipAnalysingTitle => 'AI is analyzing your run';

  @override
  String get analyzingChipAnalysingSubtitle =>
      'Generating personalized feedback…';

  @override
  String get analyzingChipReadyTitle => 'Analysis ready';

  @override
  String analyzingChipReadyComplianceSubtitle(String score) {
    return 'Compliance $score/10';
  }

  @override
  String get analyzingChipReadyTapToView => 'Tap to view';

  @override
  String get analyzingChipLoggedTitle => 'Run logged';

  @override
  String get analyzingChipLoggedNoMatch => 'No matching training day';

  @override
  String get trainingResultNoResultYet => 'No result recorded yet.';

  @override
  String get goalDetailSectionTraining => 'Training';

  @override
  String get goalDetailSectionNotActive => 'Not active';

  @override
  String get chatErrorConnectionInterrupted =>
      'Connection interrupted. Tap retry.';

  @override
  String get chatErrorRequestTimedOut => 'Request timed out';

  @override
  String get chatErrorCannotReachServer => 'Cannot reach server';

  @override
  String chatErrorServerStatus(String status) {
    return 'Server error ($status)';
  }

  @override
  String get chatErrorUnknown => 'Unknown error';

  @override
  String get watchOnlyOnIos =>
      'Sending workouts to your watch is only available on iOS.';

  @override
  String get watchNativeBridgeError => 'Native bridge error.';

  @override
  String watchRecomputeFailed(String error) {
    return 'Couldn\'t recompute: $error';
  }

  @override
  String get toolIndicatorDefault => 'Working on it…';

  @override
  String get toolIndicatorGetRecentRuns => 'Looking up your recent runs…';

  @override
  String get toolIndicatorSearchActivities => 'Looking up your activities…';

  @override
  String get toolIndicatorGetActivityDetails => 'Digging into that run…';

  @override
  String get toolIndicatorGetCurrentSchedule => 'Loading your schedule…';

  @override
  String get toolIndicatorGetGoalInfo => 'Checking your goal…';

  @override
  String get toolIndicatorGetComplianceReport => 'Reviewing compliance…';

  @override
  String get toolIndicatorCreateSchedule => 'Building your training plan…';

  @override
  String get toolIndicatorEditSchedule => 'Revising your plan…';

  @override
  String get toolIndicatorModifySchedule => 'Adjusting your schedule…';

  @override
  String get toolIndicatorGetCurrentProposal => 'Reviewing the proposal…';

  @override
  String get toolIndicatorGetRunningProfile =>
      'Analysing your running history…';

  @override
  String get toolIndicatorPresentRunningStats => 'Preparing your stats…';

  @override
  String get toolIndicatorOfferChoices => 'Preparing options…';

  @override
  String get toolIndicatorEditWorkout => 'Adjusting this workout…';

  @override
  String get toolIndicatorRescheduleWorkout => 'Moving this workout…';

  @override
  String get toolIndicatorEscalateToCoach => 'Routing to your coach…';

  @override
  String get choiceGroupOther => 'Other';

  @override
  String get orgJoinedSnack => 'Joined organization';

  @override
  String get newChatTitle => 'New Chat';

  @override
  String get trainingCoachSuggestion1 => 'Move this run to tomorrow…';

  @override
  String get trainingCoachSuggestion2 => 'Make this easier, I feel tired…';

  @override
  String get trainingCoachSuggestion3 => 'Why is today\'s pace so fast?';

  @override
  String get trainingCoachSuggestion4 => 'Swap for a rest day instead…';

  @override
  String get trainingCoachSuggestion5 => 'Shorten this to 5km…';

  @override
  String get trainingCoachSuggestion6 => 'What if I skip the intervals?';

  @override
  String get trainingCoachSuggestion7 => 'Can I do this on the treadmill?';

  @override
  String get trainingCoachSuggestion8 => 'Explain the goal of this session…';

  @override
  String get scheduleCoachSuggestion1 => 'Change the easy run to interval...';

  @override
  String get scheduleCoachSuggestion2 => 'Move Monday workouts to Thursday...';

  @override
  String get scheduleCoachSuggestion3 => 'Am I improving at the right pace?';

  @override
  String get scheduleCoachSuggestion4 => 'Swap my long run to Saturday...';

  @override
  String get scheduleCoachSuggestion5 => 'Make this week a recovery week...';

  @override
  String get scheduleCoachSuggestion6 => 'Should I push harder this week?';

  @override
  String get scheduleCoachSuggestion7 =>
      'What\'s the goal of Wednesday\'s run?';

  @override
  String get scheduleCoachSuggestion8 => 'Cut one easy run, I need rest...';

  @override
  String get scheduleCoachSuggestion9 => 'Am I on track for my race?';

  @override
  String get scheduleCoachSuggestion10 => 'Explain the tempo session to me...';

  @override
  String get scheduleCoachSuggestion11 => 'Can we add a hill session?';

  @override
  String get scheduleCoachSuggestion12 => 'I felt wrecked yesterday, adjust...';

  @override
  String get goalCoachSuggestion1 => 'Train me for a marathon...';

  @override
  String get goalCoachSuggestion2 => 'Help me get faster at 10k...';

  @override
  String get goalCoachSuggestion3 => 'I have a half marathon in May...';

  @override
  String get goalCoachSuggestion4 => 'What\'s a realistic PR goal?';

  @override
  String get goalCoachSuggestion5 => 'Build a fitness plan for me...';

  @override
  String get goalCoachSuggestion6 => 'I want to break 45 at 10k...';

  @override
  String get goalCoachSuggestion7 => 'Get me race-ready in 12 weeks...';

  @override
  String get goalCoachSuggestion8 => 'Can we target a sub-4 marathon?';

  @override
  String get goalCoachSuggestion9 => 'Design a base-building block...';

  @override
  String get goalCoachSuggestion10 => 'Plan my next training cycle...';

  @override
  String get wearableActivityFallbackName => 'Run';

  @override
  String get trainingTypeEasy => 'Easy';

  @override
  String get trainingTypeTempo => 'Tempo';

  @override
  String get trainingTypeInterval => 'Intervals';

  @override
  String get trainingTypeLongRun => 'Long run';

  @override
  String get trainingTypeThreshold => 'Threshold';

  @override
  String get paywallEyebrow => 'YOUR PLAN';

  @override
  String get paywallPreviewTitle => 'Your training plan';

  @override
  String get paywallUnlockCta => 'UNLOCK RUNCOACH PRO';

  @override
  String get paywallNoDaysPlaceholder => 'No sessions this week.';

  @override
  String get paywallLockedHint => 'PRO';

  @override
  String paywallWeekEyebrow(int weekNumber) {
    return 'WEEK $weekNumber';
  }

  @override
  String paywallWeekTotalKm(String km) {
    return '$km km total';
  }

  @override
  String get paywallManageSubscription => 'Manage subscription';

  @override
  String get paywallProBadge => 'PRO';

  @override
  String get paywallProTrialBadge => 'PRO · TRIAL';

  @override
  String paywallLockedWeeksTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more weeks',
      one: '1 more week',
    );
    return '$_temp0';
  }

  @override
  String get paywallLockedWeeksSubtitle =>
      'Unlock RunCoach Pro to see your full plan';
}
