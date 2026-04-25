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

- Authenticates users via Strava OAuth2 (Sanctum tokens for the Flutter app)
- Syncs Strava running activities (3 months on login, real-time via webhooks)
- Runs an agentic AI coach (Laravel AI SDK) that has full access to the user's Strava data
- Generates training schedules for races with a proposal/approval flow
- Auto-matches completed activities to planned training days and scores compliance

## Core architecture

### AI Coach (the main agentic feature)

The coach uses **Laravel AI SDK** (`laravel/ai` v0.5.1). Default provider is **Anthropic** (`claude-sonnet-4-6`) via `config/ai.php`. Key files:

- `app/Ai/Agents/RunCoachAgent.php` — main agent. Implements `Agent`, `Conversational`, `HasTools`. Uses `Promptable` + `RemembersConversations` traits. Takes a `User` in constructor. Branches the system prompt on `agent_conversations.context`: `'onboarding'` → `onboardingInstructions()` (scripted flow), otherwise → `coachInstructions()`.
- Other agents (one-shot `prompt()`, no tools):
  - `PlanExplanationAgent` — `HasStructuredOutput`, returns `{name, explanation}` for the plan details modal
  - `ActivityFeedbackAgent` — post-run feedback for completed activities
  - `WeeklyInsightAgent` — weekly coach notes
  - `RunningNarrativeAgent` — narrative paragraph for `UserRunningProfile`
- `app/Ai/Tools/*.php` — 11 tools the coach agent can call:
  - **Onboarding-only UI tools** (return display payloads the stream controller forwards to Flutter as `data-stats` / `data-chips` events):
    - `GetRunningProfile` — (no args) returns cached `UserRunningProfile`, or triggers fresh analysis inline
    - `PresentRunningStats` — renders a stats card in the chat (4 metrics)
    - `OfferChoices` — renders tappable chip row (label/value pairs)
  - **Strava query tools**:
    - `GetRecentRuns` — N most recent runs, no date input
    - `SearchStravaActivities` — Strava API date-range query (NOT local DB), auto-paginates, returns aggregates + runs
    - `GetActivityDetails` — per-km splits, laps, HR for a single activity id
  - **Schedule + compliance**:
    - `GetCurrentSchedule` — active schedule with compliance
    - `GetGoalInfo` — goal details + readiness
    - `GetComplianceReport` — compliance breakdown + trends
    - `CreateSchedule` — proposes a new training plan (requires approval)
    - `ModifySchedule` — proposes schedule changes (requires approval)
- `app/Services/ProposalService.php` — detects proposals from `agent_conversation_messages.tool_results` and applies accepted ones. `applyCreateSchedule()` drops any training day whose date is before today (hard guarantee against past-dated week 1 days).

**How proposals work:** When the agent calls `CreateSchedule` or `ModifySchedule`, the tool returns JSON with `requires_approval: true`. The SDK stores that in `tool_results`. After `$agent->prompt()` returns, `ProposalService::detectProposalFromConversation()` queries that column, finds the proposal, and stores a `CoachProposal` record. The user accepts/rejects via `/coach/proposals/{id}/accept` or `/reject`. Before acceptance they can open a details modal fed by `GET /coach/proposals/{id}/explanation` (cached 7 days per proposal via `Cache::remember`).

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

### Plan generation pipeline (onboarding + edits)

This is the single most important pipeline in the backend. Read this before touching anything in `RunCoachAgent`, `PlanOptimizerService`, `PlanVerifierAgent`, `CreateSchedule`, `EditSchedule`, or `VerifyPlan`.

#### Top-down flow

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
    │       c. Build priming message: form data + 12-month profile metrics
    │       d. RunCoachAgent::make(user)->continue($cid, as: $user)->prompt($priming)
    │   3. Mark row completed with {conversation_id, proposal_id}
    │      (on Throwable: failed() callback marks row failed + error_message)
    │
    ▼
