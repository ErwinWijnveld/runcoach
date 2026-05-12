# Onboarding — runner-level tone signal

**Status:** Draft, ready for implementation
**Date:** 2026-05-11
**Author:** Erwin + Claude

---

## 1. Problem

Today's onboarding asks for goal type, distance, days/week, coach style, intensity bias, and other plan-shaping inputs — but never asks the runner *what kind of runner they are*. The agents (`OnboardingAgent`, `RunCoachAgent`) communicate at a uniform level regardless of whether they're talking to a 5-month beginner or a sub-3 marathoner.

That has two costs:
1. **Beginners get jargon-bombed.** Words like *threshold*, *VDOT*, *vO2max*, *fartlek*, *LT2* appear in plan explanations and post-run feedback without definition. New runners feel coached at, not coached.
2. **Advanced runners get hand-held.** "Your easy pace is the speed where you can still chat" is patronising to someone who's run 5+ years.

This spec adds a single onboarding step that captures the runner's self-identified level and feeds it into both agents as a coaching-tone signal. **No plan-content effect** — the snapshot, ambition analyzer, and intensity-bias slider keep their existing roles.

---

## 2. Goals / non-goals

### Goals

1. Add **one new form step** asking the runner to self-identify on a 5-tier scale: Beginner / Intermediate / Advanced / Sub-Elite / Elite.
2. **Map to 3 internal tone buckets** (Novice / Standard / Expert) so the agent prompts have a clean, low-cardinality switch.
3. **Persist on `users.runner_level`** so coach-chat turns months later still benefit without re-asking.
4. **Feed both agents** (`OnboardingAgent` post-build reply + `RunCoachAgent` ongoing chat) via prompt-instruction guidance, with explicit examples per bucket.
5. **Guardrail in the prompt:** runner_level shapes phrasing only — never adjusts plan content. The snapshot + ambition + intensity-bias own that surface.

### Non-goals

- Validating goal feasibility against runner_level. A Beginner picking sub-3 marathon stays a `PlanAmbitionAnalyzer` concern.
- Builder-knob effects. No new floors, ceilings, or quality density per level. Tone is the entire scope.
- Settings surface for editing post-onboarding. v1 captures it once at onboarding; future polish.
- Enforcing runner_level. The agent reads it as guidance, not as a hard switch — it's free to break tone for a specific question if context demands (e.g. a Beginner asks "what is VDOT", explain it regardless).
- Deriving runner_level from snapshot data. The CLAUDE.md says "level is derived from data" — this spec is the explicit override for **tone identity**, separate from the data-derived volume / pace / intensity-history signals.

---

## 3. Architecture

### 3a. Two enums, clean split

`App\Enums\RunnerLevel` is the wire-level + persisted enum (5 cases). `App\Enums\RunnerToneBucket` is what the agent prompts branch on (3 cases). The mapping lives on `RunnerLevel::toneBucket()` so future tier changes don't ripple into agent code.

```php
namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum RunnerLevel: string
{
    use HasValues;

    case Beginner = 'beginner';
    case Intermediate = 'intermediate';
    case Advanced = 'advanced';
    case SubElite = 'sub_elite';
    case Elite = 'elite';

    public function toneBucket(): RunnerToneBucket
    {
        return match ($this) {
            self::Beginner => RunnerToneBucket::Novice,
            self::Intermediate => RunnerToneBucket::Standard,
            self::Advanced, self::SubElite, self::Elite => RunnerToneBucket::Expert,
        };
    }
}

enum RunnerToneBucket: string
{
    use HasValues;

    case Novice = 'novice';
    case Standard = 'standard';
    case Expert = 'expert';
}
```

### 3b. Persistence

New column on `users`:

```php
// database/migrations/2026_05_11_NNNNNN_add_runner_level_to_users.php
Schema::table('users', function (Blueprint $table): void {
    if (! Schema::hasColumn('users', 'runner_level')) {
        $table->string('runner_level', 16)
            ->default('intermediate')
            ->after('intensity_bias');
    }
});
```

Forward-only with `hasColumn` guard per the migrations rule. `'intermediate'` default keeps existing rows on a sensible middle tone — no breaking change.

User model fillable + cast follows the same pattern as `coach_style` / `intensity_bias`:

```php
#[Fillable([..., 'coach_style', 'intensity_bias', 'runner_level', ...])]

protected function casts(): array {
    return [
        ...
        'runner_level' => RunnerLevel::class,
    ];
}
```

### 3c. Form input

Add to `App\Support\Onboarding\OnboardingFormInput`:

```php
public function __construct(
    // ... existing ...
    public RunnerLevel $runnerLevel = RunnerLevel::Intermediate,
) {}
```

