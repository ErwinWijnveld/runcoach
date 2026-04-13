# Coach Agent Refactor — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the custom OpenAI chat-completion wrapper with a proper Laravel AI SDK Agent that uses `RemembersConversations` for persistence and granular tools that let the AI autonomously decide what data to fetch.

**Architecture:** Single `RunCoachAgent` class implementing `Agent`, `Conversational`, `HasTools` via `Promptable` + `RemembersConversations`. 8 focused Tool classes implementing the `Laravel\Ai\Contracts\Tool` interface. The SDK handles the agent loop, tool calling, and conversation persistence automatically. Proposal system (create/modify schedule) stays — mutation tools return proposal payloads that the controller detects and stores.

**Tech Stack:** Laravel AI SDK (`laravel/ai`), OpenAI provider (swappable)

**Spec:** `docs/superpowers/specs/2026-04-13-coach-agent-refactor.md`

---

## File Structure

```
api/
├── app/
│   ├── Ai/
│   │   ├── Agents/
│   │   │   └── RunCoachAgent.php          — Main agent class
│   │   └── Tools/
│   │       ├── GetRecentActivities.php    — List recent runs with full details
│   │       ├── GetActivityDetail.php      — Single activity lookup by date/name
│   │       ├── GetTrainingSummary.php      — Aggregated stats over a period
│   │       ├── GetCurrentSchedule.php      — Active schedule with compliance
│   │       ├── GetRaceInfo.php            — Race details + readiness
│   │       ├── GetComplianceReport.php    — Compliance breakdown + trends
│   │       ├── CreateSchedule.php         — Propose new schedule (needs approval)
│   │       └── ModifySchedule.php         — Propose schedule changes (needs approval)
│   ├── Http/
│   │   └── Controllers/
│   │       └── CoachController.php        — MODIFIED: use RunCoachAgent
│   ├── Models/
│   │   └── CoachProposal.php             — MODIFIED: FK to agent_conversation_messages
│   └── Services/
│       └── ProposalService.php           — Extracted: apply proposal logic
├── database/
│   └── migrations/
│       └── 2026_04_13_200000_refactor_coach_to_agent_sdk.php
├── routes/
│   └── api.php                           — No changes
└── tests/
    └── Feature/
        └── CoachChatTest.php             — MODIFIED: use RunCoachAgent::fake()
```

**Delete after migration:**
- `app/Services/CoachChatService.php`
- `app/Services/CoachTools/` (entire directory)
- `app/Models/CoachConversation.php`
- `app/Models/CoachMessage.php`
- `database/factories/CoachConversationFactory.php`
- `database/factories/CoachMessageFactory.php`

---

### Task 1: Database Migration

**Files:**
- Create: `api/database/migrations/2026_04_13_200000_refactor_coach_to_agent_sdk.php`

- [ ] **Step 1: Generate migration**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:migration refactor_coach_to_agent_sdk --no-interaction
```

- [ ] **Step 2: Fill migration**

Edit the generated migration file. Set the `up()` method:

```php
public function up(): void
{
    Schema::table('coach_proposals', function (Blueprint $table) {
        $table->dropForeign(['coach_message_id']);
        $table->dropColumn('coach_message_id');
        $table->string('agent_message_id', 36)->nullable()->after('id');
        $table->foreignId('user_id')->nullable()->after('agent_message_id')->constrained()->cascadeOnDelete();
    });

    Schema::dropIfExists('coach_proposals_backup');
    Schema::dropIfExists('coach_messages');
    Schema::dropIfExists('coach_conversations');
}

public function down(): void
{
    Schema::create('coach_conversations', function (Blueprint $table) {
        $table->id();
        $table->foreignId('user_id')->constrained()->cascadeOnDelete();
        $table->foreignId('race_id')->nullable()->constrained()->nullOnDelete();
        $table->string('title');
        $table->timestamps();
    });

    Schema::create('coach_messages', function (Blueprint $table) {
        $table->id();
        $table->foreignId('coach_conversation_id')->constrained()->cascadeOnDelete();
        $table->string('role');
        $table->text('content');
        $table->json('context_snapshot')->nullable();
        $table->timestamps();
    });

    Schema::table('coach_proposals', function (Blueprint $table) {
        $table->dropColumn(['agent_message_id', 'user_id']);
        $table->foreignId('coach_message_id')->nullable()->constrained()->cascadeOnDelete();
    });
}
```

- [ ] **Step 3: Run migration**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan migrate --no-interaction
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/database/migrations/
git commit -m "feat: add migration for coach agent SDK refactor"
```

---

