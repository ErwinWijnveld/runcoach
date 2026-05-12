# Onboarding Runner-Level Tone Signal — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a single onboarding form step asking the runner to self-identify on a 5-tier scale (Beginner → Elite); collapse to 3 tone buckets internally; feed both onboarding + coach-chat agents so their communication tone matches the runner's stated identity. No plan-content effect.

**Architecture:** New `RunnerLevel` enum (5 cases) + `RunnerToneBucket` enum (3 cases) split keeps tier-tuning separate from agent-prompt code. Level persists on `users.runner_level` (default `'intermediate'` for back-compat). `OnboardingAgent` reads via priming message; `RunCoachAgent` reads directly from the user it owns. Both agents get an identical prompt fragment with a hard "shapes phrasing only, never plan content" guardrail.

**Tech Stack:** Laravel 13 backed enums + FormRequest + Eloquent migration. PHPUnit. Flutter Riverpod codegen + Freezed 3.x. Existing `ChoiceGroup<T>` widget for the form step.

**Spec:** `docs/superpowers/specs/2026-05-11-onboarding-runner-level-design.md`

---

## Task 1: Create `RunnerToneBucket` enum

**Files:**
- Create: `api/app/Enums/RunnerToneBucket.php`

- [ ] **Step 1: Create the file**

```php
<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Three-bucket tone axis the agent prompts branch on. `RunnerLevel`
 * collapses to this via `toneBucket()` — keeping prompt code stable
 * when we tune the 5-tier UI cases.
 */
enum RunnerToneBucket: string
{
    use HasValues;

    case Novice = 'novice';
    case Standard = 'standard';
    case Expert = 'expert';
}
```

- [ ] **Step 2: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/app/Enums/RunnerToneBucket.php
git commit -m "feat(runner-level): add RunnerToneBucket enum

Three-case backed enum that RunnerLevel collapses to via
toneBucket(). Agents branch prompts on this rather than the 5-tier
UI enum so tier changes don't ripple into prompt code."
```

---

## Task 2: Create `RunnerLevel` enum + `toneBucket()` mapping

**Files:**
- Create: `api/app/Enums/RunnerLevel.php`
- Create: `api/tests/Unit/Enums/RunnerLevelTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Unit\Enums;

use App\Enums\RunnerLevel;
use App\Enums\RunnerToneBucket;
use PHPUnit\Framework\TestCase;

class RunnerLevelTest extends TestCase
{
    public function test_beginner_maps_to_novice_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Novice, RunnerLevel::Beginner->toneBucket());
    }

    public function test_intermediate_maps_to_standard_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Standard, RunnerLevel::Intermediate->toneBucket());
    }

    public function test_advanced_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::Advanced->toneBucket());
    }

    public function test_sub_elite_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::SubElite->toneBucket());
    }

    public function test_elite_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::Elite->toneBucket());
    }
}
```

- [ ] **Step 2: Run test, expect fail**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter RunnerLevelTest
```

Expected: FAIL with `Class "App\Enums\RunnerLevel" not found`.

- [ ] **Step 3: Create the enum**

```php
<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Runner's self-identified ability level (set during onboarding,
 * persistent on users.runner_level). Drives agent communication tone
 * only — has no effect on plan content. The 5 UI tiers collapse to
 * 3 `RunnerToneBucket` cases via `toneBucket()`.
 */
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
```

- [ ] **Step 4: Run test, expect pass**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter RunnerLevelTest
```

Expected: all 5 tests pass.

- [ ] **Step 5: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/app/Enums/RunnerLevel.php api/tests/Unit/Enums/RunnerLevelTest.php
git commit -m "feat(runner-level): RunnerLevel enum with toneBucket mapping

Five UI cases (Beginner through Elite) collapse to three
RunnerToneBucket cases (Novice / Standard / Expert) via
toneBucket(). Test pins all 5 mappings."
```

---

## Task 3: Parse `runner_level` in `OnboardingFormInput`

**Files:**
- Modify: `api/app/Support/Onboarding/OnboardingFormInput.php`
- Modify: `api/tests/Unit/Support/Onboarding/OnboardingFormInputTest.php`

- [ ] **Step 1: Add the failing tests**

Append to the existing `OnboardingFormInputTest` class:

```php
public function test_from_array_parses_runner_level_beginner(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
        'runner_level' => 'beginner',
    ]);

    $this->assertSame(RunnerLevel::Beginner, $input->runnerLevel);
}

public function test_from_array_parses_runner_level_sub_elite(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
        'runner_level' => 'sub_elite',
    ]);

    $this->assertSame(RunnerLevel::SubElite, $input->runnerLevel);
}

public function test_from_array_defaults_runner_level_to_intermediate_when_missing(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
    ]);

    $this->assertSame(RunnerLevel::Intermediate, $input->runnerLevel);
}

public function test_from_array_defaults_runner_level_to_intermediate_for_invalid(): void
{
    $input = OnboardingFormInput::fromArray([
        'goal_type' => 'race',
        'days_per_week' => 4,
        'runner_level' => 'nonsense',
    ]);

    $this->assertSame(RunnerLevel::Intermediate, $input->runnerLevel);
}
```

