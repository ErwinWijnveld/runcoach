import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show
        Colors,
        Material,
        ReorderableDragStartListener,
        ReorderableListView;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/i18n/build_context_l10n.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/l10n/app_localizations.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/onboarding/widgets/choice_group.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_chart.dart';
import 'package:app/features/onboarding/widgets/intensity_bias_segmented_control.dart';
import 'package:app/features/onboarding/widgets/step_scaffold.dart';
import 'package:app/features/push/services/push_service.dart';
import 'package:app/features/wearable/data/wearable_api.dart';

/// Logical step identifiers. The concrete list shown to the user is
/// computed from `goalType` (see `_flowFor`).
enum _Step {
  goalType,
  distance,
  raceName,
  raceDate,
  goalTime,
  prCurrent,
  daysPerWeek,
  preferredWeekdays,
  runTypePreferences,
  coachStyle,
  runnerLevel,
  intensity,
  review,
}

List<_Step> _flowFor(OnboardingGoalType? goalType) {
  return switch (goalType) {
    OnboardingGoalType.race => const [
        _Step.goalType,
        _Step.distance,
        _Step.raceName,
        _Step.raceDate,
        _Step.goalTime,
        _Step.daysPerWeek,
        _Step.preferredWeekdays,
        _Step.runTypePreferences,
        _Step.coachStyle,
        _Step.runnerLevel,
        _Step.intensity,
        _Step.review,
      ],
    OnboardingGoalType.pr => const [
        _Step.goalType,
        _Step.distance,
        _Step.goalTime,
        _Step.prCurrent,
        _Step.daysPerWeek,
        _Step.preferredWeekdays,
        _Step.runTypePreferences,
        _Step.coachStyle,
        _Step.runnerLevel,
        _Step.intensity,
        _Step.review,
      ],
    OnboardingGoalType.fitness ||
    OnboardingGoalType.weightLoss ||
    null => const [
        _Step.goalType,
        _Step.daysPerWeek,
        _Step.preferredWeekdays,
        _Step.runTypePreferences,
        _Step.coachStyle,
        _Step.runnerLevel,
        _Step.intensity,
        _Step.review,
      ],
  };
}

class OnboardingFormScreen extends ConsumerStatefulWidget {
  /// Optional logical step name to enter the form at. `null` (default) means
  /// goal-type step. Used by the in-chat "Start new plan" card to drop a
  /// returning user into the form at the goal-type step but with the
  /// previously-saved form fields wiped (a fresh plan, not a resumed draft).
  ///
  /// Valid values mirror the `_Step` enum names in snake_case:
  /// `goal_type` / `distance` / `race_name` / `race_date` / `goal_time` /
  /// `pr_current` / `days_per_week` / `preferred_weekdays` /
  /// `run_type_preferences` / `coach_style` / `review`.
  final String? startStep;

  const OnboardingFormScreen({super.key, this.startStep});

  @override
  ConsumerState<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends ConsumerState<OnboardingFormScreen> {
  int _currentIndex = 0;

  static const _stepFromName = <String, _Step>{
    'goal_type': _Step.goalType,
    'distance': _Step.distance,
    'race_name': _Step.raceName,
    'race_date': _Step.raceDate,
    'goal_time': _Step.goalTime,
    'pr_current': _Step.prCurrent,
    'days_per_week': _Step.daysPerWeek,
    'preferred_weekdays': _Step.preferredWeekdays,
    'run_type_preferences': _Step.runTypePreferences,
    'coach_style': _Step.coachStyle,
    'runner_level': _Step.runnerLevel,
    'intensity': _Step.intensity,
    'review': _Step.review,
  };

  @override
  void initState() {
    super.initState();
    final entry = widget.startStep;
    if (entry == null) return;
    // Returning user re-entry (via the in-chat "Start new plan" card):
    // wipe any saved draft from a previous form pass so the fields don't
    // pre-fill with stale state. Done in a post-frame callback because the
    // form provider can't be mutated during the build phase of initState.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.invalidate(onboardingFormProvider);
      final step = _stepFromName[entry];
      if (step == null) return;
      // Locate the step in the default (no-goal-type-yet) flow. Once the
      // runner picks a goal type the flow re-shapes; we don't need to map
      // beyond the goal-type step in practice (that's the only documented
      // entry point), but the table keeps the helper general.
      final flow = _flowFor(ref.read(onboardingFormProvider).goalType);
      final idx = flow.indexOf(step);
      if (idx >= 0) setState(() => _currentIndex = idx);
    });
  }

  void _advance() {
    final flow = _flowFor(ref.read(onboardingFormProvider).goalType);
    if (_currentIndex < flow.length - 1) {
      setState(() => _currentIndex++);
    }
  }

  void _goBack() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    } else if (context.canPop()) {
      context.pop();
    }
  }

  void _submit() {
    // Ask for push permission at the moment the user commits to generating
    // a plan. Apple's prompt is one-shot — asking earlier (e.g. on first
    // launch) tanks opt-in, asking now lines up with a clear value: getting
    // notified when the plan is ready ~60–110s later.
    // Fire-and-forget; we navigate immediately.
    ref.read(pushServiceProvider).requestPermissionAndRegister();
    context.go('/onboarding/generating');
  }

  @override
  Widget build(BuildContext context) {
    final form = ref.watch(onboardingFormProvider);
    final flow = _flowFor(form.goalType);
    final safeIndex = _currentIndex.clamp(0, flow.length - 1);
    final step = flow[safeIndex];

    return switch (step) {
      _Step.goalType => _GoalTypeStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.distance => _DistanceStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.raceName => _RaceNameStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.raceDate => _RaceDateStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.goalTime => _GoalTimeStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.prCurrent => _PrCurrentStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.daysPerWeek => _DaysPerWeekStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.preferredWeekdays => _PreferredWeekdaysStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.runTypePreferences => _RunTypePreferencesStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.coachStyle => _CoachStyleStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.runnerLevel => _RunnerLevelStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.intensity => _IntensityStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onContinue: _advance,
          onBack: _goBack,
        ),
      _Step.review => _ReviewStep(
          stepIndex: safeIndex,
          stepCount: flow.length,
          form: form,
          onSubmit: _submit,
          onBack: _goBack,
        ),
    };
  }
}