### Task 2: Read-Only Tools (GetRecentActivities, GetActivityDetail, GetTrainingSummary)

**Files:**
- Create: `api/app/Ai/Tools/GetRecentActivities.php`
- Create: `api/app/Ai/Tools/GetActivityDetail.php`
- Create: `api/app/Ai/Tools/GetTrainingSummary.php`

- [ ] **Step 1: Create directory**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
mkdir -p app/Ai/Tools app/Ai/Agents
```

- [ ] **Step 2: Create GetRecentActivities tool**

Create `api/app/Ai/Tools/GetRecentActivities.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRecentActivities implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get the user\'s recent running activities with full details including date, name, distance, pace, duration, and heart rate. Returns individual runs, not aggregates.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'limit' => $schema->integer()->description('Number of recent activities to return (1-20)')->default(10),
        ];
    }

    public function handle(Request $request): string
    {
        $limit = min(20, max(1, $request->get('limit', 10)));

        $activities = $this->user->stravaActivities()
            ->where('type', 'Run')
            ->orderByDesc('start_date')
            ->limit($limit)
            ->get();

        if ($activities->isEmpty()) {
            return json_encode(['message' => 'No running activities found.']);
        }

        $runs = $activities->map(fn ($a) => [
            'date' => $a->start_date->format('Y-m-d'),
            'day' => $a->start_date->format('l'),
            'name' => $a->name,
            'distance_km' => $a->distanceInKm(),
            'pace_per_km' => floor($a->paceSecondsPerKm() / 60) . ':' . str_pad($a->paceSecondsPerKm() % 60, 2, '0', STR_PAD_LEFT),
            'pace_seconds_per_km' => $a->paceSecondsPerKm(),
            'duration_minutes' => round($a->moving_time_seconds / 60, 1),
            'avg_heart_rate' => $a->average_heartrate ? round($a->average_heartrate, 0) : null,
        ])->values()->toArray();

        return json_encode(['activities' => $runs, 'total_found' => $activities->count()]);
    }
}
```

- [ ] **Step 3: Create GetActivityDetail tool**

Create `api/app/Ai/Tools/GetActivityDetail.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetActivityDetail implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Look up a specific running activity by date or name. Returns full details including distance, pace, heart rate, elapsed time, and any matching training result with compliance scores.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'date' => $schema->string()->description('Activity date in YYYY-MM-DD format'),
            'name' => $schema->string()->description('Activity name to search for (partial match)'),
        ];
    }

    public function handle(Request $request): string
    {
        $query = $this->user->stravaActivities()->where('type', 'Run');

        if ($request->get('date')) {
            $query->whereDate('start_date', $request->get('date'));
        }

        if ($request->get('name')) {
            $query->where('name', 'like', '%' . $request->get('name') . '%');
        }

        $activity = $query->orderByDesc('start_date')->first();

        if (! $activity) {
            return json_encode(['message' => 'No activity found matching the criteria.']);
        }

        $result = $activity->trainingResults()->with('trainingDay')->first();

        $data = [
            'date' => $activity->start_date->format('Y-m-d H:i'),
            'day' => $activity->start_date->format('l'),
            'name' => $activity->name,
            'distance_km' => $activity->distanceInKm(),
            'pace_per_km' => floor($activity->paceSecondsPerKm() / 60) . ':' . str_pad($activity->paceSecondsPerKm() % 60, 2, '0', STR_PAD_LEFT),
            'duration_minutes' => round($activity->moving_time_seconds / 60, 1),
            'elapsed_minutes' => round($activity->elapsed_time_seconds / 60, 1),
            'avg_heart_rate' => $activity->average_heartrate ? round($activity->average_heartrate, 0) : null,
            'avg_speed_kmh' => round($activity->average_speed * 3.6, 1),
        ];

        if ($result) {
            $data['training_match'] = [
                'planned_title' => $result->trainingDay->title,
                'planned_type' => $result->trainingDay->type->value,
                'planned_km' => $result->trainingDay->target_km,
                'compliance_score' => $result->compliance_score,
                'pace_score' => $result->pace_score,
                'distance_score' => $result->distance_score,
                'heart_rate_score' => $result->heart_rate_score,
                'ai_feedback' => $result->ai_feedback,
            ];
        }

        return json_encode($data);
    }
}
```

- [ ] **Step 4: Create GetTrainingSummary tool**

Create `api/app/Ai/Tools/GetTrainingSummary.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetTrainingSummary implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get aggregated running statistics over a time period: total runs, total km, average pace, average heart rate, longest run, weekly averages, and trends.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'weeks' => $schema->integer()->description('Number of weeks to look back (1-13)')->default(12),
        ];
    }

    public function handle(Request $request): string
    {
        $weeks = min(13, max(1, $request->get('weeks', 12)));
        $since = now()->subWeeks($weeks);

        $activities = $this->user->stravaActivities()
            ->where('start_date', '>=', $since)
            ->where('type', 'Run')
            ->orderByDesc('start_date')
            ->get();

        if ($activities->isEmpty()) {
            return json_encode(['message' => 'No running activities found in the last ' . $weeks . ' weeks.']);
        }

        $totalKm = $activities->sum(fn ($a) => $a->distanceInKm());
        $totalRuns = $activities->count();
        $avgPace = (int) $activities->avg(fn ($a) => $a->paceSecondsPerKm());
        $longestRun = $activities->max(fn ($a) => $a->distanceInKm());
        $avgHeartRate = $activities->whereNotNull('average_heartrate')->avg('average_heartrate');

        return json_encode([
            'period_weeks' => $weeks,
            'total_runs' => $totalRuns,
            'total_km' => round($totalKm, 1),
            'avg_km_per_week' => round($totalKm / $weeks, 1),
            'avg_pace_per_km' => floor($avgPace / 60) . ':' . str_pad($avgPace % 60, 2, '0', STR_PAD_LEFT),
            'longest_run_km' => $longestRun,
            'avg_heart_rate' => $avgHeartRate ? round($avgHeartRate, 0) : null,
            'runs_per_week' => round($totalRuns / $weeks, 1),
        ]);
    }
}
```

- [ ] **Step 5: Run Pint and verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan tinker --execute 'echo "OK";'
```

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Ai/Tools/GetRecentActivities.php api/app/Ai/Tools/GetActivityDetail.php api/app/Ai/Tools/GetTrainingSummary.php
git commit -m "feat: add granular Strava data tools for AI agent"
```

---

### Task 3: Schedule & Race Tools (GetCurrentSchedule, GetRaceInfo, GetComplianceReport)

**Files:**
- Create: `api/app/Ai/Tools/GetCurrentSchedule.php`
- Create: `api/app/Ai/Tools/GetRaceInfo.php`
- Create: `api/app/Ai/Tools/GetComplianceReport.php`

- [ ] **Step 1: Create GetCurrentSchedule tool**

Create `api/app/Ai/Tools/GetCurrentSchedule.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetCurrentSchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get the user\'s active training schedule with all weeks, days, target paces/distances, and compliance results for completed sessions.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_id' => $schema->integer()->description('Specific race ID. Omit to get the active race.'),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $request->get('race_id')
            ? $this->user->races()->find($request->get('race_id'))
            : $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found.']);
        }

        $weeks = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        $data = [
            'race' => [
                'name' => $race->name,
                'distance' => $race->distance->value,
                'race_date' => $race->race_date->toDateString(),
                'weeks_until_race' => $race->weeksUntilRace(),
            ],
            'weeks' => $weeks->map(fn ($week) => [
                'week_number' => $week->week_number,
                'starts_at' => $week->starts_at->toDateString(),
                'total_km' => $week->total_km,
                'focus' => $week->focus,
                'days' => $week->trainingDays->map(fn ($day) => [
                    'id' => $day->id,
                    'date' => $day->date->toDateString(),
                    'type' => $day->type->value,
                    'title' => $day->title,
                    'target_km' => $day->target_km,
                    'target_pace_seconds_per_km' => $day->target_pace_seconds_per_km,
                    'completed' => $day->result !== null,
                    'compliance_score' => $day->result?->compliance_score,
                ])->toArray(),
            ])->toArray(),
        ];

        return json_encode($data);
    }
}
```

- [ ] **Step 2: Create GetRaceInfo tool**

Create `api/app/Ai/Tools/GetRaceInfo.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetRaceInfo implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get details about the user\'s active or specific race: name, distance, date, goal time, weeks remaining, completion rate, and readiness assessment.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_id' => $schema->integer()->description('Specific race ID. Omit for active race.'),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $request->get('race_id')
            ? $this->user->races()->find($request->get('race_id'))
            : $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found. The runner has not set up a race goal yet.']);
        }

        $totalDays = $race->trainingWeeks()->withCount('trainingDays')->get()->sum('training_days_count');
        $completedResults = TrainingResult::whereHas('trainingDay.trainingWeek', fn ($q) => $q->where('race_id', $race->id))->get();
        $completionRate = $totalDays > 0 ? round($completedResults->count() / $totalDays * 100, 1) : 0;

        return json_encode([
            'name' => $race->name,
            'distance' => $race->distance->value,
            'goal_time_seconds' => $race->goal_time_seconds,
            'race_date' => $race->race_date->toDateString(),
            'weeks_until_race' => $race->weeksUntilRace(),
            'status' => $race->status->value,
            'completion_rate_percent' => $completionRate,
            'sessions_completed' => $completedResults->count(),
            'sessions_planned' => $totalDays,
            'avg_compliance' => $completedResults->count() > 0 ? round($completedResults->avg('compliance_score'), 1) : null,
        ]);
    }
}
```

- [ ] **Step 3: Create GetComplianceReport tool**

Create `api/app/Ai/Tools/GetComplianceReport.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetComplianceReport implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Get a detailed compliance report showing how well the runner has been following their training plan: per-session scores, averages, trends over time.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'period' => $schema->string()->enum(['week', 'month', 'all'])->description('Time period for the report')->required(),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return json_encode(['message' => 'No active race found.']);
        }

        $query = TrainingResult::whereHas('trainingDay.trainingWeek', fn ($q) => $q->where('race_id', $race->id))
            ->with('trainingDay');

        $period = $request->get('period', 'all');
        if ($period === 'week') {
            $query->where('matched_at', '>=', now()->startOfWeek());
        } elseif ($period === 'month') {
            $query->where('matched_at', '>=', now()->subMonth());
        }

        $results = $query->orderByDesc('matched_at')->get();

        if ($results->isEmpty()) {
            return json_encode(['message' => 'No completed training sessions found for this period.']);
        }

        $sessions = $results->map(fn ($r) => [
            'date' => $r->trainingDay->date->toDateString(),
            'title' => $r->trainingDay->title,
            'type' => $r->trainingDay->type->value,
            'compliance_score' => $r->compliance_score,
            'pace_score' => $r->pace_score,
            'distance_score' => $r->distance_score,
            'actual_km' => $r->actual_km,
        ])->toArray();

        return json_encode([
            'period' => $period,
            'total_sessions' => $results->count(),
            'avg_compliance_score' => round($results->avg('compliance_score'), 1),
            'avg_pace_score' => round($results->avg('pace_score'), 1),
            'avg_distance_score' => round($results->avg('distance_score'), 1),
            'best_score' => $results->max('compliance_score'),
            'lowest_score' => $results->min('compliance_score'),
            'sessions' => $sessions,
        ]);
    }
}
```

- [ ] **Step 4: Run Pint and verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan tinker --execute 'echo "OK";'
```

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Ai/Tools/GetCurrentSchedule.php api/app/Ai/Tools/GetRaceInfo.php api/app/Ai/Tools/GetComplianceReport.php
git commit -m "feat: add schedule, race, and compliance tools for AI agent"
```

---

### Task 4: Mutation Tools (CreateSchedule, ModifySchedule)

**Files:**
- Create: `api/app/Ai/Tools/CreateSchedule.php`
- Create: `api/app/Ai/Tools/ModifySchedule.php`

These tools return proposal payloads (JSON with `requires_approval: true`). They do NOT persist anything — the controller handles that.

- [ ] **Step 1: Create CreateSchedule tool**

Create `api/app/Ai/Tools/CreateSchedule.php`:

```php
<?php