Add to the imports block at the top:

```php
use App\Enums\RunnerLevel;
```

- [ ] **Step 2: Run test, expect fail**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter OnboardingFormInputTest
```

Expected: FAIL — property `runnerLevel` doesn't exist on `OnboardingFormInput`.

- [ ] **Step 3: Add the field + resolver to `OnboardingFormInput`**

Add `use App\Enums\RunnerLevel;` to the imports (alphabetical, after `IntensityBias`).

Update the constructor signature to include the new field:

```php
public function __construct(
    public GoalType $goalType,
    public ?string $goalName,
    public ?int $distanceMeters,
    public ?CarbonImmutable $targetDate,
    public ?int $goalTimeSeconds,
    public ?int $prCurrentSeconds,
    public int $daysPerWeek,
    public ?array $preferredWeekdays,
    public CoachStyle $coachStyle,
    public ?string $additionalNotes,
    public ?array $runTypePreferences = null,
    public IntensityBias $intensityBias = IntensityBias::Standard,
    public RunnerLevel $runnerLevel = RunnerLevel::Intermediate,
) {}
```

Update `fromArray()` `return new self(...)` to pass the new field at the end:

```php
return new self(
    goalType: $goalType,
    goalName: self::resolveGoalName($data, $goalType),
    distanceMeters: $distanceMeters,
    targetDate: $targetDate,
    goalTimeSeconds: self::resolvePositiveInt($data['goal_time_seconds'] ?? null),
    prCurrentSeconds: self::resolvePositiveInt($data['pr_current_seconds'] ?? null),
    daysPerWeek: $days,
    preferredWeekdays: $weekdays,
    coachStyle: $coachStyle,
    additionalNotes: self::resolveNotes($data),
    runTypePreferences: self::resolveRunTypePreferences($data['run_type_preferences'] ?? null),
    intensityBias: self::resolveIntensityBias($data['intensity_bias'] ?? null),
    runnerLevel: self::resolveRunnerLevel($data['runner_level'] ?? null),
);
```

Add the resolver method next to `resolveIntensityBias`:

```php
private static function resolveRunnerLevel(mixed $raw): RunnerLevel
{
    if ($raw instanceof RunnerLevel) {
        return $raw;
    }
    if (! is_string($raw)) {
        return RunnerLevel::Intermediate;
    }

    return RunnerLevel::tryFrom($raw) ?? RunnerLevel::Intermediate;
}
```

- [ ] **Step 4: Run tests, expect pass**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter OnboardingFormInputTest
```

Expected: 4 new tests pass; existing tests still pass.

- [ ] **Step 5: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/app/Support/Onboarding/OnboardingFormInput.php api/tests/Unit/Support/Onboarding/OnboardingFormInputTest.php
git commit -m "feat(runner-level): OnboardingFormInput parses runner_level

Defaults to Intermediate when missing or invalid so old payloads
generate unchanged plans + agent tone."
```

---

## Task 4: Migration — add `runner_level` to `users`

**Files:**
- Create: `api/database/migrations/2026_05_11_NNNNNN_add_runner_level_to_users.php`

- [ ] **Step 1: Generate the migration**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan make:migration add_runner_level_to_users --table=users
```

Artisan produces a skeleton file at `database/migrations/2026_05_11_<timestamp>_add_runner_level_to_users.php`.

- [ ] **Step 2: Replace the file contents**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (! Schema::hasColumn('users', 'runner_level')) {
                $table->string('runner_level', 16)
                    ->default('intermediate')
                    ->after('intensity_bias');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            if (Schema::hasColumn('users', 'runner_level')) {
                $table->dropColumn('runner_level');
            }
        });
    }
};
```

- [ ] **Step 3: Run the migration**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan migrate
```