// ---- Step 1: goal type ----

class _GoalTypeStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _GoalTypeStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_GoalTypeStep> createState() => _GoalTypeStepState();
}

class _GoalTypeStepState extends ConsumerState<_GoalTypeStep> {
  late final TextEditingController _notesCtrl =
      TextEditingController(text: widget.form.notes ?? '');
  bool _otherSelected = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(onboardingFormProvider.notifier);
    final goalType = widget.form.goalType;

    final canContinue = !_otherSelected
        ? goalType != null
        : _notesCtrl.text.trim().isNotEmpty;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormGoalTypeTitle,
      subtitle: l10n.onbFormGoalTypeSubtitle,
      canContinue: canContinue,
      onContinue: () {
        if (_otherSelected) {
          notifier.setGoalType(OnboardingGoalType.fitness);
          notifier.setNotes(_notesCtrl.text.trim());
        }
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: ChoiceGroup<OnboardingGoalType>(
        options: [
          ChoiceOption(
            value: OnboardingGoalType.race,
            label: l10n.onbFormGoalTypeRaceLabel,
            subtitle: l10n.onbFormGoalTypeRaceSubtitle,
          ),
          ChoiceOption(
            value: OnboardingGoalType.pr,
            label: l10n.onbFormGoalTypePrLabel,
            subtitle: l10n.onbFormGoalTypePrSubtitle,
          ),
          ChoiceOption(
            value: OnboardingGoalType.fitness,
            label: l10n.onbFormGoalTypeFitnessLabel,
            subtitle: l10n.onbFormGoalTypeFitnessSubtitle,
          ),
          ChoiceOption(
            value: OnboardingGoalType.weightLoss,
            label: l10n.onbFormGoalTypeWeightLossLabel,
            subtitle: l10n.onbFormGoalTypeWeightLossSubtitle,
          ),
        ],
        selected: _otherSelected ? null : goalType,
        onSelected: (v) {
          setState(() => _otherSelected = false);
          notifier.setGoalType(v);
          notifier.setNotes(null);
        },
        otherSelected: _otherSelected,
        onOtherTapped: () => setState(() {
          _otherSelected = true;
        }),
        otherChild: _NotesField(
          controller: _notesCtrl,
          hint: l10n.onbFormGoalTypeOtherHint,
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}

// ---- Step 2: distance ----

class _DistanceStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _DistanceStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_DistanceStep> createState() => _DistanceStepState();
}

class _DistanceStepState extends ConsumerState<_DistanceStep> {
  bool _otherSelected = false;
  late final TextEditingController _kmCtrl = TextEditingController(
    text: _prefillKm(widget.form.distanceMeters),
  );

  String _prefillKm(int? meters) {
    if (meters == null) return '';
    const common = {5000, 10000, 21097, 42195};
    if (common.contains(meters)) return '';
    return (meters / 1000).toStringAsFixed(1);
  }

  @override
  void initState() {
    super.initState();
    const common = {5000, 10000, 21097, 42195};
    if (widget.form.distanceMeters != null &&
        !common.contains(widget.form.distanceMeters)) {
      _otherSelected = true;
    }
  }

  @override
  void dispose() {
    _kmCtrl.dispose();
    super.dispose();
  }

  int? _kmAsMeters() {
    final v = double.tryParse(_kmCtrl.text.replaceAll(',', '.'));
    if (v == null || v < 1 || v > 1000) return null;
    return (v * 1000).round();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = _otherSelected ? null : widget.form.distanceMeters;

    final canContinue =
        !_otherSelected ? selected != null : _kmAsMeters() != null;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormDistanceTitle,
      subtitle: l10n.onbFormDistanceSubtitle,
      canContinue: canContinue,
      onContinue: () {
        if (_otherSelected) {
          final meters = _kmAsMeters();
          if (meters != null) notifier.setDistance(meters);
        }
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: ChoiceGroup<int>(
        options: [
          ChoiceOption(value: 5000, label: l10n.onbFormDistance5k),
          ChoiceOption(value: 10000, label: l10n.onbFormDistance10k),
          ChoiceOption(value: 21097, label: l10n.onbFormDistanceHalf),
          ChoiceOption(value: 42195, label: l10n.onbFormDistanceMarathon),
        ],
        selected: selected,
        onSelected: (v) {
          setState(() => _otherSelected = false);
          notifier.setDistance(v);
        },
        otherSelected: _otherSelected,
        onOtherTapped: () => setState(() {
          _otherSelected = true;
        }),
        otherChild: _NumberField(
          controller: _kmCtrl,
          hint: l10n.onbFormDistanceOtherHint,
          suffix: 'km',
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}

// ---- Step 3: race name ----

class _RaceNameStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _RaceNameStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_RaceNameStep> createState() => _RaceNameStepState();
}

class _RaceNameStepState extends ConsumerState<_RaceNameStep> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.form.goalName ?? '');

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(onboardingFormProvider.notifier);
    final canContinue = _ctrl.text.trim().isNotEmpty;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormRaceNameTitle,
      subtitle: l10n.onbFormRaceNameSubtitle,
      canContinue: canContinue,
      onSkip: () {
        notifier.setGoalName(null);
        widget.onContinue();
      },
      onContinue: () {
        notifier.setGoalName(_ctrl.text.trim());
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: _TextField(
        controller: _ctrl,
        hint: l10n.onbFormRaceNameHint,
        onChanged: (_) => setState(() {}),
      ),
    );
  }
}

// ---- Step 4: race date ----

class _RaceDateStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _RaceDateStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_RaceDateStep> createState() => _RaceDateStepState();
}

class _RaceDateStepState extends ConsumerState<_RaceDateStep> {
  late DateTime _selected = _initial();