namespace App\Ai\Tools;

use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class CreateSchedule implements Tool
{
    public function description(): string
    {
        return 'Create a new training schedule for a race. Returns a proposal that the runner must approve before it takes effect. Generate a complete week-by-week plan with specific sessions for each day, using periodization, 80/20 rule, and progressive overload.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'race_name' => $schema->string()->required()->description('Name of the race'),
            'distance' => $schema->string()->enum(['5k', '10k', 'half_marathon', 'marathon', 'custom'])->required(),
            'goal_time_seconds' => $schema->integer()->description('Target finish time in seconds'),
            'race_date' => $schema->string()->required()->description('Race date in YYYY-MM-DD format'),
            'schedule' => $schema->string()->required()->description('Complete schedule as JSON string: {"weeks": [{"week_number": 1, "focus": "base building", "total_km": 30, "days": [{"day_of_week": 1, "type": "easy|tempo|interval|long_run|recovery|rest|mobility", "title": "...", "description": "...", "target_km": 5, "target_pace_seconds_per_km": 330, "target_heart_rate_zone": 2}]}]}'),
        ];
    }

    public function handle(Request $request): string
    {
        return json_encode([
            'requires_approval' => true,
            'proposal_type' => 'create_schedule',
            'payload' => [
                'race_name' => $request->get('race_name'),
                'distance' => $request->get('distance'),
                'goal_time_seconds' => $request->get('goal_time_seconds'),
                'race_date' => $request->get('race_date'),
                'schedule' => json_decode($request->get('schedule'), true) ?? [],
            ],
        ]);
    }
}
```

- [ ] **Step 2: Create ModifySchedule tool**

Create `api/app/Ai/Tools/ModifySchedule.php`:

```php
<?php

