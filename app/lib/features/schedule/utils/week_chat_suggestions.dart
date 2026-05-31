import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_week.dart';

typedef WeekChatSuggestion = ({
  IconData icon,
  String label,
  String subtitle,
  String prompt,
});

/// Build 1-3 contextual suggestions for the empty state of the
/// Schedule-week chat. Driven by the SHAPE of the week (not the runner)
/// — pick prompts that match what's in the plan this week (intervals,
/// long run, deload, etc.). All copy is localized via [l10n].
List<WeekChatSuggestion> weekChatSuggestions(
  AppLocalizations l10n,
  String localeTag,
  TrainingWeek week,
) {
  final days = week.trainingDays ?? const <TrainingDay>[];

  TrainingDay? intervalDay;
  TrainingDay? longRunDay;
  TrainingDay? raceDay;
  double maxKm = 0;

  for (final d in days) {
    if (d.type == 'interval' && intervalDay == null) intervalDay = d;
    if (d.type == 'long_run' && longRunDay == null) longRunDay = d;
    final km = d.targetKm ?? 0;
    if (km > maxKm) maxKm = km;
    // Race day shows up as type=tempo with goal_name as title — pace and
    // distance match the goal. Best heuristic we have without pulling
    // the goal: title looks like a race ("half", "marathon", "5k", or
    // any title that isn't the generic type label).
    final title = d.title.toLowerCase();
    if (d.type == 'tempo' &&
        (title.contains('marathon') ||
            title.contains('half') ||
            title.contains('race') ||
            title.contains('10k') ||
            title.contains('5k'))) {
      raceDay = d;
    }
  }

  final focus = week.focus.toLowerCase();
  final isDeload = focus.contains('deload') ||
      focus.contains('recovery') ||
      focus.contains('cutback') ||
      focus.contains('herstel');

  final picks = <WeekChatSuggestion>[];

  if (raceDay != null) {
    picks.add((
      icon: CupertinoIcons.flag_fill,
      label: l10n.weekChatSuggestionRaceDayPrep,
      subtitle: l10n.weekChatSuggestionRaceDayPrepSub,
      prompt: l10n.weekChatSuggestionRaceDayPrep,
    ));
  }

  if (intervalDay != null) {
    final dayName = _dayName(intervalDay.date, localeTag);
    picks.add((
      icon: CupertinoIcons.timer_fill,
      label: l10n.weekChatSuggestionIntervalPace(dayName),
      subtitle: l10n.weekChatSuggestionIntervalPaceSub,
      prompt: l10n.weekChatSuggestionIntervalPace(dayName),
    ));
  }

  if (longRunDay != null) {
    final dayName = _dayName(longRunDay.date, localeTag);
    picks.add((
      icon: CupertinoIcons.map_fill,
      label: l10n.weekChatSuggestionLongRunPace(dayName),
      subtitle: l10n.weekChatSuggestionLongRunPaceSub,
      prompt: l10n.weekChatSuggestionLongRunPace(dayName),
    ));
  }

  if (isDeload) {
    picks.add((
      icon: CupertinoIcons.moon_zzz_fill,
      label: l10n.weekChatSuggestionDeloadWhy,
      subtitle: l10n.weekChatSuggestionDeloadWhySub,
      prompt: l10n.weekChatSuggestionDeloadWhy,
    ));
  }

  if (picks.length < 3) {
    picks.add((
      icon: CupertinoIcons.exclamationmark_circle_fill,
      label: l10n.weekChatSuggestionTooHard,
      subtitle: l10n.weekChatSuggestionTooHardSub,
      prompt: l10n.weekChatSuggestionTooHard,
    ));
  }

  if (picks.length < 3 && intervalDay != null) {
    picks.add((
      icon: CupertinoIcons.arrow_2_squarepath,
      label: l10n.weekChatSuggestionSwapInterval,
      subtitle: l10n.weekChatSuggestionSwapIntervalSub,
      prompt: l10n.weekChatSuggestionSwapInterval,
    ));
  }

  return picks.take(3).toList(growable: false);
}

String _dayName(String dateIso, String localeTag) {
  final d = DateTime.tryParse(dateIso);
  if (d == null) return '';
  return DateFormat.EEEE(localeTag).format(d);
}
