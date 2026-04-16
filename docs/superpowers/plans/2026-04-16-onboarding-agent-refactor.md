# Onboarding — refactor to fully agent-driven

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the scripted onboarding state machine with a `context='onboarding'` conversation that runs through the existing `RunCoachAgent` via the existing streaming endpoint. Everything the user sees is driven by the agent obeying tight system instructions; rich UI (stats card, chip suggestions) comes from dedicated tools the agent calls.

**Architecture:**
- Backend: `RunCoachAgent::instructions()` branches on conversation `context`. For `onboarding`, it follows a strict script: call `present_running_stats` → greet + ask goal → call `offer_choices` → branch on user reply → more `offer_choices` calls → `create_schedule`. Chip taps and free text are both just user messages — the agent parses whichever.
- Two new tools render UI: `PresentRunningStats(metrics)` and `OfferChoices(chips)`. Their tool_results are streamed as dedicated SSE events (`data-stats`, `data-chips`) matching the existing `data-proposal` pattern. On conversation reload they're read back from `tool_results`.
- Flutter: onboarding uses the **existing `coachChatProvider`** + `CoachStreamClient`. The `OnboardingShell` becomes a thin scaffold that creates the onboarding conversation and mounts `CoachChatView` pointed at it.
- Net delete >> net add. Polling, `OnboardingChat` provider, `OnboardingController::advance`, `ChipClassifier`, `AnalyzeRunningProfileJob`, `RunOnboardingPlanAgentJob`, custom `messageType`/`messagePayload` on `CoachMessage`, the 3 onboarding endpoints beyond `/start` — all gone.

**Tech Stack:** Laravel 13 + Laravel AI SDK + Sanctum; Flutter + Riverpod + Freezed + Retrofit + SSE streaming (existing `CoachStreamClient`).

**Reference docs:**
- Previous plan: `docs/superpowers/plans/2026-04-16-onboarding-and-goal-rename.md` (original scripted-flow implementation)
- Spec: `docs/superpowers/specs/2026-04-16-onboarding-and-goal-rename-design.md` (kept for context but architecture diagram is now obsolete; rely on this plan instead)
- Existing agent pattern: `api/app/Ai/Agents/RunCoachAgent.php`, `api/app/Ai/Tools/CreateSchedule.php`, `api/app/Http/Controllers/CoachController.php::sendMessage`
- Existing stream protocol: Vercel AI SDK-compatible SSE; `api/app/Http/Controllers/CoachController.php::sendMessage` emits `data-proposal`; Flutter `app/lib/features/coach/data/coach_stream_client.dart` parses it into `ProposalEvent`

---

## File Structure

### Backend (`api/`) — new files

| Path | Responsibility |
|---|---|
| `app/Ai/Tools/PresentRunningStats.php` | Agent-callable tool; takes metrics map, returns `{display: 'stats_card', metrics: {...}}` |
| `app/Ai/Tools/OfferChoices.php` | Agent-callable tool; takes chips array, returns `{display: 'chip_suggestions', chips: [{label, value}]}` |

### Backend — modified

| Path | Why |
|---|---|
| `app/Ai/Agents/RunCoachAgent.php` | `instructions()` branches on conversation `context`; registers the 2 new tools |
| `app/Http/Controllers/OnboardingController.php` | Reduced to a single `start` endpoint that creates the onboarding conversation + kicks off the agent with a seed user message |
| `app/Http/Controllers/CoachController.php` | `show()` returns `tool_results` JSON per message so the client can re-hydrate stats/chips on reload; `sendMessage()` stream emits `data-stats` + `data-chips` alongside `data-proposal` |
| `app/Services/ProposalService.php` | No changes needed — onboarding completion flag already flips on proposal accept |
| `routes/api.php` | Keep only `POST /v1/onboarding/start`; delete `GET /v1/onboarding/conversations/{id}` and `POST /v1/onboarding/conversations/{id}/messages` |

### Backend — deleted

| Path | Why |
|---|---|
| `app/Jobs/AnalyzeRunningProfileJob.php` | Replaced by the agent calling `get_running_profile` (which analyzes on-demand if profile missing) |
| `app/Jobs/RunOnboardingPlanAgentJob.php` | Agent runs in-request via the streaming endpoint |
| `app/Services/ChipClassifier.php` | Agent does natural-language parsing natively |
| `tests/Feature/Services/ChipClassifierTest.php` | — |
| `tests/Feature/Jobs/AnalyzeRunningProfileJobTest.php` | — |
| `tests/Feature/Http/OnboardingBranchTest.php` | — |
| `tests/Feature/Http/OnboardingRacePathTest.php` | — |
| `tests/Feature/Http/OnboardingNonRacePathsTest.php` | — |
| `tests/Feature/Http/OnboardingCoachStyleTest.php` | — |
| `tests/Feature/Http/OnboardingShowTest.php` | No onboarding show endpoint anymore |

### Backend — modify-and-keep

| Path | Changes |
|---|---|
| `app/Services/RunningProfileService.php` | `analyze()` is now called synchronously from the `get_running_profile` tool when no cached profile exists. No code change needed if the tool handles this. |
| `app/Ai/Tools/GetRunningProfile.php` | When no cached profile, trigger `RunningProfileService::analyze()` inline rather than returning "no profile" — the agent should always get a profile back |
| `database/migrations/..._create_agent_conversations_table.php` | No change — `context` column stays |
| `database/migrations/..._add_meta_to_agent_conversations_table.php` | Safe to delete — no code uses `meta` for onboarding anymore — but leaving it in place is also fine (empty nullable column). Delete for cleanliness. |
| `tests/Feature/Http/OnboardingStartTest.php` | Rewrite: assert conversation created with `context='onboarding'`; no job dispatch assertion (no job anymore) |

### Flutter (`app/lib/`) — new files

None. Everything reuses existing providers and widgets.

### Flutter — modified