`fromArray()` parses `runner_level` (string) → enum, falling back to `Intermediate` when missing or invalid (matches `coach_style` / `intensity_bias` pattern).

### 3d. BuildPlan tool persists on user

`App\Ai\Tools\BuildPlan::handle()` extends the existing coach_style / intensity_bias persistence block:

```php
if ($this->user->runner_level !== $form->runnerLevel) {
    $this->user->runner_level = $form->runnerLevel;
    $userChanged = true;
}
```

Schema gains an optional `runner_level` field:

```php
'runner_level' => $schema->string()
    ->enum(['beginner', 'intermediate', 'advanced', 'sub_elite', 'elite'])
    ->required()
    ->nullable()
    ->description('Runner self-identified level. Drives agent communication tone only — has no effect on plan content. Null falls back to intermediate.'),
```

### 3e. Agent prompts

Both agents read the tone bucket and adapt their phrasing. The actual mapping mechanism differs because of how each agent is wired:

**`OnboardingAgent`** receives form data via the priming message. `OnboardingPlanGeneratorService::buildPrimingMessage()` adds a line:

```
- runner_level: advanced (tone: expert)
```

The agent's `instructions()` get the tone-bucket fragment described below.

**`RunCoachAgent`** has `User` in its constructor. Its `coachInstructions()` method reads `$this->user->runner_level->toneBucket()->value` directly and injects it into the prompt via heredoc interpolation — no priming-message dependency.

**Shared prompt fragment** (identical text in both `OnboardingAgent::instructions()` and `RunCoachAgent::coachInstructions()`):

```
The runner's self-reported level is <runner_level> (tone bucket: <tone>).
Adapt your communication style accordingly:

- tone=novice (Beginner): define running terms the first time you use them.
  Examples: "easy pace" = "conversational, can-still-chat pace"; "intervals"
  = "short hard reps with rest between"; "threshold" = "roughly your 1-hour
  race effort". Reassure on plan ramp. Avoid jargon: VDOT, fartlek, LT2, TSS.
- tone=standard (Intermediate): assume the runner knows easy / tempo / long
  / intervals as types. Briefly define less common terms when first used.
  Friendly, not hand-holdy.
- tone=expert (Advanced / Sub-Elite / Elite): skip basic explanations. Use
  technical vocabulary directly (threshold, VDOT, vO2max, lactate, fartlek,
  race-pace work). Be concise.

This shapes phrasing only — never adjust the actual plan, paces, or volume
based on runner_level. Plan content is controlled by the snapshot, ambition
analyzer, and intensity_bias.
```

The "shapes phrasing only" guardrail is the most important line: it prevents the agent from self-justifying plan adjustments based on the runner's stated level.

---

## 4. UI

### 4a. New step in `_Step` enum

```dart
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
  runnerLevel,   // ← new, between coachStyle and intensity
  intensity,
  review,
}
```

Added to all three `_flowFor` branches (race, pr, fitness/weight_loss). Race-flow grows from 12 → 13 steps; pr-flow from 11 → 12; fitness/weight_loss from 7 → 8.

### 4b. Layout

```
Step 11 of 13

How would you describe your running?
This helps us tailor how we explain things.

┌──────────────────────────────────────────┐
│ ○  Beginner                              │
│    Just started or returning             │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ ◉  Intermediate                          │
│    Run regularly, race occasionally      │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ ○  Advanced                              │
│    Know your zones, race seriously       │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ ○  Sub-Elite                             │
│    Structured training, competitive      │
└──────────────────────────────────────────┘
┌──────────────────────────────────────────┐
│ ○  Elite                                 │
│    Sponsored or top-level competing      │
└──────────────────────────────────────────┘

           [ Continue ]
```

Uses the existing `ChoiceGroup<RunnerLevel>` widget with `ChoiceOption` cards — identical to `_CoachStyleStep`, `_DaysPerWeekStep`, etc. Continue always enabled because the default (`Intermediate`) is pre-selected.

**Subtitle wording is identity-cue, not km-range.** Mismatches between self-identified level and `self_reported_weekly_km` are by design — they're orthogonal signals (km is a number, level is identity).

### 4c. Review step

New row in `_ReviewStep`, between Coach style and Intensity, hidden when default:

```dart
if (form.runnerLevel != RunnerLevel.intermediate)
  _reviewRow('Running level', _runnerLevelLabel(form.runnerLevel)),
```

With:

```dart
String _runnerLevelLabel(RunnerLevel level) => switch (level) {
      RunnerLevel.beginner => 'Beginner',
      RunnerLevel.intermediate => 'Intermediate',
      RunnerLevel.advanced => 'Advanced',
      RunnerLevel.subElite => 'Sub-Elite',
      RunnerLevel.elite => 'Elite',
    };
```