Expected: `2026_05_11_<timestamp>_add_runner_level_to_users ... DONE`.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/database/migrations/*_add_runner_level_to_users.php
git commit -m "feat(runner-level): users.runner_level column

Nullable string defaulting to 'intermediate' so existing rows keep
generating unchanged agent tone. Forward-only with hasColumn guard
per migrations rule."
```

---

## Task 5: User model — fillable + cast

**Files:**
- Modify: `api/app/Models/User.php`

- [ ] **Step 1: Add to fillable + cast + import**

Add the import alphabetically (after `IntensityBias`):

```php
use App\Enums\RunnerLevel;
```

Add `'runner_level'` to the `#[Fillable([...])]` array, immediately after `'intensity_bias'`.

Add the cast inside the `casts()` array, immediately after the `intensity_bias` line:

```php
'runner_level' => RunnerLevel::class,
```

- [ ] **Step 2: Smoke-test the cast**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan tinker --execute 'use App\Models\User; $u = User::first(); echo "type: ".get_class($u->runner_level)." value: ".$u->runner_level->value."\n"; $u->update(["runner_level" => "advanced"]); $u->refresh(); echo "after: ".$u->runner_level->value."\n";'
```

Expected output:
```
type: App\Enums\RunnerLevel value: intermediate
after: advanced
```

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/app/Models/User.php
git commit -m "feat(runner-level): User fillable + RunnerLevel cast"
```

---

## Task 6: Validate `runner_level` in `GeneratePlanRequest`

**Files:**
- Modify: `api/app/Http/Requests/GeneratePlanRequest.php`

- [ ] **Step 1: Add the validation rule**

Locate the `rules()` array and add this line immediately below the `intensity_bias` rule:

```php
'runner_level' => 'nullable|string|in:beginner,intermediate,advanced,sub_elite,elite',
```

- [ ] **Step 2: Verify validation works**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter "Onboarding|GeneratePlan" 2>&1 | tail -5
```

Expected: no regression. Existing onboarding controller / job tests still pass; the new rule is permissive.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/app/Http/Requests/GeneratePlanRequest.php
git commit -m "feat(runner-level): validate runner_level on generate-plan"
```

---

## Task 7: `BuildPlan` tool — schema field + persistence

**Files:**
- Modify: `api/app/Ai/Tools/BuildPlan.php`

- [ ] **Step 1: Add the schema entry**

Locate the `schema(JsonSchema $schema)` method's returned array. Add an `intensity_bias`-style entry immediately after the existing `intensity_bias` schema field (i.e. before the closing `]`):

```php
'runner_level' => $schema->string()
    ->enum(['beginner', 'intermediate', 'advanced', 'sub_elite', 'elite'])
    ->required()
    ->nullable()
    ->description('Runner self-identified level. Drives agent communication tone only — has no effect on plan content. Null falls back to intermediate.'),
```

- [ ] **Step 2: Pass through to `OnboardingFormInput::fromArray()`**

Locate the `$form = OnboardingFormInput::fromArray([...])` block at the start of `handle()`. Add a line after `'intensity_bias'`:

```php
'runner_level' => $request['runner_level'] ?? null,
```

- [ ] **Step 3: Add persistence next to coach_style / intensity_bias**

Locate the existing persistence block (the `if ($this->user->coach_style !== ...)` / `if ($this->user->intensity_bias !== ...)` pair). Add a third arm before `if ($userChanged) { $this->user->save(); }`:

```php
if ($this->user->runner_level !== $form->runnerLevel) {
    $this->user->runner_level = $form->runnerLevel;
    $userChanged = true;
}
```

- [ ] **Step 4: Smoke-test by running existing tool tests**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact tests/Feature/Ai/Tools/BuildPlanIntensityBiasTest.php 2>&1 | tail -5
```

Expected: 4 existing tests still pass — the runner_level addition is back-compat (defaults to Intermediate when missing).

- [ ] **Step 5: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/app/Ai/Tools/BuildPlan.php
git commit -m "feat(runner-level): BuildPlan accepts + persists runner_level

Schema field added next to intensity_bias. Persistence mirrors the
existing coach_style / intensity_bias pattern — runner_level is a
sticky user preference, not a per-plan field."
```

---

## Task 8: Inject `runner_level` into the onboarding priming message

**Files:**
- Modify: `api/app/Services/OnboardingPlanGeneratorService.php`

- [ ] **Step 1: Add the priming-message line**

In `buildPrimingMessage()`, locate the `$lines = [...]` array. The existing block ends with the `coach_style` and `intensity_bias` lines. Add a third line that includes the tone bucket so the agent doesn't have to recompute it:

```php
'- runner_level: '.($formData['runner_level'] ?? 'intermediate').' (tone: '.\App\Enums\RunnerLevel::tryFrom($formData['runner_level'] ?? 'intermediate')->toneBucket()->value.')',
```

Place it immediately after the `intensity_bias` line. The output looks like:

```
- intensity_bias: standard
- runner_level: advanced (tone: expert)
```

- [ ] **Step 2: Add the import**

At the top of the file, add (alphabetical, after `App\Enums\ProposalStatus`):

```php
use App\Enums\RunnerLevel;
```

Update the priming line to use the short name:

```php
'- runner_level: '.($formData['runner_level'] ?? 'intermediate').' (tone: '.RunnerLevel::tryFrom($formData['runner_level'] ?? 'intermediate')->toneBucket()->value.')',
```

- [ ] **Step 3: Run service tests**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter "OnboardingPlanGenerator|Onboarding" 2>&1 | tail -5
```

Expected: no regression.

- [ ] **Step 4: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/app/Services/OnboardingPlanGeneratorService.php
git commit -m "feat(runner-level): priming message includes runner_level + tone

OnboardingAgent now sees both the 5-tier label and the collapsed
3-bucket tone hint, so it doesn't need to derive the mapping itself."
```

---

## Task 9: `OnboardingAgent` prompt — tone-bucket guidance

**Files:**
- Modify: `api/app/Ai/Agents/OnboardingAgent.php`

- [ ] **Step 1: Add the prompt fragment**

In `instructions()`, locate the `Step 4 — Reply with a short, friendly message.` block. After the existing tone-related rules (the existing 4a-c rules from the intensity-bias work), append a new rule `d` that introduces the tone bucket:

Locate this passage in the current instructions:

```
          c. If `intensity_bias` in the priming message is NOT `standard`, acknowledge it in one short sentence — speak to the experience, not the mechanism:
              • `take_it_easy` → "I dialed back the ramp a bit since you asked to ease in — week-to-week jumps are smaller and the peak is lower."
              • `push_me_harder` → "You asked for a tougher build, so this plan sits at the upper edge of what your fitness can support — recovery matters more than usual."

        Total reply ≤ 60 words. No markdown, no headings, no lists, no em-dashes.
```

Insert a `d.` block immediately before the `Total reply ≤ 60 words.` line:

```
          d. The priming message includes `runner_level` and `tone`. Adapt the entire reply to the tone bucket — this shapes phrasing only, NEVER plan content:
              • `tone=novice` (Beginner): when you use a coaching term, define it the first time. Examples: "easy pace" = "conversational, can-still-chat pace"; "intervals" = "short hard reps with rest"; "threshold" = "roughly your 1-hour race effort". Skip jargon: VDOT, fartlek, LT2, TSS. Reassure on the plan ramp.
              • `tone=standard` (Intermediate): assume the runner knows easy / tempo / long. Briefly define less common terms when first used. Friendly, not hand-holdy.
              • `tone=expert` (Advanced / Sub-Elite / Elite): skip basic explanations. Use technical vocabulary directly (threshold, VDOT, vO2max, lactate, fartlek, race-pace work). Be concise.
            DO NOT adjust paces, volume, or plan structure based on runner_level. Plan content is owned by the snapshot, ambition analyzer, and intensity_bias.
```

- [ ] **Step 2: Bump the reply word cap**

The added guidance may justify slightly more flexibility. Update the line:

```
        Total reply ≤ 60 words. No markdown, no headings, no lists, no em-dashes.
```

to:

```
        Total reply ≤ 80 words. No markdown, no headings, no lists, no em-dashes.
```

- [ ] **Step 3: Smoke-test that agent tests still pass**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter "Onboarding|GeneratePlan" 2>&1 | tail -5
```

Expected: no regression — the prompt fragment is plain text, not executable.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/app/Ai/Agents/OnboardingAgent.php
git commit -m "feat(runner-level): OnboardingAgent prompt adapts tone per bucket

Three-bucket tone rule (novice / standard / expert) joins the
existing intensity-bias rule, with a hard 'shapes phrasing only,
never plan content' guardrail. Word cap bumped 60->80 to give the
agent room for the tone-appropriate wording."
```

---

## Task 10: `RunCoachAgent` prompt — same tone-bucket guidance

**Files:**
- Modify: `api/app/Ai/Agents/RunCoachAgent.php`

- [ ] **Step 1: Locate `coachInstructions()`**

```bash
cd /Users/erwin/personal/runcoach/api && grep -n "function coachInstructions\|tone\|VDOT\|threshold pace" app/Ai/Agents/RunCoachAgent.php | head -10
```

Identify the `coachInstructions()` method body. It's a heredoc.

- [ ] **Step 2: Inject the tone variable + fragment**

At the top of `coachInstructions()` (before the `return <<<PROMPT` line), add:

```php
$tone = $this->user->runner_level->toneBucket()->value;
$levelLabel = $this->user->runner_level->value;
```

Inside the heredoc (somewhere near the existing coaching-style guidance), add a new section heading + fragment. A good place is just after the section about coach_style if one exists, otherwise near the top of the role/voice section:

```
## Communication tone

The runner's self-reported level is {$levelLabel} (tone bucket: {$tone}).
Adapt your phrasing for the entire conversation — this shapes wording only,
NEVER plan content, paces, or volume.

- tone=novice (Beginner): when you first use a coaching term, define it.
  Examples: "easy pace" = "conversational, can-still-chat pace"; "intervals"
  = "short hard reps with rest"; "threshold" = "roughly your 1-hour race
  effort". Skip jargon: VDOT, fartlek, LT2, TSS. Reassure on plan ramp.
- tone=standard (Intermediate): assume the runner knows easy / tempo / long.
  Briefly define less common terms when first used. Friendly, not hand-holdy.
- tone=expert (Advanced / Sub-Elite / Elite): skip basic explanations. Use
  technical vocabulary directly (threshold, VDOT, vO2max, lactate, fartlek,
  race-pace work). Be concise.

If the runner asks a direct question that requires explaining a basic term
(e.g. an Expert asks "what is VDOT?"), explain it — the tone is a default,
not a refusal.
```

The two `{$tone}` and `{$levelLabel}` placeholders must be inside the heredoc so Laravel's string interpolation substitutes them at runtime.

- [ ] **Step 3: Verify the substitution works**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan tinker --execute 'use App\Ai\Agents\RunCoachAgent; use App\Models\User; $u = User::first(); $u->update(["runner_level" => "advanced"]); $agent = RunCoachAgent::make(user: $u->fresh()); $text = $agent->instructions(); echo str_contains($text, "(tone bucket: expert)") ? "OK\n" : "FAIL\n";'
```

Expected: `OK`.

- [ ] **Step 4: Run coach tests**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact --filter "RunCoachAgent|Coach" 2>&1 | tail -5
```

Expected: no regression. The prompt is plain text.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/app/Ai/Agents/RunCoachAgent.php
git commit -m "feat(runner-level): RunCoachAgent prompt adapts tone per bucket

coachInstructions() now reads user->runner_level directly (no
priming-message dependency) and adapts phrasing. Same 3-bucket
guidance + same 'phrasing only, not plan' guardrail as
OnboardingAgent. Explicit override: direct questions about basic
terms get answered regardless of tone."
```

---

## Task 11: Expose `runner_level` on auth + profile responses

**Files:**
- Modify: `api/app/Http/Controllers/AuthController.php`
- Modify: `api/app/Http/Controllers/ProfileController.php`

- [ ] **Step 1: Add to AuthController serializer**

In `AuthController::serializeUser()`, locate the `$user->only([...])` array. Add `'runner_level'` immediately after `'intensity_bias'`:

```php
...$user->only(['id', 'name', 'email', 'coach_style', 'intensity_bias', 'runner_level', 'has_completed_onboarding']),
```

- [ ] **Step 2: Add to ProfileController serializer**

In `ProfileController::profile()`, locate the `$user->only([...])` array. Add `'runner_level'` immediately after `'intensity_bias'`:

```php
...$user->only([
    'id', 'name', 'email',
    'coach_style', 'intensity_bias', 'runner_level', 'has_completed_onboarding',
    'heart_rate_zones', 'heart_rate_zones_source',
    'date_of_birth',
]),
```

- [ ] **Step 3: Smoke-test**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan tinker --execute 'echo json_encode(App\Models\User::first()->only(["id","email","coach_style","intensity_bias","runner_level"]));'
```

Expected output includes `"runner_level":"intermediate"` (or whatever was set).

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add api/app/Http/Controllers/AuthController.php api/app/Http/Controllers/ProfileController.php
git commit -m "feat(runner-level): expose runner_level on auth + profile responses"
```

---

## Task 12: End-to-end test — runner_level is sticky + plan-content-invariant

**Files:**
- Create: `api/tests/Feature/Ai/Tools/BuildPlanRunnerLevelTest.php`

- [ ] **Step 1: Write the new test class**

```php
<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\BuildPlan;
use App\Enums\RunnerLevel;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\Onboarding\FitnessSnapshotService;
use App\Services\Onboarding\PlanAmbitionAnalyzer;
use App\Services\Onboarding\TrainingPlanBuilder;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class BuildPlanRunnerLevelTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function makeTool(User $user): BuildPlan
    {
        return new BuildPlan(
            user: $user,
            snapshots: app(FitnessSnapshotService::class),
            builder: app(TrainingPlanBuilder::class),
            optimizer: app(PlanOptimizerService::class),
            proposals: app(ProposalService::class),
            ambition: app(PlanAmbitionAnalyzer::class),
        );
    }

    /**
     * Self-reported baseline keeps the snapshot deterministic across
     * runs so the only variable is runner_level.
     */
    private function user(): User
    {
        return User::factory()->create([
            'self_reported_weekly_km' => 25.0,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now(),
            'runner_level' => 'intermediate',
        ]);
    }

    private function args(string $runnerLevel): array
    {
        return [
            'goal_type' => 'race',
            'goal_name' => 'Runner-Level Test',
            'distance_meters' => 21097,
            'target_date' => now()->addWeeks(12)->endOfWeek()->toDateString(),
            'goal_time_seconds' => 6300,
            'pr_current_seconds' => null,
            'days_per_week' => 4,
            'preferred_weekdays' => [2, 4, 6, 7],
            'coach_style' => 'balanced',
            'additional_notes' => null,
            'run_type_preferences' => null,
            'intensity_bias' => 'standard',
            'runner_level' => $runnerLevel,
        ];
    }

    /**
     * Strip volatile fields (proposal id, timestamps) before comparing
     * two plan payloads. The comparison surface is the schedule shape,
     * paces, volumes, and titles — i.e. what the runner sees.
     */
    private function planFingerprint(array $payload): array
    {
        return array_map(function (array $week): array {
            return [
                'week_number' => $week['week_number'] ?? null,
                'total_km' => $week['total_km'] ?? null,
                'days' => array_map(fn (array $d): array => [
                    'day_of_week' => $d['day_of_week'] ?? null,
                    'type' => $d['type'] ?? null,
                    'target_km' => $d['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $d['target_pace_seconds_per_km'] ?? null,
                ], $week['days'] ?? []),
            ];
        }, $payload['schedule']['weeks'] ?? []);
    }

    public function test_runner_level_persists_on_user_after_handle(): void
    {
        $user = $this->user();
        $this->assertSame(RunnerLevel::Intermediate, $user->runner_level);

        $this->makeTool($user)->handle(new Request($this->args('beginner')));

        $this->assertSame(RunnerLevel::Beginner, $user->fresh()->runner_level);
    }

    public function test_runner_level_defaults_to_intermediate_when_missing(): void
    {
        $user = $this->user();
        $args = $this->args('intermediate');
        unset($args['runner_level']);

        $result = json_decode($this->makeTool($user)->handle(new Request($args)), true);

        $this->assertTrue($result['requires_approval']);
        $this->assertSame(RunnerLevel::Intermediate, $user->fresh()->runner_level);
    }

    /**
     * Critical invariant: runner_level shapes agent phrasing only.
     * Two plans built with the same form + same snapshot but different
     * runner_level must produce identical plan content.
     */
    public function test_plan_content_is_identical_across_runner_levels(): void
    {
        $userBeginner = $this->user();
        $resultBeginner = json_decode(
            $this->makeTool($userBeginner)->handle(new Request($this->args('beginner'))),
            true,
        );

        $userExpert = $this->user();
        $resultExpert = json_decode(
            $this->makeTool($userExpert)->handle(new Request($this->args('elite'))),
            true,
        );

        $beginnerProposal = CoachProposal::findOrFail($resultBeginner['proposal_id']);
        $expertProposal = CoachProposal::findOrFail($resultExpert['proposal_id']);

        $this->assertEquals(
            $this->planFingerprint($beginnerProposal->payload),
            $this->planFingerprint($expertProposal->payload),
            'Plan content must NOT depend on runner_level — it is a tone signal only.',
        );
    }
}
```

- [ ] **Step 2: Run the new tests**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact tests/Feature/Ai/Tools/BuildPlanRunnerLevelTest.php
```