| Path | Why |
|---|---|
| `features/coach/models/coach_message.dart` | Drop `messageType` + `messagePayload`. Add optional `statsCard` + `chips` fields populated from tool_results (same pattern as `proposal`) |
| `features/coach/models/coach_stats_card.dart` | **New** — Freezed model for stats payload (`metrics: Map<String, dynamic>`) |
| `features/coach/models/coach_chip_suggestions.dart` | **New** — Freezed model for chips (`chips: List<CoachChip>` with `label` + `value`) |
| `features/coach/widgets/message_bubble.dart` | Replace the `messageType` switch with: if `message.statsCard != null` render `StatsCardBubble`; if `message.chips != null` render `ChipSuggestionsRow` below the bubble |
| `features/coach/widgets/stats_card_bubble.dart` | Keep, take `CoachStatsCard` instead of raw Map |
| `features/coach/widgets/chip_suggestions_row.dart` | Keep, take `List<CoachChip>` instead of raw list |
| `features/coach/providers/coach_provider.dart` | In `CoachChat.sendMessage`, handle new stream events `StatsEvent` + `ChipsEvent` — attach to current message |
| `features/coach/data/coach_stream_client.dart` | Parse `data-stats` and `data-chips` SSE events into `StatsEvent` + `ChipsEvent` |
| `features/coach/models/vercel_stream_event.dart` | Add `StatsEvent` + `ChipsEvent` sealed variants |
| `features/coach/data/coach_api.dart` (+ `.g`) | Retrofit `getConversation` response type already untyped; no schema change needed, but make sure it parses tool_results on messages |
| `features/onboarding/screens/onboarding_shell.dart` | Thin scaffold; on mount, POST `/onboarding/start` to get `conversation_id`; mount `CoachChatView` with regular `coachChatProvider(id)` |

### Flutter — deleted

| Path | Why |
|---|---|
| `features/onboarding/providers/onboarding_chat_provider.dart` + `.g` | Replaced by `coachChatProvider` |
| `features/onboarding/data/onboarding_api.dart` + `.g` | Only `start` endpoint remains — expose via a tiny Retrofit method on `coach_api.dart` instead, or via inline `Dio` call in the shell |
| `features/onboarding/providers/onboarding_provider.dart` + `.g` | Merged into the shell's on-mount effect |

---

# Phase 1 — Backend tools + agent instructions

## Task 1: Create `PresentRunningStats` tool

**Files:**
- Create: `api/app/Ai/Tools/PresentRunningStats.php`
- Test: `api/tests/Feature/Ai/Tools/PresentRunningStatsTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Ai/Tools/PresentRunningStatsTest.php`:

```php
<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\PresentRunningStats;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\Request;
use Laravel\Ai\Schema\JsonSchema;
use Tests\TestCase;

class PresentRunningStatsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_stats_card_payload(): void
    {
        $user = User::factory()->create();
        $tool = new PresentRunningStats($user);

        $request = Request::create('', 'POST', [
            'weekly_avg_km' => 25.0,
            'weekly_avg_runs' => 3,
            'avg_pace_seconds_per_km' => 295,
            'session_avg_duration_seconds' => 2700,
        ]);

        $raw = $tool->handle($request);
        $decoded = json_decode($raw, true);

        $this->assertEquals('stats_card', $decoded['display']);
        $this->assertEquals(25.0, $decoded['metrics']['weekly_avg_km']);
        $this->assertEquals(3, $decoded['metrics']['weekly_avg_runs']);
    }

    public function test_schema_declares_all_four_metric_params(): void
    {
        $user = User::factory()->create();
        $tool = new PresentRunningStats($user);
        $schema = $tool->schema(new JsonSchema);

        $names = array_column($schema, 'name');
        sort($names);
        $this->assertEquals(
            ['avg_pace_seconds_per_km', 'session_avg_duration_seconds', 'weekly_avg_km', 'weekly_avg_runs'],
            $names,
        );
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact --filter=PresentRunningStatsTest
```

Expected: FAIL — class missing.

- [ ] **Step 3: Create the tool**

Mirror the structure of `api/app/Ai/Tools/GetRunningProfile.php`. Create `api/app/Ai/Tools/PresentRunningStats.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Http\Request;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Schema\JsonSchema;

class PresentRunningStats implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<TXT
Render a stats card in the chat for the user. Use this AS THE FIRST THING in an onboarding conversation, right after silently loading the profile, to show the user their 12-month snapshot. The UI will render a 2×2 grid of tiles with the supplied metrics. After calling this tool, follow up with a short warm narrative line and move on to asking what they're training for.

DO NOT use this outside onboarding.
TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            $schema->number('weekly_avg_km')
                ->description('Weekly average kilometers over the last 12 months')
                ->required(),
            $schema->integer('weekly_avg_runs')
                ->description('Weekly average run count over the last 12 months')
                ->required(),
            $schema->integer('avg_pace_seconds_per_km')
                ->description('Average pace, seconds per km')
                ->required(),
            $schema->integer('session_avg_duration_seconds')
                ->description('Average run duration, seconds')
                ->required(),
        ];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'display' => 'stats_card',
            'metrics' => [
                'weekly_avg_km' => $request['weekly_avg_km'],
                'weekly_avg_runs' => $request['weekly_avg_runs'],
                'avg_pace_seconds_per_km' => $request['avg_pace_seconds_per_km'],
                'session_avg_duration_seconds' => $request['session_avg_duration_seconds'],
            ],
        ]);
    }
}
```

- [ ] **Step 4: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact --filter=PresentRunningStatsTest
```

Expected: PASS.

- [ ] **Step 5: Pint + commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
```

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): PresentRunningStats agent tool"
```

---

## Task 2: Create `OfferChoices` tool

**Files:**
- Create: `api/app/Ai/Tools/OfferChoices.php`
- Test: `api/tests/Feature/Ai/Tools/OfferChoicesTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature\Ai\Tools;