  DateTime _initial() {
    if (widget.form.targetDate != null) {
      return DateTime.parse(widget.form.targetDate!);
    }
    return DateTime.now().add(const Duration(days: 56));
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final today = DateTime.now();
    final minDate = DateTime(today.year, today.month, today.day).add(const Duration(days: 14));

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormRaceDateTitle,
      subtitle: l10n.onbFormRaceDateSubtitle,
      canContinue: _selected.isAfter(today),
      onContinue: () {
        notifier.setTargetDate(_formatIso(_selected));
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: SizedBox(
          height: 220,
          child: CupertinoDatePicker(
            mode: CupertinoDatePickerMode.date,
            initialDateTime: _selected.isBefore(minDate) ? minDate : _selected,
            minimumDate: minDate,
            maximumDate: today.add(const Duration(days: 365 * 2)),
            onDateTimeChanged: (d) => setState(() => _selected = d),
          ),
        ),
      ),
    );
  }

  String _formatIso(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }
}

// ---- Step 5: goal time ----

class _GoalTimeStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _GoalTimeStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_GoalTimeStep> createState() => _GoalTimeStepState();
}

class _GoalTimeStepState extends ConsumerState<_GoalTimeStep> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.form.goalTimeSeconds == null
        ? ''
        : _formatSecondsToHuman(widget.form.goalTimeSeconds!),
  );

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final parsed = parseGoalTimeInput(_ctrl.text, widget.form.distanceMeters);

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormGoalTimeTitle,
      subtitle: l10n.onbFormGoalTimeSubtitle,
      canContinue: parsed != null,
      onSkip: () {
        widget.onContinue();
      },
      onContinue: () {
        if (parsed != null) notifier.setGoalTime(parsed);
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TextField(
            controller: _ctrl,
            hint: l10n.onbFormGoalTimeHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _SuggestionChips(
            distanceMeters: widget.form.distanceMeters,
            currentText: _ctrl.text,
            onTap: (s) {
              setState(() {
                _ctrl.text = s;
                _ctrl.selection = TextSelection.collapsed(offset: s.length);
              });
            },
          ),
          const SizedBox(height: 10),
          _GoalTimePreview(
            text: _ctrl.text,
            parsedSeconds: parsed,
            distanceMeters: widget.form.distanceMeters,
          ),
        ],
      ),
    );
  }
}

// ---- Step 6: current PR (pr flow only) ----

class _PrCurrentStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _PrCurrentStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_PrCurrentStep> createState() => _PrCurrentStepState();
}

class _PrCurrentStepState extends ConsumerState<_PrCurrentStep> {
  late final TextEditingController _ctrl = TextEditingController(
    text: widget.form.prCurrentSeconds == null
        ? ''
        : _formatSecondsToHuman(widget.form.prCurrentSeconds!),
  );
  bool _prefillApplied = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final parsed = parseGoalTimeInput(_ctrl.text, widget.form.distanceMeters);

    // Pre-fill with HealthKit PR at the chosen distance. Same one-shot
    // pattern as _GoalTimeStep — never clobber user input.
    final distanceMeters = widget.form.distanceMeters;
    if (distanceMeters != null && !_prefillApplied && _ctrl.text.trim().isEmpty) {
      ref.listen(personalRecordForDistanceProvider(distanceMeters), (_, next) {
        next.whenData((pr) {
          if (!mounted || _prefillApplied) return;
          if (_ctrl.text.trim().isNotEmpty) return;
          if (pr == null) return;
          final seconds = pr['duration_seconds'] as int?;
          if (seconds == null) return;
          setState(() {
            _ctrl.text = _formatSecondsToHuman(seconds);
            _prefillApplied = true;
            notifier.setPrCurrent(seconds);
          });
        });
      });
      ref.watch(personalRecordForDistanceProvider(distanceMeters));
    }