Expected: all 3 tests pass. If the invariance test fails, it means BuildPlan / the agent toolchain is somehow reading runner_level and modifying the plan — investigate.

- [ ] **Step 3: Pint + commit**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
cd /Users/erwin/personal/runcoach && git add api/tests/Feature/Ai/Tools/BuildPlanRunnerLevelTest.php
git commit -m "test(runner-level): persistence + plan-content invariance

Three tests: runner_level persists on user after BuildPlan handle,
defaults to intermediate when missing, and (most importantly) the
generated plan payload is byte-identical across runner_level values
when all other inputs match — pinning the 'phrasing only, never
plan content' guardrail."
```

---

## Task 13: Pint + full backend test suite

- [ ] **Step 1: Pint pass**

```bash
cd /Users/erwin/personal/runcoach/api && vendor/bin/pint --dirty --format agent
```

- [ ] **Step 2: Full suite**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan test --compact 2>&1 | tail -5
```

Expected: `Tests: X passed` with at most the 5 pre-existing APNs / .p8 failures noted in earlier sessions. No new failures from the runner_level work.

- [ ] **Step 3: Commit any Pint fixes**

```bash
cd /Users/erwin/personal/runcoach && git status
# if Pint touched anything beyond what we already committed:
git add -A && git commit -m "style: pint"
```