use App\Ai\Tools\OfferChoices;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Http\Request;
use Laravel\Ai\Schema\JsonSchema;
use Tests\TestCase;

class OfferChoicesTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_chip_suggestions_payload(): void
    {
        $user = User::factory()->create();
        $tool = new OfferChoices($user);

        $request = Request::create('', 'POST', [
            'chips' => [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
            ],
        ]);

        $raw = $tool->handle($request);
        $decoded = json_decode($raw, true);

        $this->assertEquals('chip_suggestions', $decoded['display']);
        $this->assertCount(3, $decoded['chips']);
        $this->assertEquals('race', $decoded['chips'][0]['value']);
    }
}
```

- [ ] **Step 2: Run to verify it fails.**

- [ ] **Step 3: Create the tool**

`api/app/Ai/Tools/OfferChoices.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Http\Request;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Schema\JsonSchema;

class OfferChoices implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<TXT
Render a row of tappable chip suggestions for the user. Use this when you have a short closed-list question: what distance, how many days per week, coach style, etc. The user can tap a chip OR type free text — both arrive back as a regular user message; you parse whichever. Provide 2–6 chips. Each chip has a display `label` and a machine-friendly `value`. Labels should be human (e.g. "Half marathon"); values should be stable keys (e.g. "half_marathon").

DO NOT use this for the final plan proposal — use create_schedule for that.
TXT;
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            $schema->array('chips')
                ->description('2–6 chip options. Each has `label` (human) and `value` (machine).')
                ->items(
                    $schema->object()
                        ->property('label', $schema->string()->required())
                        ->property('value', $schema->string()->required())
                )
                ->required(),
        ];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'display' => 'chip_suggestions',
            'chips' => $request['chips'],
        ]);
    }
}
```

- [ ] **Step 4: Run test, pint, commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact --filter=OfferChoicesTest
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): OfferChoices agent tool"
```

---

## Task 3: Auto-analyze in `GetRunningProfile` when profile missing

**Files:**
- Modify: `api/app/Ai/Tools/GetRunningProfile.php`
- Test: `api/tests/Feature/Ai/Tools/GetRunningProfileTest.php` — extend existing

- [ ] **Step 1: Add a test for the auto-analyze behaviour**

Add to `GetRunningProfileTest`:

```php
public function test_triggers_analysis_when_no_profile_cached(): void
{
    $user = User::factory()->create();
    $this->assertNull(\App\Models\UserRunningProfile::where('user_id', $user->id)->first());

    $fakeProfile = \App\Models\UserRunningProfile::create([
        'user_id' => $user->id,
        'metrics' => ['weekly_avg_km' => 20.0, 'weekly_avg_runs' => 3],
        'narrative_summary' => 'Consistent.',
        'analyzed_at' => now(),
    ]);
    // Delete so analyze() is the only path to a profile
    $fakeProfile->delete();

    $service = \Mockery::mock(\App\Services\RunningProfileService::class);
    $service->shouldReceive('analyze')->once()->with(\Mockery::on(fn ($u) => $u->id === $user->id))
        ->andReturnUsing(function ($u) {
            return \App\Models\UserRunningProfile::create([
                'user_id' => $u->id,
                'metrics' => ['weekly_avg_km' => 20.0, 'weekly_avg_runs' => 3],
                'narrative_summary' => 'Freshly analysed.',
                'analyzed_at' => now(),
            ]);
        });
    $this->app->instance(\App\Services\RunningProfileService::class, $service);

    $tool = new \App\Ai\Tools\GetRunningProfile($user);
    $raw = $tool->handle(\Illuminate\Http\Request::create('', 'POST'));
    $decoded = json_decode($raw, true);

    $this->assertEquals(20.0, $decoded['metrics']['weekly_avg_km']);
    $this->assertEquals('Freshly analysed.', $decoded['narrative_summary']);
}
```

- [ ] **Step 2: Run to see it fails (current impl returns "no profile" without analyzing).**

- [ ] **Step 3: Update the tool**

In `api/app/Ai/Tools/GetRunningProfile.php`, replace the "no profile" early-return with a synchronous analyze call. Constructor stays; add `RunningProfileService` via app resolution:

```php
public function handle(Request $request): string
{
    $profile = UserRunningProfile::where('user_id', $this->user->id)->first();

    if (!$profile) {
        $profile = app(\App\Services\RunningProfileService::class)->analyze($this->user);
    }

    return json_encode([
        'analyzed_at' => optional($profile->analyzed_at)->toIso8601String(),
        'metrics' => $profile->metrics,
        'narrative_summary' => $profile->narrative_summary,
    ]);
}
```

Update the description too:

```
Get the user's 12-month running profile (weekly averages, pace, consistency, narrative). Fast cached lookup. If no cache exists (first onboarding call), this triggers a fresh Strava fetch + analysis — takes 5–15 seconds but happens inline. Always returns a profile.
```

- [ ] **Step 4: Run tests, pint, commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact --filter=GetRunningProfileTest
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): GetRunningProfile auto-analyzes when no cached profile"
```

---

## Task 4: Update `RunCoachAgent` — register new tools + onboarding instructions

**Files:**
- Modify: `api/app/Ai/Agents/RunCoachAgent.php`

- [ ] **Step 1: Register the 2 new tools**

In the `tools()` method or equivalent, add `PresentRunningStats::class` and `OfferChoices::class` to the tool list alongside existing tools.

- [ ] **Step 2: Make `instructions()` context-aware**

The agent has access to the active conversation (check the trait `RemembersConversations` — likely `$this->conversation()` or `$this->conversationId()`). Look up the `context` column; if `onboarding`, return onboarding-specific instructions. Else return the existing coach instructions.

Implementation:

```php
public function instructions(): string
{
    $convoId = $this->conversationId();  // from RemembersConversations

    $context = null;
    if ($convoId) {
        $context = \Illuminate\Support\Facades\DB::table('agent_conversations')
            ->where('id', $convoId)
            ->value('context');
    }

    if ($context === 'onboarding') {
        return $this->onboardingInstructions();
    }

    return $this->coachInstructions();  // extract existing instructions into this method
}

