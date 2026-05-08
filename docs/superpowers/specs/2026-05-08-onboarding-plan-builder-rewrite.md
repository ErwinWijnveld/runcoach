# Onboarding plan generation — rewrite as deterministic builder

**Status:** Draft, awaiting review
**Date:** 2026-05-08
**Author:** Erwin + Claude

---

## 1. Problem

The first plan a runner gets — the one generated at the end of onboarding — is the most important plan we ever make. It sets the tone for the whole product. Today it has three concrete failure modes:

### 1a. The pace baseline is a 12-month average across all run types

`RunningProfileService::aggregate()` (`api/app/Services/RunningProfileService.php:99-114`) computes:

```php
$avgPace = $totalSeconds / ($totalMeters / 1000);  // every run, 52 weeks, mixed
```

That number is then read directly by `PlanOptimizerService::resolveBaselinePace()` (`api/app/Services/PlanOptimizerService.php:442-448`) and used as the runner's "baseline pace" for filling in easy + long-run paces (everything else gets a fixed delta added: `easy = baseline + 30s`, `long = baseline + 15s`, `tempo = baseline − 25s`, etc).

Concrete failure modes:

| Scenario | Reality | What the service computes |
|---|---|---|
| 11 mo plodding @ 6:30, last 4 weeks fit @ 5:15 after a training block | current ≈ 5:15 | mixes to ≈ 6:20 — every easy run prescribed too slow |
| 3 mo fast (PR), 9 mo injury comeback @ 7:00 | current ≈ 7:00 | mixes to ≈ 6:00 — every easy run prescribed too fast |
| 80% easy @ 6:00 + 20% intervals @ 4:30 | "easy" ≈ 6:00 | mixes to 5:42 — easy runs prescribed at moderate pace |

The existing `paceTrend` field doesn't catch this — it only flags >5% change between the first and second 6-month halves of the 12-mo window, far too coarse. A 4-week ramp-up disappears entirely.

### 1b. The 80/20 polarized rule produces broken plans for 2-3 day/week runners

`RunCoachAgent::planDesignPrinciples()` ships "Polarized 80/20 — ~80% easy, ~20% quality" as a coaching principle the agent should follow. For a runner with 2 days/week that's 1.6 easy + 0.4 quality, which the agent rounds to "2 easy runs". For 3 days/week it's "2 easy + 1 long". Empirically the produced plans rarely contain a tempo or interval session at low frequencies.

That's bad coaching for low-volume runners. The classic FIRST 3-runs-a-week marathon plan (Daniels) explicitly schedules **3 quality runs** per week. The University of Verona study comparing 80/20 vs 40/50/10 in <4 hr/week recreational runners found no significant difference — at low volumes intensity distribution matters less than consistency. ([sources at end of report](#sources))

The product behaviour should be: at 2-3 days/week, prefer fewer-but-quality sessions (1 quality + 1 long; or 1 quality + 1 tempo + 1 long). 80/20 only kicks in meaningfully at 4+ days/week.

### 1c. The agent loop is overengineered for first-plan generation

The current onboarding pipeline is:

```
RunCoachAgent (Sonnet) drafts plan as JSON
  → CreateSchedule tool persists it as proposal
  → agent calls VerifyPlan tool
  → PlanVerifierAgent (Haiku) audits 5 rules
  → if fail: agent calls EditSchedule
  → re-verify (max 2 cycles, hardcoded counter to prevent doom-loop)
  → ProposalService::detectProposalFromConversation reads tool_results
```

This is 3-5 LLM calls, ~60-110s wall clock, ~30-50k input tokens + 8-15k output tokens, with the same coaching rules duplicated in 3 places (agent prompt, optimizer, verifier) and a known doom-loop risk that's already been silenced with hardcoded caps and prompt scrubbing ("never say 'max cycles' to the user").

The verify-loop architecture is genuinely useful for **coach-chat edits** ("can you move my Tuesday?") because that requires coaching judgment about an existing plan. But for the first plan from a structured form input, it's overkill — the structure is deterministic given (current threshold pace, weekly volume, days/week, target date, target pace).

---

## 2. Goals / non-goals

### Goals

1. **Pace baseline must reflect *current* fitness**, not a 12-month average. Recent threshold pace, derived from the runner's actual HR-zone-anchored data over the last 90 days (configurable window).
2. **Session mix must scale with `days_per_week`** — no rigid 80/20 at low frequencies.
3. **First-plan generation should be deterministic, fast, and idempotent.** Same form + same recent activity history = same plan.
4. **Single source of truth for plan-shape rules** — split into clearly-named building blocks, no rule duplicated across prompts and code.
5. **Coach-chat editing flow stays unchanged.** `RunCoachAgent` + `VerifyPlan` + `EditSchedule` keep their current behaviour for "edit my plan" conversations after onboarding completes.