---

## Task 14: Flutter — `RunnerLevel` enum + form data field

**Files:**
- Modify: `app/lib/features/onboarding/models/onboarding_form_data.dart`

- [ ] **Step 1: Add the enum + form field**

Inside `app/lib/features/onboarding/models/onboarding_form_data.dart`, add the new enum at the bottom of the file (next to `IntensityBias`):

```dart
/// Runner's self-identified level. Sent to backend as the wire string
/// in `intensity_bias`-style snake_case. Drives agent communication
/// tone only — has no effect on plan content.
enum RunnerLevel {
  @JsonValue('beginner')
  beginner,
  @JsonValue('intermediate')
  intermediate,
  @JsonValue('advanced')
  advanced,
  @JsonValue('sub_elite')
  subElite,
  @JsonValue('elite')
  elite,
}
```

In the `OnboardingFormData` factory, add the new field at the end of the constructor parameter list, immediately after `intensityBias`:

```dart
@JsonKey(name: 'runner_level')
@Default(RunnerLevel.intermediate)
RunnerLevel runnerLevel,
```

- [ ] **Step 2: Run codegen**

```bash
cd /Users/erwin/personal/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

Expected: 7 outputs written. No errors.

- [ ] **Step 3: Analyze**

```bash
cd /Users/erwin/personal/runcoach/app && flutter analyze lib/features/onboarding/models/ 2>&1 | tail -3
```

Expected: `No issues found!`.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add app/lib/features/onboarding/models/onboarding_form_data.dart app/lib/features/onboarding/models/onboarding_form_data.freezed.dart app/lib/features/onboarding/models/onboarding_form_data.g.dart
git commit -m "feat(runner-level): Flutter RunnerLevel enum + form data field

Default Intermediate. @JsonKey + @JsonValue annotations map to
backend's snake_case wire form."
```