private function onboardingInstructions(): string
{
    return <<<TXT
You are onboarding a new user to the RunCore coaching app. Follow this exact sequence. Do not skip steps. Do not be chatty before step 1.

STEP 1 — Analyze running history:
Silently call `get_running_profile`. This loads 12 months of Strava data (may take 5–15s on first call).

STEP 2 — Show the snapshot:
Call `present_running_stats` with the 4 metrics from the profile: weekly_avg_km, weekly_avg_runs, avg_pace_seconds_per_km, session_avg_duration_seconds.

STEP 3 — Warm narrative (1 sentence, in the chat message, no tool call):
Paraphrase the profile's narrative_summary into ONE short sentence. Example: "Strong year — consistent weeks and a clear progression in your long runs."

STEP 4 — Ask the branching question, in the SAME message, followed by a `offer_choices` tool call:
Message text: "Anything you're training for, or want to work toward?"
Chips: [
  {label: "Race coming up!", value: "race"},
  {label: "General fitness", value: "general_fitness"},
  {label: "Get faster", value: "pr_attempt"}
]

STEP 5 — Branch on user's reply:

IF user chose "race" (value `race` OR free text like "marathon in March"):
  Reply: "Alright, let's get you going! To create the plan I need:\n1. Race name\n2. Race date\n3. Goal time, if you have one\n\nOptional but helpful: race distance (if not obvious from the name), days/week you want to run, any injuries or days you can't train.\n\nSend me something like: \"City 10K, 12 sep 2025, goal 55:00, 4 days/week\""
  Wait for user free-text. Parse into goal_name, target_date, goal_time_seconds, distance, days_per_week.
  If any of race name, race date, or goal time is missing, ask a single follow-up to fill the gap.
  Then jump to STEP 6.

IF user chose "general_fitness":
  Call `offer_choices` with chips [2, 3, 4, 5, 6] labeled "2 days", "3 days", etc. (values as strings).
  After user responds, jump to STEP 6 with distance=null, target_date=null, goal_time_seconds=null, goal_name="General fitness".

IF user chose "pr_attempt":
  Call `offer_choices` with distance chips: 5k, 10k, half_marathon, marathon, custom.
  After user picks distance, ask: "What's your current PR and target? e.g. \"currently 22:30, target 20:00\""
  Parse both times into seconds. `goal_time_seconds` = target.
  Call `offer_choices` with days/week chips [2..6].
  After user picks, jump to STEP 6 with target_date=null, goal_name="Get faster at {distance}".

STEP 6 — Coach style:
Call `offer_choices` with chips:
[
  {label: "Strict — hold me to it", value: "strict"},
  {label: "Balanced", value: "balanced"},
  {label: "Flexible — adapt to my life", value: "flexible"}
]

STEP 7 — Generate the plan:
Call `create_schedule` with the accumulated parameters:
- goal_type: "race" | "general_fitness" | "pr_attempt"
- goal_name, distance, target_date, goal_time_seconds (all from above; nullable where appropriate)
- schedule: design a sensible weekly plan sized to the user's profile (weekly_avg_km from step 1). Apply the coach style to the tone of the plan descriptions. Follow the 80/20 rule, max 10% weekly overload, taper for races.

The user will see a proposal card and accept/adjust. If they accept, onboarding is complete automatically.

GENERAL RULES:
- NEVER write the chip list as plain text. ALWAYS use `offer_choices` for chip-based questions.
- NEVER skip `present_running_stats` in step 2 — the UI needs the tool result to render the card.
- Keep messages short. One clear thing at a time.
- If the user goes off-script mid-onboarding (asks a random question), briefly answer and then steer back to the current step.
TXT;
}

private function coachInstructions(): string
{
    // ...move the existing instructions content here verbatim
}
```

Exact method names (`conversationId()`) depend on the `RemembersConversations` trait's public API — inspect the trait and adapt. If the trait exposes a different accessor, use whatever it provides. Worst case, pass the conversation id via a setter at request time.

- [ ] **Step 3: Run the existing agent tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact
```

All existing coach tests should still pass (the non-onboarding branch of `instructions()` is the old content). Fix any that break.

- [ ] **Step 4: Pint + commit**

```bash
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): RunCoachAgent onboarding instructions branch on conversation context"
```

---

## Task 5: Simplify `OnboardingController` — just a `start` endpoint

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — reduce to one method
- Modify: `api/routes/api.php` — remove the show + reply routes
- Modify: `api/tests/Feature/Http/OnboardingStartTest.php` — rewrite

- [ ] **Step 1: Rewrite the controller**

Replace the entire controller contents with:

```php
<?php

namespace App\Http\Controllers;

use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    /**
     * Ensure an onboarding conversation exists for the user. Returns its id.
     * Idempotent: returns the existing onboarding conversation if one is open.
     *
     * The frontend then mounts CoachChatView pointed at this conversation and
     * sends its first message via the regular /coach/chat endpoint. The agent,
     * reading `context='onboarding'`, follows the onboarding script.
     */
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();

        $existing = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();

        if ($existing !== null) {
            return response()->json(['conversation_id' => $existing->id]);
        }

        $conversationId = (string) Str::uuid();
        $now = now();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['conversation_id' => $conversationId]);
    }
}
```

- [ ] **Step 2: Remove the onboarding show + reply routes**

Open `api/routes/api.php`. Keep:
```php
Route::prefix('onboarding')->group(function () {
    Route::post('/start', [\App\Http\Controllers\OnboardingController::class, 'start']);
});
```

Delete the `/conversations/{conversationId}` show route and the `/conversations/{conversationId}/messages` reply route.

- [ ] **Step 3: Rewrite the start test**

