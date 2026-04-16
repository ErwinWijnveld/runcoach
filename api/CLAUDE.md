<laravel-boost-guidelines>
=== foundation rules ===

# Laravel Boost Guidelines

The Laravel Boost guidelines are specifically curated by Laravel maintainers for this application. These guidelines should be followed closely to ensure the best experience when building Laravel applications.

## Foundational Context

This application is a Laravel application and its main Laravel ecosystems package & versions are below. You are an expert with them all. Ensure you abide by these specific packages & versions.

- php - 8.5
- laravel/ai (AI) - v0
- laravel/framework (LARAVEL) - v13
- laravel/prompts (PROMPTS) - v0
- laravel/sanctum (SANCTUM) - v4
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

The coach uses **Laravel AI SDK** (`laravel/ai`) — NOT a custom OpenAI wrapper. Key files:

- `app/Ai/Agents/RunCoachAgent.php` — the Agent class. Implements `Agent`, `Conversational`, `HasTools`. Uses `Promptable` + `RemembersConversations` traits. Takes a `User` in constructor.
- `app/Ai/Tools/*.php` — 8 tools the agent can call:
  - `GetRecentRuns` — fetches the N most recent runs (no date input). Use for "last run", "recent runs"
  - `SearchStravaActivities` — queries Strava API for a date range (NOT local DB), auto-paginates, returns aggregates + individual runs
  - `GetActivityDetails` — per-km splits, laps, HR summary for a single activity (requires `activity_id` from one of the listing tools)
  - `GetCurrentSchedule` — active training schedule with compliance
  - `GetRaceInfo` — race details + readiness
  - `GetComplianceReport` — compliance breakdown + trends
  - `CreateSchedule` — proposes new training plan (requires approval)
  - `ModifySchedule` — proposes schedule changes (requires approval)
- `app/Services/ProposalService.php` — detects proposals from `agent_conversation_messages.tool_results` and applies accepted ones

**How proposals work:** When the agent calls `CreateSchedule` or `ModifySchedule`, the tool returns JSON with `requires_approval: true`. The SDK stores that in `tool_results`. After `$agent->prompt()` returns, `ProposalService::detectProposalFromConversation()` queries that column, finds the proposal, and stores a `CoachProposal` record. The user accepts/rejects via `/coach/proposals/{id}/accept` or `/reject`.

**The SDK manages conversations automatically** via `agent_conversations` and `agent_conversation_messages` tables (created by SDK migrations). Do NOT use `CoachConversation` or `CoachMessage` models — they no longer exist. Conversation IDs are UUIDs (36-char strings), not integers.

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
- `Race` → `TrainingWeek` → `TrainingDay` → `TrainingResult`
- `CoachProposal` (with `agent_message_id` FK to SDK's messages table, `user_id` FK to users)

All enums are in `app/Enums/` as PHP 8.1 backed enums: `CoachStyle`, `MessageRole`, `ProposalStatus`, `ProposalType`, `RaceDistance`, `RaceStatus`, `RunnerLevel`, `TrainingType`.

### API Structure

All routes under `/api/v1/*` prefix in `routes/api.php`. Public routes: Strava OAuth + webhooks. Everything else requires `auth:sanctum`.

Controllers live in `app/Http/Controllers/`: Auth, Profile, Race, TrainingSchedule, Strava, StravaWebhook, Coach, Dashboard.

## Project-specific conventions

### Tools (Laravel AI SDK)

- Every tool implements `Laravel\Ai\Contracts\Tool` with `description()`, `schema(JsonSchema $schema)`, `handle(Request $request)`.
- `handle()` must return a **string** (use `json_encode()`).
- Access request params with **array access**: `$request['key']` — NOT `$request->get()` or `$request->input()`.
- **OpenAI strict mode**: every schema param MUST have `->required()`. For truly optional params, use `->required()->nullable()` — this satisfies strict mode while allowing null values. Do NOT use `->default()`.
- Tools that need user data take `User $user` in constructor, injected from the agent.

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

- 45 feature tests in `tests/Feature/`. Use `LazilyRefreshDatabase` trait (NOT `RefreshDatabase`).
- Coach tests use `RunCoachAgent::fake(['response text'])` to mock agent responses.
- Run: `php artisan test --compact`

### Pint formatting

Always run `vendor/bin/pint --dirty --format agent` after modifying PHP files.

## Specs and plans

All feature design specs live in `../docs/superpowers/specs/` and implementation plans in `../docs/superpowers/plans/`. Before implementing non-trivial changes, consult existing specs and plans first.