### Non-goals

- Periodically recalibrating fitness as the runner gets fitter through their plan. Out of scope here — there's already a separate `PaceAdjustmentEvaluator` mechanism for per-run nudges, and a future "your fitness has shifted, want to regenerate?" flow is not blocked by this work.
- Replacing the verifier for coach-chat edits. The verify-loop stays for `EditSchedule` flows.
- Strava / Garmin / Polar specifics. The new code reads from `wearable_activities` like everything else does, source-agnostic.
- Multi-goal support, training-plan import/export, structured workout exchange formats.
- Predicting race times the runner didn't ask for. We use goal_time when set; we don't second-guess it.

---

## 3. New architecture

### 3a. Split: dedicated `OnboardingAgent` for the loading-screen path

Today's `RunCoachAgent` branches its `instructions()` on `agent_conversations.context === 'onboarding'`. That branching collapses two genuinely different jobs into one giant prompt + tool surface — the onboarding job needs none of the activity-query tools, none of the chip/stats UI tools, and only one mutation tool (a builder, not the JSON-emitting `CreateSchedule`).

We introduce a new `App\Ai\Agents\OnboardingAgent`:

- Single tool: `BuildOnboardingPlan` (described below).
- No verify loop, no `VerifyPlan` tool, no `EditSchedule` tool.
- Tiny system prompt — its job is essentially "call the tool with these form fields, then say one friendly sentence."
- Still uses `RemembersConversations` so the conversation thread survives for subsequent coach-chat turns. The conversation `context` stays `'onboarding'` until the proposal is accepted; after acceptance, normal coach-chat takes over (and routes back to `RunCoachAgent`'s `coachInstructions()` because the context is no longer onboarding-without-acceptance).

`OnboardingPlanGeneratorService::generate()` stays the public entry point but delegates to `OnboardingAgent` instead of `RunCoachAgent`.

### 3b. New deterministic service: `TrainingPlanBuilder`

```php
namespace App\Services\Onboarding;

final class TrainingPlanBuilder
{
    public function build(
        FitnessSnapshot $snapshot,
        OnboardingFormInput $form,
    ): array;  // shape compatible with existing PlanOptimizerService::optimize()
}
```

Pure PHP service. No LLM call inside. The builder produces the schedule payload directly, then the existing `PlanOptimizerService` runs as a post-pass for race-day enforcement, weekly totals, deduplication, etc — exactly the same passes it does today, just with cleaner inputs.

Why keep `PlanOptimizerService` instead of folding everything into the builder? Because the optimizer is also called from `EditSchedule` (coach-chat path) where it operates on agent-emitted JSON. Keeping it as a separate post-pass means both paths share the same structural-correctness guarantees.

### 3c. New value object: `FitnessSnapshot`

Replaces the 12-month-aggregate input that today flows from `RunningProfileService::metrics`. Lives in `App\Support\Onboarding\FitnessSnapshot`:

```php
final readonly class FitnessSnapshot
{
    public function __construct(
        // Pace anchors, all in seconds-per-km, all derived from
        // recent (≤ 90 day) activity. Null when the derivation
        // chain found no signal — caller falls back to defaults
        // and surfaces "low confidence" copy in the UI.
        public ?int $thresholdPaceSecondsPerKm,
        public ?int $easyPaceSecondsPerKm,
        public ?int $vo2maxPaceSecondsPerKm,

        // How we got the threshold number — drives UI copy and
        // also gates whether the builder is allowed to ramp paces
        // aggressively toward goal_time.
        public PaceConfidence $confidence,        // High | Medium | Low | None
        public PaceDerivation $derivation,        // see enum below

        // Volume signals — also recent-window, not 12 mo.
        public float $weeklyKmRecent4Weeks,
        public float $weeklyRunsRecent4Weeks,
        public float $longestRunRecent8Weeks,

        // Heart-rate context (read from existing user.heart_rate_zones,
        // already populated by HeartRateZoneDeriver after onboarding step).
        public ?int $maxHeartRate,

        // Did the runner do ANY tempo / interval work in the last
        // 12 weeks? Drives whether we ramp quality paces aggressively
        // or conservatively.
        public bool $hasIntensityHistory,
    ) {}
}

enum PaceConfidence: string {
    case High = 'high';      // recent threshold-quality effort observed
    case Medium = 'medium';  // HR-zone-pace derivation succeeded
    case Low = 'low';        // recent avg used as proxy
    case None = 'none';      // no signal — defaults
}

enum PaceDerivation: string {
    case RecentThresholdEffort = 'recent_threshold_effort';
    case HrZonePace = 'hr_zone_pace';
    case RecentAverage = 'recent_average';
    case Fallback = 'fallback';
}
```

### 3d. New service: `FitnessSnapshotService`

```php
namespace App\Services\Onboarding;

final class FitnessSnapshotService
{
    public function snapshot(User $user): FitnessSnapshot;
}
```

Lives alongside (does not replace) `RunningProfileService`. The latter stays in place for the coach-chat narrative ("you've logged 247 runs over 12 months..."), the dashboard, and the existing onboarding overview screen. The snapshot service is purely the input to plan generation.

#### Derivation chain — fall through from best to worst signal

The user explicitly asked for the HR-zone-anchored approach. We make that the **primary** path and use direct threshold-effort detection only as a higher-confidence override when one exists.

##### Step 1 — recent threshold-quality effort (highest confidence)

Scan the last 30 days for a single run that *is* a threshold-equivalent effort:
- Duration 20-60 minutes (matches a tempo or short race)
- Avg HR ≥ 85% of max HR (LT2 lower bound — see [TrainingPeaks thresholds](https://www.trainingpeaks.com/learn/articles/thresholds-411/))
- Pace stable across the run (≤ 10% coefficient of variation, only checkable when `raw_data.splits` exists; otherwise skip this filter)
- Distance ≥ 4 km (filters out hard-effort intervals where avg pace masks per-rep pace)

If found, take its avg pace as `thresholdPaceSecondsPerKm`. Confidence = High, derivation = RecentThresholdEffort.

##### Step 2 — HR-zone pace mining (the user's preferred default — Medium confidence)

For each HR zone Z2..Z5 (resolved from `users.heart_rate_zones`, populated by the existing `HeartRateZoneDeriver`), find the **fastest sustained pace** in that zone over the last 90 days:

```sql
-- per zone: runs whose avg_heartrate falls in the zone, duration ≥ 15 min,
-- ordered by avg_pace_seconds_per_km ascending (faster = lower number)
SELECT id, average_pace_seconds_per_km, average_heartrate, start_date, duration_seconds
FROM wearable_activities
WHERE user_id = ?
  AND type IN ('Run', 'TrailRun', 'VirtualRun')
  AND duration_seconds >= 900                 -- 15 min minimum
  AND average_heartrate BETWEEN ? AND ?       -- zone bounds
  AND average_pace_seconds_per_km IS NOT NULL
  AND average_pace_seconds_per_km BETWEEN 180 AND 720   -- sanity: 3:00-12:00/km
  AND start_date >= NOW() - INTERVAL 90 DAY
ORDER BY average_pace_seconds_per_km ASC
LIMIT 5;
```

For each zone with ≥ 1 hit, take the **median of the top 3** (or just the fastest if 1-2 hits). Median-of-top-N protects against a single GPS-glitch fast pace. Mirrors the pattern `HeartRateZoneDeriver` already uses for max HR.

**Mapping zones to pace anchors:**

| Zone | What it represents | Maps to |
|---|---|---|
| Z2 (60-70% HR) | aerobic / conversational | `easyPaceSecondsPerKm` (raw) |
| Z3 (70-80% HR) | moderate / steady | (used internally for cross-check) |
| Z4 (80-90% HR) | threshold | `thresholdPaceSecondsPerKm` (raw) |
| Z5 (>90% HR) | VO2max | `vo2maxPaceSecondsPerKm` (raw) |

**The "can they still do this?" recency check** (the user explicitly called this out):

For each pace anchor, check whether the run that produced it falls within the **last 30 days** (configurable):

- If yes → use the value as-is.
- If no → **adjust conservatively** by adding seconds-per-km penalty based on how stale the record is:
  - 30-60 days old: +5 sec/km
  - 60-90 days old: +10 sec/km
  - >90 days old: shouldn't happen given the 90-day query cap, but if it does, +15 sec/km.

The exact penalty values are tunable; they should land in `app/Services/Onboarding/FitnessSnapshotService.php` as named constants so they're trivially reviewable and adjustable. **This needs your sign-off — the numbers are coaching judgment, not hard science.**

If the derivation succeeds for at least Z2 and Z4, we have enough to proceed. Confidence = Medium, derivation = HrZonePace.

##### Step 3 — recent average fallback (Low confidence)

When zone-pace derivation produced fewer than two anchor zones (e.g. all the runner's runs are in Z2, no quality history at all):

- Compute avg pace over runs in the last 30 days (NOT 12 mo).
- `easyPaceSecondsPerKm = recent_avg`
- `thresholdPaceSecondsPerKm = recent_avg − 30s` (rough VDOT-ish gap; see [Daniels' easy-to-T-pace gap](https://gopace.run/pace-predictor))
- `vo2maxPaceSecondsPerKm = recent_avg − 50s`

Confidence = Low, derivation = RecentAverage.

##### Step 4 — fallback when no recent runs at all

- All anchors null.
- Confidence = None, derivation = Fallback.
- The builder uses provider-default paces (a slow but safe set: 6:00 easy, 5:00 threshold, 4:30 VO2max) and the UI surfaces a "We couldn't read your fitness — start conservative and we'll dial in over the first 2 weeks" message on the proposal card.

#### `hasIntensityHistory` flag

True when **either**:
- `derivation === RecentThresholdEffort`, OR
- The HR-zone derivation found at least 2 distinct days with avg HR in Z4 or Z5 in the last 60 days.

Drives a single decision in the builder: how aggressively to ramp quality-day paces toward goal pace. Without intensity history we ramp gentler and skip the deepest VO2max work in week 1-3.

### 3e. New value object: `OnboardingFormInput`

Just a typed wrapper for what's currently a `payload` array on `plan_generations.payload`. Parses the same JSON shape; gives the builder a predictable surface.

```php
final readonly class OnboardingFormInput
{
    public function __construct(
        public GoalType $goalType,
        public ?string $goalName,
        public ?int $distanceMeters,
        public ?CarbonImmutable $targetDate,
        public ?int $goalTimeSeconds,
        public int $daysPerWeek,
        /** @var list<int>|null  ISO 1=Mon..7=Sun */
        public ?array $preferredWeekdays,
        public CoachStyle $coachStyle,
        public ?string $additionalNotes,
    ) {}
}
```

### 3f. The new agent's single tool: `BuildOnboardingPlan`

```php
namespace App\Ai\Tools;

final class BuildOnboardingPlan implements Tool
{
    public function __construct(
        private User $user,
        private FitnessSnapshotService $snapshots,
        private TrainingPlanBuilder $builder,
        private PlanOptimizerService $optimizer,
        private ProposalService $proposals,
    ) {}

    public function description(): string;
    public function schema(JsonSchema $schema): array;
    public function handle(Request $request): string;
}
```

Schema is just the form-input fields (goal_type, goal_name, distance, target_date, goal_time_seconds, days_per_week, preferred_weekdays, additional_notes). Crucially: **no `schedule` parameter**. The agent doesn't emit JSON for the plan — the builder does.

Inside `handle()`:

1. Snapshot fitness → `FitnessSnapshot`
2. Build payload → `array` (shape compatible with optimizer)
3. Optimize → `array` (same passes the optimizer runs today)
4. Persist as pending proposal via `ProposalService::persistPending()`
5. Return tool result `{requires_approval: true, proposal_id, plan_structure, fitness_summary}`

`fitness_summary` is a small object the agent uses to phrase its one-line reply (and the Flutter onboarding loading screen could surface it too):

```json
{
  "confidence": "medium",
  "derivation": "hr_zone_pace",
  "easy_pace_label": "5:35/km",
  "threshold_pace_label": "4:50/km",
  "weekly_km_recent": 28
}
```

### 3g. Updated flow

```
POST /onboarding/generate-plan
    │ (unchanged)
    ▼
plan_generations row → GeneratePlan job
    │
    ▼
OnboardingPlanGeneratorService::generate(user, formData)
    1. Reject stale pending proposals (unchanged)
    2. Insert agent_conversations row context='onboarding' (unchanged)
    3. Build priming message (just the form fields — no metrics)
    4. OnboardingAgent::make($user)->continue($cid)->prompt($priming)
         │
         ▼
       OnboardingAgent.instructions():
         "Call build_onboarding_plan with the form fields from the priming
          message. Do NOT ask follow-up questions. After the tool returns,
          reply with one short friendly sentence telling the runner the
          plan is ready and they can accept or ask to adjust."
         │
         ▼
       Agent calls BuildOnboardingPlan tool
         │
         ▼
       BuildOnboardingPlan.handle():
         a. snapshot = FitnessSnapshotService.snapshot(user)
         b. payload  = TrainingPlanBuilder.build(snapshot, form)
         c. payload  = PlanOptimizerService.optimize(payload, user)
         d. proposal = ProposalService.persistPending(...)
         e. return { requires_approval, proposal_id, plan_structure, fitness_summary }
         │
         ▼
       Agent emits one-sentence reply
    5. ProposalService.detectProposalFromConversation → CoachProposal row
    6. Mark plan_generations row completed
    │
    ▼
Push notification + Flutter polls latestPlanGeneration → /coach/chat/{cid}
```

Wall clock: dominated by the single LLM round-trip (the one-sentence reply). Expected ~2-4s end-to-end, vs the current 60-110s.

---

## 4. The builder rules — concrete, reviewable

This is the section that needs your closest attention. Every rule below is a coaching-judgment call, and writing them down is the whole point of this rewrite.

### 4a. Plan duration

```
weeks = clamp(
    target_date ? ceil((target_date - this_monday) / 7) : default_weeks_for_goal,
    min: 4,
    max: 24
)
```

`default_weeks_for_goal`:
- 5k: 6 weeks
- 10k: 8 weeks
- HM: 12 weeks
- Marathon: 16 weeks
- General fitness: 8 weeks
- PR attempt without target_date: 8 weeks

If target_date < today + 4 weeks → still build, but cap volume aggressively (no week >120% of week 1 baseline).

### 4b. Peak weekly volume

```
peak_km = clamp(
    target_recommended[goal_distance],
    min: snapshot.weeklyKmRecent4Weeks,        // never below current baseline
    max: snapshot.weeklyKmRecent4Weeks * 1.6   // never more than 60% above current
)
```

`target_recommended`:
- 5k: 25 km
- 10k: 35 km
- HM: 50 km
- Marathon: 65 km
- General fitness: max(snapshot.weeklyKm × 1.2, 20)
- PR attempt: same as race for the distance

The 1.6× cap is the safety rail against "runner does 10 km/week, plan jumps to 50 km/week peak". The min-bound is to avoid plans that sit *below* what the runner already does — that signals the wrong distance choice rather than a soft plan.

### 4c. Weekly volume curve

```
1. Start at week 1 = max(snapshot.weeklyKmRecent4Weeks, peak_km × 0.5)
2. Ramp linearly toward peak over (weeks - taper_weeks) weeks
3. Clamp week-over-week growth to ≤ 30% (Riegel-ish "no big jumps")
4. Insert cutback weeks every 4th: 75% of the would-be week
5. Taper weeks (last 2-3 weeks):
   - For race / PR: week T-2 = peak × 0.7, week T-1 = peak × 0.55, race week = peak × 0.4 + race itself
   - For general fitness: hold peak through last week
```

Taper schedule is fixed for race-style goals; user feedback on tapering is high-noise so we don't expose taper choice in the form.

### 4d. Session mix per `days_per_week` (the 80/20 fix)

This is the rule the user flagged. Hardcoded mapping, applied to **build weeks** (cutback and taper weeks have their own rules below):

| `days_per_week` | Sessions | Comment |
|---|---|---|
| 1 | `[long]` | Single weekly long run, paced as easy + 5s. Quality work would be reckless at this frequency. |
| 2 | `[quality, long]` | Alternate weeks: tempo / intervals on the quality day. Long always Sunday-or-equivalent. |
| 3 | `[quality, easy_or_tempo, long]` | Mid-week quality + a moderate-effort progression run (Daniels-style "moderate") + long. |
| 4 | `[quality, tempo, easy, long]` | Adds a true easy recovery day. |
| 5 | `[quality, tempo, easy, easy, long]` | First week 80/20 starts to make sense. |
| 6 | `[quality, tempo, easy, easy, easy, long]` | Classic high-volume mix. |
| 7 | `[quality, tempo, easy, easy, easy, easy, long]` | Two-a-days not modeled; 7 distinct days. |

**Quality alternation rule** (for 2-3 day plans): odd build weeks = intervals, even build weeks = tempo. Keeps both stimuli in rotation without overloading either. For 4+ day plans we fix `quality = intervals` and `tempo = tempo` since both fit naturally.

**During cutback weeks** (every 4th): replace `quality` with `easy_or_tempo` (drop the hardest session); keep `long` but at 80% distance. Volume ≈ 75% of would-be week.

**During taper weeks**: keep `quality` but at race-pace and shorter; skip `tempo`; keep `long` but progressively shorter. Race week = 1-2 short shakeouts + race.

**Race day** is always added on `target_date` regardless of how this distribution lays out. `PlanOptimizerService::ensureRaceDayEntry` continues to handle that as a post-pass.

### 4e. Pace assignment

| Session type | Pace |
|---|---|
| `easy` | `snapshot.easyPaceSecondsPerKm` (raw, no offset) |
| `long` | `snapshot.easyPaceSecondsPerKm + 10s` (slightly more relaxed) |
| `tempo` | progresses across plan: starts at `threshold + 10s`, ends at `threshold` (or `goal_pace` whichever is faster) by week T-3 |
| `quality` (intervals) | per-segment work pace ramps from `vo2max + 10s` early plan to `vo2max` or `goal_pace` late plan |
| race day | `goal_time / distance_km` if goal_time set, else `threshold` |

When `snapshot.confidence === None`, all paces use the fallback defaults (6:00/5:00/4:30).

When `goal_time_seconds` is set AND its implied pace is faster than threshold, we ramp tempo paces toward goal pace across the plan (the existing `planDesignPrinciples` ramp is correct; we keep it). We never set tempo *slower* than threshold even if the goal_time pace is slower — that's a sign the runner overshot and the plan should still build aerobic base.

### 4f. Day-of-week placement

Constraints, in priority order:

1. Race day must land on `target_date`.
2. `quality` and `long` must be ≥ 2 days apart (no back-to-back hard days).
3. `quality` and `tempo` must be ≥ 1 day apart.
4. All training days must be in `preferred_weekdays` (or auto-extend per existing `enforcePreferredWeekdays` lenient mode if there's a conflict).
5. Long run prefers Sat/Sun (1=Mon..7=Sun → 6 or 7), then Mon, in that order.
6. Quality day prefers Tue/Wed (2 or 3), then Thu (4).

Solver: a small backtracking helper. The combinatorics are tiny (≤ 7 weekdays × ≤ 7 sessions). Lives in the builder, fully unit-tested with permutation fixtures.

### 4g. Interval session structure

Re-use the existing `PlanOptimizerService::normalizeIntervals()` rules. The builder emits a canonical shape:

- 2-3 day plans (lower-volume runners): `4×400m` early plan, ramping to `5×800m` mid plan, `6×800m` peak. Recovery 90s. Cooldown 300s.
- 4+ day plans: same structure but reps scale up (`6×400m → 6×800m → 8×800m`).

For "quality alternates with tempo" weeks, the tempo is a progression run: 3-5km at threshold pace, with the back third at threshold − 5s.

These specific rep counts are coaching choices and the **biggest set of numbers we should review together before I implement**.

### 4h. Race day enforcement

Unchanged from today. `PlanOptimizerService::enforceRaceDay()` runs as the post-pass and writes `target_km = goal_km`, `target_pace = goal_pace`, `type = tempo`, `title = goal_name`. Builder just emits a tempo-typed entry with a placeholder description and lets the optimizer take over.

---

## 5. Migration / backward compatibility

### 5a. New code lives alongside old

- `App\Services\Onboarding\TrainingPlanBuilder` (new)
- `App\Services\Onboarding\FitnessSnapshotService` (new)
- `App\Support\Onboarding\FitnessSnapshot` (new)
- `App\Support\Onboarding\OnboardingFormInput` (new)
- `App\Ai\Agents\OnboardingAgent` (new)
- `App\Ai\Tools\BuildOnboardingPlan` (new)

### 5b. Old code that gets removed

After the new flow is stable:
- The `if ($context === 'onboarding')` branch in `RunCoachAgent::instructions()` and the entire `RunCoachAgent::onboardingInstructions()` method.
- `OnboardingPlanGeneratorService::buildPrimingMessage()` — replaced by a much shorter prime that just lists form fields (no metrics).
- The verify-loop is **kept** in `RunCoachAgent` because coach-chat edits still use it. Just not used during onboarding.

### 5c. Schema changes

**None.** All persisted state (`plan_generations`, `agent_conversations`, `coach_proposals`, `wearable_activities`, `users.heart_rate_zones`) is reused as-is.

### 5d. API surface changes

**None.** `POST /onboarding/generate-plan` and `GET /onboarding/plan-generation/latest` are unchanged. The Flutter onboarding screen sees identical responses.

The proposal payload shape is unchanged — `PlanOptimizerService::optimize()` still produces the same structure.

### 5e. Cutover

Single deploy. Feature-flag is overkill for a pre-launch product with one user. The new path replaces the old onboarding path in one commit.

---

## 6. Edge cases (full enumeration)

| # | Scenario | Outcome |
|---|---|---|
| 1 | Healthy runner, 30+ qualifying runs, varied HR | snapshot `confidence=Medium`, derivation `HrZonePace`. Builder uses derived paces. |
| 2 | Runner with one recent threshold-quality 5k race | snapshot `confidence=High`, derivation `RecentThresholdEffort`. |
| 3 | Runner 11 mo plodding, last 4 wk fit | Step 1 catches the recent fitness, OR Step 2 finds Z4 hits in last 30d → no penalty. Plan reflects current. |
| 4 | Runner 3 mo fast, 9 mo injury | Step 1 finds nothing (no recent threshold). Step 2 finds Z4 hits in 60-90d window → applies +10s penalty conservatively. Plan reflects safer baseline. |
| 5 | Runner runs only easy, never a tempo | Step 1 + 2 fail to find threshold (no Z4 hits). Step 3 runs `recent_avg − 30s` heuristic. `hasIntensityHistory = false`. Builder ramps quality conservatively. |
| 6 | New user, 0 runs synced | Step 4 fallback. Default paces. UI surfaces low-confidence message. |
| 7 | All runs old (>90 days) | Step 2 query window misses them. Step 3 `recent_avg` window also misses them (30 d). Step 4 fallback. |
| 8 | All runs are recovery jogs (avg HR < 130) | `MIN_AVG_HR` filter (re-used from `HeartRateZoneDeriver`) eliminates them. Step 3 fallback at best. |
| 9 | Indoor/treadmill runs only | `WearableActivity::RUN_TYPES` includes `VirtualRun`. Pace is reliable for treadmill. Treated as normal. |
| 10 | HR data missing (runner trains without watch chest strap) | Step 2 fails (no zone HR data). Falls through to Step 3 (pace-only avg). Confidence = Low. |
| 11 | Manual `heart_rate_zones` set by user (source = manual) | Used as-is by Step 2. No interaction with the manual-vs-derived system — `FitnessSnapshotService` only reads zones, never writes. |
| 12 | `goal_time_seconds` faster than what threshold pace permits (over-ambitious goal) | Builder ramps tempo paces toward goal pace per existing rule. Race day pace = goal pace. UI shows "ambitious goal" banner via existing flow. |
| 13 | `goal_time_seconds` slower than threshold (under-ambitious) | Builder uses threshold pace for tempo (we never train slower than current capacity). Race day still uses goal pace (it's their target, not ours to override). |
| 14 | `target_date` < today + 4 weeks | Plan still builds, capped to `min: 4` weeks via `clamp`. Volume safety rail prevents jumps. |
| 15 | `target_date` is null (general fitness) | `default_weeks_for_goal` applies; `PlanOptimizerService::alignTargetDateToLastDay()` snaps it post-build. |
| 16 | `preferred_weekdays` has fewer entries than `days_per_week` | Caught at form-validation time today (`OnboardingController::generatePlan`). If it slips through, builder backtracking solver fails → falls back to the next-most-flexible placement (auto-extends preferred_weekdays). |
| 17 | `additional_notes` mentions an injury / constraint | Surfaced to the agent's one-sentence reply — the agent can mention "I'll keep an eye on the easy days given the IT-band note" but doesn't change the plan. Future work: a structured-notes parser that adjusts volume. |
| 18 | Builder produces a plan with 0 quality sessions because `days_per_week = 1` | By design (see 4d). UI doesn't need to handle specially. |
| 19 | User reruns onboarding (rare — only after account deletion) | No state to reconcile; `OnboardingPlanGeneratorService::generate` already rejects pending proposals at start. |
| 20 | Two devices simultaneously POST `/onboarding/generate-plan` | Existing in-flight check on `plan_generations` row makes the second call a no-op. Unchanged. |
| 21 | Plan generation fails (e.g. all derivation steps return null AND the builder hits an unexpected error) | `GeneratePlan::failed()` marks the row failed, push notification fires (existing flow). User sees retry UI in the loading screen. |
| 22 | Race-day entry would land on a `preferred_weekdays = false` day (e.g. user picks Mon/Wed/Fri but race is Sunday) | Race day is exempt from the weekday filter — existing optimizer rule. Plan generation succeeds. |
| 23 | Builder emits a duplicate day_of_week in one week (programming error) | `PlanOptimizerService::deduplicateDaysPerWeek()` post-pass handles. Unit tests should catch the bug pre-commit. |
| 24 | Runner has `coaches_own_plans = true` org membership | Should never reach onboarding plan generation in the first place — admin sets the goal. Not a regression. |
| 25 | Snapshot says `confidence = None` AND `goal_time_seconds` is set | Use goal pace for race day; everything else uses fallback defaults. No upgrade. UI surfaces "we'll dial in over the first 2 weeks" copy. |

---

## 7. Test plan

### Unit tests (PHPUnit, the bulk of the work)

`tests/Unit/Services/Onboarding/FitnessSnapshotServiceTest.php` (new):
- Step 1 catches a clean tempo run
- Step 1 rejects a run with high CV (when splits available)
- Step 2 finds top-3 fastest in each zone
- Step 2 median-of-3 ignores a single GPS-glitch fast pace
- Step 2 staleness penalty: 30-60d, 60-90d, >90d
- Step 3 fires when zone derivation found <2 anchors
- Step 4 fires with no runs at all
- `hasIntensityHistory` true/false thresholds
- Z2 only → Step 2 returns one anchor → falls to Step 3
- Filters: too short, too easy, no HR

`tests/Unit/Services/Onboarding/TrainingPlanBuilderTest.php` (new):
- One snapshot fixture × each `days_per_week ∈ {1..7}` → asserts session-mix per week
- Volume curve: peak-week km bounded by 1.6× recent baseline
- Cutback every 4th week
- Taper for race goals (last 2-3 weeks reduced)
- Quality alternation odd/even weeks at 2-3 days/week
- Race day on target_date
- ≥ 1 rest day between quality and long
- Pace assignment per session type
- Confidence=None → fallback paces

`tests/Unit/Support/Onboarding/FitnessSnapshotTest.php` (new): just constructor/getters smoke test.

### Feature tests (existing patterns)

`tests/Feature/Jobs/GeneratePlanJobTest.php` (extend):
- New flow: `OnboardingAgent::fake([...])` → assert `BuildOnboardingPlan` was the only tool called
- Proposal row created with deterministic payload (snapshot the optimizer-output JSON)
- `plan_generations` marked completed
- Push notification dispatched (already covered, just keep)

`tests/Feature/Onboarding/OnboardingPlanGeneratorServiceTest.php` (new):
- 8 representative runner profiles × 4 goal types matrix
- Each combination produces a non-empty plan with a race-day entry on target_date

### Comparison harness (one-shot, not committed)

A dev-only Artisan command `php artisan onboarding:compare-plans --user=ID` that runs both the old and new flow on the same fitness snapshot, dumps both payloads to `/tmp/`, and prints a diff summary. We use it once during cutover to eyeball N=10 representative profiles. Discarded after cutover.

---

## 8. What I am NOT proposing

A few related ideas I considered and explicitly want to leave out of this spec — flag any you want pulled in:

- **Calling Daniels' VDOT formula**. We get most of the same benefit by using HR-zone-derived paces directly. Adding VDOT introduces another set of constants (T-pace, I-pace, R-pace ratios) that conflict with the simpler `easy / threshold / VO2max` model the rest of the codebase already uses.
- **A confidence-boosting "do a 5k time trial in week 1" prompt**. Could meaningfully tighten the snapshot for low-confidence cases. Out of scope here; surface it as a post-MVP feature.
- **Letting the runner adjust the proposed plan before acceptance via a structured form** (rather than the chat). Proposed-but-deferred.
- **Persisting `FitnessSnapshot` so weekly insights / pace-adjustment-evaluator can read it** instead of re-querying. Worthwhile but separate scope; today's snapshot is built once and dropped after the proposal lands.
- **A "regenerate plan" button after the runner has been training for N weeks**. Same scope creep concern.

---

## 9. Open questions for review

These are the calls I want your sign-off on before I write any code:

1. **Staleness penalty values** (Step 2 of derivation): 30-60d → +5s, 60-90d → +10s. Numbers are coaching judgment. Are these in the right ballpark, or do you want them more / less aggressive?

2. **The session-mix table** in §4d. Specifically: at 2 days/week, is `[quality, long]` the right call, or do you want `[tempo, long]` (less risky) as the default with quality only every other week?

3. **The quality alternation at 2-3 days/week** (odd weeks intervals, even weeks tempo). Or always pick one and stick with it for the whole plan (more predictable for the runner)?

4. **Peak-volume cap of 1.6× recent baseline** (§4b). Conservative? Aggressive? Different cap per goal distance?

5. **Default weeks per goal distance** (§4a). 5k=6, 10k=8, HM=12, M=16. Standard. But do you want the runner to be able to *override* (e.g. "I want a 20-week 10k plan because I'm building from scratch")?

6. **Interval rep counts** in §4g. The exact rep schedule (`4×400m → 5×800m → 6×800m`) is the most coaching-judgment-heavy section. Worth spending 15 min walking through these together once you're reviewing.

7. **The fallback-default paces** (Step 4 derivation): 6:00 / 5:00 / 4:30 for easy / threshold / VO2max. Reasonable for an absolute beginner? Or too fast / slow?

8. **"Race day always lands on target_date"**: confirmed today, just want to confirm we never change this.

9. **The dev-only comparison harness in §7**: do you want it fully committed (and gated `--env=local` only), or one-shot disposed-of after cutover?

10. **Naming**: `TrainingPlanBuilder` vs `OnboardingPlanBuilder` vs `FirstPlanBuilder`. Today the latter two are more honest about scope (it doesn't build plans for coach-chat edits). I lean `OnboardingPlanBuilder` to make the boundary obvious in `grep`. WDYT?

---

## 10. Sources

- [VDOT Calculator & Daniels Running — GoPace](https://gopace.run/pace-predictor)
- [Riegel formula accuracy — RunnersConnect](https://runnersconnect.net/race-calculators/)
- [Lactate threshold testing — RunnersConnect](https://runnersconnect.net/how-to-calculate-your-lactate-threshold/)
- [TrainingPeaks: Thresholds 411](https://www.trainingpeaks.com/learn/articles/thresholds-411/)
- [Joe Friel on setting zones — TrainingPeaks](https://www.trainingpeaks.com/learn/articles/joe-friel-s-quick-guide-to-setting-zones/)
- [80/20 polarized training overview — Marathon Handbook](https://marathonhandbook.com/polarized-training/)
- [Verona study: low-volume runners — PMC](https://pmc.ncbi.nlm.nih.gov/articles/PMC4621419/)
- [Canadian Running: how to actually apply 80/20](https://runningmagazine.ca/sections/training/the-80-20-rule-how-to-actually-apply-it-to-your-training/)
- [Critique of 80/20 at low volumes — 80/20 Endurance](https://www.8020endurance.com/new-study-strikes-fatal-blow-to-80-20-training-philosophy/)
- Existing related spec: `docs/superpowers/specs/2026-05-08-hr-zones-auto-derive.md` (HR-zone derivation; this spec consumes its output)