Replace `api/tests/Feature/Http/OnboardingStartTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingStartTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_creates_onboarding_conversation(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/onboarding/start');

        $response->assertOk()->assertJsonStructure(['conversation_id']);

        $this->assertEquals(
            1,
            DB::table('agent_conversations')
                ->where('user_id', $user->id)
                ->where('context', 'onboarding')
                ->count(),
        );
    }

    public function test_idempotent(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $first = $this->postJson('/api/v1/onboarding/start')->assertOk();
        $second = $this->postJson('/api/v1/onboarding/start')->assertOk();

        $this->assertEquals(
            $first->json('conversation_id'),
            $second->json('conversation_id'),
        );
    }
}
```

- [ ] **Step 4: Run the onboarding tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact --filter=OnboardingStartTest
```

- [ ] **Step 5: Pint + commit**

```bash
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "refactor(api): OnboardingController reduced to start endpoint; delete state machine"
```

---

## Task 6: Delete dead code (jobs, classifier, obsolete tests)

**Files to delete:**
- `api/app/Jobs/AnalyzeRunningProfileJob.php`
- `api/app/Jobs/RunOnboardingPlanAgentJob.php`
- `api/app/Services/ChipClassifier.php`
- `api/tests/Feature/Services/ChipClassifierTest.php`
- `api/tests/Feature/Jobs/AnalyzeRunningProfileJobTest.php`
- `api/tests/Feature/Http/OnboardingBranchTest.php`
- `api/tests/Feature/Http/OnboardingRacePathTest.php`
- `api/tests/Feature/Http/OnboardingNonRacePathsTest.php`
- `api/tests/Feature/Http/OnboardingCoachStyleTest.php`
- `api/tests/Feature/Http/OnboardingShowTest.php`
- `api/database/migrations/2026_04_16_161356_add_meta_to_agent_conversations_table.php` (no longer needed; `meta` column was only for `onboarding_step`)

- [ ] **Step 1: Delete files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
git rm app/Jobs/AnalyzeRunningProfileJob.php
git rm app/Jobs/RunOnboardingPlanAgentJob.php
git rm app/Services/ChipClassifier.php
git rm tests/Feature/Services/ChipClassifierTest.php
git rm tests/Feature/Jobs/AnalyzeRunningProfileJobTest.php
git rm tests/Feature/Http/OnboardingBranchTest.php
git rm tests/Feature/Http/OnboardingRacePathTest.php
git rm tests/Feature/Http/OnboardingNonRacePathsTest.php
git rm tests/Feature/Http/OnboardingCoachStyleTest.php
git rm tests/Feature/Http/OnboardingShowTest.php
git rm database/migrations/2026_04_16_161356_add_meta_to_agent_conversations_table.php
```

- [ ] **Step 2: Grep for any stragglers**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
grep -rn "AnalyzeRunningProfileJob\|RunOnboardingPlanAgentJob\|ChipClassifier" app tests routes 2>&1 | head
```

Expected: no output. Fix any remaining references manually.

- [ ] **Step 3: migrate:fresh + run tests**

```bash
php artisan migrate:fresh
php artisan test --compact
```

All tests pass.

- [ ] **Step 4: Pint + commit**

```bash
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "chore(api): delete onboarding jobs, ChipClassifier, obsolete tests"
```

---

## Task 7: `CoachController::show` returns `tool_results` per message

**Files:**
- Modify: `api/app/Http/Controllers/CoachController.php::show`
- Test: `api/tests/Feature/CoachChatTest.php` — extend existing conversation show test

Rationale: when the Flutter client reloads a conversation (or for the regular coach view), it needs tool_results so it can re-hydrate stats cards and chip suggestions on historic messages (same as proposals, but proposals currently come from a separate table — we can follow the same pattern as proposals OR inline them via tool_results).

- [ ] **Step 1: Extend show**

Currently `show()` selects `['id', 'role', 'content', 'created_at']`. Add `tool_results` (raw JSON string column, same storage as proposals use):

```php
$messages = DB::table('agent_conversation_messages')
    ->where('conversation_id', $conversationId)
    ->whereIn('role', ['user', 'assistant'])
    ->orderBy('created_at')
    ->get(['id', 'role', 'content', 'tool_results', 'created_at']);
```

Decode `tool_results` on each message before returning:

```php
$messagesWithProposals = $messages->map(function ($msg) use ($proposals) {
    $msg->proposal = $proposals->get($msg->id);
    $msg->tool_results = json_decode($msg->tool_results ?? '[]', true) ?: [];
    return $msg;
});
```

- [ ] **Step 2: Add a show test that asserts tool_results come through**

```php
public function test_show_returns_tool_results_for_messages(): void
{
    $user = User::factory()->create();
    Sanctum::actingAs($user);

    $convoId = (string) Str::uuid();
    DB::table('agent_conversations')->insert([
        'id' => $convoId, 'user_id' => $user->id, 'title' => 'Test',
        'created_at' => now(), 'updated_at' => now(),
    ]);
    $msgId = (string) Str::uuid();
    DB::table('agent_conversation_messages')->insert([
        'id' => $msgId,
        'conversation_id' => $convoId,
        'user_id' => $user->id,
        'agent' => 'RunCoachAgent',
        'role' => 'assistant',
        'content' => 'hi',
        'attachments' => '[]',
        'tool_calls' => '[]',
        'tool_results' => json_encode([
            ['tool' => 'present_running_stats', 'result' => [
                'display' => 'stats_card',
                'metrics' => ['weekly_avg_km' => 20.0],
            ]],
        ]),
        'usage' => '[]',
        'meta' => null,
        'created_at' => now(),
        'updated_at' => now(),
    ]);

    $response = $this->getJson("/api/v1/coach/conversations/{$convoId}")->assertOk();

    $this->assertCount(1, $response->json('data.messages'));
    $this->assertEquals('stats_card',
        $response->json('data.messages.0.tool_results.0.result.display')
    );
}
```

- [ ] **Step 3: Run tests, pint, commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): coach show returns tool_results per message"
```