namespace App\Ai\Tools;

use App\Enums\RaceStatus;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class ModifySchedule implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return 'Modify specific days in an existing training schedule. Returns a proposal that the runner must approve. Can change workout type, distance, pace, or swap days.';
    }

    public function schema(JsonSchema $schema): array
    {
        return [
            'changes' => $schema->string()->required()->description('JSON array of changes: [{"training_day_id": 1, "type": "easy", "title": "Easy Run", "description": "...", "target_km": 5, "target_pace_seconds_per_km": 330, "target_heart_rate_zone": 2}]'),
        ];
    }

    public function handle(Request $request): string
    {
        $race = $this->user->races()->where('status', RaceStatus::Active)->latest()->first();

        return json_encode([
            'requires_approval' => true,
            'proposal_type' => 'modify_schedule',
            'payload' => [
                'race_id' => $race?->id,
                'changes' => json_decode($request->get('changes'), true) ?? [],
            ],
        ]);
    }
}
```

- [ ] **Step 3: Run Pint and verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan tinker --execute 'echo "OK";'
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Ai/Tools/CreateSchedule.php api/app/Ai/Tools/ModifySchedule.php
git commit -m "feat: add schedule mutation tools with proposal flow"
```

---

### Task 5: RunCoachAgent + ProposalService