---

## Task 15: Flutter — form provider mutator

**Files:**
- Modify: `app/lib/features/onboarding/providers/onboarding_form_provider.dart`

- [ ] **Step 1: Add the mutator**

In `OnboardingForm` class, immediately after `setIntensityBias`, add:

```dart
void setRunnerLevel(RunnerLevel level) {
  state = state.copyWith(runnerLevel: level);
}
```

- [ ] **Step 2: Run codegen if needed**

```bash
cd /Users/erwin/personal/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add app/lib/features/onboarding/providers/onboarding_form_provider.dart app/lib/features/onboarding/providers/onboarding_form_provider.g.dart
git commit -m "feat(runner-level): setRunnerLevel mutator on OnboardingForm"
```

---

## Task 16: Flutter — User model round-trip

**Files:**
- Modify: `app/lib/features/auth/models/user.dart`

- [ ] **Step 1: Add the field**

Locate the existing line:

```dart
@JsonKey(name: 'intensity_bias') @Default('standard') String intensityBias,
```

Add a new line immediately below it:

```dart
@JsonKey(name: 'runner_level') @Default('intermediate') String runnerLevel,
```

(Stored as plain `String` to match the existing `coachStyle` / `intensityBias` round-trip pattern — consumers convert with `RunnerLevel.values.byName(...)` or by string compare.)

