import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/onboarding/widgets/choice_group.dart';
import 'package:app/features/onboarding/widgets/step_scaffold.dart';
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
  coachStyle,
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
        _Step.coachStyle,
        _Step.review,
      ],
    OnboardingGoalType.pr => const [
        _Step.goalType,
        _Step.distance,
        _Step.goalTime,
        _Step.prCurrent,
        _Step.daysPerWeek,
        _Step.preferredWeekdays,
        _Step.coachStyle,
        _Step.review,
      ],
    OnboardingGoalType.fitness ||
    OnboardingGoalType.weightLoss ||
    null => const [
        _Step.goalType,
        _Step.daysPerWeek,
        _Step.preferredWeekdays,
        _Step.coachStyle,
        _Step.review,
      ],
  };
}

class OnboardingFormScreen extends ConsumerStatefulWidget {
  const OnboardingFormScreen({super.key});

  @override
  ConsumerState<OnboardingFormScreen> createState() => _OnboardingFormScreenState();
}

class _OnboardingFormScreenState extends ConsumerState<OnboardingFormScreen> {
  int _currentIndex = 0;

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
      _Step.coachStyle => _CoachStyleStep(
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
    final notifier = ref.read(onboardingFormProvider.notifier);
    final goalType = widget.form.goalType;

    final canContinue = !_otherSelected
        ? goalType != null
        : _notesCtrl.text.trim().isNotEmpty;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: "What are you training for?",
      subtitle: "We'll tailor the plan around your answer.",
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
        options: const [
          ChoiceOption(
            value: OnboardingGoalType.race,
            label: 'Train for a race',
            subtitle: 'You\'ve got a specific event on the horizon.',
          ),
          ChoiceOption(
            value: OnboardingGoalType.pr,
            label: 'Get faster at a distance',
            subtitle: 'Go after a personal record.',
          ),
          ChoiceOption(
            value: OnboardingGoalType.fitness,
            label: 'General fitness',
            subtitle: 'Run regularly, no specific target.',
          ),
          ChoiceOption(
            value: OnboardingGoalType.weightLoss,
            label: 'Weight loss',
            subtitle: 'Consistent running to steadily drop weight.',
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
          hint: "Describe what you're after…",
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
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = _otherSelected ? null : widget.form.distanceMeters;

    final canContinue =
        !_otherSelected ? selected != null : _kmAsMeters() != null;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'What distance?',
      subtitle: 'Pick the race or target distance.',
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
        options: const [
          ChoiceOption(value: 5000, label: '5K'),
          ChoiceOption(value: 10000, label: '10K'),
          ChoiceOption(value: 21097, label: 'Half marathon'),
          ChoiceOption(value: 42195, label: 'Marathon'),
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
          hint: 'Distance in kilometers',
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
    final notifier = ref.read(onboardingFormProvider.notifier);
    final canContinue = _ctrl.text.trim().isNotEmpty;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: "What's the race called?",
      subtitle: "Anything goes, we just use it as a label.",
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
        hint: 'Rotterdam Marathon',
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

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: "When's race day?",
      subtitle: 'We need at least a couple weeks to build a proper plan.',
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

    // Auto-prefill the field with the runner's PR at the chosen distance
    // (HealthKit query, cached per-distance). Only when the field is empty
    // and the user hasn't already typed anything — never overwrite user
    // input. Triggers once per distance change.
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
          });
        });
      });
      // Kick off the query (also primes the family cache).
      ref.watch(personalRecordForDistanceProvider(distanceMeters));
    }

    final prAsync = distanceMeters == null
        ? null
        : ref.watch(personalRecordForDistanceProvider(distanceMeters));
    final prSeconds = prAsync?.value?['duration_seconds'] as int?;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'What goal time or pace are you aiming for?',
      subtitle: prSeconds != null
          ? 'Pre-filled from your fastest matching run in Apple Health. Adjust if you want to push past it.'
          : 'Enter it however feels natural, we parse it.',
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
            hint: 'e.g. 1:45:00, 25:30, or 5:30/km',
            onChanged: (_) => setState(() {}),
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

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: "What's your current PR?",
      subtitle: prSeconds != null
          ? 'Pre-filled from your fastest matching run in Apple Health. Adjust if needed.'
          : 'Optional, helps us gauge a realistic target.',
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
            hint: 'e.g. 1:52:00 or 5:45/km',
            onChanged: (_) => setState(() {}),
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
    final notifier = ref.read(onboardingFormProvider.notifier);
    final selected = _otherSelected ? null : widget.form.daysPerWeek;

    final canContinue = _otherSelected
        ? _notesCtrl.text.trim().isNotEmpty
        : selected != null;

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'How many days per week?',
      subtitle: 'Be realistic. The plan is only as good as your consistency.',
      canContinue: canContinue,
      onContinue: () {
        if (_otherSelected) {
          notifier.setNotes(_notesCtrl.text.trim());
        }
        widget.onContinue();
      },
      onBack: widget.onBack,
      child: ChoiceGroup<int>(
        options: const [
          ChoiceOption(value: 1, label: '1 day', subtitle: 'Keeps the habit alive.'),
          ChoiceOption(value: 2, label: '2 days', subtitle: 'Minimal but consistent.'),
          ChoiceOption(value: 3, label: '3 days', subtitle: 'A solid base to build on.'),
          ChoiceOption(value: 4, label: '4 days', subtitle: 'Great balance for most runners.'),
          ChoiceOption(value: 5, label: '5 days', subtitle: 'Solid block for serious goals.'),
          ChoiceOption(value: 6, label: '6 days', subtitle: 'High volume, for experienced runners.'),
          ChoiceOption(value: 7, label: '7 days', subtitle: 'Every day, only if recovery is dialed in.'),
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
          hint: 'Tell me about your schedule…',
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

  static const List<({int iso, String label, String short})> _days = [
    (iso: 1, label: 'Monday', short: 'Mon'),
    (iso: 2, label: 'Tuesday', short: 'Tue'),
    (iso: 3, label: 'Wednesday', short: 'Wed'),
    (iso: 4, label: 'Thursday', short: 'Thu'),
    (iso: 5, label: 'Friday', short: 'Fri'),
    (iso: 6, label: 'Saturday', short: 'Sat'),
    (iso: 7, label: 'Sunday', short: 'Sun'),
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
    final notifier = ref.read(onboardingFormProvider.notifier);
    final daysPerWeek = widget.form.daysPerWeek ?? 0;
    final count = _selected.length;
    final enough = count == 0 || count >= daysPerWeek;
    final canContinue = enough;

    final hint = (count > 0 && count < daysPerWeek)
        ? 'Pick at least $daysPerWeek days (you chose $count).'
        : 'Leave empty if any day works.';

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'Which weekdays can you run?',
      subtitle: 'Optional — pick the days that work for you.',
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
          ..._days.map((d) {
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

// ---- Step 8: coach style ----

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

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'How should I coach you?',
      subtitle: 'This shapes the tone of the plan and how I push you.',
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
        options: const [
          ChoiceOption(
            value: CoachStyleOption.balanced,
            label: 'Balanced',
            subtitle: 'Structure, but with room to adapt.',
          ),
          ChoiceOption(
            value: CoachStyleOption.strict,
            label: 'Strict',
            subtitle: "Hold me to it. Don't soften the plan.",
          ),
          ChoiceOption(
            value: CoachStyleOption.flexible,
            label: 'Flexible',
            subtitle: 'Adapt to my life when things slip.',
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
          hint: 'Describe how you want to be coached…',
          onChanged: (_) => setState(() {}),
        ),
      ),
    );
  }
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
    final form = widget.form;
    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'Ready to build your plan?',
      subtitle: "Quick recap. I'll take it from here.",
      canContinue: true,
      continueLabel: 'CREATE MY PLAN',
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
                _reviewRow('Goal', _goalLabel(form)),
                if (form.distanceMeters != null)
                  _reviewRow('Distance', _distanceLabel(form.distanceMeters!)),
                if (form.goalName != null && form.goalName!.isNotEmpty)
                  _reviewRow('Race', form.goalName!),
                if (form.targetDate != null)
                  _reviewRow('Race day', formatDateString(form.targetDate, fallback: form.targetDate!)),
                if (form.goalTimeSeconds != null)
                  _reviewRow('Goal time', _formatDuration(form.goalTimeSeconds!)),
                if (form.prCurrentSeconds != null)
                  _reviewRow(
                      'Current PR', _formatDuration(form.prCurrentSeconds!)),
                if (form.daysPerWeek != null)
                  _reviewRow('Days / week', '${form.daysPerWeek}'),
                if (form.preferredWeekdays != null &&
                    form.preferredWeekdays!.isNotEmpty)
                  _reviewRow(
                    'Preferred days',
                    _weekdaysLabel(form.preferredWeekdays!),
                  ),
                if (form.coachStyle != null)
                  _reviewRow('Coach style', _coachStyleLabel(form.coachStyle!)),
                if (form.notes != null && form.notes!.isNotEmpty)
                  _reviewRow('Notes', form.notes!),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Anything else for your coach?',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryInk,
            ),
          ),
          const SizedBox(height: 8),
          _NotesField(
            controller: _extraNotesCtrl,
            hint: 'Injuries, schedule quirks, anything to consider…',
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

  String _goalLabel(OnboardingFormData form) => switch (form.goalType) {
        OnboardingGoalType.race => 'Train for a race',
        OnboardingGoalType.pr => 'Chase a PR',
        OnboardingGoalType.fitness => 'General fitness',
        OnboardingGoalType.weightLoss => 'Weight loss',
        null => '-',
      };

  String _distanceLabel(int meters) {
    switch (meters) {
      case 5000:
        return '5K';
      case 10000:
        return '10K';
      case 21097:
        return 'Half marathon';
      case 42195:
        return 'Marathon';
    }
    return '${(meters / 1000).toStringAsFixed(1)} km';
  }

  String _coachStyleLabel(CoachStyleOption style) => switch (style) {
        CoachStyleOption.balanced => 'Balanced',
        CoachStyleOption.strict => 'Strict',
        CoachStyleOption.flexible => 'Flexible',
      };

  String _weekdaysLabel(List<int> days) {
    const names = {
      1: 'Mon',
      2: 'Tue',
      3: 'Wed',
      4: 'Thu',
      5: 'Fri',
      6: 'Sat',
      7: 'Sun',
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

    if (parsedSeconds == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Text(
          "Didn't quite catch that. Try 1:45:00 or 5:30/km.",
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
    final paceSuffix = pace == null ? '' : ' ($pace/km)';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        "≈ $total total$paceSuffix",
        style: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.inkMuted,
        ),
      ),
    );
  }
}