**Files:**
- Create: `api/app/Ai/Agents/RunCoachAgent.php`
- Create: `api/app/Services/ProposalService.php`

- [ ] **Step 1: Create RunCoachAgent**

Create `api/app/Ai/Agents/RunCoachAgent.php`:

```php
<?php

namespace App\Ai\Agents;

use App\Ai\Tools\CreateSchedule;
use App\Ai\Tools\GetActivityDetail;
use App\Ai\Tools\GetComplianceReport;
use App\Ai\Tools\GetCurrentSchedule;
use App\Ai\Tools\GetRaceInfo;
use App\Ai\Tools\GetRecentActivities;
use App\Ai\Tools\GetTrainingSummary;
use App\Ai\Tools\ModifySchedule;
use App\Models\User;
use Laravel\Ai\Concerns\RemembersConversations;
use Laravel\Ai\Contracts\Agent;
use Laravel\Ai\Contracts\Conversational;
use Laravel\Ai\Contracts\HasTools;
use Laravel\Ai\Promptable;

class RunCoachAgent implements Agent, Conversational, HasTools
{
    use Promptable, RemembersConversations;

    public function __construct(private User $user) {}

    public function instructions(): string
    {
        $style = $this->user->coach_style?->value ?? 'balanced';
        $level = $this->user->level?->value ?? 'unknown';
        $capacity = $this->user->weekly_km_capacity ?? 'unknown';

        return <<<PROMPT
        You are RunCoach, a personal AI running coach. Your coaching style is: {$style}.

        You have access to the runner's complete Strava activity history and their training schedule. Use your tools to look up whatever data you need — you can see individual runs, pace, distance, heart rate, and training compliance.

        Coaching principles:
        - Always reference the runner's actual data. Never invent numbers.
        - Use periodization, the 80/20 rule (80% easy / 20% hard), and progressive overload.
        - Be specific: mention actual dates, distances, and paces from their data.
        - When creating or modifying schedules, always use the appropriate tool. The runner must approve changes before they take effect.
        - Keep responses concise and actionable.

        The runner's profile:
        - Level: {$level}
        - Weekly capacity: {$capacity} km
        - Coach style preference: {$style}
        PROMPT;
    }

    public function tools(): iterable
    {
        return [
            new GetRecentActivities($this->user),
            new GetActivityDetail($this->user),
            new GetTrainingSummary($this->user),
            new GetCurrentSchedule($this->user),
            new GetRaceInfo($this->user),
            new GetComplianceReport($this->user),
            new CreateSchedule,
            new ModifySchedule($this->user),
        ];
    }
}
```

- [ ] **Step 2: Create ProposalService**

Extract the proposal apply logic from `CoachChatService` into its own service.

Create `api/app/Services/ProposalService.php`:

```php
<?php

namespace App\Services;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\RaceStatus;
use App\Models\CoachProposal;
use App\Models\TrainingDay;
use App\Models\User;
use Carbon\Carbon;

class ProposalService
{
    public function createFromAgentResponse(User $user, string $agentResponseText, ?string $agentMessageId = null): ?CoachProposal
    {
        // Check if the response text contains a proposal JSON block
        if (! str_contains($agentResponseText, '"requires_approval"')) {
            return null;
        }

        // Extract JSON from the response — the tool result may be embedded
        preg_match('/\{[^{}]*"requires_approval"\s*:\s*true[^{}]*"payload"\s*:\s*\{.*?\}\s*\}/s', $agentResponseText, $matches);

        if (empty($matches)) {
            return null;
        }

        $proposalData = json_decode($matches[0], true);

        if (! $proposalData || ! isset($proposalData['proposal_type'])) {
            return null;
        }

        return CoachProposal::create([
            'agent_message_id' => $agentMessageId,
            'user_id' => $user->id,
            'type' => ProposalType::from($proposalData['proposal_type']),
            'payload' => $proposalData['payload'],
            'status' => ProposalStatus::Pending,
        ]);
    }

    public function apply(CoachProposal $proposal, User $user): void
    {
        match ($proposal->type) {
            ProposalType::CreateSchedule => $this->applyCreateSchedule($user, $proposal->payload),
            ProposalType::ModifySchedule => $this->applyModifySchedule($user, $proposal->payload),
            ProposalType::AlternativeWeek => $this->applyAlternativeWeek($user, $proposal->payload),
        };

        $proposal->update([
            'status' => ProposalStatus::Accepted,
            'applied_at' => now(),
        ]);
    }

    private function applyCreateSchedule(User $user, array $payload): void
    {
        $race = $user->races()->create([
            'name' => $payload['race_name'],
            'distance' => $payload['distance'],
            'goal_time_seconds' => $payload['goal_time_seconds'] ?? null,
            'race_date' => $payload['race_date'],
            'status' => RaceStatus::Active,
        ]);

        $weeks = $payload['schedule']['weeks'] ?? [];

        foreach ($weeks as $weekData) {
            $startsAt = Carbon::parse($payload['race_date'])
                ->subWeeks(count($weeks) - $weekData['week_number'] + 1)
                ->startOfWeek();

            $week = $race->trainingWeeks()->create([
                'week_number' => $weekData['week_number'],
                'starts_at' => $startsAt,
                'total_km' => $weekData['total_km'],
                'focus' => $weekData['focus'],
            ]);

            foreach ($weekData['days'] ?? [] as $dayData) {
                $week->trainingDays()->create([
                    'date' => $startsAt->copy()->addDays($dayData['day_of_week'] - 1),
                    'type' => $dayData['type'],
                    'title' => $dayData['title'],
                    'description' => $dayData['description'] ?? null,
                    'target_km' => $dayData['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $dayData['target_heart_rate_zone'] ?? null,
                    'order' => $dayData['day_of_week'],
                ]);
            }
        }
    }

    private function applyModifySchedule(User $user, array $payload): void
    {
        foreach ($payload['changes'] ?? [] as $change) {
            $day = TrainingDay::whereHas('trainingWeek.race', fn ($q) => $q->where('user_id', $user->id))
                ->find($change['training_day_id']);

            if ($day) {
                $day->update(array_filter([
                    'type' => $change['type'] ?? null,
                    'title' => $change['title'] ?? null,
                    'description' => $change['description'] ?? null,
                    'target_km' => $change['target_km'] ?? null,
                    'target_pace_seconds_per_km' => $change['target_pace_seconds_per_km'] ?? null,
                    'target_heart_rate_zone' => $change['target_heart_rate_zone'] ?? null,
                ], fn ($v) => $v !== null));
            }
        }
    }

    private function applyAlternativeWeek(User $user, array $payload): void
    {
        $race = $user->races()->findOrFail($payload['race_id']);
        $week = $race->trainingWeeks()->where('week_number', $payload['week_number'])->firstOrFail();

        $week->trainingDays()->whereDoesntHave('result')->delete();

        foreach ($payload['alternative_days'] ?? [] as $dayData) {
            $week->trainingDays()->create([
                'date' => $week->starts_at->copy()->addDays($dayData['day_of_week'] - 1),
                'type' => $dayData['type'],
                'title' => $dayData['title'],
                'description' => $dayData['description'] ?? null,
                'target_km' => $dayData['target_km'] ?? null,
                'target_pace_seconds_per_km' => $dayData['target_pace_seconds_per_km'] ?? null,
                'target_heart_rate_zone' => $dayData['target_heart_rate_zone'] ?? null,
                'order' => $dayData['day_of_week'],
            ]);
        }
    }
}
```