- [ ] **Step 2: Run codegen**

```bash
cd /Users/erwin/personal/runcoach/app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 3: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add app/lib/features/auth/models/user.dart app/lib/features/auth/models/user.freezed.dart app/lib/features/auth/models/user.g.dart
git commit -m "feat(runner-level): User model exposes runner_level"
```

---

## Task 17: Flutter — `_RunnerLevelStep` widget + `_flowFor` + review row

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_form_screen.dart`
- Create: `app/test/features/onboarding/runner_level_step_test.dart`

- [ ] **Step 1: Add `_Step.runnerLevel` to the enum**

In the `_Step` enum at the top of the file, insert `runnerLevel` between `coachStyle` and `intensity`:

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
  runnerLevel,
  intensity,
  review,
}
```

- [ ] **Step 2: Add to every `_flowFor` branch**

In `_flowFor()`, add `_Step.runnerLevel` between `_Step.coachStyle` and `_Step.intensity` in each of the three switch arms (race, pr, fitness/weight_loss/null branches).

- [ ] **Step 3: Add to the analytics-key map**

In `_OnboardingFormScreenState`, find the `_stepFromName` const map and add the new entry between `'coach_style'` and `'intensity'`:

```dart
'runner_level': _Step.runnerLevel,
```

- [ ] **Step 4: Add the switch arm in `build()`**

In `_OnboardingFormScreenState.build()`, find the `switch (step) { ... }` block and add the new case between `_Step.coachStyle` and `_Step.intensity`:

```dart
_Step.runnerLevel => _RunnerLevelStep(
    stepIndex: safeIndex,
    stepCount: flow.length,
    form: form,
    onContinue: _advance,
    onBack: _goBack,
  ),
```

- [ ] **Step 5: Implement `_RunnerLevelStep`**

At the bottom of the file (after the existing `_CoachStyleStep` and before `_IntensityStep`), insert:

```dart
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

    return StepScaffold(
      stepIndex: widget.stepIndex,
      stepCount: widget.stepCount,
      title: 'How would you describe your running?',
      subtitle: 'This helps us tailor how we explain things.',
      canContinue: true,
      onContinue: widget.onContinue,
      onBack: widget.onBack,
      child: ChoiceGroup<RunnerLevel>(
        options: const [
          ChoiceOption(
            value: RunnerLevel.beginner,
            label: 'Beginner',
            subtitle: 'Just started or returning',
          ),
          ChoiceOption(
            value: RunnerLevel.intermediate,
            label: 'Intermediate',
            subtitle: 'Run regularly, race occasionally',
          ),
          ChoiceOption(
            value: RunnerLevel.advanced,
            label: 'Advanced',
            subtitle: 'Know your zones, race seriously',
          ),
          ChoiceOption(
            value: RunnerLevel.subElite,
            label: 'Sub-Elite',
            subtitle: 'Structured training, competitive',
          ),
          ChoiceOption(
            value: RunnerLevel.elite,
            label: 'Elite',
            subtitle: 'Sponsored or top-level competing',
          ),
        ],
        selected: selected,
        onSelected: notifier.setRunnerLevel,
      ),
    );
  }
}
```

- [ ] **Step 6: Add the Review row**

In `_ReviewStep`'s `build()`, locate the existing intensity-bias review row:

```dart
if (form.intensityBias != IntensityBias.standard)
  _reviewRow('Intensity', _intensityLabel(form.intensityBias)),
```

Insert a new conditional row immediately above it (so the review reads "Coach style → Running level → Intensity → Notes"):

```dart
if (form.runnerLevel != RunnerLevel.intermediate)
  _reviewRow('Running level', _runnerLevelLabel(form.runnerLevel)),
```

In `_ReviewStepState`, locate `_intensityLabel(...)` and immediately above it add:

```dart
String _runnerLevelLabel(RunnerLevel level) => switch (level) {
      RunnerLevel.beginner => 'Beginner',
      RunnerLevel.intermediate => 'Intermediate',
      RunnerLevel.advanced => 'Advanced',
      RunnerLevel.subElite => 'Sub-Elite',
      RunnerLevel.elite => 'Elite',
    };
```

- [ ] **Step 7: Write the widget test**

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';
import 'package:app/features/onboarding/widgets/choice_group.dart';