    final prAsync = distanceMeters == null
        ? null
        : ref.watch(personalRecordForDistanceProvider(distanceMeters));
    final prSeconds = prAsync?.value?['duration_seconds'] as int?;

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormPrTitle,
      subtitle: prSeconds != null
          ? l10n.onbFormPrSubtitlePrefilled
          : l10n.onbFormPrSubtitleOptional,
      canContinue: _ctrl.text.trim().isEmpty || parsed != null,
      onSkip: () {
        notifier.setPrCurrent(null);
        widget.onContinue();
      },
      onContinue: () {
        notifier.setPrCurrent(parsed);
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _TextField(
            controller: _ctrl,
            hint: l10n.onbFormPrHint,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          _SuggestionChips(
            distanceMeters: widget.form.distanceMeters,
            currentText: _ctrl.text,
            onTap: (s) {
              setState(() {
                _ctrl.text = s;
                _ctrl.selection = TextSelection.collapsed(offset: s.length);
              });
            },
          ),
          const SizedBox(height: 10),
          _GoalTimePreview(
            text: _ctrl.text,
            parsedSeconds: parsed,
            distanceMeters: widget.form.distanceMeters,
          ),
        ],
      ),
    );
  }
}

// ---- Step 7: days per week ----

class _DaysPerWeekStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _DaysPerWeekStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_DaysPerWeekStep> createState() => _DaysPerWeekStepState();
}

class _DaysPerWeekStepState extends ConsumerState<_DaysPerWeekStep> {
  bool _otherSelected = false;
  late final TextEditingController _notesCtrl =
      TextEditingController(text: widget.form.notes ?? '');

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = _otherSelected ? null : widget.form.daysPerWeek;