---

## Task 8: Stream `data-stats` + `data-chips` SSE events

**Files:**
- Modify: `api/app/Http/Controllers/CoachController.php::sendMessage` — detect new tool types and emit events

- [ ] **Step 1: Emit dedicated events when the stream encounters these tools**

Inside the streaming loop, after consuming each agent event, inspect `tool_results` for the current message. If the latest tool_result's `display` is `stats_card` or `chip_suggestions`, emit an SSE data event before continuing:

```php
foreach ($stream as $event) {
    $payload = $event->toVercelProtocolArray();
    if (! empty($payload)) {
        echo 'data: '.json_encode($payload)."\n\n";
        ob_flush();
        flush();
    }

    // If the agent just finished a tool that produces UI, emit a dedicated event.
    // $event's shape depends on the SDK — adapt to whatever ToolEnd/ToolResult event it emits.
    if (method_exists($event, 'toolName') && method_exists($event, 'result')) {
        $result = $event->result();
        if (is_array($result)) {
            if (($result['display'] ?? null) === 'stats_card') {
                echo 'data: '.json_encode([
                    'type' => 'data-stats',
                    'data' => ['metrics' => $result['metrics']],
                ])."\n\n";
                ob_flush(); flush();
            }
            if (($result['display'] ?? null) === 'chip_suggestions') {
                echo 'data: '.json_encode([
                    'type' => 'data-chips',
                    'data' => ['chips' => $result['chips']],
                ])."\n\n";
                ob_flush(); flush();
            }
        }
    }
}
```

Adapt to the actual SDK event shape — inspect `Laravel\Ai\Events\*` or equivalent to find the tool-end event's public accessors. If `toolName()`/`result()` aren't exactly those names, use whatever the SDK exposes.