void main() {
  testWidgets('runner-level mutator updates form state', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Material(
            child: Consumer(builder: (context, ref, _) {
              final selected = ref.watch(onboardingFormProvider).runnerLevel;
              return ChoiceGroup<RunnerLevel>(
                options: const [
                  ChoiceOption(value: RunnerLevel.beginner, label: 'Beginner'),
                  ChoiceOption(value: RunnerLevel.intermediate, label: 'Intermediate'),
                  ChoiceOption(value: RunnerLevel.advanced, label: 'Advanced'),
                  ChoiceOption(value: RunnerLevel.subElite, label: 'Sub-Elite'),
                  ChoiceOption(value: RunnerLevel.elite, label: 'Elite'),
                ],
                selected: selected,
                onSelected: ref.read(onboardingFormProvider.notifier).setRunnerLevel,
              );
            }),
          ),
        ),
      ),
    );

    // All five labels render.
    expect(find.text('Beginner'), findsOneWidget);
    expect(find.text('Intermediate'), findsOneWidget);
    expect(find.text('Advanced'), findsOneWidget);
    expect(find.text('Sub-Elite'), findsOneWidget);
    expect(find.text('Elite'), findsOneWidget);

    // Default is Intermediate.
    expect(
      container.read(onboardingFormProvider).runnerLevel,
      RunnerLevel.intermediate,
    );

    // Tap Beginner -> form state flips.
    await tester.tap(find.text('Beginner'));
    await tester.pump();
    expect(
      container.read(onboardingFormProvider).runnerLevel,
      RunnerLevel.beginner,
    );
  });
}
```

- [ ] **Step 8: Run the test**

```bash
cd /Users/erwin/personal/runcoach/app && flutter test test/features/onboarding/runner_level_step_test.dart
```

Expected: test passes.

- [ ] **Step 9: Analyze**

```bash
cd /Users/erwin/personal/runcoach/app && flutter analyze lib/features/onboarding/ test/features/onboarding/ 2>&1 | tail -3
```

Expected: `No issues found!`.

- [ ] **Step 10: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add app/lib/features/onboarding/screens/onboarding_form_screen.dart app/test/features/onboarding/runner_level_step_test.dart
git commit -m "feat(runner-level): add runner-level form step + review row

New _Step.runnerLevel between coachStyle and intensity in every
goal-flow branch. Five ChoiceGroup cards with identity-cue
subtitles. Continue always enabled (Intermediate is a sensible
default). Review row only renders when non-default."
```

---

## Task 18: Flutter analyze + test suite

- [ ] **Step 1: Run analyze**

```bash
cd /Users/erwin/personal/runcoach/app && flutter analyze
```

Expected: `No issues found!`. If any new issues from earlier tasks slip through, fix them inline.

- [ ] **Step 2: Run full Flutter tests**

```bash
cd /Users/erwin/personal/runcoach/app && flutter test 2>&1 | tail -10
```

Expected: all tests pass (including the new runner-level test and the previously passing intensity-bias tests). The pre-existing `message_bubble_test.dart` failure from the prior session is unrelated to this work.

- [ ] **Step 3: Commit any analyzer fix-ups**

```bash
cd /Users/erwin/personal/runcoach && git status
# if anything was touched:
git add -A && git commit -m "fix(runner-level): analyzer/test cleanup"
```

---

## Task 19: Manual E2E + version bump (deferred to user)

This task is **not auto-executable** — it requires running the simulator/device and verifying agent behaviour. Defer to the user.

- [ ] **Step 1: Backend running**

```bash
cd /Users/erwin/personal/runcoach/api && composer run dev
```

- [ ] **Step 2: Reset dev user**

```bash
cd /Users/erwin/personal/runcoach/api && php artisan tinker --execute 'use App\Models\User; $u = User::orderBy("id")->first(); $u->update(["has_completed_onboarding" => false, "runner_level" => "intermediate"]);'
```

- [ ] **Step 3: Walk through onboarding as Beginner**

```bash
cd /Users/erwin/personal/runcoach/app && bash scripts/run-dev.sh
```

Complete onboarding, on the runner-level step pick **Beginner**, finish. Read the agent's first reply in the chat — expect language like "easy pace = conversational" or "intervals are short hard reps with rest". Should NOT contain words like VDOT, fartlek, lactate.

- [ ] **Step 4: Reset, walk through as Advanced**

Repeat step 2 and step 3 but pick **Advanced**. Agent reply should use technical vocabulary directly — no definition prefixes — and be more concise.

- [ ] **Step 5: Coach-chat continuity**

After step 4, send a chat message asking "How should I pace my next tempo run?" — the reply should use threshold-pace language directly without explaining what threshold is.

- [ ] **Step 6: Bump pubspec build number**

Open `app/pubspec.yaml`, bump the `+N` in `version: 1.0.0+N`.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwin/personal/runcoach && git add app/pubspec.yaml
git commit -m "chore: bump build number for runner-level release"
```

---

## Done

The feature is shippable when:
- Backend test suite green (`php artisan test --compact`) modulo the pre-existing APNs failures
- Flutter `flutter analyze && flutter test` green modulo the pre-existing `message_bubble_test.dart` failure
- Task 12's plan-content-invariance test passes — this is the key safeguard that runner_level can't accidentally start shifting builder output
- Manual E2E in Task 19 confirms the agent's vocabulary actually changes with tone bucket

Per project convention (`./CLAUDE.md` → "Never auto-push, build, or upload"), do NOT push to origin/main or run `bash scripts/build-ios.sh` / `bash scripts/upload-ios.sh` without explicit per-turn instruction.