- [ ] **Step 3: Run Pint and verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan tinker --execute 'echo "OK";'
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Ai/ api/app/Services/ProposalService.php
git commit -m "feat: add RunCoachAgent with RemembersConversations and ProposalService"
```

---

### Task 6: Update CoachController + CoachProposal Model

**Files:**
- Modify: `api/app/Http/Controllers/CoachController.php`
- Modify: `api/app/Models/CoachProposal.php`
- Modify: `api/app/Models/User.php` (remove coachConversations relationship)

- [ ] **Step 1: Update CoachProposal model**

Replace `api/app/Models/CoachProposal.php`:

```php
<?php

namespace App\Models;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use Database\Factories\CoachProposalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['agent_message_id', 'user_id', 'type', 'payload', 'status', 'applied_at'])]
class CoachProposal extends Model
{
    /** @use HasFactory<CoachProposalFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'type' => ProposalType::class,
            'payload' => 'array',
            'status' => ProposalStatus::class,
            'applied_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

- [ ] **Step 2: Update User model — remove coachConversations relationship**

Read `api/app/Models/User.php` and remove the `coachConversations()` method (the SDK manages conversations via `agent_conversations` table).

- [ ] **Step 3: Rewrite CoachController**

Replace `api/app/Http/Controllers/CoachController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Http\Requests\SendMessageRequest;
use App\Models\CoachProposal;
use App\Services\ProposalService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class CoachController extends Controller
{
    public function __construct(
        private ProposalService $proposalService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $conversations = DB::table('agent_conversations')
            ->where('user_id', $request->user()->id)
            ->orderByDesc('updated_at')
            ->get(['id', 'title', 'created_at', 'updated_at']);

        return response()->json(['data' => $conversations]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['title' => 'sometimes|string|max:255']);

        $agent = RunCoachAgent::make(user: $request->user());
        $response = $agent
            ->forUser($request->user())
            ->prompt($request->input('title', 'Hello! I\'m ready to start coaching.'));

        return response()->json([
            'data' => [
                'id' => $response->conversationId,
                'title' => $request->input('title', 'New Chat'),
                'message' => (string) $response,
            ],
        ], 201);
    }

    public function show(Request $request, string $conversationId): JsonResponse
    {
        $conversation = DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $request->user()->id)
            ->firstOrFail();

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->whereIn('role', ['user', 'assistant'])
            ->orderBy('created_at')
            ->get(['id', 'role', 'content', 'created_at']);

        $proposals = CoachProposal::where('user_id', $request->user()->id)
            ->whereIn('agent_message_id', $messages->pluck('id'))
            ->get()
            ->keyBy('agent_message_id');

        $messagesWithProposals = $messages->map(function ($msg) use ($proposals) {
            $msg->proposal = $proposals->get($msg->id);

            return $msg;
        });

        return response()->json([
            'data' => [
                'id' => $conversation->id,
                'title' => $conversation->title,
                'messages' => $messagesWithProposals,
            ],
        ]);
    }

    public function sendMessage(SendMessageRequest $request, string $conversationId): JsonResponse
    {
        $user = $request->user();

        // Verify conversation belongs to user
        DB::table('agent_conversations')
            ->where('id', $conversationId)
            ->where('user_id', $user->id)
            ->firstOrFail();

        $agent = RunCoachAgent::make(user: $user);
        $response = $agent
            ->continue($conversationId, as: $user)
            ->prompt($request->validated()['content']);

        // Check for proposals in tool results
        $proposal = $this->proposalService->createFromAgentResponse(
            $user,
            (string) $response,
            $response->invocationId,
        );

        return response()->json([
            'data' => [
                'message' => [
                    'role' => 'assistant',
                    'content' => (string) $response,
                ],
                'proposal' => $proposal,
            ],
        ]);
    }

    public function acceptProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::where('user_id', $request->user()->id)
            ->where('status', ProposalStatus::Pending)
            ->findOrFail($proposalId);

        $this->proposalService->apply($proposal, $request->user());

        return response()->json(['message' => 'Proposal accepted and applied']);
    }

    public function rejectProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::where('user_id', $request->user()->id)
            ->where('status', ProposalStatus::Pending)
            ->findOrFail($proposalId);

        $proposal->update(['status' => ProposalStatus::Rejected]);

        return response()->json(['message' => 'Proposal rejected']);
    }
}
```

- [ ] **Step 4: Run Pint and verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan tinker --execute 'echo "OK";'
```

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/CoachController.php api/app/Models/CoachProposal.php api/app/Models/User.php
git commit -m "feat: rewrite CoachController to use RunCoachAgent SDK"
```

---

### Task 7: Cleanup Old Code

**Files:**
- Delete: `api/app/Services/CoachChatService.php`
- Delete: `api/app/Services/CoachTools/` (entire directory)
- Delete: `api/app/Models/CoachConversation.php`
- Delete: `api/app/Models/CoachMessage.php`
- Delete: `api/database/factories/CoachConversationFactory.php`
- Delete: `api/database/factories/CoachMessageFactory.php`

- [ ] **Step 1: Delete old files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
rm -f app/Services/CoachChatService.php
rm -rf app/Services/CoachTools/
rm -f app/Models/CoachConversation.php
rm -f app/Models/CoachMessage.php
rm -f database/factories/CoachConversationFactory.php
rm -f database/factories/CoachMessageFactory.php
```

- [ ] **Step 2: Update CoachProposal factory**

Read and update `api/database/factories/CoachProposalFactory.php` — remove the `CoachMessage` reference:

```php
<?php

namespace Database\Factories;

use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<CoachProposal>
 */
class CoachProposalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'agent_message_id' => fake()->uuid(),
            'user_id' => User::factory(),
            'type' => 'create_schedule',
            'payload' => ['weeks' => []],
            'status' => 'pending',
            'applied_at' => null,
        ];
    }
}
```

- [ ] **Step 3: Verify no broken imports**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
vendor/bin/pint --dirty --format agent
php artisan route:list --path=api/v1 2>&1 | head -5
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add -A api/
git commit -m "refactor: remove old CoachChatService and custom tool classes"
```