### 4d. Flutter enum + form data

In `app/lib/features/onboarding/models/onboarding_form_data.dart`, add inline (next to `IntensityBias`):

```dart
enum RunnerLevel {
  @JsonValue('beginner') beginner,
  @JsonValue('intermediate') intermediate,
  @JsonValue('advanced') advanced,
  @JsonValue('sub_elite') subElite,
  @JsonValue('elite') elite,
}
```

Extend `OnboardingFormData`:

```dart
@JsonKey(name: 'runner_level')
@Default(RunnerLevel.intermediate)
RunnerLevel runnerLevel,
```

Provider mutator:

```dart
void setRunnerLevel(RunnerLevel level) {
  state = state.copyWith(runnerLevel: level);
}
```

User model (`features/auth/models/user.dart`) adds for round-trip:

```dart
@JsonKey(name: 'runner_level') @Default('intermediate') String runnerLevel,
```

---

## 5. API changes

### 5a. `POST /onboarding/generate-plan`

Request body gains an optional field:

```json
{
  ...
  "coach_style": "balanced",
  "intensity_bias": "standard",
  "runner_level": "advanced"
}
```

Validation in `GeneratePlanRequest::rules()`:

```php
'runner_level' => 'nullable|string|in:beginner,intermediate,advanced,sub_elite,elite',
```

When null/missing, the controller persists `RunnerLevel::Intermediate` (mirrors how `intensity_bias` defaults).

### 5b. User serialization

Add `runner_level` to both:
- `AuthController::serializeUser()` `->only([...])` list (next to `coach_style` and `intensity_bias`)
- `ProfileController::profile()` `->only([...])` list (same spot)

The Eloquent cast handles enum → string conversion automatically for JSON output.

---

## 6. Edge cases

| # | Scenario | Outcome |
|---|---|---|
| 1 | Existing user (pre-migration), reopens onboarding | Column defaults to `'intermediate'`. Agent uses Standard tone. No special handling. |
| 2 | Old API client (pre-feature) without `runner_level` | Validator nullable → service writes Intermediate → identical behaviour to today. |
| 3 | Runner picks Elite but snapshot shows 8 km/wk + no intensity history | Plan content unchanged (snapshot wins for builder). Agent uses Expert tone. The mismatch is the runner's choice — we don't second-guess identity. |
| 4 | Runner picks Beginner but PR is sub-40 5K | Plan content unchanged (snapshot + ambition do their thing). Agent explains things gently. Inverse of case 3 — also OK. |
| 5 | Runner asks "what is VDOT" while marked Expert | Agent should still explain it (one explicit question overrides tone default). The prompt instruction is "use technical vocabulary directly", not "refuse to explain". |
| 6 | Coach-chat plan rebuild months later | `OnboardingFormInput::fromArray()` reads `users.runner_level` as the default when the tool didn't pass it explicitly. The level is "sticky" until the runner explicitly changes it (future settings screen). |
| 7 | Invalid value sent | Validator returns 422. (Existing behaviour for invalid `coach_style`.) |
| 8 | Tone-bucket logic gets out of sync | Single source of truth: `RunnerLevel::toneBucket()`. Tests pin the 5-case mapping. |
| 9 | Agent uses runner_level to adjust plan content | The prompt explicitly forbids it. If it happens anyway, the deterministic `TrainingPlanBuilder` reasserts the correct shape (the agent never authors plan JSON since the Adjust+Build refactor). |

---

## 7. Test plan

### Backend (PHPUnit)

**`tests/Unit/Enums/RunnerLevelTest.php`** (new):
- `Beginner->toneBucket() === Novice`
- `Intermediate->toneBucket() === Standard`
- `Advanced->toneBucket() === Expert`
- `SubElite->toneBucket() === Expert`
- `Elite->toneBucket() === Expert`

**`tests/Unit/Support/Onboarding/OnboardingFormInputTest.php`** (extend):
- `fromArray(['runner_level' => 'beginner', ...])` → `RunnerLevel::Beginner`
- Missing `runner_level` → `RunnerLevel::Intermediate`
- Invalid string → `RunnerLevel::Intermediate`

**`tests/Feature/Ai/Tools/BuildPlanRunnerLevelTest.php`** (new):
- POST `runner_level: 'beginner'` → `users.runner_level === Beginner` after handle.
- Missing field → default Intermediate persisted.
- **Critical invariant test:** same form + same snapshot × runner_level=Beginner vs Expert → resulting proposal payload has byte-identical `total_km` per week AND byte-identical `target_pace_seconds_per_km` per day. Pins the "tone only, no plan effect" guarantee.