    final canContinue = _otherSelected
        ? _notesCtrl.text.trim().isNotEmpty
        : selected != null;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormDaysTitle,
      subtitle: l10n.onbFormDaysSubtitle,
      canContinue: canContinue,
      onContinue: () {
        if (_otherSelected) {
          notifier.setNotes(_notesCtrl.text.trim());
        }
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: ChoiceGroup<int>(
        options: [
          ChoiceOption(value: 1, label: l10n.onbFormDays1Label, subtitle: l10n.onbFormDays1Sub),
          ChoiceOption(value: 2, label: l10n.onbFormDays2Label, subtitle: l10n.onbFormDays2Sub),
          ChoiceOption(value: 3, label: l10n.onbFormDays3Label, subtitle: l10n.onbFormDays3Sub),
          ChoiceOption(value: 4, label: l10n.onbFormDays4Label, subtitle: l10n.onbFormDays4Sub),
          ChoiceOption(value: 5, label: l10n.onbFormDays5Label, subtitle: l10n.onbFormDays5Sub),
          ChoiceOption(value: 6, label: l10n.onbFormDays6Label, subtitle: l10n.onbFormDays6Sub),
          ChoiceOption(value: 7, label: l10n.onbFormDays7Label, subtitle: l10n.onbFormDays7Sub),
        ],
        selected: selected,
        onSelected: (v) {
          setState(() => _otherSelected = false);
          notifier.setDaysPerWeek(v);
          notifier.setNotes(null);
        },
        otherSelected: _otherSelected,
        onOtherTapped: () => setState(() {
          _otherSelected = true;
        }),
        otherChild: _NotesField(
          controller: _notesCtrl,
          hint: l10n.onbFormDaysOtherHint,
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}

// ---- Step: preferred weekdays (multi-select) ----

class _PreferredWeekdaysStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _PreferredWeekdaysStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_PreferredWeekdaysStep> createState() =>
      _PreferredWeekdaysStepState();
}

class _PreferredWeekdaysStepState
    extends ConsumerState<_PreferredWeekdaysStep> {
  late final Set<int> _selected = {...?widget.form.preferredWeekdays};

  List<({int iso, String label, String short})> _daysFor(AppLocalizations l) => [
        (iso: 1, label: l.weekdayMon, short: l.weekdayMonShort),
        (iso: 2, label: l.weekdayTue, short: l.weekdayTueShort),
        (iso: 3, label: l.weekdayWed, short: l.weekdayWedShort),
        (iso: 4, label: l.weekdayThu, short: l.weekdayThuShort),
        (iso: 5, label: l.weekdayFri, short: l.weekdayFriShort),
        (iso: 6, label: l.weekdaySat, short: l.weekdaySatShort),
        (iso: 7, label: l.weekdaySun, short: l.weekdaySunShort),
      ];

  void _toggle(int iso) {
    setState(() {
      if (_selected.contains(iso)) {
        _selected.remove(iso);
      } else {
        _selected.add(iso);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final notifier = ref.read(onboardingFormProvider.notifier);
    final daysPerWeek = widget.form.daysPerWeek ?? 0;
    final count = _selected.length;
    final enough = count == 0 || count >= daysPerWeek;
    final canContinue = enough;

    final hint = (count > 0 && count < daysPerWeek)
        ? l10n.onbFormWeekdaysHintShort(daysPerWeek, count)
        : l10n.onbFormWeekdaysHintEnough;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormWeekdaysTitle,
      subtitle: l10n.onbFormWeekdaysSubtitle,
      canContinue: canContinue,
      onSkip: () {
        notifier.setPreferredWeekdays(null);
        widget.onContinue();
      },
      onContinue: () {
        notifier.setPreferredWeekdays(
          _selected.isEmpty ? null : _selected.toList(),
        );
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ..._daysFor(l10n).map((d) {
            final selected = _selected.contains(d.iso);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _WeekdayTile(
                label: d.label,
                short: d.short,
                selected: selected,
                onTap: () => _toggle(d.iso),
              ),
            );
          }),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              hint,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekdayTile extends StatelessWidget {
  final String label;
  final String short;
  final bool selected;
  final VoidCallback onTap;

  const _WeekdayTile({
    required this.label,
    required this.short,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryInk : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryInk : AppColors.inputBorder,
          ),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(
                short,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: selected ? AppColors.cream : AppColors.inkMuted,
                ),
              ),
            ),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primaryInk,
                ),
              ),
            ),
            Icon(
              selected
                  ? CupertinoIcons.check_mark_circled_solid
                  : CupertinoIcons.circle,
              size: 22,
              color: selected ? AppColors.gold : AppColors.inputBorder,
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Step: rank favourite run types (drag to reorder) ----

class _RunTypePreferencesStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _RunTypePreferencesStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_RunTypePreferencesStep> createState() =>
      _RunTypePreferencesStepState();
}

class _RunTypePreferencesStepState
    extends ConsumerState<_RunTypePreferencesStep> {
  /// Default ordering used both as the starting state and as the fallback
  /// when the runner skips. Index 0 = currently in "gold" position.
  static const List<RunTypePreferenceOption> _defaultOrder = [
    RunTypePreferenceOption.easy,
    RunTypePreferenceOption.tempo,
    RunTypePreferenceOption.interval,
    RunTypePreferenceOption.longRun,
  ];

  late List<RunTypePreferenceOption> _order;

  @override
  void initState() {
    super.initState();
    final existing = widget.form.runTypePreferences;
    if (existing == null || existing.isEmpty) {
      _order = List.of(_defaultOrder);
    } else {
      // Honour stored order; append any missing types at the end so the
      // list always covers all four options.
      final seen = <RunTypePreferenceOption>{};
      final ordered = <RunTypePreferenceOption>[];
      for (final option in existing) {
        if (seen.add(option)) ordered.add(option);
      }
      for (final option in _defaultOrder) {
        if (seen.add(option)) ordered.add(option);
      }
      _order = ordered;
    }
  }

  void _handleReorder(int oldIndex, int newIndex) {
    setState(() {
      var to = newIndex;
      if (to > oldIndex) to -= 1;
      final moved = _order.removeAt(oldIndex);
      _order.insert(to, moved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormRankTitle,
      subtitle: l10n.onbFormRankSubtitle,
      canContinue: true,
      onSkip: () {
        notifier.setRunTypePreferences(null);
        widget.onContinue();
      },
      onContinue: () {
        notifier.setRunTypePreferences(_order);
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ReorderableListView(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            buildDefaultDragHandles: false,
            proxyDecorator: (child, index, animation) => Material(
              color: const Color(0x00000000),
              child: child,
            ),
            onReorder: _handleReorder,
            children: [
              for (var i = 0; i < _order.length; i++)
                Padding(
                  key: ValueKey(_order[i]),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RunTypeRankCard(
                    rank: i + 1,
                    option: _order[i],
                    listIndex: i,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              l10n.onbFormRankFooter,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.inkMuted,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RunTypeRankCard extends StatelessWidget {
  final int rank;
  final RunTypePreferenceOption option;
  final int listIndex;

  const _RunTypeRankCard({
    required this.rank,
    required this.option,
    required this.listIndex,
  });

  @override
  Widget build(BuildContext context) {
    final (label, hint) = _meta(context.l10n, option);

    // Wrapping the WHOLE card in ReorderableDragStartListener makes the
    // entire surface draggable instead of forcing the user to hit the
    // small handle icon. Uses immediate-drag (no long press required).
    return ReorderableDragStartListener(
      index: listIndex,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.inputBorder),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 32,
              child: Text(
                '#$rank',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryInk,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primaryInk,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    hint,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            // Decorative drag affordance — the whole card is the drag
            // target now, the icon is just a visual hint.
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 4),
              child: Icon(
                CupertinoIcons.line_horizontal_3,
                size: 22,
                color: AppColors.inkMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static (String, String) _meta(AppLocalizations l, RunTypePreferenceOption option) {
    return switch (option) {
      RunTypePreferenceOption.easy => (l.runTypeEasyLabel, l.runTypeEasySub),
      RunTypePreferenceOption.tempo => (l.runTypeTempoLabel, l.runTypeTempoSub),
      RunTypePreferenceOption.interval => (l.runTypeIntervalLabel, l.runTypeIntervalSub),
      RunTypePreferenceOption.longRun => (l.runTypeLongRunLabel, l.runTypeLongRunSub),
    };
  }
}

// ---- Step: coach style ----

class _CoachStyleStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _CoachStyleStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_CoachStyleStep> createState() => _CoachStyleStepState();
}

class _CoachStyleStepState extends ConsumerState<_CoachStyleStep> {
  late final TextEditingController _notesCtrl =
      TextEditingController(text: widget.form.notes ?? '');
  bool _otherSelected = false;

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = _otherSelected ? null : widget.form.coachStyle;

    final canContinue = !_otherSelected
        ? selected != null
        : _notesCtrl.text.trim().isNotEmpty;

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormCoachStyleTitle,
      subtitle: l10n.onbFormCoachStyleSubtitle,
      canContinue: canContinue,
      onContinue: () {
        if (_otherSelected) {
          notifier.setCoachStyle(CoachStyleOption.balanced);
          notifier.setNotes(_notesCtrl.text.trim());
        }
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: ChoiceGroup<CoachStyleOption>(
        options: [
          ChoiceOption(
            value: CoachStyleOption.balanced,
            label: l10n.coachStyleBalancedLabel,
            subtitle: l10n.coachStyleBalancedSub,
          ),
          ChoiceOption(
            value: CoachStyleOption.strict,
            label: l10n.coachStyleStrictLabel,
            subtitle: l10n.coachStyleStrictSub,
          ),
          ChoiceOption(
            value: CoachStyleOption.flexible,
            label: l10n.coachStyleFlexibleLabel,
            subtitle: l10n.coachStyleFlexibleSub,
          ),
        ],
        selected: selected,
        onSelected: (v) {
          setState(() => _otherSelected = false);
          notifier.setCoachStyle(v);
          notifier.setNotes(null);
        },
        otherSelected: _otherSelected,
        onOtherTapped: () => setState(() {
          _otherSelected = true;
        }),
        otherChild: _NotesField(
          controller: _notesCtrl,
          hint: l10n.onbFormCoachStyleOtherHint,
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
}

// ---- Step: runner level ----

class _RunnerLevelStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _RunnerLevelStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_RunnerLevelStep> createState() => _RunnerLevelStepState();
}

class _RunnerLevelStepState extends ConsumerState<_RunnerLevelStep> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = widget.form.runnerLevel;

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormRunnerLevelTitle,
      subtitle: l10n.onbFormRunnerLevelSubtitle,
      canContinue: true,
      onContinue: widget.onContinue,
      onBack: widget.onBack,
      child: ChoiceGroup<RunnerLevel>(
        options: [
          ChoiceOption(
            value: RunnerLevel.beginner,
            label: l10n.runnerLevelBeginnerLabel,
            subtitle: l10n.runnerLevelBeginnerSub,
          ),
          ChoiceOption(
            value: RunnerLevel.intermediate,
            label: l10n.runnerLevelIntermediateLabel,
            subtitle: l10n.runnerLevelIntermediateSub,
          ),
          ChoiceOption(
            value: RunnerLevel.advanced,
            label: l10n.runnerLevelAdvancedLabel,
            subtitle: l10n.runnerLevelAdvancedSub,
          ),
          ChoiceOption(
            value: RunnerLevel.subElite,
            label: l10n.runnerLevelSubEliteLabel,
            subtitle: l10n.runnerLevelSubEliteSub,
          ),
          ChoiceOption(
            value: RunnerLevel.elite,
            label: l10n.runnerLevelEliteLabel,
            subtitle: l10n.runnerLevelEliteSub,
          ),
        ],
        selected: selected,
        onSelected: notifier.setRunnerLevel,
      ),
    );
  }
}

// ---- Step: intensity bias ----

class _IntensityStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _IntensityStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onContinue,
    required this.onBack,
  });

  @override
  ConsumerState<_IntensityStep> createState() => _IntensityStepState();
}

class _IntensityStepState extends ConsumerState<_IntensityStep> {
  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = widget.form.intensityBias;

    final l10n = context.l10n;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormIntensityTitle,
      subtitle: l10n.onbFormIntensitySubtitle,
      canContinue: true,
      onContinue: widget.onContinue,
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.inputBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.goldGlow,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.onbFormIntensityEyebrow,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.eyebrow,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                IntensityBiasChart(bias: selected),
                const SizedBox(height: 12),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _captionFor(l10n, selected),
                    key: ValueKey(selected),
                    style: GoogleFonts.ebGaramond(
                      fontSize: 14,
                      color: AppColors.inkMuted,
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),
          IntensityBiasSegmentedControl(
            selected: selected,
            onChanged: notifier.setIntensityBias,
          ),
        ],
      ),
    );
  }

  static String _captionFor(AppLocalizations l, IntensityBias bias) => switch (bias) {
        IntensityBias.takeItEasy => l.onbFormIntensityCaptionEasy,
        IntensityBias.standard => l.onbFormIntensityCaptionStandard,
        IntensityBias.pushMeHarder => l.onbFormIntensityCaptionHarder,
      };
}

// ---- Step 9: review ----

class _ReviewStep extends ConsumerStatefulWidget {
  final int stepIndex;
  final int stepCount;
  final OnboardingFormData form;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ReviewStep({
    required this.stepIndex,
    required this.stepCount,
    required this.form,
    required this.onSubmit,
    required this.onBack,
  });

  @override
  ConsumerState<_ReviewStep> createState() => _ReviewStepState();
}

class _ReviewStepState extends ConsumerState<_ReviewStep> {
  late final TextEditingController _extraNotesCtrl =
      TextEditingController(text: widget.form.additionalNotes ?? '');

  @override
  void dispose() {
    _extraNotesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final form = widget.form;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: l10n.onbFormReviewTitle,
      subtitle: l10n.onbFormReviewSubtitle,
      canContinue: true,
      continueLabel: l10n.onbFormReviewCreateCta,
      onContinue: () {
        ref
            .read(onboardingFormProvider.notifier)
            .setAdditionalNotes(_extraNotesCtrl.text.trim());
        widget.onSubmit();
      },
      onBack: widget.onBack,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _reviewRow(l10n.reviewRowGoal, _goalLabel(l10n, form)),
                if (form.distanceMeters != null)
                  _reviewRow(l10n.reviewRowDistance, _distanceLabel(l10n, form.distanceMeters!)),
                if (form.goalName != null && form.goalName!.isNotEmpty)
                  _reviewRow(l10n.reviewRowRace, form.goalName!),
                if (form.targetDate != null)
                  _reviewRow(l10n.reviewRowRaceDay, formatDateString(form.targetDate, fallback: form.targetDate!)),
                if (form.goalTimeSeconds != null)
                  _reviewRow(l10n.reviewRowGoalTime, _formatDuration(form.goalTimeSeconds!)),
                if (form.prCurrentSeconds != null)
                  _reviewRow(
                      l10n.reviewRowCurrentPr, _formatDuration(form.prCurrentSeconds!)),
                if (form.daysPerWeek != null)
                  _reviewRow(l10n.reviewRowDaysPerWeek, '${form.daysPerWeek}'),
                if (form.preferredWeekdays != null &&
                    form.preferredWeekdays!.isNotEmpty)
                  _reviewRow(
                    l10n.reviewRowPreferredDays,
                    _weekdaysLabel(l10n, form.preferredWeekdays!),
                  ),
                if (form.coachStyle != null)
                  _reviewRow(l10n.reviewRowCoachStyle, _coachStyleLabel(l10n, form.coachStyle!)),
                if (form.runnerLevel != RunnerLevel.intermediate)
                  _reviewRow(l10n.reviewRowRunnerLevel, _runnerLevelLabel(l10n, form.runnerLevel)),
                if (form.intensityBias != IntensityBias.standard)
                  _reviewRow(l10n.reviewRowIntensity, _intensityLabel(l10n, form.intensityBias)),
                if (form.notes != null && form.notes!.isNotEmpty)
                  _reviewRow(l10n.reviewRowNotes, form.notes!),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.onbFormReviewExtraNotesLabel,
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 8),
          _NotesField(
            controller: _extraNotesCtrl,
            hint: l10n.onbFormReviewExtraNotesHint,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _reviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryInk,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _goalLabel(AppLocalizations l, OnboardingFormData form) => switch (form.goalType) {
        OnboardingGoalType.race => l.reviewGoalTypeRaceShort,
        OnboardingGoalType.pr => l.reviewGoalTypePrShort,
        OnboardingGoalType.fitness => l.reviewGoalTypeFitnessShort,
        OnboardingGoalType.weightLoss => l.reviewGoalTypeWeightLossShort,
        null => '-',
      };

  String _distanceLabel(AppLocalizations l, int meters) {
    switch (meters) {
      case 5000:
        return l.onbFormDistance5k;
      case 10000:
        return l.onbFormDistance10k;
      case 21097:
        return l.onbFormDistanceHalf;
      case 42195:
        return l.onbFormDistanceMarathon;
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _coachStyleLabel(AppLocalizations l, CoachStyleOption style) => switch (style) {
        CoachStyleOption.balanced => l.coachStyleBalancedLabel,
        CoachStyleOption.strict => l.coachStyleStrictLabel,
        CoachStyleOption.flexible => l.coachStyleFlexibleLabel,
      };

  String _intensityLabel(AppLocalizations l, IntensityBias bias) => switch (bias) {
        IntensityBias.takeItEasy => l.intensityBiasEasyLabel,
        IntensityBias.standard => l.intensityBiasStandardLabel,
        IntensityBias.pushMeHarder => l.intensityBiasHarderLabel,
      };

  String _runnerLevelLabel(AppLocalizations l, RunnerLevel level) => switch (level) {
        RunnerLevel.beginner => l.runnerLevelBeginnerLabel,
        RunnerLevel.intermediate => l.runnerLevelIntermediateLabel,
        RunnerLevel.advanced => l.runnerLevelAdvancedLabel,
        RunnerLevel.subElite => l.runnerLevelSubEliteLabel,
        RunnerLevel.elite => l.runnerLevelEliteLabel,
      };

  String _weekdaysLabel(AppLocalizations l, List<int> days) {
    final names = {
      1: l.weekdayMonShort,
      2: l.weekdayTueShort,
      3: l.weekdayWedShort,
      4: l.weekdayThuShort,
      5: l.weekdayFriShort,
      6: l.weekdaySatShort,
      7: l.weekdaySunShort,
    };
    final sorted = [...days]..sort();
    return sorted.map((d) => names[d] ?? '?').join(', ');
  }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    if (h == 0) {
      return '$m:${s.toString().padLeft(2, '0')}';
    }
    return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ---- Shared input widgets ----

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _TextField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hint,
      onChanged: onChanged,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryInk,
      ),
    );
  }
}

class _NotesField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _NotesField({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hint,
      onChanged: onChanged,
      maxLines: 3,
      minLines: 2,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryInk,
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final String suffix;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.hint,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: hint,
      onChanged: onChanged,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffix: Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Text(
          suffix,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.inkMuted,
          ),
        ),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.inputBorder),
      ),
      style: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: AppColors.primaryInk,
      ),
    );
  }
}

// ---- Goal-time parsing + preview ----

/// Parse a free-text goal time/pace input into seconds.
///
/// Handles:
/// - `H:MM:SS` / `HH:MM:SS` → total seconds
/// - `MM:SS` where the first number is ≥ 15 or distance is unknown → total seconds
/// - `MM:SS` where the first number is < 15 and a distance is known → pace,
///   multiplied by distance
/// - `X:YY/km` → pace, multiplied by distance
/// - `1h 45m`, `1h45min`, `1h`, `45min`, `45m` → hours + minutes
/// - plain integer → interpreted as minutes
///
/// Returns null when the input cannot be parsed (the Continue button uses
/// that to stay disabled).
int? parseGoalTimeInput(String raw, int? distanceMeters) {
  final cleaned = raw.toLowerCase().replaceAll(RegExp(r'\s+'), '');
  if (cleaned.isEmpty) return null;

  int? paceToTotal(int secondsPerKm) {
    if (distanceMeters == null || distanceMeters <= 0) return null;
    final total = (secondsPerKm * distanceMeters / 1000).round();
    return total > 0 ? total : null;
  }

  // Pace with explicit /km or /mi suffix
  final paceUnit = RegExp(r'^(\d{1,2}):(\d{1,2})(?:min)?/(km|mi)$').firstMatch(cleaned);
  if (paceUnit != null) {
    final secondsPerKm = int.parse(paceUnit.group(1)!) * 60 + int.parse(paceUnit.group(2)!);
    // Treat /mi the same as /km for now — we build km-pace plans.
    return paceToTotal(secondsPerKm);
  }

  // HH:MM:SS
  final hms = RegExp(r'^(\d{1,2}):(\d{1,2}):(\d{1,2})$').firstMatch(cleaned);
  if (hms != null) {
    final h = int.parse(hms.group(1)!);
    final m = int.parse(hms.group(2)!);
    final s = int.parse(hms.group(3)!);
    if (m >= 60 || s >= 60) return null;
    return h * 3600 + m * 60 + s;
  }

  // MM:SS — ambiguous (could be total time or pace)
  final mmss = RegExp(r'^(\d{1,2}):(\d{1,2})$').firstMatch(cleaned);
  if (mmss != null) {
    final a = int.parse(mmss.group(1)!);
    final b = int.parse(mmss.group(2)!);
    if (b >= 60) return null;
    if (a >= 15 || distanceMeters == null) {
      // Treat as MM:SS total time
      return a * 60 + b;
    }
    // Pace (e.g. 5:30 per km)
    return paceToTotal(a * 60 + b);
  }

  // Hours + minutes: 1h 45m, 1h45min, 1h, 45m, 45min, 45minutes
  final hm = RegExp(r'^(?:(\d{1,2})h)?(?:(\d{1,3})(?:m|min|minutes?)?)?$').firstMatch(cleaned);
  if (hm != null && (hm.group(1) != null || hm.group(2) != null)) {
    final h = int.tryParse(hm.group(1) ?? '') ?? 0;
    final m = int.tryParse(hm.group(2) ?? '') ?? 0;
    final total = h * 3600 + m * 60;
    return total > 0 ? total : null;
  }

  return null;
}

/// Human-readable inverse of [parseGoalTimeInput] for prefills and previews.
String _formatSecondsToHuman(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h == 0) return '$m:${s.toString().padLeft(2, '0')}';
  return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}

class _GoalTimePreview extends StatelessWidget {
  final String text;
  final int? parsedSeconds;
  final int? distanceMeters;