---

### Task 8: Update Tests

**Files:**
- Modify: `api/tests/Feature/CoachChatTest.php`
- Modify: `api/tests/Feature/ModelRelationshipsTest.php`

- [ ] **Step 1: Rewrite CoachChatTest**

Replace `api/tests/Feature/CoachChatTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\ProposalStatus;
use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class CoachChatTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_create_conversation(): void
    {
        RunCoachAgent::fake(['Hello! I\'m your running coach.']);

        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Training Chat',
        ], $headers);

        $response->assertCreated();
        $response->assertJsonStructure(['data' => ['id', 'title', 'message']]);
    }

    public function test_send_message(): void
    {
        RunCoachAgent::fake([
            'Hello! I\'m your running coach.',
            'Based on your recent runs, you\'re doing great!',
        ]);

        [$user, $headers] = $this->authUser();

        // Create conversation first
        $createResponse = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Test Chat',
        ], $headers);

        $conversationId = $createResponse->json('data.id');

        // Send follow-up message
        $response = $this->postJson("/api/v1/coach/conversations/{$conversationId}/messages", [
            'content' => 'How is my training going?',
        ], $headers);

        $response->assertOk();
        $response->assertJsonStructure(['data' => ['message' => ['role', 'content']]]);
    }

    public function test_accept_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'payload' => [
                'race_name' => 'Test Race',
                'distance' => 'half_marathon',
                'race_date' => now()->addMonths(3)->toDateString(),
                'schedule' => ['weeks' => []],
            ],
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/accept", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Accepted, $proposal->fresh()->status);
    }

    public function test_reject_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/reject", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Rejected, $proposal->fresh()->status);
    }
}
```

- [ ] **Step 2: Update ModelRelationshipsTest — remove coach conversation/message tests**

Read `api/tests/Feature/ModelRelationshipsTest.php` and remove these tests:
- `test_user_has_many_coach_conversations`
- `test_coach_conversation_has_many_messages`
- `test_coach_message_has_one_proposal`

These models no longer exist. The SDK manages conversations internally.

- [ ] **Step 3: Run full test suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact
```

Fix any failures.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/tests/
git commit -m "test: update tests for agent SDK refactor"
```

---

## Summary

| Task | What it builds |
|------|---------------|
| 1 | Database migration (alter proposals FK, drop old tables) |
| 2 | Read-only Strava tools (GetRecentActivities, GetActivityDetail, GetTrainingSummary) |
| 3 | Schedule/race tools (GetCurrentSchedule, GetRaceInfo, GetComplianceReport) |
| 4 | Mutation tools (CreateSchedule, ModifySchedule) with proposal flow |
| 5 | RunCoachAgent + ProposalService |
| 6 | Rewrite CoachController + update CoachProposal model |
| 7 | Delete old code (CoachChatService, custom tools, old models) |
| 8 | Update tests to use `RunCoachAgent::fake()` |

**Total: 8 tasks. The agent will be able to autonomously decide what data to fetch, see individual runs, and answer specific questions about the user's training.**