**`tests/Feature/Http/OnboardingProfileTest.php`** (extend if exists):
- `GET /profile` returns `runner_level` field.

### Flutter

**`app/test/features/onboarding/runner_level_step_test.dart`** (new):
- Five cards render with correct labels (Beginner / Intermediate / Advanced / Sub-Elite / Elite) and subtitles.
- Default selection is Intermediate (radio dot on middle card).
- Tap "Beginner" → `onboardingFormProvider`'s `runnerLevel` becomes `RunnerLevel.beginner`.
- Continue button is always enabled.

### Not tested

**Agent tone shifts.** Verifying the agent actually changes vocabulary based on tone bucket requires a real LLM round-trip — not representative in unit tests. The prompt fragment is specific enough that we trust it. Manual E2E covers the actual behaviour.

### Manual E2E (Notion test entry)

- 3 dev users, one per tone bucket (Beginner / Intermediate / Advanced or higher).
- Each completes onboarding with `additional_notes` set to something requiring explanation (e.g. "I'm scared of intervals").
- Verify the post-build agent reply matches the bucket: Beginner gets "intervals = short hard reps with rest"; Expert gets "we'll keep the interval volume conservative on week 1".
- Continue into coach chat, ask "What's a tempo?" — Beginner gets a definition; Expert gets a curt "threshold-pace effort".
- Verify the same runner_level is in effect across multiple chat turns (sticky).

---

## 8. Files

### Backend

| File | Change |
|---|---|
| `database/migrations/2026_05_11_NNNNNN_add_runner_level_to_users.php` | **new** — nullable string with `'intermediate'` default |
| `app/Enums/RunnerLevel.php` | **new** — five-case backed enum with `toneBucket()` method |
| `app/Enums/RunnerToneBucket.php` | **new** — three-case backed enum |
| `app/Support/Onboarding/OnboardingFormInput.php` | add `runnerLevel` field; `fromArray()` parses with Intermediate fallback |
| `app/Models/User.php` | fillable + `RunnerLevel::class` cast |
| `app/Http/Requests/GeneratePlanRequest.php` | validation rule for `runner_level` |
| `app/Http/Controllers/AuthController.php` | expose `runner_level` in `serializeUser()` |
| `app/Http/Controllers/ProfileController.php` | expose `runner_level` in profile response |
| `app/Ai/Tools/BuildPlan.php` | schema field + persistence next to coach_style/intensity_bias |
| `app/Services/OnboardingPlanGeneratorService.php` | priming message includes `runner_level` + `tone` line |
| `app/Ai/Agents/OnboardingAgent.php` | tone-bucket fragment in `instructions()` |
| `app/Ai/Agents/RunCoachAgent.php` | tone-bucket fragment in `coachInstructions()`; reads `user->runner_level->toneBucket()` directly |

### Flutter

| File | Change |
|---|---|
| `app/lib/features/onboarding/models/onboarding_form_data.dart` | add `RunnerLevel` enum + `runnerLevel` field with default Intermediate |
| `app/lib/features/onboarding/providers/onboarding_form_provider.dart` | `setRunnerLevel(RunnerLevel)` mutator |
| `app/lib/features/onboarding/screens/onboarding_form_screen.dart` | add `_Step.runnerLevel`, wire `_flowFor`, implement `_RunnerLevelStep` widget, add review row |
| `app/lib/features/auth/models/user.dart` | add `runnerLevel` field for `/profile` round-trip |

### Tests

| File | Coverage |
|---|---|
| `tests/Unit/Enums/RunnerLevelTest.php` (**new**) | `toneBucket()` mapping for all 5 cases |
| `tests/Unit/Support/Onboarding/OnboardingFormInputTest.php` (extend) | `runner_level` parsing + defaults + fallbacks |
| `tests/Feature/Ai/Tools/BuildPlanRunnerLevelTest.php` (**new**) | persistence + plan-content-invariance under runner_level change |
| `app/test/features/onboarding/runner_level_step_test.dart` (**new**) | widget interactions, default selection |

---

## 9. Migration / rollout

Single deploy. No feature flag (single-user pre-launch product).

- `users.runner_level` defaults to `'intermediate'` for existing rows. Zero behaviour change for the next plan generation — the agent uses the Standard tone bucket, which is roughly what the prompts produce today.
- Old Flutter clients keep working — they don't send `runner_level`, validator allows nullable, service defaults to Intermediate.
- New TestFlight build bumps `version: 1.0.0+N` in `pubspec.yaml`.

---

## 10. Open questions

None. Design is constrained: 5 tiers → 3 buckets, no builder effect, sticky on user. Subtitle wording is the most subjective surface and reviewable post-launch without schema change.