[RunCoachAgent.instructions()]
    branches on agent_conversations.context:
    └─ 'onboarding' AND no proposal yet → onboardingInstructions() [GENERATE mode]
    └─ 'onboarding' AND proposal exists → onboardingInstructions() [REVIEW/EDIT mode]
    └─ otherwise                        → coachInstructions()
    │
    ▼
[Agent autonomous tool loop, driven by the SDK]
    Generate mode:
        CreateSchedule → VerifyPlan → (EditSchedule → VerifyPlan)*  → reply
    Review/Edit mode (follow-up user message):
        GetCurrentProposal? → EditSchedule → VerifyPlan → (EditSchedule → VerifyPlan)* → reply
    │
    ▼
ProposalService::detectProposalFromConversation()
    Reads agent_conversation_messages.tool_results, finds the last
    `requires_approval:true` row, hydrates a CoachProposal row.
    │
    ▼
[Flutter] OnboardingGeneratingScreen polls GET /onboarding/plan-generation/latest
    every 3s. completed → /coach/chat/{conversation_id} (ProposalCard).
    failed → error UI with Try again.
```

The same agent loop runs for follow-up coach chat, just with `coachInstructions()` driving and `CoachController::sendMessage` streaming the SSE — that path stays synchronous (already streams progress, no need to queue).

#### Plan generation lifecycle (async, onboarding only)

`plan_generations` table is the single source of truth for first-time onboarding plan generation. Lifecycle: `queued → processing → completed | failed`.

- **Single in-flight per user**: POST is idempotent — returns the existing row when `User::pendingPlanGeneration()` is non-null and `isInFlight()` is true.
- **Watchdog**: `User::pendingPlanGeneration()` auto-fails any row stuck in queued/processing for >10 minutes (covers worker death where `failed()` never fires). Read-time check inside the accessor — no scheduled command needed.
- **Field on /profile + auth responses**: `pending_plan_generation` is non-null only when the user should be redirected to the loading screen or the proposal chat. Once the proposal is accepted/rejected, the field goes back to null and normal routing resumes.
- **Queue worker timeout**: deploy command must use `--timeout=600` (or higher). 120s was the historical value and would kill plan generation mid-loop.

#### The mandatory verify cycle

Hardcoded in the agent system prompt (every variant of `instructions()` includes it):

> After EVERY `create_schedule` or `edit_schedule`, immediately call `verify_plan`. If `passed:false`, batch every `issues[].suggested_fix` into ONE `edit_schedule` call, then call `verify_plan` again. Stop when `passed:true` or `cycle >= max_cycles`.

- **Cap:** `MAX_CYCLES = 2` in `VerifyPlan.php`.
- **Cap counter key:** `verify_plan:cycle:user:{$userId}` (NOT proposal_id, because `EditSchedule` supersedes the pending proposal on every call — a proposal-keyed counter would reset every iteration and the loop would never terminate).
- **Counter reset:** `CreateSchedule::handle` calls `Cache::forget(VerifyPlan::cycleCacheKey($userId))` before persisting, so a fresh generation always starts at cycle 1.
- **Counter increment:** in `VerifyPlan::handle`, before calling Haiku.
- **Capped short-circuit:** when the counter exceeds `MAX_CYCLES`, `VerifyPlan` returns `{passed:true, capped:true, summary:"Max verification cycles reached..."}` WITHOUT calling Haiku. This forces the agent to terminate the loop.
- **User-facing reply discipline:** the prompt explicitly forbids the agent from saying "max cycles", "verifier", "server-managed", "display label", or any internal mechanic in its reply when the cap fires. If you see those words leak into the chat, the prompt's been edited.

#### The optimizer (deterministic post-processor)

`PlanOptimizerService::optimize($payload, User $user, bool $alignRaceDay = true)` runs at the END of `CreateSchedule::handle` and `EditSchedule::handle`. Everything beyond the agent's raw draft is deterministic — the AI is responsible for *coaching judgment* (volume curve, hard/easy mix, when to insert intervals), the optimizer is responsible for *structural correctness* (preferred days, race-day position, paces, titles, totals).

**`alignRaceDay`:** `true` on create (allows `alignTargetDateToLastDay` for open-ended plans). `false` on edit (the user has already seen and reasoned about `target_date`, don't move it).

**Pipeline order — KEEP this order, the comments in `optimize()` explain why:**

| # | Pass | What it does |
|---|---|---|
| 1 | `enforcePreferredWeekdays` | Drop days whose DOW isn't in `preferred_weekdays[]`. Race-day exempt by date match. |
| 2 | `enforceMinimumRunLength` | Bump per-run km up to `max(4, min(6, avg_run_km × 0.4))`. Prevents 3km runs for an 8.6km/run runner. |
| 3 | `deduplicateDaysPerWeek` | Drop duplicate `day_of_week` within a single week. |
| 4 | **`ensureRaceDayEntry`** | If no day matches `target_date`, salvage a misplaced race-like day (`type=tempo` AND `target_km` within 10% of goal_km) and relocate it; otherwise insert a skeleton on target_date. **Runs BEFORE drop** so the agent's nice description survives when the agent miscounts weeks and puts the race past target_date. See `extractMisplacedRaceDay`. |
| 5 | `dropDaysPastTarget` | Strip everything strictly past `target_date`. |
| 6 | `enforceRaceDay` | Force the race-day entry's `type=tempo`, `km=goal_km`, `pace=goal_pace`, **`title=null`** (so generateTitles can rewrite to goal_name). |
| 7 | `alignTargetDateToLastDay` (create only) | For open-ended plans, snap `target_date` to the last training day's date. |
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

TTL is ~5 minutes. Within onboarding (3-4 turns in 1-2 min) the cache hits hard: turn 2+ pays full input price ONLY on the new user message. Cache hits show up as `cache_read_input_tokens` in the `[ai:usage]` log and the `token_usages` table. If you see `cache_read=0` on turn 2+, something's wrong (middleware not registered, or conversation went idle past TTL).

### Token usage tracking

- `token_usages` table (migration, `App\Models\TokenUsage`) records one row per Anthropic call with user_id, conversation_id, agent_class, context, provider, model, and all five token counters (`prompt`, `completion`, `cache_read_input`, `cache_write_input`, `reasoning`) plus `total_tokens`.
- Written by `App\Listeners\RecordAgentTokenUsage` which handles `AgentPrompted|AgentStreamed` via **Laravel 13 auto-discovery** (listeners in `app/Listeners/` are registered from their `handle()` type hint). DO NOT also `Event::listen` it in AppServiceProvider — that produces duplicate rows.
- Context resolution: RunCoachAgent + conversation context `'onboarding'` → `'onboarding'`, else `'coach'`; named agents → their snake-case labels (`plan_explanation`, `activity_feedback`, `weekly_insight`, `running_narrative`); fallback is `Str::snake(class_basename($agent))`.
- **SDK caveat**: `StreamableAgentResponse::$usage` only reflects the *final* tool-loop iteration's usage (the one that yields `StreamEnd`). Intermediate iterations that returned `stop_reason: tool_use` are not tallied. Reported totals undercount streaming agent runs by roughly 30–50%.
- Browse the data in Filament at `/admin/token-usages` (see monorepo CLAUDE.md for access).

### Strava integration

- `app/Services/StravaSyncService.php` — OAuth token exchange, refresh, activity fetching
- `app/Jobs/SyncStravaHistory.php` — queued job, fetches N months of history on login/manual sync
- `app/Jobs/ProcessStravaActivity.php` — webhook-triggered; fetches one activity, matches to training day, scores compliance, dispatches feedback generation
- `app/Jobs/GenerateActivityFeedback.php` — AI post-run feedback
- `app/Jobs/GenerateWeeklyInsight.php` — AI weekly coach notes
- `app/Services/ComplianceScoringService.php` — weighted scoring: distance 30%, pace 40%, HR 30% (redistributes to 45/55 without HR)

### Domain models

10 Eloquent models with factories, using Laravel 13 `#[Fillable]` attribute syntax (NOT `$fillable` property):
- `User`, `StravaToken`, `StravaActivity`
- `Goal` → `TrainingWeek` → `TrainingDay` → `TrainingResult`
- `CoachProposal` (with `agent_message_id` FK to SDK's messages table, `user_id` FK to users)

All enums are in `app/Enums/` as PHP 8.1 backed enums: `CoachStyle`, `MessageRole`, `ProposalStatus`, `ProposalType`, `GoalDistance`, `GoalStatus`, `TrainingType`.

### API Structure

All routes under `/api/v1/*` prefix in `routes/api.php`. Public routes: Strava OAuth + webhooks. Everything else requires `auth:sanctum`.

Controllers live in `app/Http/Controllers/`: Auth, Profile, Goal, TrainingSchedule, Strava, StravaWebhook, Coach, Dashboard.

## Project-specific conventions

### Tools (Laravel AI SDK)

- Every tool implements `Laravel\Ai\Contracts\Tool` with `description()`, `schema(JsonSchema $schema)`, `handle(Request $request)`.
- `handle()` must return a **string** (use `json_encode()`).
- Access request params with **array access**: `$request['key']` — NOT `$request->get()` or `$request->input()`.
- **Required-on-every-param**: every schema param MUST have `->required()`. For truly optional params, use `->required()->nullable()` — this satisfies OpenAI strict mode and is fine with Anthropic. Do NOT use `->default()`.
- Tools that need user data take `User $user` in constructor, injected from the agent.
- **UI-only tools** (`PresentRunningStats`, `OfferChoices`) return `json_encode(['display' => 'stats_card'|'chip_suggestions', ...])`. `CoachController::sendMessage` inspects `ToolResultEvent` payloads for `display` and forwards matching `data-stats` / `data-chips` SSE events to Flutter.

### Tool design guidelines

When adding or refactoring agent tools, follow these principles. They are derived from reviewing [r-huijts/strava-mcp](https://github.com/r-huijts/strava-mcp) ([tools folder](https://github.com/r-huijts/strava-mcp/tree/main/src/tools)) — a production Strava MCP whose tool shapes we treat as a design benchmark. Read that repo before designing a new tool.

1. **One tool per use case, not one tool per endpoint.** The MCP ships separate `getRecentActivities` (no args, latest N) and `getAllActivities` (date range + filters). We mirror this with `GetRecentRuns` + `SearchStravaActivities`. Don't force the agent to guess args for common cases — give it a narrow tool.

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

### Testing

- 91 feature tests in `tests/Feature/`. Use `LazilyRefreshDatabase` trait (NOT `RefreshDatabase`).
- Coach tests use `RunCoachAgent::fake(['response text'])` to mock agent responses.
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

## Deployment (Laravel Cloud)

Prod at **https://runcoach.free.laravel.cloud**. Full workaround + commands in `../.laravel-cloud/README.md` and the monorepo-level `../CLAUDE.md` → Deployment. Key points:

- Cloud does not officially support monorepos. `../composer.lock` is a copy of `api/composer.lock` used purely for framework detection; keep them in sync or CI (`.github/workflows/composer-lock-sync.yml`) fails.
- Build command in Cloud: `bash .laravel-cloud/build.sh` — promotes `api/` to the deployment root, then runs `composer install --no-dev` + `npm ci && npm run build`.
- Deploy command: `php artisan migrate --force && php artisan config:cache && php artisan route:cache && php artisan event:cache`.
- PHP overrides: `public/.user.ini` (web, `memory_limit=512M`, `max_execution_time=150`) and `bootstrap/app.php` line 3 (CLI / queue workers, `ini_set('memory_limit', '512M')`).

## Specs and plans

All feature design specs live in `../docs/superpowers/specs/` and implementation plans in `../docs/superpowers/plans/`. Before implementing non-trivial changes, consult existing specs and plans first.
