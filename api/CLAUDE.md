<laravel-boost-guidelines>
=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to ensure the best experience when building Laravel applications.

## Foundational Context

This application is a Laravel application and its main Laravel ecosystems package & versions are below. You are an expert with them all. Ensure you abide by these specific packages & versions.

- php - 8.5
- filament/filament (FILAMENT) - v4
- laravel/ai (AI) - v0
- laravel/framework (LARAVEL) - v13
- laravel/prompts (PROMPTS) - v0
- laravel/sanctum (SANCTUM) - v4
- livewire/livewire (LIVEWIRE) - v3
- laravel/boost (BOOST) - v2
- laravel/mcp (MCP) - v0
- laravel/pail (PAIL) - v1
- laravel/pint (PINT) - v1
- phpunit/phpunit (PHPUNIT) - v12
- tailwindcss (TAILWINDCSS) - v4

## Skills Activation

This project has domain-specific skills available. You MUST activate the relevant skill whenever you work in that domain—don't wait until you're stuck.

- `ai-sdk-development` — TRIGGER when working with ai-sdk which is Laravel official first-party AI SDK. Activate when building, editing AI agents, chatbots, text generation, image generation, audio/TTS, transcription/STT, embeddings, RAG, vector stores, reranking, structured output, streaming, conversation memory, tools, queueing, broadcasting, and provider failover across OpenAI, Anthropic, Gemini, Azure, Groq, xAI, DeepSeek, Mistral, Ollama, ElevenLabs, Cohere, Jina, and VoyageAI. Invoke when the user references ai-sdk, the `Laravel\Ai\` namespace, or this project's AI features — not for Prism PHP or other AI packages used directly.
- `laravel-best-practices` — Apply this skill whenever writing, reviewing, or refactoring Laravel PHP code. This includes creating or modifying controllers, models, migrations, form requests, policies, jobs, scheduled commands, service classes, and Eloquent queries. Triggers for N+1 and query performance issues, caching strategies, authorization and security patterns, validation, error handling, queue and job configuration, route definitions, and architectural decisions. Also use for Laravel code reviews and refactoring existing Laravel code to follow best practices. Covers any task involving Laravel backend PHP code patterns.
- `tailwindcss-development` — Always invoke when the user's message includes 'tailwind' in any form. Also invoke for: building responsive grid layouts (multi-column card grids, product grids), flex/grid page structures (dashboards with sidebars, fixed topbars, mobile-toggle navs), styling UI components (cards, tables, navbars, pricing sections, forms, inputs, badges), adding dark mode variants, fixing spacing or typography, and Tailwind v3/v4 work. The core use case: writing or fixing Tailwind utility classes in HTML templates (Blade, JSX, Vue). Skip for backend PHP logic, database queries, API routes, JavaScript with no HTML/CSS component, CSS file audits, build tool configuration, and vanilla CSS.

## Conventions

- You must follow all existing code conventions used in this application. When creating or editing a file, check sibling files for the correct structure, approach, and naming.
- Use descriptive names for variables and methods. For example, `isRegisteredForDiscounts`, not `discount()`.
- Check for existing components to reuse before writing a new one.

## Verification Scripts

- Do not create verification scripts or tinker when tests cover that functionality and prove they work. Unit and feature tests are more important.

## Application Structure & Architecture

- Stick to existing directory structure; don't create new base folders without approval.
- Do not change the application's dependencies without approval.

## Frontend Bundling

- If the user doesn't see a frontend change reflected in the UI, it could mean they need to run `npm run build`, `npm run dev`, or `composer run dev`. Ask them.

## Documentation Files

- You must only create documentation files if explicitly requested by the user.

## Replies

- Be concise in your explanations - focus on what's important rather than explaining obvious details.

=== boost rules ===

# Laravel Boost

## Tools

- Laravel Boost is an MCP server with tools designed specifically for this application. Prefer Boost tools over manual alternatives like shell commands or file reads.
- Use `database-query` to run read-only queries against the database instead of writing raw SQL in tinker.
- Use `database-schema` to inspect table structure before writing migrations or models.
- Use `get-absolute-url` to resolve the correct scheme, domain, and port for project URLs. Always use this before sharing a URL with the user.
- Use `browser-logs` to read browser logs, errors, and exceptions. Only recent logs are useful, ignore old entries.

## Searching Documentation (IMPORTANT)

- Always use `search-docs` before making code changes. Do not skip this step. It returns version-specific docs based on installed packages automatically.
- Pass a `packages` array to scope results when you know which packages are relevant.
- Use multiple broad, topic-based queries: `['rate limiting', 'routing rate limiting', 'routing']`. Expect the most relevant results first.
- Do not add package names to queries because package info is already shared. Use `test resource table`, not `filament 4 test resource table`.

### Search Syntax

1. Use words for auto-stemmed AND logic: `rate limit` matches both "rate" AND "limit".
2. Use `"quoted phrases"` for exact position matching: `"infinite scroll"` requires adjacent words in order.
3. Combine words and phrases for mixed queries: `middleware "rate limit"`.
4. Use multiple queries for OR logic: `queries=["authentication", "middleware"]`.

## Artisan

- Run Artisan commands directly via the command line (e.g., `php artisan route:list`). Use `php artisan list` to discover available commands and `php artisan [command] --help` to check parameters.
- Inspect routes with `php artisan route:list`. Filter with: `--method=GET`, `--name=users`, `--path=api`, `--except-vendor`, `--only-vendor`.
- Read configuration values using dot notation: `php artisan config:show app.name`, `php artisan config:show database.default`. Or read config files directly from the `config/` directory.
- To check environment variables, read the `.env` file directly.

## Tinker

- Execute PHP in app context for debugging and testing code. Do not create models without user approval, prefer tests with factories instead. Prefer existing Artisan commands over custom tinker code.
- Always use single quotes to prevent shell expansion: `php artisan tinker --execute 'Your::code();'`
  - Double quotes for PHP strings inside: `php artisan tinker --execute 'User::where("active", true)->count();'`

=== php rules ===

# PHP

- Always use curly braces for control structures, even for single-line bodies.
- Use PHP 8 constructor property promotion: `public function __construct(public GitHub $github) { }`. Do not leave empty zero-parameter `__construct()` methods unless the constructor is private.
- Use explicit return type declarations and type hints for all method parameters: `function isAccessible(User $user, ?string $path = null): bool`
- Use TitleCase for Enum keys: `FavoritePerson`, `BestLake`, `Monthly`.
- Prefer PHPDoc blocks over inline comments. Only add inline comments for exceptionally complex logic.
- Use array shape type definitions in PHPDoc blocks.

=== tests rules ===

# Test Enforcement

- Every change must be programmatically tested. Write a new test or update an existing test, then run the affected tests to make sure they pass.
- Run the minimum number of tests needed to ensure code quality and speed. Use `php artisan test --compact` with a specific filename or filter.

=== laravel/core rules ===

# Do Things the Laravel Way

- Use `php artisan make:` commands to create new files (i.e. migrations, controllers, models, etc.). You can list available Artisan commands using `php artisan list` and check their parameters with `php artisan [command] --help`.
- If you're creating a generic PHP class, use `php artisan make:class`.
- Pass `--no-interaction` to all Artisan commands to ensure they work without user input. You should also pass the correct `--options` to ensure correct behavior.

### Model Creation

- When creating new models, create useful factories and seeders for them too. Ask the user if they need any other things, using `php artisan make:model --help` to check the available options.

## APIs & Eloquent Resources

- For APIs, default to using Eloquent API Resources and API versioning unless existing API routes do not, then you should follow existing application convention.

## URL Generation

- When generating links to other pages, prefer named routes and the `route()` function.

## Testing

- When creating models for tests, use the factories for the models. Check if the factory has custom states that can be used before manually setting up the model.
- Faker: Use methods such as `$this->faker->word()` or `fake()->randomDigit()`. Follow existing conventions whether to use `$this->faker` or `fake()`.
- When creating tests, make use of `php artisan make:test [options] {name}` to create a feature test, and pass `--unit` to create a unit test. Most tests should be feature tests.

## Vite Error

- If you receive an "Illuminate\Foundation\ViteException: Unable to locate file in Vite manifest" error, you can run `npm run build` or ask the user to run `npm run dev` or `composer run dev`.

## Deployment

- Laravel can be deployed using [Laravel Cloud](https://cloud.laravel.com/), which is the fastest way to deploy and scale production Laravel applications.

=== pint/core rules ===

# Laravel Pint Code Formatter

- If you have modified any PHP files, you must run `vendor/bin/pint --dirty --format agent` before finalizing changes to ensure your code matches the project's expected style.
- Do not run `vendor/bin/pint --test --format agent`, simply run `vendor/bin/pint --format agent` to fix any formatting issues.

=== phpunit/core rules ===

# PHPUnit

- This application uses PHPUnit for testing. All tests must be written as PHPUnit classes. Use `php artisan make:test --phpunit {name}` to create a new test.
- If you see a test using "Pest", convert it to PHPUnit.
- Every time a test has been updated, run that singular test.
- When the tests relating to your feature are passing, ask the user if they would like to also run the entire test suite to make sure everything is still passing.
- Tests should cover all happy paths, failure paths, and edge cases.
- You must not remove any tests or test files from the tests directory without approval. These are not temporary or helper files; these are core to the application.

## Running Tests

- Run the minimal number of tests, using an appropriate filter, before finalizing.
- To run all tests: `php artisan test --compact`.
- To run all tests in a file: `php artisan test --compact tests/Feature/ExampleTest.php`.
- To filter on a particular test name: `php artisan test --compact --filter=testName` (recommended after making a change to a related file).

</laravel-boost-guidelines>

---

# RunCoach API — Project-specific context

This is the Laravel backend for **RunCoach**, a personal AI running coach app. See `../CLAUDE.md` for the monorepo overview.

## What this backend does

- Authenticates users via **Sign in with Apple** (`POST /auth/apple` verifies the iOS-issued identity token against Apple's JWKS via `firebase/php-jwt`, returns a Sanctum bearer)
- **Ingests wearable activities** pushed by the Flutter app (`POST /wearable/activities`) into a wearable-agnostic `wearable_activities` table — currently `source='apple_health'` only; Garmin/Polar/Strava can be added later via Open Wearables without schema changes
- Auto-matches each ingested activity to the user's active training schedule and scores compliance (pace/distance/HR)
- Runs an agentic AI coach (Laravel AI SDK) that reads from the local DB only — no live external API calls during a coach turn
- Generates training schedules for races with a proposal/approval flow

## Core architecture

### AI Coach (the main agentic feature)

The coach uses **Laravel AI SDK** (`laravel/ai` v0.5.1). Default provider is **Anthropic** (`claude-sonnet-4-6`) via `config/ai.php`. Key files:

- `app/Ai/Agents/RunCoachAgent.php` — main agent. Implements `Agent`, `Conversational`, `HasTools`. Uses `Promptable` + `RemembersConversations` traits. Takes a `User` in constructor. Branches the system prompt on `agent_conversations.context`: `'onboarding'` → `onboardingInstructions()` (scripted flow), otherwise → `coachInstructions()`.
- Other agents (one-shot `prompt()`, no tools):
  - `PlanExplanationAgent` — `HasStructuredOutput`, returns `{name, explanation}` for the plan details modal
  - `ActivityFeedbackAgent` — post-run feedback for completed activities
  - `WeeklyInsightAgent` — weekly coach notes
  - `RunningNarrativeAgent` — narrative paragraph for `UserRunningProfile`
- `app/Ai/Tools/*.php` — coach + onboarding agent tools:
  - **UI display tools** (forwarded to Flutter as `data-stats` / `data-chips` events):
    - `PresentRunningStats` — stats card (4 metrics)
    - `OfferChoices` — tappable chip row
  - **Activity query tools (all read from `wearable_activities`, no live external API):**
    - `GetRunningProfile` — cached `UserRunningProfile` (12-mo aggregate; the onboarding builder uses `FitnessSnapshotService` for recent fitness instead)
    - `GetRecentRuns` — N most recent runs, no date input
    - `SearchActivities` — date-range query with aggregates + weekly breakdown
    - `GetActivityDetails` — per-km splits + HR curve when stored in `raw_data.splits`
  - **Plan-state query tools:**
    - `GetCurrentSchedule` — active schedule with compliance
    - `GetCurrentProposal` — pending proposal payload (call before `adjust_plan` if you need full structure)
    - `GetGoalInfo` — goal details + readiness
    - `GetComplianceReport` — compliance breakdown + trends
  - **Plan-mutation tools (the unified Adjust + Build pattern):**
    - `BuildPlan` — generates a complete plan from form-style inputs (goal_type, distance_meters, target_date, goal_time_seconds, days_per_week, preferred_weekdays, run_type_preferences, additional_notes). Used by both onboarding (first plan) AND coach-chat (full rebuilds when the goal changes). No verify loop, no JSON authoring — pure deterministic builder. ~6s wall clock.
    - `AdjustPlan` — targeted edits to the latest pending proposal OR the active goal (auto-detects). Operations: `replace` / `add` / `remove` / `adjust` / `shift` / `set_goal`. Pace AND distance are honored verbatim for every non-interval day (wide sanity windows only — pace [150, 720] s/km, distance [1, 80] km; no relative-to-snapshot clamp). Race day untouchable. Returns an enriched `applied[]` (before→after per touched day + an `adjustments[]` note array for anything the server changed — including interval normalization: an invalid `intervals` structure replaced by the default skeleton, clamped reps via `IntervalBlueprint::normalizationNotes`, intervals sent to a non-interval day; warm-up/cool-down clamps are deliberately NOT noted since these notes render verbatim on the runner-facing diff card) so the agent reports honestly. Every interval-day snapshot (before AND after, all actions incl. `shift`) carries an `intervals` summary string of the stored WORK SETS (`IntervalBlueprint::summary`, e.g. `"4×800m @4:30/km (rec 90s)"` — warm-up/cool-down omitted by design); the Flutter revision modal renders it in the detail line. Used by both agents for ANY tweak. ~10s wall clock.
    - `ModifySchedule` — legacy bulk-editor for active plans. Largely superseded by `AdjustPlan`; kept only if a legacy proposal type still references it.
    - `EditWorkout` — workout-chat-only single-day edit (used by `WorkoutAgent`); internally delegates to `AdjustPlan`.
    - `ProposeNewPlanCard` — emits `display: new_plan_card` (SSE `data-new-plan`). Replaces the multi-turn `offer_choices` chip flow for new-plan requests; Flutter renders a "Start new training plan" card whose tap drops the runner into `/onboarding/form?for=new-plan&step=goal_type`. `BuildPlan` is no longer in `RunCoachAgent`'s toolset; only `OnboardingAgent` (driven by the form submit) still uses it.
- `app/Services/ProposalService.php` — detects proposals from `agent_conversation_messages.tool_results` and applies accepted ones. Applies `CreateSchedule` (creates new goal + activates), `EditActivePlan` (updates active goal in place), `ModifySchedule` (legacy), `AlternativeWeek` (legacy). `applyCreateSchedule()` drops any training day whose date is before today.

**How proposals work:** When the agent calls `BuildPlan` or `AdjustPlan`, the tool returns JSON with `requires_approval: true`. The SDK stores that in `tool_results`. After `$agent->prompt()` returns, `ProposalService::detectProposalFromConversation()` queries that column, finds the proposal, and stores a `CoachProposal` record. The user accepts/rejects via `/coach/proposals/{id}/accept` or `/reject`. Before acceptance they can open a details modal fed by `GET /coach/proposals/{id}/explanation` (cached 7 days per proposal via `Cache::remember`). Active-goal edits via `AdjustPlan` carry a `diff` array on the payload so the Flutter `ProposalCard` renders a "PLAN REVISION (N changes)" pill. Each diff entry is the true before→after of a touched day (a `before` snapshot + the new flat fields) plus an optional `adjustments[]` note list — built post-optimize in `AdjustPlan::buildDiff`, so the modal shows exactly what was stored, not just what was requested.

**The SDK manages conversations automatically** via `agent_conversations` and `agent_conversation_messages` tables (created by SDK migrations). Do NOT use `CoachConversation` or `CoachMessage` models — they no longer exist. Conversation IDs are UUIDs (36-char strings), not integers.

### Anthropic integration (SDK patches)

> **Hard rule: never edit files under `vendor/`.** No exceptions. They get silently wiped by `composer install/update`, they create dependency-inversion (vendor → app references), and they hide the real fix from future sessions. If you think you need a vendor patch, either (a) work around it in app code, or (b) open an upstream PR. If the fix really must live in a vendor file, use `cweagans/composer-patches` with a committed `.patch` file — discussed with the user first.

Two HTTP middlewares live in `app/Ai/Support/` and are registered in `AppServiceProvider::boot()` via `Http::globalRequestMiddleware`:
- **`AnthropicToolInputSanitizer`** — fixes `tool_use.input: []` → `{}` for tools with empty params. Without this the SDK's DB round-trip of `arguments` collapses `{}` to `[]` (PHP assoc-array ambiguity) and Anthropic returns `400 "Input should be a valid dictionary"` on any `continue()`+prompt against a stored conversation that previously invoked a no-arg tool (e.g. `GetRunningProfile`). Also clears `Content-Length` after body rewrite (Guzzle doesn't recompute it for streaming requests → truncated JSON → 400).
- **`AnthropicPromptCaching`** — attaches `cache_control: ephemeral` to the last tool in every outgoing Anthropic request. This caches `system` + all `tools` (~7k tokens for RunCoachAgent). Onboarding turns 2+ hit the cache and pay ~10% of the normal input price. Cache hits show up in `token_usages.cache_read_input_tokens`. Also clears `Content-Length` (same reason as above).

#### Tool-spinner UX (app-side, no vendor patches)

The SDK's Anthropic streaming handler only yields the `ToolCall` event at `content_block_stop` — i.e. after the full tool input JSON has streamed in. For large tool inputs (`create_schedule` generates 2-3k tokens of JSON, takes 20-30s) this means the UI would sit silent between the text ending and the tool firing.

Workaround lives entirely in the Flutter coach provider (`app/lib/features/coach/providers/coach_provider.dart`): on the `text-end` Vercel-protocol event we set a generic `toolIndicator: 'Thinking'` so the spinner shows up immediately. As soon as the SDK emits the actual `tool-input-available` event (which carries `toolName`), it overwrites with the specific humanised label ("Building your training plan…"). On the next text delta the indicator clears.

An earlier attempt patched the SDK to yield a second ToolCall event at `content_block_start` — that polluted `$response->toolCalls` with duplicate ids and caused `messages.N.content.M: tool_use ids must be unique` on the next turn. We removed the vendor patch; DO NOT bring it back.

### Plan generation pipeline (unified Adjust + Build pattern)

ONE pattern for both onboarding and coach-chat: `BuildPlan` for full creates / rebuilds, `AdjustPlan` for everything else. No verify loop. No LLM authoring of schedule JSON. Read this before touching anything in `OnboardingAgent`, `RunCoachAgent`, `PlanOptimizerService`, `BuildPlan`, `AdjustPlan`.

> **Migration note (2026-05):** the old `CreateSchedule` + `EditSchedule` + `VerifyPlan` + `PlanVerifierAgent` stack was removed in favour of the deterministic Build/Adjust pattern. The OLD coach-chat path was 30-90s per edit (verify-loop + Sonnet JSON authoring + Haiku audit). The new path is 6-15s. All plan structure now comes from the deterministic builder + server-side op clamps; coaching judgment for tweaks is encoded in `TrainingPlanBuilder` constants, NOT in agent prompts.

#### Onboarding (first-plan generation)

```
[Flutter onboarding form]
    │
    ▼
POST /onboarding/generate-plan
    │   1. Reject re-entry if a PlanGeneration row is already in flight
    │   2. Insert plan_generations row (status=queued, payload=form data)
    │   3. Dispatch GeneratePlan job
    │   4. Return 202 {id, status:'queued', conversation_id:null, ...}
    │
    ▼
[Queue worker] GeneratePlan::handle()
    │   1. Mark row processing, set started_at
    │   2. OnboardingPlanGeneratorService::generate($user, $row->payload)
    │       a. Reject any stale pending proposals
    │       b. Insert agent_conversations row with context='onboarding'
    │       c. Build priming message: just the form fields (no metrics dump)
    │       d. OnboardingAgent::make(user)->continue($cid, as: $user)->prompt($priming)
    │   3. Mark row completed with {conversation_id, proposal_id}
    │      (on Throwable: failed() callback marks row failed + error_message)
    │
    ▼
[OnboardingAgent — minimal LLM, 3 tools]
    Tools: build_onboarding_plan, adjust_onboarding_plan, get_recent_runs.
    Step 1 (always)  call build_onboarding_plan ONCE with form fields.
    Step 2 (optional) read additional_notes:
      - injury / pain / "coming back from" → MUST call adjust_onboarding_plan
        to replace tempos+intervals with easy in early weeks (the
        deterministic builder doesn't know about injuries; it can hand
        you tempos in week 1 of an injury comeback plan).
      - training preferences ("more intervals", "no long runs Sundays",
        "extra day on Wed") → call adjust_onboarding_plan to swap/add/move.
      - empty / generic → skip.
    Step 3 (optional) get_recent_runs for activity context when notes warrant it.
    Step 4 (always)  one short friendly reply. If ambition.level is
        ambitious / very_ambitious, paraphrase the ambition.suggestion in
        coach-friendly language (no "ambition_level" jargon).
    │
    ▼
[BuildOnboardingPlan tool — deterministic pipeline]
    a. snapshot = FitnessSnapshotService::snapshot($user)
         → Tier 1: recent threshold-quality effort (≤30d) → High confidence
         → Tier 2: HR-zone fastest-pace mining (≤90d, with staleness penalty) → Medium
         → Tier 3: recent (30d) avg pace + heuristic offsets → Low
         → Tier 4: provider defaults → None
    b. ambition = PlanAmbitionAnalyzer::analyze (two-pass: assess base
         weeks, derive extension, re-assess with extended weeks). Drives
         peak-volume multiplier (1.6× / 1.7× / 1.8×) AND plan-length
         extension (+0 / +4 / +8 weeks for realistic / ambitious / very_ambitious).
    c. payload = TrainingPlanBuilder::build($snapshot, $form, $ambition)
         Deterministic — volume curve, session mix per days_per_week
         (with effective_days dropping session count when volume can't
         sustain meaningful sessions), cutbacks/taper, per-session paces
         ramping toward goal, interval blueprint, race-day skeleton.
    d. payload = PlanOptimizerService::optimize($payload, $user)
         Order: alignTargetDateToLastDay runs FIRST (sets target_date for
         open-ended plans) so the race-day passes can enforce on the
         final day. Same post-pass coach-chat edits also use.
    e. proposal = ProposalService::persistPending(...)
    f. Returns {requires_approval, proposal_id, plan_structure, fitness_summary, ambition}

[AdjustOnboardingPlan tool — optional second pass, AI-driven tweaks]
    Operates on the latest pending proposal. Operations: replace, add,
    remove, adjust per (week, day_of_week). Pace overrides honored
    verbatim (non-interval days; [150, 720] s/km sanity window only).
    Distance clamped to [4 km, 1.5×
    builder]. Race day untouchable. `add` respects preferred_weekdays.
    Re-runs optimizer + persists a new pending proposal (supersedes the
    previous).
    │
    ▼
ProposalService::detectProposalFromConversation()
    Same as before — reads agent_conversation_messages.tool_results.
    │
    ▼
[Flutter] OnboardingGeneratingScreen polls /onboarding/plan-generation/latest
    completed → /coach/chat/{conversation_id} (ProposalCard).
    failed → error UI with Try again.
```

End-to-end ~5-15s (was 60-110s):
- ~6s for the simple build + reply path (no notes / no adjustment)
- ~14s when notes trigger an `adjust_plan` second tool call

Same form input always produces the same base plan — the builder is deterministic, testable with PHPUnit. The AI's adjustments (when notes warrant them) and reply text vary; tests for those paths fake the agent.

#### Coach-chat edits (after onboarding, ongoing)

Once the proposal is accepted (or the runner is back chatting later), every message flows through `RunCoachAgent`'s `coachInstructions()` with the SAME tools as onboarding plus query tools (`GetRecentRuns`, `SearchActivities`, `GetCurrentSchedule`, etc).

```
[user message]
    ▼
RunCoachAgent ── tools ──→
    AdjustPlan (small tweaks) — auto-targets active goal, ~10s
    OR
    BuildPlan (full rebuild) — deterministic, ~10s
        ↓
    ProposalService.detectProposalFromConversation
```

Plan-mutation contract:
- **Tweaks** (change a day, swap session type, shift weekday, update goal time, race date moved, etc) → `adjust_plan`. Pace AND distance honored verbatim (non-interval days, sanity window only), race-day untouchable. Active-goal edits emit `EditActivePlan` proposals carrying a before→after `diff` array for the "PLAN REVISION" UI.
- **Rebuilds** (different goal_type, race cancelled, original goal complete) → `build_plan`. Same form-style input as onboarding. On accept, `applyCreateSchedule` creates a new `Goal` and `GoalService::activate` deactivates the old one.

#### Plan generation lifecycle (async, onboarding only)

`plan_generations` table is the single source of truth for first-time onboarding plan generation. Lifecycle: `queued → processing → completed | failed`.

- **Single in-flight per user**: POST is idempotent — returns the existing row when `User::pendingPlanGeneration()` is non-null and `isInFlight()` is true.
- **Watchdog**: `User::pendingPlanGeneration()` auto-fails any row stuck in queued/processing for >10 minutes (covers worker death where `failed()` never fires). Read-time check inside the accessor — no scheduled command needed.
- **Field on /profile + auth responses**: `pending_plan_generation` is non-null only when the user should be redirected to the loading screen or the proposal chat. Once the proposal is accepted/rejected, the field goes back to null and normal routing resumes.
- **Queue worker timeout**: deploy command must use `--timeout=600` (or higher). 120s was the historical value and would kill plan generation mid-loop.

#### Verify loop — REMOVED

The old Haiku-audited verify loop was retired with the Build/Adjust migration. There is no `VerifyPlan` tool, no `PlanVerifierAgent`, no `verify_plan:cycle:user` cache key. Plan structure is guaranteed by the deterministic builder; per-edit safety comes from `AdjustPlan`'s server-side clamps + the optimizer's structural post-pass.

Historical context (delete after a few months):
- Old `MAX_CYCLES = 2` cap; counter at `verify_plan:cycle:user:{id}` — both gone.
- Old prompt rule "after EVERY `create_schedule` or `edit_schedule`, call `verify_plan`" — gone.
- Doom-loop scrubs ("never say 'max cycles' to the user") — gone.

#### Plan-pipeline services (used by both onboarding + coach-chat)

The plan-builder code lives under `app/Services/Onboarding/`, `app/Support/Onboarding/`, plus the agent + tools under `app/Ai/`. The "Onboarding" namespace is historical — the SAME services power coach-chat plan rebuilds via `BuildPlan`.

- **`FitnessSnapshotService`** (`app/Services/Onboarding/`) — derives a recent-fitness snapshot. **Tier 0**: self-reported overrides from `users.self_reported_weekly_km` / `users.self_reported_easy_pace_seconds_per_km` (filled in `/onboarding/overview` — when non-null they win over the cascade). Then 4-tier cascade (recent threshold effort → HR-zone mining → recent average → fallback). Reads HR zones from `users.heart_rate_zones`. Tunable knobs are constants on the class (`STALENESS_PENALTIES`, `EASY_OFFSET_FROM_THRESHOLD`, `RECENT_THRESHOLD_LOOKBACK_DAYS`).
- **`PlanAmbitionAnalyzer`** (`app/Services/Onboarding/`) — compares the runner's stated goal pace + volume vs realistic improvement rates (Daniels, Pfitzinger). Returns `AmbitionAssessment` with `level` (realistic / ambitious / very_ambitious), `peakVolumeMultiplier` (1.6× / 1.7× / 1.8×), `weeksExtension` (+0 / +4 / +8), `summary`, and `suggestion`. `REALISTIC_IMPROVEMENT_PER_MONTH = 12.0 sec/km/month`. Auto-extension only fires when `target_date` is null.
- **`IntensityBias`** (`app/Enums/`) — runner-facing 3-position slider (`take_it_easy` / `standard` / `push_me_harder`) persisted on `users.intensity_bias` (cast as enum). Captured in onboarding form (`OnboardingFormInput::intensityBias`) and applied via `AmbitionAssessment::applyBias()` which shifts the level ±1 inside the extended 5-tier `EffectiveAmbitionLevel` table, then re-reads `weeklyGrowthRatio` + `qualityPaceRampGain` from the shifted tier. Default = `Standard` (no shift).
- **`TrainingPlanBuilder`** (`app/Services/Onboarding/`) — pure-PHP plan composer. Coaching judgment encoded as constants: `PEAK_KM_FOR_DISTANCE`, `MAX_PEAK_VS_BASELINE_RATIO`, `CUTBACK_EVERY_N_WEEKS`, `TAPER_FRACTIONS`, `LONG_RUN_CAP_BY_RANK`, plus separate `DEFAULT_WEEKS_FOR_GOAL` (race completion) and `DEFAULT_WEEKS_FOR_PR_ATTEMPT` (PR cycles).
- **Effective-days logic** (`TrainingPlanBuilder::resolveEffectiveDays`) — `days_per_week` is the runner's TARGET, not a hard constraint. When the week's volume can't sustain that many meaningful sessions (each ≥ MIN_RUN_KM=4 km, long ≥ 7 km in build), the count is reduced. A low-baseline runner asking for 4 days starts at 2 and ramps up.
- **Long-run-is-longest invariant** — post-render bump in `planSessions` ensures `long_run.target_km ≥ longest_other_session + 1 km`.
- **Quality-pace ramps** (`tempoPace` + `intervalBlueprint` workPace) — peak at the LAST BUILD WEEK (`weeksToRace = taperLen`). Tempos end at `goal_pace + 5s` (sustainable); interval work ends at `goal_pace` (race-pace specificity in intervals, not tempos).
- **`FitnessSnapshot`** + **`OnboardingFormInput`** + **`AmbitionAssessment`** (`app/Support/Onboarding/`) — readonly value objects. `OnboardingFormInput::fromArray()` normalises form aliases (`'pr'` → `pr_attempt`, `'fitness'` / `'weight_loss'` → `general_fitness`) and the `runTypePreferences` ranking. The ranking influences quality-slot type, easy→quality upgrade at 5+ days, and long-run length cap. `AmbitionAssessment::toFeasibilityPayload()` exposes the wire-shape `{feasibility_pct, pace_score_pct, volume_score_pct, verdict_zone, verdict_label, detail, adjust_prefill, ...}` consumed by the Flutter plan-details modal; returns null when no measurable goal. Constants `PACE_WEIGHT` (0.6), `VOLUME_WEIGHT` (0.4), `ZONE_OK_MIN_PCT` (70), `ZONE_STRETCH_MIN_PCT` (40) are tunable on the class. Spec: `../docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.
- **`BuildPlan` tool** (`app/Ai/Tools/`) — used by BOTH agents. Wraps snapshot → ambition (two-pass) → builder → optimizer → proposal. Returns `{requires_approval, proposal_id, plan_structure, fitness_summary, ambition}`. The `ambition` field carries `level + summary + suggestion` so the agent can warn the runner naturally. Also injects `AmbitionAssessment::toFeasibilityPayload()` into the persisted `CoachProposal.payload['ambition']` so the Flutter plan-details modal can render its feasibility section without re-running the analyzer (skipped when goal has no measurable target). Spec: `../docs/superpowers/specs/2026-05-12-plan-feasibility-analysis-design.md`.
- **`AdjustPlan` tool** (`app/Ai/Tools/`) — used by BOTH agents. Auto-targets latest pending proposal → active goal → fallback. Operations: `replace` / `add` / `remove` / `adjust` / `shift` / `set_goal`. Pace AND distance honored verbatim for every non-interval day (absolute sanity windows only — pace [150, 720] s/km, distance [1, 80] km; no relative clamp; interval pace lives per work block in the grouped `intervals` blueprint), race-day untouchable, `add` respects `preferred_weekdays`. Interval sessions are authored in the COMPACT grouped form (`{warmup_seconds, steps:[{type:block,reps,…}], cooldown_seconds}` — see the tool description). Active-goal edits emit `EditActivePlan` proposals carrying a before→after `diff` array (built by `buildDiff`, includes `adjustments[]` notes) for the "PLAN REVISION" UI. **Type-swap behavior**: when a `replace`/`adjust` op changes `type`, the old `title` and `target_pace_seconds_per_km` are cleared so the optimizer regenerates them; switching TO `interval` without an explicit `intervals` triggers `PlanOptimizerService::defaultIntervalBlueprint` (one 4×400m + 90s block + warmup + cooldown).
- **`OnboardingAgent`** (`app/Ai/Agents/`) — minimal Sonnet agent. Tools: `BuildPlan`, `AdjustPlan`, `GetRecentRuns`. Prompt has injury-aware step 2 (any mention of pain / tendonitis / "coming back from" MUST trigger `adjust_plan` to replace tempos+intervals with easy in early weeks).
- **`RunCoachAgent`** (`app/Ai/Agents/`) — full coach-chat agent. Tools: query tools (`GetRunningProfile`, `GetRecentRuns`, `SearchActivities`, `GetActivityDetails`, `GetCurrentSchedule`, `GetCurrentProposal`, `GetGoalInfo`, `GetComplianceReport`) + `BuildPlan` + `AdjustPlan` (gated by `planMutationsAllowed()` for coach-managed clients).

**Tunable constants list** (when plans need adjustment):
- Pace cascade: `FitnessSnapshotService::STALENESS_PENALTIES` (30/60/90d penalty steps), `EASY_OFFSET_FROM_THRESHOLD` (75s default), `VO2MAX_OFFSET_FROM_THRESHOLD` (-20s).
- Ambition thresholds: `PlanAmbitionAnalyzer::REALISTIC_IMPROVEMENT_PER_MONTH` (12 sec/km/month), `MIN_VOLUME_FOR_RACE_PREP` (5k=25, 10k=35, HM=50, M=65 km/week), `RACE_PACE_DELTA_FROM_THRESHOLD`.
- Volume safety: `TrainingPlanBuilder::MAX_PEAK_VS_BASELINE_RATIO` (1.6× baseline default; ambition cranks to 1.7×/1.8×, intensity-bias floor 1.45× / ceiling 1.95×), `MAX_WEEKLY_GROWTH_RATIO` (1.30 W-o-W default; bias-tiered 1.22 → 1.36).
- Intensity bias (`users.intensity_bias` enum): `AmbitionAssessment::applyBias()` shifts the analyzer's level ±1 against `EffectiveAmbitionLevel` (Conservative / Realistic / Ambitious / VeryAmbitious / AllIn), each tier carrying its own `peakVolumeMultiplier` + `weeklyGrowthRatio` + `qualityPaceRampGain` (multiplied into `tempoPace()` / `intervalBlueprint()` progress). Builder reads via private state cached at the top of `build()`. Spec: `../docs/superpowers/specs/2026-05-11-onboarding-intensity-bias-design.md`.
- Runner level (`users.runner_level` enum, 5 cases Beginner → Elite): drives agent communication tone AND the interval blueprint shape. `RunnerLevel::toneBucket()` collapses to 3-case `RunnerToneBucket` (Novice / Standard / Expert) — `OnboardingAgent` reads it via priming-message line, `RunCoachAgent::coachInstructions()` reads `$user->runner_level->toneBucket()` directly. **Builder effect — Expert tier (Advanced/SubElite/Elite) uses a longer-rep interval progression**: early 4×800m/90s, mid 5×1000m/120s, peak 4×1200m/150s, sharpener 4×600m/90s @ goal pace. Novice/Standard (Beginner/Intermediate) keeps the original 5×400 → 5×800 → 6×800 + 4×400 sharpener. Pinning tests: `BuildPlanRunnerLevelTest::test_plan_content_is_identical_within_expert_tier` (Advanced/SubElite/Elite match), `..._within_non_expert_tiers` (Beginner/Intermediate match), `..._differs_between_novice_and_expert` (cross-bucket diverges). Volume/cadence/non-interval days are still tone-bucket-agnostic. Spec: `../docs/superpowers/specs/2026-05-11-onboarding-runner-level-design.md`.
- Plan length: `DEFAULT_WEEKS_FOR_GOAL` + `DEFAULT_WEEKS_FOR_PR_ATTEMPT`. `weeksExtension` adds +0/+4/+8 by ambition level (only when target_date null).
- Session mix: `TrainingPlanBuilder::pickSessionTypes()` (the 1-7 day table). `applyEasyToQualityUpgrade()` swaps one easy for a second quality at 5+ days/week if intervals/tempo is gold-ranked.
- Long-run cap: `LONG_RUN_CAP_BY_RANK` (gold=0.48, silver=0.44, bronze=0.40, last=0.36) + session-count boost (+0.20 for 2-day weeks, +0.10 for 3-day).
- Interval reps: `TrainingPlanBuilder::intervalBlueprint()` (4×400 → 5×800 → 6×800 progression, sharpener at goal pace).
- Taper: `TrainingPlanBuilder::TAPER_WEEKS` (3), `TAPER_FRACTIONS` ([0.70, 0.55, 0.40]).
- Adjust clamps: `AdjustPlan::PACE_MIN_SECONDS` (150) / `PACE_MAX_SECONDS` (720) + `KM_SANITY_MIN` (1) / `KM_SANITY_MAX` (80) — absolute sanity windows only, no relative-to-snapshot clamp (explicit pace AND distance requests are honored verbatim on non-interval days). `KM_MIN` (4) is now just the `add`-skeleton default. `enforceMinimumRunLength` is **create-only** (gated on `alignRaceDay`) so an explicit edit like "make Tuesday 3 km" is no longer bumped.

Tests: `tests/Feature/Services/Onboarding/FitnessSnapshotServiceTest.php`, `TrainingPlanBuilderTest.php`, `tests/Feature/Ai/Tools/AdjustPlanTest.php`. Each derivation tier, each days-per-week branch, ranking effects, low-volume long-run regressions, and adjust-tool guard rails (clamps, race-day protection, shift collisions, set_goal validation, active-goal targeting + diff) all have coverage.

#### The optimizer (deterministic post-processor)

`PlanOptimizerService::optimize($payload, User $user, bool $alignRaceDay = true)` runs at the END of `CreateSchedule::handle`, `EditSchedule::handle`, AND `BuildOnboardingPlan::handle`. Everything beyond the raw draft (whether agent-authored or builder-emitted) is deterministic — the optimizer is responsible for *structural correctness* (preferred days, race-day position, paces, titles, totals).

**`alignRaceDay`:** `true` on create (allows `alignTargetDateToLastDay` for open-ended plans). `false` on edit (the user has already seen and reasoned about `target_date`, don't move it).

**Pipeline order — KEEP this order, the comments in `optimize()` explain why:**

| # | Pass | What it does |
|---|---|---|
| 1 | `enforcePreferredWeekdays` | Drop days whose DOW isn't in `preferred_weekdays[]`. Race-day exempt by date match. |
| 2 | `enforceMinimumRunLength` | **Create-only** (`alignRaceDay=true`). Bump per-run km up to `max(4, min(6, avg_run_km × 0.4))`. Prevents 3km runs for an 8.6km/run runner. Skipped on edits so an explicit short-run request sticks. |
| 3 | `deduplicateDaysPerWeek` | Drop duplicate `day_of_week` within a single week. |
| 4 | **`alignTargetDateToLastDay`** (create only) | For open-ended plans (no `target_date`), snap it to the last training day. **Runs BEFORE the race-day passes** — without this, `enforceRaceDay` sees `target_date=null` and becomes a no-op for PR-attempt / general-fitness goals, leaving the runner's last day mislabeled as long_run/easy at snapshot pace instead of race-pace tempo. |
| 5 | **`ensureRaceDayEntry`** | If no day matches `target_date`, salvage a misplaced race-like day (`type=tempo` AND `target_km` within 10% of goal_km) and relocate it; otherwise insert a skeleton on target_date. Runs BEFORE drop so the agent's nice description survives when the agent miscounts weeks and puts the race past target_date. See `extractMisplacedRaceDay`. |
| 6 | `dropDaysPastTarget` | Strip everything strictly past `target_date`. |
| 7 | `enforceRaceDay` | Force the race-day entry's `type=tempo`, `km=goal_km`, `pace=goal_pace`, **`title=null`** (so generateTitles can rewrite to goal_name). |
| 8 | `reclassifyLongRuns` | Demote `long_run` days under `MIN_LONG_RUN_KM` (6.0) to `easy`. |
| 9 | `promoteLongRuns` | If a week has no `long_run` but has a clear longest `easy` ≥ MIN_LONG_RUN_KM, promote it. |
| 10 | `computePaces` | Fill `target_pace_seconds_per_km` for null fields, using the runner's baseline pace + a type-specific delta (easy +30, long +15, tempo −25, interval −50, threshold −25). AI-set quality paces survive (only nulls get filled). |
| 11 | `generateTitles` | Race day → `goal_name`. Other days with no title → just the type label (`"Easy"`, `"Long run"`, `"Tempo"`, `"Intervals"`, `"Threshold"`). The km is NOT in the title — the UI renders km separately. |
| 12 | `recalculateWeeklyTotals` | Sum `total_km` per week. |

**`goal_name` handling:** read from `$payload['goal_name']` *regardless* of `alignRaceDay`. `enforceRaceDay` nulls the title on EVERY call (create + edit), so `generateTitles` always needs `goal_name` available to relabel the race day. If `goal_name` is missing, the race day falls through to `dayTitle()` and ends up labeled "Tempo" — this is a regression to look out for. Test: `test_race_day_keeps_goal_name_title_on_edit_pass`.

#### The verifier (PlanVerifierAgent)

`app/Ai/Agents/PlanVerifierAgent.php`. One-shot Haiku auditor:
- `#[Model('claude-haiku-4-5')]` — 10× cheaper, 3-5× faster than Sonnet for a structured rules check. The verify loop runs up to 2× per plan, so this matters.
- `#[Temperature(0.2)]` — same plan should get the same verdict run-to-run.
- No tools, no memory; the caller (`VerifyPlan::buildPrompt`) packs all context into the prompt.

**Output shape (strict JSON):** `{passed, summary, issues[]}`. Each issue: `severity` (critical|major|minor), `area` (volume|progression|structure|recovery), `week`, `day_of_week`, `description`, `suggested_fix`. Pass = zero critical, zero major. Minor alone doesn't fail.

**What it checks (the only 5 principles):**
1. Single-week volume jumps — flag CRITICAL only if a single week has a run > 2× the runner's currently-demonstrated longest run, or weekly total jumps > 30%.
2. Cutback weeks — after 3 consecutive build weeks; missing across 6+ build weeks is major.
3. Taper — final 2-3 weeks should drop volume 30-50% while preserving race-pace work.
4. Rest cadence — at least 1 day per week with no run.
5. Long-run proportion — no single long run > 40% of week's total.

**The "Do NOT flag" list (extend this whenever Haiku hallucinates a false positive):**
- Titles, paces, HR zones, weekly totals (deterministic post-pass).
- Race-day title or `target_date` alignment (optimizer handles).
- **The training entry on `target_date` itself** — Haiku kept flagging "should be type 'race'" or "should not be a tempo workout". There is NO `race` type in `TrainingType`; the convention is `tempo` with `km=goal_km`, `title=goal_name`. Adding this rule killed a doom loop.
- 80/20 intensity, presence of `intervals` array on interval days (agent prompt enforces).

**Known Haiku weakness:** invents `(week, day_of_week)` pairs that don't exist in the plan. The prompt ends with "scan weeks[].days[].day_of_week before emitting a fix", but it's still imperfect — that's why agent EditSchedule ops sometimes fail with `"week N has no day on day_of_week M"` errors. Today: agent retries (each retry ≈ 25s of LLM streaming). TODO in `../TODO.md`: tighten the agent's prompt to always re-read `plan_structure` from the latest tool result before composing ops.

#### Caching middleware (cost / latency lever)

`AnthropicPromptCaching` (in `app/Ai/Support/`) attaches TWO `cache_control: ephemeral` breakpoints per outgoing Anthropic request:
1. On the last tool — caches `system` + all `tools` (~7k tokens for RunCoachAgent's 13 tools).
2. On the last content block of the last assistant message — caches the conversation history.

TTL is ~5 minutes. Onboarding is now a single LLM round-trip (the friendly reply after `BuildOnboardingPlan` returns), so caching matters less there — but coach-chat conversations span many turns and the cache reliably trims input cost ~10× from turn 2+. Cache hits show up as `cache_read_input_tokens` in the `[ai:usage]` log and the `token_usages` table.

### Token usage tracking

- `token_usages` table (migration, `App\Models\TokenUsage`) records one row per Anthropic call with user_id, conversation_id, agent_class, context, provider, model, and all five token counters (`prompt`, `completion`, `cache_read_input`, `cache_write_input`, `reasoning`) plus `total_tokens`.
- Written by `App\Listeners\RecordAgentTokenUsage` which handles `AgentPrompted|AgentStreamed` via **Laravel 13 auto-discovery** (listeners in `app/Listeners/` are registered from their `handle()` type hint). DO NOT also `Event::listen` it in AppServiceProvider — that produces duplicate rows.
- Context resolution: RunCoachAgent + conversation context `'onboarding'` → `'onboarding'`, else `'coach'`; named agents → their snake-case labels (`plan_explanation`, `activity_feedback`, `weekly_insight`, `running_narrative`); fallback is `Str::snake(class_basename($agent))`.
- **SDK caveat**: `StreamableAgentResponse::$usage` only reflects the *final* tool-loop iteration's usage (the one that yields `StreamEnd`). Intermediate iterations that returned `stop_reason: tool_use` are not tallied. Reported totals undercount streaming agent runs by roughly 30–50%.
- Browse the data in Filament at `/admin/token-usages` (see monorepo CLAUDE.md for access).

### Sign in with Apple

- `app/Services/Auth/AppleIdentityTokenVerifier.php` — fetches Apple's JWKS from `https://appleid.apple.com/auth/keys` (cached 1h via `Cache::remember('apple:jwks', 3600, ...)`), validates the JWT signature, issuer (`https://appleid.apple.com`), audience (`config('services.apple.bundle_id')`, default `com.erwinwijnveld.runcoach`), and expiry. Returns `{sub, email, email_verified}`.
- `app/Services/Auth/InvalidAppleIdentityTokenException.php` — thrown for any verification failure; `AuthController::appleSignIn` translates it to a 401.
- `app/Http/Controllers/AuthController.php::appleSignIn` — accepts `{identity_token, email?, name?}`, verifies, upserts a User on `apple_sub`, returns `{token, user}`. Apple only includes `email`/`name` on the *first* sign-in per user — subsequent sign-ins return only the `sub`, so the controller falls back to the JWT's `email` claim or a synthesized `<sub>@privaterelay.appleid.com` placeholder.
- **Mockable in tests**: `AppleIdentityTokenVerifier` is constructor-injected, so tests bind a Mockery instance via `$this->app->instance(AppleIdentityTokenVerifier::class, $mock)` — no need to generate real Apple-signed JWTs. See `tests/Feature/AuthTest.php`.

### Push notifications (APNs, iOS-only for now)

User-visible push pipeline. Spec: `docs/superpowers/specs/2026-04-26-push-notifications.md`. Currently the only triggers are plan-generation completion + failure, but the building blocks are reusable.

**Stack:** `laravel-notification-channels/apn` v6 → Pushok HTTP/2 → APNs (sandbox or prod).

**Auth:** Token-based with a `.p8` from Apple Developer → Keys → APNs. NOT certificate-based. One key per team, no expiry, same key for sandbox + prod (only the server endpoint flips).

**Config:** `config/broadcasting.php` → `connections.apn` (the package reads that exact path, NOT `services.apn`). Env vars: `APN_KEY_ID`, `APN_TEAM_ID`, `APN_BUNDLE_ID`, `APN_PRIVATE_KEY_PATH` (relative to `base_path()`, defaults to `storage/app/apns/AuthKey.p8`), `APN_PRODUCTION` (false for local + TestFlight, true for App Store builds — sandbox vs prod APNs server). The `.p8` file lives at `api/storage/app/apns/AuthKey.p8`, gitignored.

**Pieces:**
- `app/Models/DeviceToken.php` (`device_tokens` table) — one row per `(user_id, token)`, columns: `platform` (`ios`/`android`), `app_version` nullable, `last_seen_at`. Bumped on every register call.
- `app/Http/Controllers/DeviceTokenController.php` — `POST /api/v1/devices` (idempotent upsert, refreshes `last_seen_at`) + `DELETE /api/v1/devices` (signed-out cleanup).
- `App\Models\User::routeNotificationForApn()` — returns the user's iOS tokens. The package reads this magic-named method automatically when the channel is `ApnChannel`.
- `app/Notifications/PlanGenerationCompleted.php` — title + body + `expiresAt = now+4h` + custom payload `{type, conversation_id}`. `ShouldQueue` so APNs round-trip doesn't stall the job.
- `app/Notifications/PlanGenerationFailed.php` — same shape, `type=plan_generation_failed`.
- `app/Jobs/GeneratePlan::handle()` calls `$row->user->notify(new PlanGenerationCompleted($cid))` after a successful run; `failed()` dispatches `PlanGenerationFailed`.
- `app/Listeners/PruneInvalidApnsToken.php` — auto-discovered listener for `Illuminate\Notifications\Events\NotificationFailed`. When the channel is `ApnChannel` AND reason is `Unregistered` or `BadDeviceToken`, drops the row from `device_tokens`. APNs surfaces these reasons when the app was uninstalled or the token was never valid for this team.

**Test caveat:** `Notification::fake()` MUST be set up in any test that exercises `GeneratePlan::handle()` or `failed()`, otherwise the job tries the real APNs round-trip and fails on the missing `.p8` (especially in CI). `tests/Feature/Jobs/GeneratePlanJobTest.php` does this in `setUp()`.

**Adding a new push trigger:**
1. `php artisan make:notification YourEvent` — make it `ShouldQueue`, `via()` returns `[ApnChannel::class]`, `toApn()` returns an `ApnMessage` with title/body/`custom('type', 'your_event')`/`custom(<routing key>, …)`.
2. `$user->notify(new YourEvent(...))` from wherever the event happens.
3. Add the routing case to Flutter `PushService.routeFromPayload()` (returns the deep-link path for the new `type`).

**Scheduled push (daily training-day reminder):**
- `app/Console/Commands/SendTrainingDayReminders.php` (`plan:remind-today`) — queries today's `training_days` for users with active goals, skipping days that already have a `TrainingResult`. Title `"Today: {km}km {Type label}"`, body includes target pace + custom title (used for race day = goal name).
- `routes/console.php` schedules it `dailyAt('07:00')->timezone(config('app.reminder_timezone'))->withoutOverlapping()->onOneServer()`.
- `config/app.php` → `reminder_timezone` (env `REMINDER_TIMEZONE`, default `Europe/Amsterdam`). Single market default for v1 — when the userbase spans multiple regions, hash users by tz and run one scheduled task per tz, OR add `users.timezone` and shard the query.
- Manual run: `php artisan plan:remind-today` (uses today) or `--date=2026-04-27` to backfill / dry-run a different day.
- Tap routing: `training_day_reminder` with `training_day_id` payload → Flutter routes to `/schedule/day/{id}`.

### Wearable ingestion

- `app/Models/WearableActivity.php` (`wearable_activities` table) — provider-agnostic activity row. Key columns: `source` (string enum: `apple_health`, `strava`, `garmin`, `polar`, ...), `source_activity_id` (string — HKWorkout uuid, Open Wearables workout uuid, Strava activity id), `source_user_id` (for dedup), `distance_meters`, `duration_seconds`, `elapsed_seconds`, `average_pace_seconds_per_km`, `average_heartrate`, `max_heartrate`, `elevation_gain_meters`, `calories_kcal`, `start_date`, `end_date`, `raw_data` (JSON, source-specific extras like Apple Health splits). Unique index on `(source, source_activity_id)` makes ingestion idempotent. Constants: `WearableActivity::RUN_TYPES = ['Run', 'TrailRun', 'VirtualRun']`.
- `app/Http/Controllers/WearableActivityController.php` — `POST /wearable/activities` accepts a batch (`{activities: [...]}`, max 200/req), upserts each row, dispatches `ProcessWearableActivity` per row. `GET /wearable/activities` lists the user's history (paginated 30/page).
- `app/Jobs/ProcessWearableActivity.php` — filters to `RUN_TYPES`, calls `ComplianceScoringService::matchAndScore`, queues `GenerateActivityFeedback` + `GenerateWeeklyInsight` if a TrainingResult landed.
- `app/Jobs/GenerateActivityFeedback.php` — AI post-run feedback. No more streams API — splits surface only when the source supplies them in `raw_data.splits`.
- `app/Jobs/GenerateWeeklyInsight.php` — AI weekly coach notes.
- `app/Services/ComplianceScoringService.php` — weighted scoring: distance 30%, pace 40%, HR 30% (redistributes to 45/55 without HR). Uses `actual_pace_seconds_per_km` directly from the activity row (no derivation from speed).

**Adding a new source (e.g. Open Wearables for Garmin):**
1. Write a service that fetches workouts and posts them to `POST /wearable/activities` with `source='garmin'`. Could live as a queued job, a webhook controller, or both.
2. That's it — the unique constraint, ProcessWearableActivity dispatch, AI tools, and onboarding flow all work as-is. Optional: add an icon/label for the new source in `app/lib/features/schedule/widgets/wearable_summary_card.dart` and `select_activity_sheet.dart`.

### Domain models

Eleven Eloquent models with factories, using Laravel 13 `#[Fillable]` attribute syntax (NOT `$fillable` property):
- `User` (with `apple_sub` unique-nullable column for Apple Sign-In identity), `WearableActivity`
- `Goal` → `TrainingWeek` → `TrainingDay` → `TrainingResult` (`wearable_activity_id` FK)
- `CoachProposal` (with `agent_message_id` FK to SDK's messages table, `user_id` FK to users)
- `UserRunningProfile`, `PlanGeneration`, `TokenUsage`, `Organization`, `OrganizationMembership`

All enums are in `app/Enums/` as PHP 8.1 backed enums: `CoachStyle`, `MessageRole`, `ProposalStatus`, `ProposalType`, `GoalDistance`, `GoalStatus`, `GoalType`, `TrainingType`, `MembershipStatus`, `OrganizationRole`, `OrganizationStatus`, `PlanGenerationStatus`.

### API Structure

All routes under `/api/v1/*` prefix in `routes/api.php`. Public routes: `POST /auth/apple` + `POST /auth/dev-login`. Everything else requires `auth:sanctum`.

Controllers live in `app/Http/Controllers/`: Auth, Profile, Goal, TrainingSchedule, WearableActivity, Coach, Dashboard, Onboarding, plus `Api/MembershipController` and `Api/OrganizationController`.

### HR-zone auto-derivation

Single endpoint `POST /api/v1/profile/heart-rate-zones/derive` (`HeartRateZonesController::derive`) computes a 5-zone table from age + (optional) resting HR + (optional) upward correction from observed peaks. Matches Strava / Polar / Apple Fitness defaults — research-grounded over the v0 "median-of-top-N from training data" approach which systematically underestimated max HR (recreational runners almost never hit true max in normal training).

**Derivation order:**
1. **Tanaka prior** (`source = derived_age`) — `maxHR = 208 − 0.7·age` from HealthKit `dateOfBirth`. Tanaka et al. 2001 meta-analysis (n≈19k), ±7 bpm SD. Replaces the older `220 − age` formula and is what most coaching tools use.
2. **Karvonen zone bounds** when resting HR is also available — bounds = `restingHR + pct × HRR`. Apple Fitness uses this since watchOS 10. More accurate for fit runners with low resting HR (their HRR is wider than the plain `pct × maxHR` curve suggests).
3. **Upward-only empirical correction** (Garmin model) — when ≥3 qualifying runs have `max_heartrate ≥ Tanaka + UPWARD_CORRECTION_BUFFER` (5 bpm), use the median of those top observations instead of Tanaka. Catches genuine race-PB / VO2max efforts where the runner DID hit max, without letting normal training drag the estimate downward. Same qualifying filters as the v0 path (≥10 min, avg HR ≥ 130, 100-220 physiological window, ≤365 days, running types only).
4. **Default** (`source = default`) — when no age available. NOT persisted (leaves `users.heart_rate_zones` null so reads keep falling through to `HeartRateZones::DEFAULTS` at runtime).

`App\Support\HeartRateZoneDeriver` owns the algorithm with two const knobs: `UPWARD_CORRECTION_BUFFER` (5 bpm above Tanaka), `UPWARD_CORRECTION_MIN_SAMPLES` (3 high-effort observations). `App\Support\DerivationResult` (readonly) is the return shape. `App\Support\HeartRateZones` holds the qualifying-run filter constants + `TANAKA_*` + `ZONE_PCT` (0.60/0.70/0.80/0.90).

**The `derived_empirical` enum case is legacy** — kept for backward compat (existing rows in users.heart_rate_zones_source) but the deriver no longer produces it. Next recompute flips the row to `derived_age`.

Source-tracking column `users.heart_rate_zones_source` (`App\Enums\HeartRateZonesSource`):
- `manual` — set by `UpdateProfileRequest::prepareForValidation` whenever `heart_rate_zones` is in a `PUT /profile` body. Sticky against scheduled re-derives but NOT against this endpoint (the recompute flow is an explicit user action — overrides manual).
- The endpoint always recomputes and persists when source ≠ Default. Spec: `docs/superpowers/specs/2026-05-08-hr-zones-auto-derive.md`.

**`users.date_of_birth`** (date, nullable) — manually-entered DOB stashed by the derive endpoint when `date_of_birth` is in the body. Drives:
- Backend's age computation (`Carbon::parse($dob)->age` — handles month/day rollover correctly so age stays accurate without storing it).
- DOB-picker prefill on subsequent recomputes (Flutter reads `user.dateOfBirth` directly).
- The yearly birthday push (see below).

**Removed**: `RunningProfileService::analyze` no longer touches zones — derivation lives only in `HeartRateZoneDeriver` to avoid dual-write divergence.

### Yearly birthday push

`App\Console\Commands\SendBirthdayZoneReminders` (`plan:remind-birthday`) runs daily at 09:00 in `config('app.reminder_timezone')` (default Europe/Amsterdam). Queries `users WHERE date_of_birth IS NOT NULL AND MONTH(date_of_birth) = MONTH(today) AND DAY(...) = DAY(today) AND date_of_birth < today` (the `< today` skips the runner's actual birth date so newborn fixtures don't trigger). Dispatches `App\Notifications\BirthdayZoneCheckReminder` (custom `type=birthday_zone_check`).

Tap routing: Flutter `PushService.routeFromPayload` maps `birthday_zone_check` → `/profile/heart-rate-zones`, a thin route screen that opens `HeartRateZonesSheet` on mount and falls back to `/dashboard` after the sheet pops.

Manual run: `php artisan plan:remind-birthday` (today) or `--date=2026-12-15`. Notification class is `ShouldQueue`, so the `Notification::fake()` pattern applies in tests (`tests/Feature/Console/SendBirthdayZoneRemindersTest.php`).

Leap-year edge (Feb 29) is intentionally not handled in v1 — affected users (~0.07%) miss the push on non-leap years. Future polish: shift to Feb 28 in non-leap years.

### Reschedule training day

`PATCH /api/v1/training-days/{day}` (`TrainingScheduleController::updateDay`) moves a `TrainingDay` to a new date. Validation rules:
- `date` ≥ today and ≤ goal `target_date` (when set)
- 422 if the day already has a `TrainingResult` linked (unlink first)
- 422 if the day IS the race day (its `date` equals `goal.target_date`) — moving it would break the optimizer's race-day-on-target-date invariant. The user has to edit the goal date instead.

After update, the day is auto-re-assigned to the matching `TrainingWeek` (week whose `[starts_at, starts_at + 7d)` contains the new date) so weekly views stay coherent. The optimizer is NOT re-run on `updateDay`.

Besides `date`, the endpoint accepts in-place content edits (the app's edit-day sheet): `target_km`, `target_pace_seconds_per_km` (dropped on interval days), `target_heart_rate_zone`, and `intervals` — the grouped blueprint from the app's interval block editor. `intervals` is 422 on non-interval days and 422 when `IntervalBlueprint::normalize` rejects it (empty/garbage — storing that would null the derived `target_km`); accepted structures are stored normalized and the saving hook derives `target_km`, which the response carries back. Spec: `../docs/superpowers/specs/2026-06-10-app-interval-editor-design.md`. Tests: `tests/Feature/TrainingScheduleTest.php` (search `intervals`).

### Off-plan run linking ("buiten schema")

`ComplianceScoringService::findMatchingDay` auto-matches a run ONLY when it lands on a planned session's **exact date** (was a ±1-day window). Runs on any other day get no `TrainingResult` and surface as off-plan runs.

- `TrainingScheduleController::schedule` attaches `unplanned_runs` to each week: run-type `wearable_activities` within the week's `[starts_at, starts_at + 7d)` range that `whereDoesntHave('trainingResults')`. One query for the whole plan span, grouped in PHP, shaped to match the Flutter `WearableActivitySummary` model. (`currentWeek` does NOT attach them — only the full schedule, which both the schedule screen and dashboard read.)
- `POST /wearable/activities/{activity}/link-day` (`linkActivityToScheduleDay`) links an off-plan run to a planned session: it **relocates the chosen `TrainingDay` onto the run's actual `start_date`** (reusing `updateDay`'s week-reassign logic but allowing past dates — that's the whole point, unlike `updateDay` which forbids `< today`), then `ComplianceScoringService::scoreDay($day, $activity)` + `GenerateActivityFeedback::dispatch`. Guards: activity owned + run-type + not already linked (409); day owned + no result + not the race day (422). Sits in the general auth group (NOT `require.pro`), alongside `match-activity`.
- Tests: `tests/Feature/Http/TrainingDayMatchTest.php` (`test_link_*`), `tests/Feature/TrainingScheduleTest.php` (`test_schedule_includes_off_plan_runs_in_their_week`), `tests/Feature/ComplianceScoringTest.php` (`test_run_one_day_off_does_not_auto_match`).

### Notifications inbox (action-required items)

Generic per-user inbox for items the runner needs to act on. Backed by `user_notifications` (`App\Models\UserNotification`):
- `type` (string discriminator: currently only `plan_evaluation`)
- `title`, `body` — display copy
- `action_data` (JSON) — type-specific payload (e.g. `{"evaluation_id": 42}`)
- `status` (`pending` / `accepted` / `dismissed`) + `acted_at`

**Endpoints** (all under `auth:sanctum`):
- `GET /api/v1/notifications` → pending list, capped at 50 items (`NotificationController::MAX_INBOX_ITEMS`)
- `POST /api/v1/notifications/{id}/accept` → routes by `type` to the right handler, marks accepted
- `POST /api/v1/notifications/{id}/dismiss` → marks dismissed (and cascades to the linked `PlanEvaluation` when applicable)

**Adding a new type**:
1. Pick a string like `profile_completion` and add as a `UserNotification::TYPE_*` constant
2. Decide what `action_data` shape it needs and document it
3. Add a producer (a service / job that creates the row when conditions trigger).
4. Add a `match` arm in `NotificationController::accept` for the type, calling its specific handler. Default falls through to `abort(422, …)`.
5. (Optional) extend the Flutter `_NotificationCard` with a tertiary action when the type warrants it. See `app/CLAUDE.md` for the UI pattern.

### Mid-plan evaluation moments

`TrainingPlanBuilder::scheduleEvaluations()` emits `evaluations[]` entries every 2nd week (`EVALUATION_EVERY_N_WEEKS = 2`), skipping the taper window (last `taperLengthForRamp()` weeks). `ProposalService::applyCreateSchedule` persists them as `plan_evaluations` rows (status `pending`) linked to the goal + week.

Every evening at 19:00 in the reminder timezone, `plan:run-evaluations` (`App\Console\Commands\RunPlanEvaluations`) dispatches `GeneratePlanEvaluation` for every pending row whose `scheduled_for` has arrived AND whose goal is still active. The job:
1. Runs `PlanEvaluationAgent` (Sonnet, one-shot with `GetRecentRuns` / `GetComplianceReport` / `GetCurrentSchedule` read tools + `AdjustPlan` when `planMutationsAllowed()`).
2. Detects any `EditActivePlan` proposal that `AdjustPlan` produced (by `id > snapshot_before`).
3. Stores the AI markdown report + (optional) `proposal_id` on the `PlanEvaluation` row.
4. Creates a `user_notifications` row (`type=plan_evaluation`) + dispatches `PlanEvaluationReady` APNs push. Push body differs by whether a proposal exists.

Accept flow: `NotificationController::applyPlanEvaluation` resolves the linked evaluation, applies its `proposal` (if any) via `ProposalService::apply`, and flips the evaluation status to `Accepted`. Dismiss flips the evaluation to `Dismissed` without applying.

Coach-managed clients (`organizations.coaches_own_plans = true`) get read tools only — agent produces a report but no proposal, so the runner just sees the markdown summary.

**Tests:** `tests/Feature/Http/NotificationControllerTest.php` (accept/dismiss/auth flow).

### Interval data shape — GROUPED blueprint (must read before touching interval code)

**`intervals_json` stores the canonical GROUPED blueprint, not a flat segment list.** Shape:
```
{warmup_seconds:int|null, steps:[
  {type:"block", reps, work_distance_m|null, work_duration_seconds|null, work_pace_seconds_per_km|null, recovery_seconds},
  {type:"rep",   work_distance_m|null, work_duration_seconds|null, work_pace_seconds_per_km|null},
  {type:"rest",  duration_seconds}
], cooldown_seconds:int}
```
"4×800m/2min then 4×400m/1min" = TWO `block` steps (no expanded repetition). Multi-loop, pyramids, warmup/cooldown all native.

**`App\Support\Intervals\IntervalBlueprint` is the single source of truth** — `collapse(flat)→grouped`, `expand(grouped)→flat`, `normalize(either)→clamped grouped`. Lifted from the (proven) Filament parse/serialize. Everything that touches intervals delegates to it:
- `PlanOptimizerService::normalizeIntervals` runs `IntervalBlueprint::normalize` on every interval day (accepts grouped OR legacy flat, returns grouped; naked interval day → `defaultIntervalBlueprint` 4×400m).
- `ProposalService::normalizeIntervals` = thin wrapper over the helper.
- `TrainingPlanBuilder::intervalBlueprint` emits grouped directly.
- Filament `GoalSchedule` parse/serialize map form-state ↔ grouped via the helper.
- Existing flat-shaped rows are migrated by `2026_06_09_..._convert_intervals_json_to_grouped_blueprint` (idempotent data migration; folds flat→grouped, skips already-grouped). Rows that fail conversion are nulled WITH a `Log::warning` carrying the day id + raw JSON, so data loss is auditable. The accessor + helper also tolerate flat at read-time as a belt-and-braces fallback.

**Day-level pace is still always null on interval days.** Per-block work pace lives in `steps[].work_pace_seconds_per_km` (filled by `PlanOptimizerService::computePaces` when null). `TrainingDay::workSetAveragePaceSecondsPerKm()` = unweighted mean across non-rest steps' work pace (per-STEP, not per-rep). Storing one day-level number would mask the per-block paces.

**Interval-day `target_km` is DERIVED, never authored (recompute-on-write invariant).** After any write, an interval day's `target_km` equals `IntervalBlueprint::estimateTotalKm(intervals_json)` — work steps by literal distance (or duration ÷ pace), time segments (warmup/recoveries/rests/cooldown) at a jog pace = avg work pace + 100 s/km clamped [180, 720] (fallback 360 when no work pace; constants `ESTIMATE_*` on the helper). Pure function of the blueprint — no user/snapshot input — so every write path stores the same number. Enforced in THREE places: `PlanOptimizerService::recomputeIntervalDistances` (payload pass, after `computePaces`, before `recalculateWeeklyTotals`), the `TrainingDay::saving` hook (Filament/ProposalService/any direct row write), and the `2026_06_10_..._recompute_interval_day_target_km` backfill (also re-sums affected `training_weeks.total_km`). The builder's old `max(estimated, allocated)` inflation is gone — `TrainingPlanBuilder::renderQuality` emits the estimate directly. Agent-supplied `target_km` on interval days is overridden and flagged in `adjustments[]` ("derived from the session structure"); both `AdjustPlan` and `EditWorkout` descriptions tell the agent to change `intervals` instead. The Filament edit modal hides the Distance input on interval days behind a live "Distance (auto)" placeholder. Spec: `../docs/superpowers/specs/2026-06-10-interval-target-km-recompute.md`. Tests: `tests/Feature/Support/IntervalBlueprintTest.php` (estimator), `tests/Feature/Models/TrainingDayTargetKmRecomputeTest.php` (hook), `tests/Feature/Migrations/RecomputeIntervalTargetKmTest.php` (backfill).

**Wire format = grouped end-to-end** (A-volledig): the API returns grouped, the Flutter `IntervalBlueprint`/`IntervalStep` Freezed models parse it (with a flat fallback for unmigrated rows), and the watch path expands to flat in Dart so the native WorkoutKit bridge is unchanged (native `IntervalBlock(iterations:)` mapping is a deferred refinement).

**`training_results.pace_score` is nullable.** On interval days `ComplianceScoringService::intervalPaceScore` scores the whole-run average against a blueprint-derived band `[work-set avg pace, jog pace + 90s]` (see "Interval compliance scoring" below) and returns null only when the blueprint carries no work paces or the activity has no average pace. On non-interval days it stays null when there's no day-level target pace. `weightedOverall` renormalises whatever components are missing.

**Filament editor**:
- `Action`-based modal (not the old custom CSS modal — Filament's `<x-filament-actions::modals />` gives proper scrolling/positioning).
- Steps Repeater with three row types: `block` (loop with reps count), `rep` (single one-off rep), `rest` (one-off rest). Maps form-state ↔ canonical grouped `intervals_json` via `IntervalBlueprint` (no more flat round-trip); multi-loop + pyramid sessions are first-class.
- Read-only Placeholder shows the live work-set average ("Pace (work-set avg): 4:30/km") while editing; updates as the coach tweaks any work segment.
- Pace text inputs validated by regex `^\d{1,2}:[0-5]\d$` — invalid input fails Filament validation rather than silently coercing to null on save.

**Tests:** `tests/Feature/Models/TrainingDayWorkAvgPaceTest.php` (accessor) + `tests/Feature/ComplianceScoringTest.php` (interval scoring, search `interval_day_`) + `tests/Feature/Filament/GoalScheduleIntervalsTest.php` (parser/serializer round-trip + UI behaviour).

### Interval session rules

Enforced by `IntervalBlueprint::normalize` (called from `PlanOptimizerService::normalizeIntervals` for every create/edit) AND documented for the agent in the `AdjustPlan` tool description. Only applies when `day.type === 'interval'`:

- **Warmup**: optional (`warmup_seconds` null = none), time-based, capped at 120s.
- **Work step**: exactly ONE of `work_distance_m` or `work_duration_seconds` per block/rep (distance preferred when both set).
- **Recovery**: `block.recovery_seconds` / `rest.duration_seconds`, time-based, min 15s default 90s. (Distance-based recoveries are no longer converted — canonical recovery is time only.)
- **Cooldown**: REQUIRED, time-based, clamped to [60s, 600s], default 300s. Always present.
- **Reps**: clamped [1, 60].

`PlanVerifierAgent` is told NOT to flag any of these (the optimizer handles them). When adding interval-shape rules, update both the agent prompt AND `normalizeIntervals` so the deterministic pass keeps the plan canonical regardless of agent compliance.

**Interval pace is per work block, never on the day** — `training_days.target_pace_seconds_per_km` is forced null for interval days by `PlanOptimizerService::computePaces`. The "day-level" pace is computed at read time via `TrainingDay::workSetAveragePaceSecondsPerKm()` (unweighted mean of non-rest steps' `work_pace_seconds_per_km`). Don't reintroduce day-level pace writes on intervals. Tests: `tests/Feature/Models/TrainingDayWorkAvgPaceTest.php`, `tests/Feature/Support/IntervalBlueprintTest.php`, `tests/Feature/Migrations/ConvertIntervalsToGroupedTest.php`.

**Interval compliance scoring is a plausibility model over whole-session aggregates** (we ingest no splits/HR samples yet — the app sends `raw_data: {}` apart from `route`). All three components branch on `day.type === 'interval'` in `ComplianceScoringService`:
- **HR** — the session **max** HR must touch the zone BELOW the day's target (Z5 day → peaks ≥ default Z4 min). The old avg-HR-vs-Z5 comparison structurally scored 1-5 on correctly executed sessions (avg mixes warmup/recoveries/cooldown → lands Z3/Z4). No upper penalty; missing `max_heartrate` → null (avg fallback deliberately does NOT kick in).
- **Pace** — whole-run average must land in `[work-set avg, IntervalBlueprint::estimateJogPace(workAvg) + 90s]` (`INTERVAL_PACE_BAND_MARGIN_SECONDS` — generous because walking recoveries are legitimate). Outside → standard deviation penalty vs the nearest edge. Faster than work avg = recoveries skipped, also penalised.
- **Distance** — asymmetric band `[IntervalBlueprint::workDistanceKm(...), target_km × 1.8]` scores 10 (target assumes a 120s-capped warmup; a real 10-15 min warmup overshoots it — that's correct execution). Below the work floor → steep ×15 slope; above the band → mild ×7.5 slope. Constants `INTERVAL_DISTANCE_*` on the service.

This stays as the fallback path once segment ingestion (HKWorkoutEvents + HR samples → per-rep scoring) lands. One-off backfill after deploy: `php artisan compliance:rescore-intervals` (`--dry-run` prints old → new and rolls back). Spec: `../docs/superpowers/specs/2026-06-10-interval-compliance-scoring-design.md`. Tests: `tests/Feature/ComplianceScoringTest.php` (`interval_day_*`), `tests/Feature/Console/RescoreIntervalComplianceTest.php`.

### i18n (locale resolution + translation files)

`SetLocale` middleware on the `api` group (`app/Http/Middleware/SetLocale.php`) resolves locale per request as: `auth()->user()?->locale` > `Accept-Language` header (Symfony's `getPreferredLanguage(['en', 'nl'])`) > `app.fallback_locale`. Sets BOTH `App::setLocale($locale)` and `Carbon::setLocale($locale)` so `__()` lookups and Carbon date formatting both honour the runner's language.

`User` implements `Illuminate\Contracts\Translation\HasLocalePreference::preferredLocale()` (returns `$this->locale ?? config('app.fallback_locale')`) so Laravel's notification system **auto-wraps** any `$user->notify(...)` dispatch in `withLocale()`. No need to set locale manually in `toApn()` — queue workers respect `$user->locale` automatically.

Translation files in `api/lang/{en,nl}/`:
- `validation.php` — Laravel default messages (published via `php artisan lang:publish`) + Dutch counterpart
- `notifications.php` — push notification copy keys (`plan_generation.completed.title`, `training_day.title_with_km`, etc.)
- `enums.php` — enum labels (currently `training_type.{easy,tempo,interval,long_run,threshold}`)
- `auth.php` + `pagination.php` + `passwords.php` shipped by `lang:publish` but stay English until those strings surface to the mobile API (they don't yet).

`TrainingType::label()` returns `__('enums.training_type.'.$this->value)` — Filament admin, notifications, and plan-generated session titles all auto-localize from a single source.

Notification classes that route through `__()`: `PlanGenerationCompleted`, `PlanGenerationFailed`, `TrainingDayReminder`, `BirthdayZoneCheckReminder`. Three remaining notifications carry deferred `TODO(i18n)` markers — `WorkoutAnalyzed` (templated verdict copy needs design review), `OrganizationInvitation` (inviter-vs-invitee locale resolution unresolved), `AdhocPush` (admin-typed copy, doesn't need localization).

`AuthController::appleSignIn` backfills `users.locale` from `Accept-Language` on the **first** sign-in only (skipped when locale is already set, so manual overrides win). `UpdateProfileRequest` accepts `locale` ∈ `{en, nl, null}` so the Flutter app can push the runner's chosen language. Spec: `docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md`. Phase 1+2 plan: `docs/superpowers/plans/2026-05-12-i18n-foundation.md`.

**Phase 4 — agent localization via `App\Ai\Support\LanguageDirective`** (`api/app/Ai/Support/LanguageDirective.php`). `LanguageDirective::current()` reads `App::getLocale()` and returns a trailing directive appended to every agent's system prompt: empty string for English (zero overhead, **preserves Anthropic prompt-cache lineage** since `system + tools` stay identical across locales), or a short Dutch directive for `nl` (idiomatic phrasing, keep running terms in original form, use Dutch decimal comma). Injected into all 5 agents that produce free-form runner-facing text: `RunCoachAgent`, `OnboardingAgent`, `WorkoutAgent`, `ActivityFeedbackAgent`, `WeeklyInsightAgent`. **`PlanExplanationAgent` is intentionally excluded** — its `HasStructuredOutput` response is consumed programmatically. Queue jobs that dispatch agents outside the HTTP request lifecycle MUST `App::setLocale($user->preferredLocale())` before invoking — already done in `GenerateActivityFeedback`, `GenerateWeeklyInsight`, `OnboardingPlanGeneratorService`. Test: `tests/Feature/Ai/Support/LanguageDirectiveTest.php`.

## Project-specific conventions

### Tools (Laravel AI SDK)

- Every tool implements `Laravel\Ai\Contracts\Tool` with `description()`, `schema(JsonSchema $schema)`, `handle(Request $request)`.
- `handle()` must return a **string** (use `json_encode()`).
- Access request params with **array access**: `$request['key']` — NOT `$request->get()` or `$request->input()`.
- **Required-on-every-param**: every schema param MUST have `->required()`. For truly optional params, use `->required()->nullable()` — this satisfies OpenAI strict mode and is fine with Anthropic. Do NOT use `->default()`.
- Tools that need user data take `User $user` in constructor, injected from the agent.
- **UI-only tools** (`PresentRunningStats`, `OfferChoices`) return `json_encode(['display' => 'stats_card'|'chip_suggestions', ...])`. `CoachController::sendMessage` inspects `ToolResultEvent` payloads for `display` and forwards matching `data-stats` / `data-chips` SSE events to Flutter.

### Pro entitlement gate for AI work

**Every queued job that spends Anthropic budget MUST early-return when `$user->isPro()` is false.** HTTP routes are gated by the `require.pro` middleware (`App\Http\Middleware\RequireProEntitlement`, returns 402), but background jobs run outside the HTTP request lifecycle and need their own guard. Without it, a runner whose subscription expired keeps generating activity feedback, weekly insights, etc. — silent budget leak.

Pattern (top of `handle()`, after the user is resolved but before any agent call):

```php
if ($user && ! $user->isPro()) {
    Log::info('Skipping AI work for non-pro user', [
        'user_id' => $user->id,
        'job' => static::class,
    ]);
    return;
}
```

Applied today: `GenerateActivityFeedback`, `GenerateWeeklyInsight`. `GeneratePlan` is the deliberate exception — onboarding runs it BEFORE the paywall (the paywall renders the generated plan as a teaser), so it's an unconditional acquisition cost. Spec: `../docs/superpowers/specs/2026-05-19-revenuecat-subscriptions.md` → "AI feature gate". When adding a new AI job, add to the checklist.

### Tool design guidelines

When adding or refactoring agent tools, follow these principles. They are derived from reviewing [r-huijts/strava-mcp](https://github.com/r-huijts/strava-mcp) ([tools folder](https://github.com/r-huijts/strava-mcp/tree/main/src/tools)) — a production Strava MCP whose tool shapes we treat as a design benchmark even though we don't actually call Strava. Read that repo before designing a new tool.

1. **One tool per use case, not one tool per endpoint.** The MCP ships separate `getRecentActivities` (no args, latest N) and `getAllActivities` (date range + filters). We mirror this with `GetRecentRuns` + `SearchActivities`. Don't force the agent to guess args for common cases — give it a narrow tool.

2. **All optional params use `->required()->nullable()`.** Handler defaults apply when null. The agent should never be forced to invent a value it doesn't have.

3. **Descriptions must include example queries and counter-examples.** Show the agent *what the tool is for* and *what it isn't*. Pattern:
   ```
   USE THIS for queries like:
   - "..."
   - "..."

   DO NOT use for "..." — use <other_tool> instead.
   ```
   This is the single biggest lever for making the agent pick the right tool.

4. **Param descriptions include format hints and defaults.** `"YYYY-MM-DD, e.g. '2025-01-01'"` beats `"a date"`. `"max 50, default 10 if null"` beats `"a number"`.

5. **Add guardrail params where cost matters.** Cap results (`limit`, `max_activities`) and API calls (`max_api_calls`) so the agent can't blow the token budget or rate limits. Put the cap in the param description too.

6. **Return shapes should include pre-computed aggregates.** The agent pays tokens per field it reads — give it `total_km`, `avg_pace`, `weekly_breakdown` so it doesn't have to sum individual runs itself.

7. **Mutations always return proposals, never write.** Schedule-creating tools return `{"requires_approval": true, ...}` — persistence happens in `ProposalService::apply()` after user approval. See `CreateSchedule`/`ModifySchedule`.

8. **Update `RunCoachAgent::instructions()` when adding a tool.** The system prompt must spell out *when to pick this tool vs the others*. Tool descriptions alone are not enough — the instructions give cross-tool guidance the individual tools can't.

### Proposals flow

Mutation tools (`CreateSchedule`, `ModifySchedule`) NEVER write to the database. They return:
```json
{"requires_approval": true, "proposal_type": "create_schedule", "payload": {...}}
```
`ProposalService::apply()` does the actual DB writes only after user approval.

### Migrations — forward-only, NEVER edit committed migrations in place

**Hard rule:** the moment a migration has shipped to prod (Laravel Cloud), it is frozen. Any subsequent schema change goes in a NEW forward migration. No exceptions.

Why: Laravel Cloud's deploy command runs `php artisan migrate --force`, which is forward-only — it never re-runs a migration whose row already exists in `migrations`. If you add columns to an existing baseline migration, `migrate:fresh` locally produces the new schema, the test suite passes, prod deploy succeeds (because `migrate --force` skips the already-run baseline), and the next request that touches the new columns blows up with `42703 / 23502` in production. We've eaten this footgun three times — `subject_type/subject_id` on `agent_conversations` (fixed by `2026_05_08_110411_add_subject_to_agent_conversations`), `heart_rate_zones_source/date_of_birth` on `users` (fixed by `2026_05_08_210000_add_hr_zone_source_and_dob_to_users`), and `pace_score` nullability on `training_results` (fixed by `2026_05_08_220000_make_pace_score_nullable_on_training_results`). Each one took the corresponding endpoint down on prod until a follow-up migration shipped.

**When you need to change schema:**
1. `php artisan make:migration descriptive_name` — produces a timestamped file.
2. Use `Schema::table(...)` with `Schema::hasColumn(...)` / `Schema::hasIndex(...)` guards so it stays idempotent across local-dev (which may already have the change via a prior in-place edit you're now correcting) and prod.
3. For column type / nullability changes, `$table->...->change()` works on Laravel 11+ without `doctrine/dbal`. Re-declaring the same definition is a no-op.
4. Test locally with `migrate:fresh --seed` AND with a mid-cycle migrate (run only the new migration on a DB that has the prior state).
5. Ship it.

**The previously-stored memory `feedback_migrations.md` ("pre-launch, rewrite migrations directly + migrate:fresh")** is now incorrect — RunCoach is past launch (TestFlight builds against `https://runcoach.laravel.cloud`). Treat all committed migrations as immutable.

If you spot an in-place edit happening (e.g. `git diff` shows changes to a migration file whose timestamp predates the last main-branch deploy), STOP and write a forward migration instead, even if the schema is "obviously safe."

### Testing

- ~295 feature tests in `tests/Feature/`. Use `LazilyRefreshDatabase` trait (NOT `RefreshDatabase`).
- Coach tests use `RunCoachAgent::fake(['response text'])` to mock agent responses.
- Apple Sign-In tests bind a Mockery `AppleIdentityTokenVerifier` instance to the container (`$this->app->instance(...)`) — see `tests/Feature/AuthTest.php`.
- Wearable ingestion tests post to `/wearable/activities` directly and assert on `wearable_activities` rows + dispatched jobs — see `tests/Feature/Http/WearableActivityIngestionTest.php`.
- Middleware/listener tests construct events directly with `Mockery::mock(TextProvider::class)` — see `tests/Feature/Listeners/RecordAgentTokenUsageTest.php`.
- Run: `php artisan test --compact`

### Pint formatting

Always run `vendor/bin/pint --dirty --format agent` after modifying PHP files.

### Debugging patterns we use

#### Diagnostic log lines

Local env emits compact one-line logs on every agent call. Tail with:

```bash
tail -f storage/logs/laravel.log | grep -E '\[(onboarding:start|agent:tool|agent:prompt|ai:usage|coach stream)\]'
```

| Marker | Source | What it tells you |
|---|---|---|
| `[onboarding:start] user_id=N goal_type=… distance=… target_date=… days=… weekdays=… style=…` | `OnboardingPlanGeneratorService::generate()` | Marks the start of a fresh onboarding with all inputs. Use as the anchor when reading a slow / failed run. |
| `[agent:tool] → ToolName input={…}` | `AppServiceProvider::logAgentToolInvocations()` | Every tool invocation, with full args. |
| `[agent:tool] ← ToolName (Nms) output={…}` | same | Tool return + duration. Errors surface as `output={"error":...}`. |
| `[ai:usage] AgentClass ctx=… model=… in=N (cache_read=N, write=N) out=N total=N` | `RecordAgentTokenUsage` listener | Per-Anthropic-call token accounting. Watch `cache_read` to confirm caching. |
| `[agent:prompt] ctx=onboarding\|coach user_id=N duration_ms=N message_bytes=N` | `OnboardingPlanGeneratorService` and `CoachController::sendMessage` | Wall-clock for the entire `prompt()` / streaming loop. Big number here = something's hot. |
| `[coach stream] ExceptionClass: message` | `CoachController::sendMessage` catch | SSE streaming error. |

**The `[ai:usage]` SDK caveat (important):** `StreamableAgentResponse::$usage` only reflects the *final* tool-loop iteration's usage. Intermediate iterations that returned `stop_reason: tool_use` are NOT tallied. Reported totals undercount streaming agent runs by 30-50%. So a fresh onboarding emitting one `[ai:usage] in=2228 out=4094` line actually burned several thousand more tokens across the iterations between `CreateSchedule` → `VerifyPlan` → reply.

#### Common failure modes (read the logs in this order)

| Symptom | Where to look | Likely cause |
|---|---|---|
| **Slow follow-up edit (~70-80s for "add intervals")** | Multiple adjacent `[agent:tool] ← EditSchedule (Nms) output={"error":...}` lines | Agent referenced a missing `(week, day_of_week)` or omitted a required field; each retry costs ~20-25s of LLM streaming. Each `EditSchedule` op JSON with intervals is 2-3KB. |
| **Race day labeled "Tempo" instead of goal_name** | `tinker --execute 'echo CoachProposal::find(N)->payload["goal_name"];'` | `goal_name` was lost in payload OR `generateTitles` ran with `$goalName=null` (used to be tied to `alignRaceDay`; now decoupled — see `optimize()` line 67-72). |
| **Race day description is generic "Goal day. Execute your plan."** | Compare agent's CreateSchedule input vs final proposal. Agent likely placed race past `target_date`. | `extractMisplacedRaceDay` didn't find a match — check `target_km` (within 10% of goal_km?) and `type` (must be `tempo`). Widen the heuristic in `extractMisplacedRaceDay` if needed. |
| **Verifier doom loop hits cap** | `[agent:tool] ← VerifyPlan` lines repeating with same `issues[].description` | Agent burning cycles trying to fix something the optimizer already handles. Read the issue description — if it mentions titles, paces, HR zones, race-day type, or anything in the verifier's "Do NOT flag" list, ADD IT TO THAT LIST in `PlanVerifierAgent::instructions()`. |
| **Cache miss on turn 2+** | `[ai:usage] cache_read=0` instead of large number | (a) `AnthropicPromptCaching` not registered in `AppServiceProvider::boot()`. (b) Conversation went idle past 5-min TTL. (c) Tools or system prompt changed between turns (cache key invalidated). |
| **Token usage rows duplicated** | `token_usages` table has 2 rows per `invocation_id` | Listener registered twice (Laravel 13 auto-discovery + a manual `Event::listen`). Remove the manual listen. |
| **"PLAN REVISION" card on fresh onboarding** | Flutter shows revision UI instead of new-plan UI | `EditSchedule` attached `diff` to a pending-proposal edit. `diff` should ONLY attach when `responseProposalType === EditActivePlan`. See `EditSchedule::handle`. |

#### Tinker recipes for the plan pipeline

```bash
# Dump the latest pending proposal's structure
php artisan tinker --execute 'use App\Models\CoachProposal; $p = CoachProposal::orderByDesc("id")->first(); echo "id={$p->id} status=".$p->status->value." goal_name=".($p->payload["goal_name"]??"?")."\n"; foreach ($p->payload["schedule"]["weeks"] as $w) { $tot=$w["total_km"]??0; $types=array_count_values(array_column($w["days"], "type")); echo "  week ".$w["week_number"]." total={$tot}km days=".count($w["days"])." types=".json_encode($types)."\n"; }'

# Inspect the race-day entry (last week's days)
php artisan tinker --execute 'use App\Models\CoachProposal; $p = CoachProposal::orderByDesc("id")->first(); $last = end($p->payload["schedule"]["weeks"]); foreach ($last["days"] as $d) { echo "  dow={$d["day_of_week"]} type={$d["type"]} km={$d["target_km"]} title=".json_encode($d["title"]??null)." desc=".substr($d["description"]??"", 0, 80)."\n"; }'

# Replay the optimizer on a payload (without round-tripping through the agent)
php artisan tinker --execute 'use App\Services\PlanOptimizerService; use App\Models\User; $payload = json_decode(file_get_contents("/tmp/plan.json"), true); $result = app(PlanOptimizerService::class)->optimize($payload, User::find(2)); echo json_encode($result["schedule"]["weeks"], JSON_PRETTY_PRINT);'

# Reset the verify-cycle cap counter for a user (useful when iterating on the verifier prompt)
php artisan tinker --execute 'Cache::forget("verify_plan:cycle:user:2");'

# Mark all pending proposals rejected (clean slate before re-onboarding)
php artisan tinker --execute 'use App\Models\CoachProposal; use App\Enums\ProposalStatus; CoachProposal::where("user_id", 2)->where("status", ProposalStatus::Pending)->update(["status" => ProposalStatus::Rejected]);'

# Inspect raw SDK-stored conversation messages (tool_calls + tool_results columns)
php artisan tinker --execute 'DB::table("agent_conversation_messages")->where("conversation_id", "uuid-here")->get(["role","content","tool_calls","tool_results"])->each(fn($m) => print($m->role.": ".substr($m->content ?? "", 0, 120)."\n"));'
```

#### Other useful patterns

- **Capture outgoing Anthropic request bodies** — in a tinker session, `Http::globalRequestMiddleware(fn($req) => tap($req, fn() => Log::info('[anthropic] '.substr((string)$req->getBody(), 0, 20000))));` then tail `storage/logs/laravel.log`. Useful when you want to see the EXACT prompt + cache_control breakpoints sent to Anthropic.
- **Admin token dashboard at `/admin/token-usages`** — fastest way to spot cost regressions, duplicate-logging, or broken cache hits without opening the log file.

### Local dev seed (`db:seed`)

`AuthController::devLogin` (`POST /auth/dev-login`, local-only) returns the OLDEST user — the same one `AdminUserSeeder` creates (`admin@runcoach.local` / `admin`). Two dev seeders ship; **toggle between them by uncommenting the call you want** in `database/seeders/DatabaseSeeder.php`:

- **`DevPlanSeeder`** (default) — drops the dev user into a **post-onboarding, mid-plan state**: 8-week half-marathon plan (week 1 starts the Monday before today), past days already have completed runs + AI feedback + compliance scores, today/upcoming open for testing edit/reschedule, plus off-plan unmatched runs + a `plan_evaluation` inbox notification. **Also grants a year of comp Pro** (`pro_active_until = now+1y`, `pro_product_id = 'dev_comp_pro'`) — without it the onboarded user is hard-gated to `/paywall` on cold start and the seeded schedule is unreachable. For testing the workout agent + schedule UI + compliance scoring.
- **`DevOnboardingSeeder`** — drops the dev user into a **pre-onboarding state**: `has_completed_onboarding=false`, `date_of_birth=2002-06-15` (age 23), age-derived HR zones (Tanaka max 192 → Z2 ≤115, Z3 ≤134, Z4 ≤154, Z5 ≤173+), and ~140 wearable activities seeded across the last 365 days (easy/tempo/long mix, ramps with phase, `mt_srand(202206)` so it's deterministic). The `/onboarding/profile` endpoint computes a real narrative off this data. Activities are tagged with the `dev-onb-seed-` prefix so re-runs scrub cleanly. Does NOT grant Pro — the post-plan paywall is part of what this flow tests.

**To switch:** swap which `$this->call(...)` is commented in `database/seeders/DatabaseSeeder.php` (the two lines after `DemoOrganizationSeeder`). Both seeders are idempotent and local-only (no-op outside `local` env); picking one wipes the other's state on next `db:seed` so you can flip without `migrate:fresh`. (The Pro grant from `DevPlanSeeder` persists on the user row after a flip — re-running `DevOnboardingSeeder` does not revoke it; `migrate:fresh` clears it.)

When invoked, `run-dev.sh` auto-loads the seeded dev user via `Auth.loginDev()` (kicked off from `_checkAuth` when `kDebugMode && !hasToken`). With the current `DevPlanSeeder` default that lands you on the dashboard / schedule with the mid-plan goal. If you flip to `DevOnboardingSeeder`, it lands instead on `/onboarding/zones` (or `/onboarding/connect-health` on native iOS — see app/CLAUDE.md §6 for the web-skip rule).

## Deployment (Laravel Cloud)

Prod at **https://runcoach.laravel.cloud**. Full workaround + commands in `../.laravel-cloud/README.md` and the monorepo-level `../CLAUDE.md` → Deployment. Key points:

- Cloud does not officially support monorepos. `../composer.lock` is a copy of `api/composer.lock` used purely for framework detection; keep them in sync or CI (`.github/workflows/composer-lock-sync.yml`) fails.
- Build command in Cloud: `bash .laravel-cloud/build.sh` — promotes `api/` to the deployment root, then runs `composer install --no-dev` + `npm ci && npm run build`.
- Deploy command: `php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan event:cache`.
- PHP overrides: `public/.user.ini` (web, `memory_limit=512M`, `max_execution_time=150`) and `bootstrap/app.php` line 3 (CLI / queue workers, `ini_set('memory_limit', '512M')`).

## Specs and plans

All feature design specs live in `../docs/superpowers/specs/` and implementation plans in `../docs/superpowers/plans/`. Before implementing non-trivial changes, consult existing specs and plans first.