  const _GoalTimePreview({
    required this.text,
    required this.parsedSeconds,
    required this.distanceMeters,
  });

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = context.l10n;
    if (parsedSeconds == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          l10n.onbFormGoalTimeParseError,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.danger,
          ),
        ),
      );
    }

    final total = _formatSecondsToHuman(parsedSeconds!);
    final pace = distanceMeters == null || distanceMeters! <= 0
        ? null
        : _formatSecondsToHuman((parsedSeconds! / (distanceMeters! / 1000)).round());
    final paceSuffix = pace == null ? '' : l10n.onbFormGoalTimePreviewPaceSuffix(pace);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        l10n.onbFormGoalTimePreview(total, paceSuffix),
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}

/// Horizontally-scrolling suggestion chips for goal time / PR inputs.
///
/// For canonical race distances we show common goal times (e.g. sub-20 5K,
/// sub-4 marathon). For "Other" custom distances we fall back to pace chips
/// (e.g. `5:30/km`) — the existing input parser handles both formats and
/// converts pace × distance to total seconds.
class _SuggestionChips extends StatelessWidget {
  final int? distanceMeters;
  final String currentText;
  final ValueChanged<String> onTap;

  const _SuggestionChips({
    required this.distanceMeters,
    required this.currentText,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestionsFor(distanceMeters);
    if (suggestions.isEmpty) return const SizedBox.shrink();

    final cleaned = currentText.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final s in suggestions)
            _SuggestionChip(
              label: s,
              selected: s.toLowerCase() == cleaned,
              onTap: () => onTap(s),
            ),
        ],
      ),
    );
  }

  static List<String> _suggestionsFor(int? meters) {
    if (meters == null) return const [];
    switch (meters) {
      case 5000:
        return const ['18:00', '20:00', '22:30', '25:00', '27:30', '30:00', '35:00'];
      case 10000:
        return const ['40:00', '45:00', '50:00', '55:00', '1:00:00', '1:05:00', '1:10:00'];
      case 21097:
        return const ['1:30:00', '1:45:00', '2:00:00', '2:15:00', '2:30:00', '2:45:00'];
      case 42195:
        return const ['3:00:00', '3:30:00', '4:00:00', '4:30:00', '5:00:00', '5:30:00'];
    }
    // "Other" — paces scale to any custom distance via parseGoalTimeInput.
    // 3:00/km (elite) → 9:00/km (walk-jog) in 30-second steps.
    return const [
      '3:00/km',
      '3:30/km',
      '4:00/km',
      '4:30/km',
      '5:00/km',
      '5:30/km',
      '6:00/km',
      '6:30/km',
      '7:00/km',
      '7:30/km',
      '8:00/km',
      '8:30/km',
      '9:00/km',
    ];
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primaryInk : Colors.white;
    final fg = selected ? AppColors.neutral : AppColors.primaryInk;
    final borderColor = selected ? AppColors.primaryInk : AppColors.inputBorder;

    return CupertinoButton(
      padding: EdgeInsets.zero,
      minimumSize: Size.zero,
      onPressed: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
      ),
    );
  }
}