- [ ] **Step 2: No test for the stream (it's hard to test SSE cleanly).**

Existing `CoachChatTest::test_accept_proposal` + friends continue to pass — the proposal streaming still works the same way.

- [ ] **Step 3: Pint + commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "feat(api): stream data-stats + data-chips events for onboarding UI tools"
```

---

# Phase 2 — Flutter refactor

## Task 9: New Freezed models `CoachStatsCard` + `CoachChipSuggestions`

**Files:**
- Create: `app/lib/features/coach/models/coach_stats_card.dart`
- Create: `app/lib/features/coach/models/coach_chip.dart`

- [ ] **Step 1: Create `coach_stats_card.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_stats_card.freezed.dart';
part 'coach_stats_card.g.dart';

@freezed
sealed class CoachStatsCard with _$CoachStatsCard {
  const factory CoachStatsCard({
    required Map<String, dynamic> metrics,
  }) = _CoachStatsCard;

  factory CoachStatsCard.fromJson(Map<String, dynamic> json) =>
      _$CoachStatsCardFromJson(json);
}
```

- [ ] **Step 2: Create `coach_chip.dart`**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_chip.freezed.dart';
part 'coach_chip.g.dart';

@freezed
sealed class CoachChip with _$CoachChip {
  const factory CoachChip({
    required String label,
    required String value,
  }) = _CoachChip;

  factory CoachChip.fromJson(Map<String, dynamic> json) =>
      _$CoachChipFromJson(json);
}
```

- [ ] **Step 3: Regen + analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "feat(app): CoachStatsCard + CoachChip freezed models"
```

---

## Task 10: Update `CoachMessage` — drop messageType, add statsCard + chips

**Files:**
- Modify: `app/lib/features/coach/models/coach_message.dart`

- [ ] **Step 1: Replace fields**

Drop `messageType` and `messagePayload`. Add:

```dart
@JsonKey(includeFromJson: false, includeToJson: false)
CoachStatsCard? statsCard,
@JsonKey(includeFromJson: false, includeToJson: false)
List<CoachChip>? chips,
```

They're streaming-derived (same pattern as `proposal`) — the Freezed class doesn't serialize them from the raw JSON; the notifier populates them.

- [ ] **Step 2: Populate from `tool_results` when hydrating historic messages**

Add a static helper:

```dart
factory CoachMessage.fromShowJson(Map<String, dynamic> json) {
  final base = CoachMessage.fromJson(json);
  final toolResults = (json['tool_results'] as List?) ?? const [];

  CoachStatsCard? stats;
  List<CoachChip>? chips;
  for (final tr in toolResults) {
    final result = (tr as Map)['result'];
    if (result is! Map) continue;
    if (result['display'] == 'stats_card') {
      stats = CoachStatsCard.fromJson(
        Map<String, dynamic>.from(result['metrics'] == null
          ? result
          : {'metrics': result['metrics']}),
      );
    }
    if (result['display'] == 'chip_suggestions') {
      final rawChips = (result['chips'] as List?) ?? const [];
      chips = rawChips
          .map((c) => CoachChip.fromJson(Map<String, dynamic>.from(c as Map)))
          .toList();
    }
  }

  return base.copyWith(statsCard: stats, chips: chips);
}
```

- [ ] **Step 3: Update `coach_provider.dart` to use `fromShowJson` when loading conversations**

```dart
return messagesList
    .map((e) => CoachMessage.fromShowJson(e as Map<String, dynamic>))
    .toList();
```

- [ ] **Step 4: Regen + analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "feat(app): CoachMessage drops messageType, gains statsCard + chips from tool_results"
```

---

## Task 11: Parse `data-stats` + `data-chips` SSE events

**Files:**
- Modify: `app/lib/features/coach/models/vercel_stream_event.dart`
- Modify: `app/lib/features/coach/data/coach_stream_client.dart`

- [ ] **Step 1: Add event variants**

In `vercel_stream_event.dart`, add sealed variants:

```dart
class StatsEvent extends VercelStreamEvent {
  final CoachStatsCard stats;
  const StatsEvent(this.stats);
}

class ChipsEvent extends VercelStreamEvent {
  final List<CoachChip> chips;
  const ChipsEvent(this.chips);
}
```

(Adapt to the existing sealed class structure — add import for the two new models.)

- [ ] **Step 2: Parse them in the stream client**

In `coach_stream_client.dart` wherever the parser dispatches on `type`, add:

```dart
case 'data-stats':
  final metrics = (data['metrics'] as Map).cast<String, dynamic>();
  yield StatsEvent(CoachStatsCard(metrics: metrics));
  break;
case 'data-chips':
  final rawChips = (data['chips'] as List);
  final chips = rawChips
      .map((c) => CoachChip.fromJson(Map<String, dynamic>.from(c as Map)))
      .toList();
  yield ChipsEvent(chips);
  break;
```

- [ ] **Step 3: Handle in `CoachChat.sendMessage`'s switch**

```dart
current = switch (event) {
  TextDeltaEvent(:final delta) => current.copyWith(
      content: current.content + delta,
      toolIndicator: null,
    ),
  ToolStartEvent(:final toolName) =>
    current.copyWith(toolIndicator: toolName),
  ToolEndEvent() => current,
  ProposalEvent(:final proposal) => current.copyWith(proposal: proposal),
  StatsEvent(:final stats) => current.copyWith(statsCard: stats),
  ChipsEvent(:final chips) => current.copyWith(chips: chips),
  ErrorEvent(:final message) => current.copyWith(
      errorDetail: message, streaming: false,
    ),
  DoneEvent() =>
    current.copyWith(streaming: false, toolIndicator: null),
};
```

- [ ] **Step 4: Analyze + commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "feat(app): stream parses data-stats + data-chips into CoachMessage fields"
```

---

## Task 12: `MessageBubble` renders `statsCard` + `chips` instead of `messageType`

**Files:**
- Modify: `app/lib/features/coach/widgets/message_bubble.dart`
- Modify: `app/lib/features/coach/widgets/stats_card_bubble.dart` (signature: take `CoachStatsCard`)
- Modify: `app/lib/features/coach/widgets/chip_suggestions_row.dart` (signature: take `List<CoachChip>`)

- [ ] **Step 1: Swap widget signatures**

`StatsCardBubble({required CoachStatsCard statsCard})` — internally read `statsCard.metrics['...']`.
`ChipSuggestionsRow({required List<CoachChip> chips, required void Function(String label, String value) onTap})` — `chips.map((c) => ... c.label ... c.value)`.

- [ ] **Step 2: Rewrite `MessageBubble.build`**

Drop the `messageType` switch. Render in order: the text bubble (if `content.isNotEmpty`), then if `message.statsCard != null` render `StatsCardBubble` under it, then if `message.chips != null` render `ChipSuggestionsRow` under that. The ThinkingCard still shows while `message.streaming && content.isEmpty && statsCard == null && chips == null`.

Rough structure:

```dart
@override
Widget build(BuildContext context) {
  final children = <Widget>[];

  if (message.content.isNotEmpty || message.streaming) {
    children.add(_existingTextBubble(context));  // unchanged
  }

  if (message.statsCard != null) {
    children.add(const SizedBox(height: 8));
    children.add(StatsCardBubble(statsCard: message.statsCard!));
  }

  if (message.chips != null && message.chips!.isNotEmpty) {
    children.add(const SizedBox(height: 8));
    children.add(ChipSuggestionsRow(
      chips: message.chips!,
      onTap: onChipTap ?? (_, __) {},
    ));
  }

  if (children.isEmpty) return const SizedBox.shrink();

  return Column(
    crossAxisAlignment: message.role == 'user'
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: children,
  );
}
```

- [ ] **Step 3: Analyze + commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs  # if any freezed changed
flutter analyze
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "feat(app): MessageBubble renders statsCard + chips instead of messageType switch"
```

---

## Task 13: `OnboardingShell` uses `coachChatProvider`; delete onboarding feature code

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_shell.dart`
- Delete: `app/lib/features/onboarding/data/onboarding_api.dart` + `.g`
- Delete: `app/lib/features/onboarding/providers/onboarding_chat_provider.dart` + `.g`
- Delete: `app/lib/features/onboarding/providers/onboarding_provider.dart` + `.g`

- [ ] **Step 1: Replace `OnboardingShell`**

```dart
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/coach/providers/coach_provider.dart'
    show coachChatProvider, proposalActionsProvider;
import 'package:app/features/coach/widgets/coach_chat_view.dart';

part 'onboarding_shell.g.dart';

@riverpod
Future<String> _onboardingConversationId(_OnboardingConversationIdRef ref) async {
  final dio = ref.watch(dioProvider);
  final response = await dio.post('/onboarding/start');
  return (response.data as Map<String, dynamic>)['conversation_id'] as String;
}

class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(_onboardingConversationIdProvider);

    return CupertinoPageScaffold(
      backgroundColor: AppColors.neutral,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.25, 0.5, 0.75, 1.0],
            colors: [
              AppColors.neutral,
              Color(0xFFFAF1D9),
              AppColors.neutral,
              Color(0xFFFAF1D9),
              AppColors.neutral,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              const SizedBox(
                height: 44,
                child: Center(
                  child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8),
                ),
              ),
              Expanded(
                child: idAsync.when(
                  data: (id) => _OnboardingAutoKickoff(
                    conversationId: id,
                    child: CoachChatView(
                      conversationId: id,
                      watchMessages: (ref) =>
                          ref.watch(coachChatProvider(id)),
                      sendMessage: (ref, text, {chipValue}) => ref
                          .read(coachChatProvider(id).notifier)
                          .sendMessage(text, chipValue: chipValue),
                      onAccept: (ref, proposalId) => ref
                          .read(proposalActionsProvider.notifier)
                          .accept(proposalId),
                      onReject: (ref, proposalId) => ref
                          .read(proposalActionsProvider.notifier)
                          .reject(proposalId),
                      onInvalidate: (ref) =>
                          ref.invalidate(coachChatProvider(id)),
                    ),
                  ),
                  loading: () =>
                      const Center(child: CupertinoActivityIndicator()),
                  error: (e, _) =>
                      Center(child: Text("Couldn't start onboarding: $e")),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sends an initial trigger message on first mount so the agent starts its
/// onboarding script. Subsequent mounts do nothing (the conversation already
/// has messages).
class _OnboardingAutoKickoff extends ConsumerStatefulWidget {
  final String conversationId;
  final Widget child;

  const _OnboardingAutoKickoff({
    required this.conversationId,
    required this.child,
  });

  @override
  ConsumerState<_OnboardingAutoKickoff> createState() =>
      _OnboardingAutoKickoffState();
}

class _OnboardingAutoKickoffState
    extends ConsumerState<_OnboardingAutoKickoff> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final messages =
          await ref.read(coachChatProvider(widget.conversationId).future);
      if (messages.isEmpty && mounted) {
        await ref
            .read(coachChatProvider(widget.conversationId).notifier)
            .sendMessage('__onboarding_start__');
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
```

The trigger message `__onboarding_start__` is a sentinel the agent ignores (onboarding instructions say "ignore the first user message if its text is `__onboarding_start__` — it's just a trigger"). Add a note in the agent instructions (Task 4) about this sentinel.

Alternative: skip the sentinel and have the backend seed an initial message server-side on first `/onboarding/start`. Either works; sentinel is simpler.

- [ ] **Step 2: Delete onboarding data + provider files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
git rm lib/features/onboarding/data/onboarding_api.dart
git rm lib/features/onboarding/data/onboarding_api.g.dart
git rm lib/features/onboarding/providers/onboarding_chat_provider.dart
git rm lib/features/onboarding/providers/onboarding_chat_provider.g.dart
git rm lib/features/onboarding/providers/onboarding_provider.dart
git rm lib/features/onboarding/providers/onboarding_provider.g.dart
```

- [ ] **Step 3: Update the agent onboarding instructions (Task 4) to include the sentinel rule**

In `RunCoachAgent::onboardingInstructions()`, prepend:

```
SPECIAL: If the user's first message is exactly `__onboarding_start__`, silently ignore it (do NOT reply to it) and start the script from STEP 1.
```

Go back to the api commit and amend, or land this as a small follow-up commit.

- [ ] **Step 4: Regen + analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api app
git commit -m "refactor(app): OnboardingShell uses coachChatProvider; delete onboarding provider + api"
```

---

# Phase 3 — Verification

## Task 14: End-to-end test + manual check

- [ ] **Step 1: Run the full backend suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan migrate:fresh
php artisan test --compact
```

Expected: all pass. Count will be lower than before because a lot of tests were deleted; that's fine.

- [ ] **Step 2: Flutter analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 3: Manual run on iOS device (per `app/CLAUDE.md`)**

Backend:
```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan serve --host=0.0.0.0 --port=8000
```

In a second terminal (only needed if QUEUE_CONNECTION stays `database`; or set `QUEUE_CONNECTION=sync` in `.env`):
```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan queue:work
```

(Note: `RunningProfileService::analyze` is called synchronously from `GetRunningProfile`, no queue worker needed anymore for onboarding. Only webhook-triggered activity jobs still need the worker.)

Flush stale state for a fresh run:
```bash
php artisan tinker --execute='\App\Models\User::first()?->update(["has_completed_onboarding" => false]); \App\Models\UserRunningProfile::truncate(); \DB::table("agent_conversations")->where("context", "onboarding")->delete();'
```

Flutter:
```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter run
```

- [ ] **Step 4: Verify the 3 happy paths**

1. **Race path**: open app → connect Strava → stats card appears within ~15s → chip row appears → tap "Race coming up!" → prompt for race details appears → type `City 10K, 12 sep 2025, goal 55:00, 4 days/week` → coach_style chips appear → tap one → "Working on your plan" loading → proposal card → tap Accept → dashboard.

2. **General fitness**: same up to chips → tap "General fitness" → days/week chips → tap "4 days" → coach_style chips → tap one → proposal → accept.

3. **Get faster**: same up to chips → tap "Get faster" → distance chips → tap "5k" → prompt for PR+target → type `currently 22:30, target 20:00` → days/week chips → tap one → coach_style chips → tap one → proposal → accept.

- [ ] **Step 5: Verify streaming works**

- Stats card should appear without a visible polling cycle — it streams in via `data-stats`.
- Chips should appear without polling.
- Text messages from the agent should stream character-by-character.
- No `/onboarding/conversations/*` requests in the Laravel logs during the flow (only `/onboarding/start` once, then `/coach/chat/*/messages` for replies).

- [ ] **Step 6: Kill mid-flow, resume**

Kill the Flutter app mid-flow. Relaunch. Onboarding should pick up from the last bot message (loaded via `coachChatProvider` → `GET /coach/conversations/{id}` which returns historic `tool_results` that hydrate the stats card and chips).

- [ ] **Step 7: If everything passes, commit a final cleanup + close out**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git log --oneline feat/onboarding-and-goal-rename | head -20
```

The refactor is complete.

---

## Deferred / future

- The old sentinel-based kickoff message `__onboarding_start__` is a minor wart. If it shows up in user-visible chat history (e.g., the Cloud AI admin UI) we should swap to a server-side auto-seed where `OnboardingController::start` inserts a system message that triggers the agent automatically on first `GET /coach/conversations/{id}`. Tracked for when we care about admin-view cleanliness.
- The refactor deletes `AnalyzeRunningProfileJob` entirely. If/when we want to re-analyze periodically (weekly refresh), that becomes a scheduled job that just calls `RunningProfileService::analyze()` for active users — not part of this plan.
