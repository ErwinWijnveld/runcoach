# RunCoach Backend API — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the complete Laravel backend API for RunCoach — authentication via Strava OAuth, training schedule management, activity sync via webhooks, compliance scoring, and an AI coach with tool-calling for schedule management.

**Architecture:** Laravel 13 REST API with Sanctum token auth. Strava OAuth2 for user authentication, webhooks for activity sync. Laravel AI SDK (OpenAI) powers the coach chat with 7 tool definitions for schedule CRUD. All schedule mutations go through a proposal/approval flow. Filament admin panel is a separate plan.

**Tech Stack:** Laravel 13, Sanctum, openai-php/laravel, Strava API (OAuth2 + Webhooks), PHPUnit

**Spec:** `docs/superpowers/specs/2026-04-13-runcoach-mvp-design.md`

---

## Boost Conventions (apply to all tasks)

- Use `php artisan make:*` with `--no-interaction` for all file generation
- Use **Eloquent API Resources** for all JSON responses (not raw `response()->json()`)
- Run `vendor/bin/pint --dirty --format agent` before every commit
- Use `LazilyRefreshDatabase` instead of `RefreshDatabase` in tests
- Use **implicit route model binding** in controllers (type-hint `Race $race` not `int $raceId`)
- Use `search-docs` MCP tool to verify Laravel 13 API syntax when needed
- Create factories alongside models, use factory states in tests

---

## File Structure

```
api/
├── app/
│   ├── Enums/
│   │   ├── CoachStyle.php          — User coach preference enum
│   │   ├── MessageRole.php         — user/assistant enum
│   │   ├── ProposalStatus.php      — pending/accepted/rejected enum
│   │   ├── ProposalType.php        — create_schedule/modify_schedule/alternative_week enum
│   │   ├── RaceDistance.php         — 5k/10k/half/marathon/custom enum
│   │   ├── RaceStatus.php          — planning/active/completed/cancelled enum
│   │   ├── RunnerLevel.php         — beginner/intermediate/advanced/elite enum
│   │   └── TrainingType.php        — easy/tempo/interval/long_run/recovery/rest/mobility enum
│   ├── Http/
│   │   ├── Controllers/
│   │   │   ├── AuthController.php          — Strava OAuth redirect/callback/logout
│   │   │   ├── CoachController.php         — Conversations, messages, proposals
│   │   │   ├── DashboardController.php     — Aggregate dashboard endpoint
│   │   │   ├── ProfileController.php       — Profile get/update/onboarding
│   │   │   ├── RaceController.php          — Race CRUD
│   │   │   ├── StravaController.php        — Sync trigger, activities list, status
│   │   │   ├── StravaWebhookController.php — Webhook verification + event receiver
│   │   │   └── TrainingScheduleController.php — Schedule/week/day/result read endpoints
│   │   ├── Requests/
│   │   │   ├── OnboardingRequest.php
│   │   │   ├── SendMessageRequest.php
│   │   │   ├── StoreRaceRequest.php
│   │   │   └── UpdateProfileRequest.php
│   │   └── Resources/
│   │       ├── CoachConversationResource.php
│   │       ├── CoachMessageResource.php
│   │       ├── CoachProposalResource.php
│   │       ├── DashboardResource.php
│   │       ├── RaceResource.php
│   │       ├── StravaActivityResource.php
│   │       ├── TrainingDayResource.php
│   │       ├── TrainingResultResource.php
│   │       ├── TrainingWeekResource.php
│   │       └── UserResource.php
│   ├── Jobs/
│   │   ├── GenerateActivityFeedback.php    — AI feedback after compliance scoring
│   │   ├── GenerateWeeklyInsight.php       — AI weekly coach notes
│   │   ├── ProcessStravaActivity.php       — Fetch, store, match, score activity
│   │   └── SyncStravaHistory.php           — Initial bulk activity import
│   ├── Models/
│   │   ├── CoachConversation.php
│   │   ├── CoachMessage.php
│   │   ├── CoachProposal.php
│   │   ├── Race.php
│   │   ├── StravaActivity.php
│   │   ├── StravaToken.php
│   │   ├── TrainingDay.php
│   │   ├── TrainingResult.php
│   │   ├── TrainingWeek.php
│   │   └── User.php
│   └── Services/
│       ├── CoachChatService.php            — AI SDK calls, tool orchestration, context building
│       ├── CoachTools/
│       │   ├── CreateScheduleTool.php
│       │   ├── GetComplianceReportTool.php
│       │   ├── GetCurrentScheduleTool.php
│       │   ├── GetRaceReadinessTool.php
│       │   ├── GetStravaSummaryTool.php
│       │   ├── ModifyScheduleTool.php
│       │   └── ProposeAlternativeWeekTool.php
│       ├── ComplianceScoringService.php    — Score calculation logic
│       └── StravaSyncService.php           — OAuth token management, API calls, activity matching
├── config/
│   └── services.php                        — Strava client ID/secret/webhook config
├── database/
│   └── migrations/
│       ├── 0001_01_01_000000_create_users_table.php          — Modified for RunCoach fields
│       ├── 2026_04_13_000001_create_strava_tokens_table.php
│       ├── 2026_04_13_000002_create_races_table.php
│       ├── 2026_04_13_000003_create_training_weeks_table.php
│       ├── 2026_04_13_000004_create_training_days_table.php
│       ├── 2026_04_13_000005_create_strava_activities_table.php
│       ├── 2026_04_13_000006_create_training_results_table.php
│       ├── 2026_04_13_000007_create_coach_conversations_table.php
│       ├── 2026_04_13_000008_create_coach_messages_table.php
│       └── 2026_04_13_000009_create_coach_proposals_table.php
├── routes/
│   └── api.php                             — All API route definitions
└── tests/
    └── Feature/
        ├── AuthTest.php
        ├── CoachChatTest.php
        ├── ComplianceScoringTest.php
        ├── DashboardTest.php
        ├── ProfileTest.php
        ├── RaceTest.php
        ├── StravaSyncTest.php
        ├── StravaWebhookTest.php
        └── TrainingScheduleTest.php
```

---

### Task 1: Laravel Project Scaffolding

> **Step 1 is done by the user (Erwin) manually.** The agent picks up from Step 2.

**Files:**
- Create: `api/` (via `laravel new` — done by user)
- Modify: `api/.env`
- Modify: `api/config/services.php`
- Modify: `api/composer.json`

- [x] **Step 1: (USER) Create Laravel project** — DONE

User ran `laravel new api` with: no starter kit, PHPUnit, SQLite. Laravel Boost (`laravel/boost`) installed and running on port 8000.

- [ ] **Step 2: Install dependencies**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
composer require laravel/sanctum openai-php/laravel
```

Note: Using `openai-php/laravel` for direct OpenAI chat completions with tool calling. Wrapped in `CoachChatService` so the provider is swappable. Laravel Boost is already installed as a dev dependency.

- [ ] **Step 3: Publish vendor configs**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan vendor:publish --provider="Laravel\Sanctum\SanctumServiceProvider"
php artisan install:api
php artisan make:queue-table
php artisan migrate
```

- [ ] **Step 4: Configure environment**

Add to `api/.env`:

```env
STRAVA_CLIENT_ID=your_client_id
STRAVA_CLIENT_SECRET=your_client_secret
STRAVA_REDIRECT_URI=http://localhost:8000/api/v1/auth/strava/callback
STRAVA_WEBHOOK_VERIFY_TOKEN=your_random_verify_token

OPENAI_API_KEY=your_openai_key
OPENAI_MODEL=gpt-4o

QUEUE_CONNECTION=database
```

- [ ] **Step 5: Add Strava config to services.php**

Add to `api/config/services.php` in the return array:

```php
'strava' => [
    'client_id' => env('STRAVA_CLIENT_ID'),
    'client_secret' => env('STRAVA_CLIENT_SECRET'),
    'redirect_uri' => env('STRAVA_REDIRECT_URI'),
    'webhook_verify_token' => env('STRAVA_WEBHOOK_VERIFY_TOKEN'),
],
```

- [ ] **Step 6: Verify project boots**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan serve &
curl -s http://localhost:8000 | head -5
# Expected: HTML output from Laravel welcome page
kill %1
```

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/
git commit -m "feat: scaffold Laravel project with Sanctum and OpenAI"
```

---

### Task 2: Enum Definitions

**Files:**
- Create: `api/app/Enums/RunnerLevel.php`
- Create: `api/app/Enums/CoachStyle.php`
- Create: `api/app/Enums/RaceDistance.php`
- Create: `api/app/Enums/RaceStatus.php`
- Create: `api/app/Enums/TrainingType.php`
- Create: `api/app/Enums/MessageRole.php`
- Create: `api/app/Enums/ProposalType.php`
- Create: `api/app/Enums/ProposalStatus.php`

- [ ] **Step 1: Create all enum files**

`api/app/Enums/RunnerLevel.php`:
```php
<?php

namespace App\Enums;

enum RunnerLevel: string
{
    case Beginner = 'beginner';
    case Intermediate = 'intermediate';
    case Advanced = 'advanced';
    case Elite = 'elite';
}
```

`api/app/Enums/CoachStyle.php`:
```php
<?php

namespace App\Enums;

enum CoachStyle: string
{
    case Motivational = 'motivational';
    case Analytical = 'analytical';
    case Balanced = 'balanced';
}
```

`api/app/Enums/RaceDistance.php`:
```php
<?php

namespace App\Enums;

enum RaceDistance: string
{
    case FiveK = '5k';
    case TenK = '10k';
    case HalfMarathon = 'half_marathon';
    case Marathon = 'marathon';
    case Custom = 'custom';
}
```

`api/app/Enums/RaceStatus.php`:
```php
<?php

namespace App\Enums;

enum RaceStatus: string
{
    case Planning = 'planning';
    case Active = 'active';
    case Completed = 'completed';
    case Cancelled = 'cancelled';
}
```

`api/app/Enums/TrainingType.php`:
```php
<?php

namespace App\Enums;

enum TrainingType: string
{
    case Easy = 'easy';
    case Tempo = 'tempo';
    case Interval = 'interval';
    case LongRun = 'long_run';
    case Recovery = 'recovery';
    case Rest = 'rest';
    case Mobility = 'mobility';
}
```

`api/app/Enums/MessageRole.php`:
```php
<?php

namespace App\Enums;

enum MessageRole: string
{
    case User = 'user';
    case Assistant = 'assistant';
}
```

`api/app/Enums/ProposalType.php`:
```php
<?php

namespace App\Enums;

enum ProposalType: string
{
    case CreateSchedule = 'create_schedule';
    case ModifySchedule = 'modify_schedule';
    case AlternativeWeek = 'alternative_week';
}
```

`api/app/Enums/ProposalStatus.php`:
```php
<?php

namespace App\Enums;

enum ProposalStatus: string
{
    case Pending = 'pending';
    case Accepted = 'accepted';
    case Rejected = 'rejected';
}
```

- [ ] **Step 2: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Enums/
git commit -m "feat: add all enum definitions"
```

---

### Task 3: Database Migrations

Use `php artisan make:migration` to generate all migration files, then fill in the schema.

**Files:**
- Modify: `api/database/migrations/0001_01_01_000000_create_users_table.php`
- Create via artisan: 9 new migrations (see steps below)

- [ ] **Step 0: Generate all migration files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:migration create_strava_tokens_table
php artisan make:migration create_races_table
php artisan make:migration create_training_weeks_table
php artisan make:migration create_training_days_table
php artisan make:migration create_strava_activities_table
php artisan make:migration create_training_results_table
php artisan make:migration create_coach_conversations_table
php artisan make:migration create_coach_messages_table
php artisan make:migration create_coach_proposals_table
```

- [ ] **Step 1: Modify users migration**

Replace the `up()` method in `api/database/migrations/0001_01_01_000000_create_users_table.php`, in the `users` table schema:

```php
Schema::create('users', function (Blueprint $table) {
    $table->id();
    $table->string('name');
    $table->string('email')->unique();
    $table->bigInteger('strava_athlete_id')->unique()->nullable();
    $table->string('level')->nullable();
    $table->string('coach_style')->default('balanced');
    $table->decimal('weekly_km_capacity', 5, 1)->nullable();
    $table->timestamp('email_verified_at')->nullable();
    $table->string('password')->nullable();
    $table->rememberToken();
    $table->timestamps();
});
```

- [ ] **Step 2: Fill strava_tokens migration**

Edit the generated `create_strava_tokens_table` migration. Set the `up()` method:

```php
Schema::create('strava_tokens', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
    $table->text('access_token');
    $table->text('refresh_token');
    $table->timestamp('expires_at');
    $table->string('athlete_scope')->nullable();
    $table->timestamps();
});
```

- [ ] **Step 3: Fill races migration**

Edit the generated `create_races_table` migration:

```php
Schema::create('races', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->string('name');
    $table->string('distance');
    $table->unsignedInteger('custom_distance_meters')->nullable();
    $table->unsignedInteger('goal_time_seconds')->nullable();
    $table->date('race_date');
    $table->string('status')->default('planning');
    $table->timestamps();
});
```

- [ ] **Step 4: Fill training_weeks migration**

Edit the generated `create_training_weeks_table` migration:

```php
Schema::create('training_weeks', function (Blueprint $table) {
    $table->id();
    $table->foreignId('race_id')->constrained()->cascadeOnDelete();
    $table->unsignedInteger('week_number');
    $table->date('starts_at');
    $table->decimal('total_km', 6, 1);
    $table->string('focus');
    $table->text('coach_notes')->nullable();
    $table->timestamps();
});
```

- [ ] **Step 5: Fill training_days migration**

Edit the generated `create_training_days_table` migration:

```php
Schema::create('training_days', function (Blueprint $table) {
    $table->id();
    $table->foreignId('training_week_id')->constrained()->cascadeOnDelete();
    $table->date('date');
    $table->string('type');
    $table->string('title');
    $table->string('description')->nullable();
    $table->decimal('target_km', 5, 1)->nullable();
    $table->unsignedInteger('target_pace_seconds_per_km')->nullable();
    $table->unsignedTinyInteger('target_heart_rate_zone')->nullable();
    $table->json('intervals_json')->nullable();
    $table->unsignedTinyInteger('order');
    $table->timestamps();
});
```

- [ ] **Step 6: Fill strava_activities migration**

Edit the generated `create_strava_activities_table` migration:

```php
Schema::create('strava_activities', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->bigInteger('strava_id')->unique();
    $table->string('type');
    $table->string('name');
    $table->unsignedInteger('distance_meters');
    $table->unsignedInteger('moving_time_seconds');
    $table->unsignedInteger('elapsed_time_seconds');
    $table->decimal('average_heartrate', 5, 1)->nullable();
    $table->decimal('average_speed', 5, 2);
    $table->timestamp('start_date');
    $table->text('summary_polyline')->nullable();
    $table->json('raw_data');
    $table->timestamp('synced_at');
    $table->timestamps();
});
```

- [ ] **Step 7: Fill training_results migration**

Edit the generated `create_training_results_table` migration:

```php
Schema::create('training_results', function (Blueprint $table) {
    $table->id();
    $table->foreignId('training_day_id')->unique()->constrained()->cascadeOnDelete();
    $table->foreignId('strava_activity_id')->nullable()->constrained()->nullOnDelete();
    $table->decimal('compliance_score', 3, 1);
    $table->decimal('actual_km', 5, 1);
    $table->unsignedInteger('actual_pace_seconds_per_km');
    $table->decimal('actual_avg_heart_rate', 5, 1)->nullable();
    $table->decimal('pace_score', 3, 1);
    $table->decimal('distance_score', 3, 1);
    $table->decimal('heart_rate_score', 3, 1)->nullable();
    $table->text('ai_feedback')->nullable();
    $table->timestamp('matched_at');
    $table->timestamps();
});
```

- [ ] **Step 8: Fill coach_conversations migration**

Edit the generated `create_coach_conversations_table` migration:

```php
Schema::create('coach_conversations', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('race_id')->nullable()->constrained()->nullOnDelete();
    $table->string('title');
    $table->timestamps();
});
```

- [ ] **Step 9: Fill coach_messages migration**

Edit the generated `create_coach_messages_table` migration:

```php
Schema::create('coach_messages', function (Blueprint $table) {
    $table->id();
    $table->foreignId('coach_conversation_id')->constrained()->cascadeOnDelete();
    $table->string('role');
    $table->text('content');
    $table->json('context_snapshot')->nullable();
    $table->timestamps();
});
```

- [ ] **Step 10: Fill coach_proposals migration**

Edit the generated `create_coach_proposals_table` migration:

```php
Schema::create('coach_proposals', function (Blueprint $table) {
    $table->id();
    $table->foreignId('coach_message_id')->constrained()->cascadeOnDelete();
    $table->string('type');
    $table->json('payload');
    $table->string('status')->default('pending');
    $table->timestamp('applied_at')->nullable();
    $table->timestamps();
});
```

- [ ] **Step 11: Run migrations to verify**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan migrate:fresh
```

Expected: All migrations run successfully with no errors.

- [ ] **Step 12: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/database/migrations/
git commit -m "feat: add all database migrations"
```

---

### Task 4: Eloquent Models with Relationships

Use `php artisan make:model` with `--factory` to generate model and factory stubs, then fill them in.

**Generate all models and factories:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:model StravaToken --factory
php artisan make:model Race --factory
php artisan make:model TrainingWeek --factory
php artisan make:model TrainingDay --factory
php artisan make:model StravaActivity --factory
php artisan make:model TrainingResult --factory
php artisan make:model CoachConversation --factory
php artisan make:model CoachMessage --factory
php artisan make:model CoachProposal --factory
```

**Files:**
- Modify: `api/app/Models/User.php`
- Modify (generated): `api/app/Models/StravaToken.php`
- Modify (generated): `api/app/Models/Race.php`
- Modify (generated): `api/app/Models/TrainingWeek.php`
- Modify (generated): `api/app/Models/TrainingDay.php`
- Modify (generated): `api/app/Models/StravaActivity.php`
- Modify (generated): `api/app/Models/TrainingResult.php`
- Modify (generated): `api/app/Models/CoachConversation.php`
- Modify (generated): `api/app/Models/CoachMessage.php`
- Modify (generated): `api/app/Models/CoachProposal.php`
- Test: `api/tests/Feature/ModelRelationshipsTest.php`

- [ ] **Step 1: Write failing test for model relationships**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:test ModelRelationshipsTest
```

Replace the generated `api/tests/Feature/ModelRelationshipsTest.php` with:

```php
<?php

namespace Tests\Feature;

use App\Enums\CoachStyle;
use App\Enums\MessageRole;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Enums\RaceDistance;
use App\Enums\RaceStatus;
use App\Enums\RunnerLevel;
use App\Enums\TrainingType;
use App\Models\CoachConversation;
use App\Models\CoachMessage;
use App\Models\CoachProposal;
use App\Models\Race;
use App\Models\StravaActivity;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ModelRelationshipsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_user_has_one_strava_token(): void
    {
        $user = User::factory()->create();
        $token = StravaToken::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->stravaToken->is($token));
    }

    public function test_user_has_many_races(): void
    {
        $user = User::factory()->create();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $this->assertTrue($user->races->contains($race));
    }

    public function test_race_has_many_training_weeks(): void
    {
        $race = Race::factory()->create();
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);

        $this->assertTrue($race->trainingWeeks->contains($week));
    }

    public function test_training_week_has_many_training_days(): void
    {
        $week = TrainingWeek::factory()->create();
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $this->assertTrue($week->trainingDays->contains($day));
    }

    public function test_training_day_has_one_result(): void
    {
        $day = TrainingDay::factory()->create();
        $result = TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $this->assertTrue($day->result->is($result));
    }

    public function test_coach_conversation_has_many_messages(): void
    {
        $conversation = CoachConversation::factory()->create();
        $message = CoachMessage::factory()->create([
            'coach_conversation_id' => $conversation->id,
        ]);

        $this->assertTrue($conversation->messages->contains($message));
    }

    public function test_coach_message_has_one_proposal(): void
    {
        $message = CoachMessage::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'coach_message_id' => $message->id,
        ]);

        $this->assertTrue($message->proposal->is($proposal));
    }

    public function test_user_casts_enums_correctly(): void
    {
        $user = User::factory()->create([
            'level' => RunnerLevel::Intermediate,
            'coach_style' => CoachStyle::Analytical,
        ]);

        $user->refresh();
        $this->assertSame(RunnerLevel::Intermediate, $user->level);
        $this->assertSame(CoachStyle::Analytical, $user->coach_style);
    }

    public function test_strava_token_encrypts_tokens(): void
    {
        $token = StravaToken::factory()->create([
            'access_token' => 'test_access_token_value',
            'refresh_token' => 'test_refresh_token_value',
        ]);

        // Raw DB value should not match plaintext
        $raw = \DB::table('strava_tokens')->where('id', $token->id)->first();
        $this->assertNotEquals('test_access_token_value', $raw->access_token);

        // Model should decrypt correctly
        $token->refresh();
        $this->assertEquals('test_access_token_value', $token->access_token);
        $this->assertEquals('test_refresh_token_value', $token->refresh_token);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ModelRelationshipsTest.php
```

Expected: FAIL — models and factories don't exist yet.

- [ ] **Step 3: Implement User model**

Replace `api/app/Models/User.php`:

```php
<?php

namespace App\Models;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

class User extends Authenticatable
{
    use HasApiTokens, HasFactory, Notifiable;

    protected $fillable = [
        'name',
        'email',
        'strava_athlete_id',
        'level',
        'coach_style',
        'weekly_km_capacity',
        'password',
    ];

    protected $hidden = [
        'password',
        'remember_token',
    ];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'level' => RunnerLevel::class,
            'coach_style' => CoachStyle::class,
            'weekly_km_capacity' => 'decimal:1',
            'strava_athlete_id' => 'integer',
        ];
    }

    public function stravaToken(): HasOne
    {
        return $this->hasOne(StravaToken::class);
    }

    public function races(): HasMany
    {
        return $this->hasMany(Race::class);
    }

    public function stravaActivities(): HasMany
    {
        return $this->hasMany(StravaActivity::class);
    }

    public function coachConversations(): HasMany
    {
        return $this->hasMany(CoachConversation::class);
    }
}
```

- [ ] **Step 4: Implement StravaToken model**

Replace the generated `api/app/Models/StravaToken.php` with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class StravaToken extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'access_token',
        'refresh_token',
        'expires_at',
        'athlete_scope',
    ];

    protected function casts(): array
    {
        return [
            'access_token' => 'encrypted',
            'refresh_token' => 'encrypted',
            'expires_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function isExpired(): bool
    {
        return $this->expires_at->isPast();
    }
}
```

- [ ] **Step 5: Implement Race model**

Replace the generated `api/app/Models/Race.php` with:

```php
<?php

namespace App\Models;

use App\Enums\RaceDistance;
use App\Enums\RaceStatus;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Race extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'name',
        'distance',
        'custom_distance_meters',
        'goal_time_seconds',
        'race_date',
        'status',
    ];

    protected function casts(): array
    {
        return [
            'distance' => RaceDistance::class,
            'status' => RaceStatus::class,
            'race_date' => 'date',
            'custom_distance_meters' => 'integer',
            'goal_time_seconds' => 'integer',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function trainingWeeks(): HasMany
    {
        return $this->hasMany(TrainingWeek::class)->orderBy('week_number');
    }

    public function weeksUntilRace(): int
    {
        return (int) now()->diffInWeeks($this->race_date);
    }
}
```

- [ ] **Step 6: Implement TrainingWeek model**

Replace the generated `api/app/Models/TrainingWeek.php` with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class TrainingWeek extends Model
{
    use HasFactory;

    protected $fillable = [
        'race_id',
        'week_number',
        'starts_at',
        'total_km',
        'focus',
        'coach_notes',
    ];

    protected function casts(): array
    {
        return [
            'starts_at' => 'date',
            'total_km' => 'decimal:1',
            'week_number' => 'integer',
        ];
    }

    public function race(): BelongsTo
    {
        return $this->belongsTo(Race::class);
    }

    public function trainingDays(): HasMany
    {
        return $this->hasMany(TrainingDay::class)->orderBy('order');
    }
}
```

- [ ] **Step 7: Implement TrainingDay model**

Replace the generated `api/app/Models/TrainingDay.php` with:

```php
<?php

namespace App\Models;

use App\Enums\TrainingType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class TrainingDay extends Model
{
    use HasFactory;

    protected $fillable = [
        'training_week_id',
        'date',
        'type',
        'title',
        'description',
        'target_km',
        'target_pace_seconds_per_km',
        'target_heart_rate_zone',
        'intervals_json',
        'order',
    ];

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'type' => TrainingType::class,
            'target_km' => 'decimal:1',
            'target_pace_seconds_per_km' => 'integer',
            'target_heart_rate_zone' => 'integer',
            'intervals_json' => 'array',
            'order' => 'integer',
        ];
    }

    public function trainingWeek(): BelongsTo
    {
        return $this->belongsTo(TrainingWeek::class);
    }

    public function result(): HasOne
    {
        return $this->hasOne(TrainingResult::class);
    }
}
```

- [ ] **Step 8: Implement StravaActivity model**

Replace the generated `api/app/Models/StravaActivity.php` with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class StravaActivity extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'strava_id',
        'type',
        'name',
        'distance_meters',
        'moving_time_seconds',
        'elapsed_time_seconds',
        'average_heartrate',
        'average_speed',
        'start_date',
        'summary_polyline',
        'raw_data',
        'synced_at',
    ];

    protected function casts(): array
    {
        return [
            'strava_id' => 'integer',
            'distance_meters' => 'integer',
            'moving_time_seconds' => 'integer',
            'elapsed_time_seconds' => 'integer',
            'average_heartrate' => 'decimal:1',
            'average_speed' => 'decimal:2',
            'start_date' => 'datetime',
            'raw_data' => 'array',
            'synced_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function trainingResult(): HasOne
    {
        return $this->hasOne(TrainingResult::class);
    }

    public function distanceInKm(): float
    {
        return round($this->distance_meters / 1000, 1);
    }

    public function paceSecondsPerKm(): int
    {
        if ($this->distance_meters === 0) {
            return 0;
        }

        return (int) round($this->moving_time_seconds / ($this->distance_meters / 1000));
    }
}
```

- [ ] **Step 9: Implement TrainingResult model**

Replace the generated `api/app/Models/TrainingResult.php` with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TrainingResult extends Model
{
    use HasFactory;

    protected $fillable = [
        'training_day_id',
        'strava_activity_id',
        'compliance_score',
        'actual_km',
        'actual_pace_seconds_per_km',
        'actual_avg_heart_rate',
        'pace_score',
        'distance_score',
        'heart_rate_score',
        'ai_feedback',
        'matched_at',
    ];

    protected function casts(): array
    {
        return [
            'compliance_score' => 'decimal:1',
            'actual_km' => 'decimal:1',
            'actual_pace_seconds_per_km' => 'integer',
            'actual_avg_heart_rate' => 'decimal:1',
            'pace_score' => 'decimal:1',
            'distance_score' => 'decimal:1',
            'heart_rate_score' => 'decimal:1',
            'matched_at' => 'datetime',
        ];
    }

    public function trainingDay(): BelongsTo
    {
        return $this->belongsTo(TrainingDay::class);
    }

    public function stravaActivity(): BelongsTo
    {
        return $this->belongsTo(StravaActivity::class);
    }
}
```

- [ ] **Step 10: Implement CoachConversation model**

Replace the generated `api/app/Models/CoachConversation.php` with:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class CoachConversation extends Model
{
    use HasFactory;

    protected $fillable = [
        'user_id',
        'race_id',
        'title',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function race(): BelongsTo
    {
        return $this->belongsTo(Race::class);
    }

    public function messages(): HasMany
    {
        return $this->hasMany(CoachMessage::class)->orderBy('created_at');
    }
}
```

- [ ] **Step 11: Implement CoachMessage model**

Replace the generated `api/app/Models/CoachMessage.php` with:

```php
<?php

namespace App\Models;

use App\Enums\MessageRole;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

class CoachMessage extends Model
{
    use HasFactory;

    protected $fillable = [
        'coach_conversation_id',
        'role',
        'content',
        'context_snapshot',
    ];

    protected function casts(): array
    {
        return [
            'role' => MessageRole::class,
            'context_snapshot' => 'array',
        ];
    }

    public function conversation(): BelongsTo
    {
        return $this->belongsTo(CoachConversation::class, 'coach_conversation_id');
    }

    public function proposal(): HasOne
    {
        return $this->hasOne(CoachProposal::class);
    }
}
```

- [ ] **Step 12: Implement CoachProposal model**

Replace the generated `api/app/Models/CoachProposal.php` with:

```php
<?php

namespace App\Models;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CoachProposal extends Model
{
    use HasFactory;

    protected $fillable = [
        'coach_message_id',
        'type',
        'payload',
        'status',
        'applied_at',
    ];

    protected function casts(): array
    {
        return [
            'type' => ProposalType::class,
            'status' => ProposalStatus::class,
            'payload' => 'array',
            'applied_at' => 'datetime',
        ];
    }

    public function message(): BelongsTo
    {
        return $this->belongsTo(CoachMessage::class, 'coach_message_id');
    }

    public function isPending(): bool
    {
        return $this->status === ProposalStatus::Pending;
    }
}
```

- [ ] **Step 13: Fill all generated model factories**

Replace `api/database/factories/StravaTokenFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class StravaTokenFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'access_token' => fake()->sha256(),
            'refresh_token' => fake()->sha256(),
            'expires_at' => now()->addHours(6),
            'athlete_scope' => 'read,activity:read',
        ];
    }
}
```

Create `api/database/factories/RaceFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Enums\RaceDistance;
use App\Enums\RaceStatus;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class RaceFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'name' => fake()->city() . ' Marathon',
            'distance' => RaceDistance::HalfMarathon,
            'goal_time_seconds' => 6300,
            'race_date' => now()->addMonths(3),
            'status' => RaceStatus::Active,
        ];
    }
}
```

Create `api/database/factories/TrainingWeekFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\Race;
use Illuminate\Database\Eloquent\Factories\Factory;

class TrainingWeekFactory extends Factory
{
    public function definition(): array
    {
        return [
            'race_id' => Race::factory(),
            'week_number' => fake()->numberBetween(1, 24),
            'starts_at' => now()->startOfWeek(),
            'total_km' => fake()->randomFloat(1, 20, 60),
            'focus' => fake()->randomElement(['base building', 'tempo development', 'race-specific', 'taper']),
        ];
    }
}
```

Create `api/database/factories/TrainingDayFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Enums\TrainingType;
use App\Models\TrainingWeek;
use Illuminate\Database\Eloquent\Factories\Factory;

class TrainingDayFactory extends Factory
{
    public function definition(): array
    {
        return [
            'training_week_id' => TrainingWeek::factory(),
            'date' => now(),
            'type' => TrainingType::Easy,
            'title' => '5km Easy Run',
            'description' => '@ 5:30 min/km',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 330,
            'target_heart_rate_zone' => 2,
            'order' => 1,
        ];
    }
}
```

Create `api/database/factories/StravaActivityFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class StravaActivityFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'strava_id' => fake()->unique()->randomNumber(9),
            'type' => 'Run',
            'name' => 'Morning Run',
            'distance_meters' => 5000,
            'moving_time_seconds' => 1650,
            'elapsed_time_seconds' => 1700,
            'average_heartrate' => 145.0,
            'average_speed' => 3.03,
            'start_date' => now(),
            'raw_data' => ['id' => 123],
            'synced_at' => now(),
        ];
    }
}
```

Create `api/database/factories/TrainingResultFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\StravaActivity;
use App\Models\TrainingDay;
use Illuminate\Database\Eloquent\Factories\Factory;

class TrainingResultFactory extends Factory
{
    public function definition(): array
    {
        return [
            'training_day_id' => TrainingDay::factory(),
            'strava_activity_id' => StravaActivity::factory(),
            'compliance_score' => 7.5,
            'actual_km' => 5.2,
            'actual_pace_seconds_per_km' => 325,
            'actual_avg_heart_rate' => 148.0,
            'pace_score' => 8.0,
            'distance_score' => 7.0,
            'heart_rate_score' => 7.5,
            'ai_feedback' => 'Good pace control on this easy run.',
            'matched_at' => now(),
        ];
    }
}
```

Create `api/database/factories/CoachConversationFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

class CoachConversationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'title' => 'Training Chat',
        ];
    }
}
```

Create `api/database/factories/CoachMessageFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Enums\MessageRole;
use App\Models\CoachConversation;
use Illuminate\Database\Eloquent\Factories\Factory;

class CoachMessageFactory extends Factory
{
    public function definition(): array
    {
        return [
            'coach_conversation_id' => CoachConversation::factory(),
            'role' => MessageRole::User,
            'content' => 'How is my training going?',
        ];
    }
}
```

Create `api/database/factories/CoachProposalFactory.php`:

```php
<?php

namespace Database\Factories;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachMessage;
use Illuminate\Database\Eloquent\Factories\Factory;

class CoachProposalFactory extends Factory
{
    public function definition(): array
    {
        return [
            'coach_message_id' => CoachMessage::factory(),
            'type' => ProposalType::CreateSchedule,
            'payload' => ['weeks' => []],
            'status' => ProposalStatus::Pending,
        ];
    }
}
```

Update `api/database/factories/UserFactory.php` — replace the `definition()` method:

```php
public function definition(): array
{
    return [
        'name' => fake()->name(),
        'email' => fake()->unique()->safeEmail(),
        'strava_athlete_id' => fake()->unique()->randomNumber(8),
        'level' => \App\Enums\RunnerLevel::Intermediate,
        'coach_style' => \App\Enums\CoachStyle::Balanced,
        'weekly_km_capacity' => 40.0,
        'email_verified_at' => now(),
        'password' => null,
        'remember_token' => \Illuminate\Support\Str::random(10),
    ];
}
```

- [ ] **Step 14: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ModelRelationshipsTest.php
```

Expected: All 9 tests PASS.

- [ ] **Step 15: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Models/ api/database/factories/ api/tests/Feature/ModelRelationshipsTest.php
git commit -m "feat: add all Eloquent models, factories, and relationship tests"
```

---

### Task 5: Strava OAuth Authentication

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller AuthController
php artisan make:test AuthTest
mkdir -p app/Services
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/AuthController.php`
- Create: `api/app/Services/StravaSyncService.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/AuthTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/AuthTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_strava_redirect_returns_authorize_url(): void
    {
        $response = $this->getJson('/api/v1/auth/strava/redirect');

        $response->assertOk();
        $response->assertJsonStructure(['url']);
        $this->assertStringContains('strava.com/oauth/authorize', $response->json('url'));
    }

    public function test_strava_callback_creates_user_and_returns_token(): void
    {
        Http::fake([
            'www.strava.com/oauth/token' => Http::response([
                'access_token' => 'fake_access_token',
                'refresh_token' => 'fake_refresh_token',
                'expires_at' => now()->addHours(6)->timestamp,
                'athlete' => [
                    'id' => 12345,
                    'firstname' => 'Test',
                    'lastname' => 'Runner',
                    'email' => 'test@example.com',
                ],
            ]),
        ]);

        $response = $this->getJson('/api/v1/auth/strava/callback?code=test_auth_code');

        $response->assertOk();
        $response->assertJsonStructure(['token', 'user']);

        $this->assertDatabaseHas('users', [
            'strava_athlete_id' => 12345,
            'name' => 'Test Runner',
        ]);
        $this->assertDatabaseCount('strava_tokens', 1);
    }

    public function test_strava_callback_updates_existing_user(): void
    {
        $user = User::factory()->create(['strava_athlete_id' => 12345]);
        StravaToken::factory()->create(['user_id' => $user->id]);

        Http::fake([
            'www.strava.com/oauth/token' => Http::response([
                'access_token' => 'new_access_token',
                'refresh_token' => 'new_refresh_token',
                'expires_at' => now()->addHours(6)->timestamp,
                'athlete' => [
                    'id' => 12345,
                    'firstname' => 'Test',
                    'lastname' => 'Runner',
                    'email' => 'test@example.com',
                ],
            ]),
        ]);

        $response = $this->getJson('/api/v1/auth/strava/callback?code=test_auth_code');

        $response->assertOk();
        $this->assertDatabaseCount('users', 1);
        $this->assertDatabaseCount('strava_tokens', 1);
    }

    public function test_logout_revokes_token(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        $response = $this->postJson('/api/v1/auth/logout', [], [
            'Authorization' => "Bearer $token",
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('personal_access_tokens', 0);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/AuthTest.php
```

Expected: FAIL — routes and controller don't exist.

- [ ] **Step 3: Implement StravaSyncService (OAuth methods)**

Create `api/app/Services/StravaSyncService.php`:

```php
<?php

namespace App\Services;

use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Support\Facades\Http;

class StravaSyncService
{
    public function getAuthorizeUrl(): string
    {
        $params = http_build_query([
            'client_id' => config('services.strava.client_id'),
            'redirect_uri' => config('services.strava.redirect_uri'),
            'response_type' => 'code',
            'scope' => 'read,activity:read_all',
        ]);

        return "https://www.strava.com/oauth/authorize?$params";
    }

    public function exchangeCode(string $code): array
    {
        $response = Http::post('https://www.strava.com/oauth/token', [
            'client_id' => config('services.strava.client_id'),
            'client_secret' => config('services.strava.client_secret'),
            'code' => $code,
            'grant_type' => 'authorization_code',
        ]);

        $response->throw();

        return $response->json();
    }

    public function createOrUpdateUser(array $stravaData): User
    {
        $athlete = $stravaData['athlete'];

        $user = User::updateOrCreate(
            ['strava_athlete_id' => $athlete['id']],
            [
                'name' => trim($athlete['firstname'] . ' ' . $athlete['lastname']),
                'email' => $athlete['email'] ?? $athlete['id'] . '@strava.runcoach',
            ]
        );

        $user->stravaToken()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'access_token' => $stravaData['access_token'],
                'refresh_token' => $stravaData['refresh_token'],
                'expires_at' => \Carbon\Carbon::createFromTimestamp($stravaData['expires_at']),
                'athlete_scope' => 'read,activity:read_all',
            ]
        );

        return $user;
    }

    public function refreshTokenIfNeeded(StravaToken $token): StravaToken
    {
        if (! $token->isExpired()) {
            return $token;
        }

        $response = Http::post('https://www.strava.com/oauth/token', [
            'client_id' => config('services.strava.client_id'),
            'client_secret' => config('services.strava.client_secret'),
            'refresh_token' => $token->refresh_token,
            'grant_type' => 'refresh_token',
        ]);

        $response->throw();
        $data = $response->json();

        $token->update([
            'access_token' => $data['access_token'],
            'refresh_token' => $data['refresh_token'],
            'expires_at' => \Carbon\Carbon::createFromTimestamp($data['expires_at']),
        ]);

        return $token->refresh();
    }

    public function fetchActivities(StravaToken $token, int $page = 1, int $perPage = 30, ?int $after = null): array
    {
        $token = $this->refreshTokenIfNeeded($token);

        $query = ['page' => $page, 'per_page' => $perPage];
        if ($after) {
            $query['after'] = $after;
        }

        $response = Http::withToken($token->access_token)
            ->get('https://www.strava.com/api/v3/athlete/activities', $query);

        $response->throw();

        return $response->json();
    }

    public function fetchActivity(StravaToken $token, int $stravaActivityId): array
    {
        $token = $this->refreshTokenIfNeeded($token);

        $response = Http::withToken($token->access_token)
            ->get("https://www.strava.com/api/v3/activities/{$stravaActivityId}");

        $response->throw();

        return $response->json();
    }
}
```

- [ ] **Step 4: Implement AuthController**

Create `api/app/Http/Controllers/AuthController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Services\StravaSyncService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AuthController extends Controller
{
    public function __construct(
        private StravaSyncService $stravaSyncService,
    ) {}

    public function redirect(): JsonResponse
    {
        return response()->json([
            'url' => $this->stravaSyncService->getAuthorizeUrl(),
        ]);
    }

    public function callback(Request $request): JsonResponse
    {
        $request->validate(['code' => 'required|string']);

        $stravaData = $this->stravaSyncService->exchangeCode($request->code);
        $user = $this->stravaSyncService->createOrUpdateUser($stravaData);

        $token = $user->createToken('api')->plainTextToken;

        return response()->json([
            'token' => $token,
            'user' => $user->only(['id', 'name', 'email', 'level', 'coach_style']),
        ]);
    }

    public function logout(Request $request): JsonResponse
    {
        $request->user()->currentAccessToken()->delete();

        return response()->json(['message' => 'Logged out']);
    }
}
```

- [ ] **Step 5: Add auth routes**

Replace `api/routes/api.php`:

```php
<?php

use App\Http\Controllers\AuthController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Auth (public)
    Route::get('auth/strava/redirect', [AuthController::class, 'redirect']);
    Route::get('auth/strava/callback', [AuthController::class, 'callback']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        Route::post('auth/logout', [AuthController::class, 'logout']);
    });
});
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/AuthTest.php
```

Expected: All 4 tests PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/AuthController.php api/app/Services/StravaSyncService.php api/routes/api.php api/tests/Feature/AuthTest.php
git commit -m "feat: add Strava OAuth authentication with Sanctum tokens"
```

---

### Task 6: Profile API

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller ProfileController
php artisan make:request UpdateProfileRequest
php artisan make:request OnboardingRequest
php artisan make:test ProfileTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/ProfileController.php`
- Modify (generated): `api/app/Http/Requests/UpdateProfileRequest.php`
- Modify (generated): `api/app/Http/Requests/OnboardingRequest.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/ProfileTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/ProfileTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(?User $user = null): array
    {
        $user ??= User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_get_profile(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/profile', $headers);

        $response->assertOk();
        $response->assertJsonFragment(['name' => $user->name]);
    }

    public function test_update_profile(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'level' => 'advanced',
            'coach_style' => 'analytical',
            'weekly_km_capacity' => 55.0,
        ], $headers);

        $response->assertOk();
        $user->refresh();
        $this->assertSame(RunnerLevel::Advanced, $user->level);
        $this->assertSame(CoachStyle::Analytical, $user->coach_style);
        $this->assertEquals(55.0, $user->weekly_km_capacity);
    }

    public function test_complete_onboarding(): void
    {
        [$user, $headers] = $this->authUser(
            User::factory()->create(['level' => null, 'coach_style' => null])
        );

        $response = $this->postJson('/api/v1/profile/onboarding', [
            'level' => 'beginner',
            'coach_style' => 'motivational',
            'weekly_km_capacity' => 20.0,
        ], $headers);

        $response->assertOk();
        $user->refresh();
        $this->assertSame(RunnerLevel::Beginner, $user->level);
    }

    public function test_unauthenticated_profile_returns_401(): void
    {
        $response = $this->getJson('/api/v1/profile');
        $response->assertUnauthorized();
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ProfileTest.php
```

Expected: FAIL — controller and routes don't exist.

- [ ] **Step 3: Implement request validators**

Create `api/app/Http/Requests/UpdateProfileRequest.php`:

```php
<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'level' => ['sometimes', Rule::enum(RunnerLevel::class)],
            'coach_style' => ['sometimes', Rule::enum(CoachStyle::class)],
            'weekly_km_capacity' => ['sometimes', 'numeric', 'min:0', 'max:300'],
        ];
    }
}
```

Create `api/app/Http/Requests/OnboardingRequest.php`:

```php
<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class OnboardingRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'level' => ['required', Rule::enum(RunnerLevel::class)],
            'coach_style' => ['required', Rule::enum(CoachStyle::class)],
            'weekly_km_capacity' => ['required', 'numeric', 'min:0', 'max:300'],
        ];
    }
}
```

- [ ] **Step 4: Implement ProfileController**

Create `api/app/Http/Controllers/ProfileController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\OnboardingRequest;
use App\Http\Requests\UpdateProfileRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $request->user()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $request->user()->fresh()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }

    public function onboarding(OnboardingRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $request->user()->fresh()->only([
                'id', 'name', 'email', 'strava_athlete_id',
                'level', 'coach_style', 'weekly_km_capacity',
            ]),
        ]);
    }
}
```

- [ ] **Step 5: Add profile routes to api.php**

Add inside the `auth:sanctum` middleware group in `api/routes/api.php`:

```php
Route::get('profile', [ProfileController::class, 'show']);
Route::put('profile', [ProfileController::class, 'update']);
Route::post('profile/onboarding', [ProfileController::class, 'onboarding']);
```

Add the import at the top:

```php
use App\Http\Controllers\ProfileController;
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ProfileTest.php
```

Expected: All 4 tests PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/ProfileController.php api/app/Http/Requests/ api/routes/api.php api/tests/Feature/ProfileTest.php
git commit -m "feat: add profile API with get, update, and onboarding"
```

---

### Task 7: Race CRUD API

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller RaceController --api
php artisan make:request StoreRaceRequest
php artisan make:test RaceTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/RaceController.php`
- Modify (generated): `api/app/Http/Requests/StoreRaceRequest.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/RaceTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/RaceTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Enums\RaceDistance;
use App\Enums\RaceStatus;
use App\Models\Race;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RaceTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_list_races(): void
    {
        [$user, $headers] = $this->authUser();
        Race::factory()->count(3)->create(['user_id' => $user->id]);
        Race::factory()->create(); // another user's race

        $response = $this->getJson('/api/v1/races', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_create_race(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/races', [
            'name' => 'Amsterdam Marathon',
            'distance' => 'marathon',
            'goal_time_seconds' => 14400,
            'race_date' => '2026-10-18',
        ], $headers);

        $response->assertCreated();
        $this->assertDatabaseHas('races', [
            'user_id' => $user->id,
            'name' => 'Amsterdam Marathon',
            'distance' => 'marathon',
        ]);
    }

    public function test_show_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->getJson("/api/v1/races/{$race->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['name' => $race->name]);
    }

    public function test_cannot_access_other_users_race(): void
    {
        [$user, $headers] = $this->authUser();
        $otherRace = Race::factory()->create();

        $response = $this->getJson("/api/v1/races/{$otherRace->id}", $headers);

        $response->assertNotFound();
    }

    public function test_update_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->putJson("/api/v1/races/{$race->id}", [
            'name' => 'Updated Race',
            'goal_time_seconds' => 7200,
        ], $headers);

        $response->assertOk();
        $this->assertEquals('Updated Race', $race->fresh()->name);
    }

    public function test_delete_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->deleteJson("/api/v1/races/{$race->id}", [], $headers);

        $response->assertOk();
        $this->assertSame(RaceStatus::Cancelled, $race->fresh()->status);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/RaceTest.php
```

Expected: FAIL.

- [ ] **Step 3: Implement StoreRaceRequest**

Create `api/app/Http/Requests/StoreRaceRequest.php`:

```php
<?php

namespace App\Http\Requests;

use App\Enums\RaceDistance;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRaceRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'distance' => ['required', Rule::enum(RaceDistance::class)],
            'custom_distance_meters' => ['nullable', 'integer', 'min:100', 'required_if:distance,custom'],
            'goal_time_seconds' => ['nullable', 'integer', 'min:300'],
            'race_date' => ['required', 'date', 'after:today'],
        ];
    }
}
```

- [ ] **Step 4: Implement RaceController**

Create `api/app/Http/Controllers/RaceController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Enums\RaceStatus;
use App\Http\Requests\StoreRaceRequest;
use App\Models\Race;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RaceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $races = $request->user()->races()
            ->orderByDesc('race_date')
            ->get();

        return response()->json(['data' => $races]);
    }

    public function store(StoreRaceRequest $request): JsonResponse
    {
        $race = $request->user()->races()->create(
            $request->validated()
        );

        return response()->json(['data' => $race], 201);
    }

    public function show(Request $request, int $raceId): JsonResponse
    {
        $race = $request->user()->races()->findOrFail($raceId);

        return response()->json([
            'data' => $race,
            'weeks_until_race' => $race->weeksUntilRace(),
        ]);
    }

    public function update(Request $request, int $raceId): JsonResponse
    {
        $race = $request->user()->races()->findOrFail($raceId);

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'goal_time_seconds' => ['sometimes', 'nullable', 'integer', 'min:300'],
            'race_date' => ['sometimes', 'date', 'after:today'],
        ]);

        $race->update($validated);

        return response()->json(['data' => $race->fresh()]);
    }

    public function destroy(Request $request, int $raceId): JsonResponse
    {
        $race = $request->user()->races()->findOrFail($raceId);
        $race->update(['status' => RaceStatus::Cancelled]);

        return response()->json(['message' => 'Race cancelled']);
    }
}
```

- [ ] **Step 5: Add race routes to api.php**

Add inside the `auth:sanctum` middleware group in `api/routes/api.php`:

```php
Route::apiResource('races', RaceController::class);
```

Add the import:

```php
use App\Http\Controllers\RaceController;
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/RaceTest.php
```

Expected: All 6 tests PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/RaceController.php api/app/Http/Requests/StoreRaceRequest.php api/routes/api.php api/tests/Feature/RaceTest.php
git commit -m "feat: add race CRUD API"
```

---

### Task 8: Training Schedule Read API

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller TrainingScheduleController
php artisan make:test TrainingScheduleTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/TrainingScheduleController.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/TrainingScheduleTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/TrainingScheduleTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Models\Race;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class TrainingScheduleTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_get_full_schedule(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id, 'week_number' => 1]);
        TrainingDay::factory()->count(7)->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/races/{$race->id}/schedule", $headers);

        $response->assertOk();
        $this->assertCount(1, $response->json('data'));
        $this->assertCount(7, $response->json('data.0.training_days'));
    }

    public function test_get_current_week(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $pastWeek = TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'week_number' => 1,
            'starts_at' => now()->subWeeks(2)->startOfWeek(),
        ]);

        $currentWeek = TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'week_number' => 2,
            'starts_at' => now()->startOfWeek(),
        ]);
        TrainingDay::factory()->count(7)->create([
            'training_week_id' => $currentWeek->id,
            'date' => now(),
        ]);

        $response = $this->getJson("/api/v1/races/{$race->id}/schedule/current", $headers);

        $response->assertOk();
        $this->assertEquals($currentWeek->id, $response->json('data.id'));
    }

    public function test_get_training_day_detail(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['title' => $day->title]);
    }

    public function test_get_training_result(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        $result = TrainingResult::factory()->create(['training_day_id' => $day->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['compliance_score' => $result->compliance_score]);
    }

    public function test_training_day_without_result_returns_null(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['race_id' => $race->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);

        $response = $this->getJson("/api/v1/training-days/{$day->id}/result", $headers);

        $response->assertOk();
        $this->assertNull($response->json('data'));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/TrainingScheduleTest.php
```

Expected: FAIL.

- [ ] **Step 3: Implement TrainingScheduleController**

Create `api/app/Http/Controllers/TrainingScheduleController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Models\TrainingDay;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TrainingScheduleController extends Controller
{
    public function schedule(Request $request, int $raceId): JsonResponse
    {
        $race = $request->user()->races()->findOrFail($raceId);

        $weeks = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        return response()->json(['data' => $weeks]);
    }

    public function currentWeek(Request $request, int $raceId): JsonResponse
    {
        $race = $request->user()->races()->findOrFail($raceId);

        $week = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        return response()->json(['data' => $week]);
    }

    public function showDay(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.race', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->with('trainingWeek', 'result')->findOrFail($dayId);

        return response()->json(['data' => $day]);
    }

    public function dayResult(Request $request, int $dayId): JsonResponse
    {
        $day = TrainingDay::whereHas('trainingWeek.race', function ($query) use ($request) {
            $query->where('user_id', $request->user()->id);
        })->findOrFail($dayId);

        $result = $day->result?->load('stravaActivity');

        return response()->json(['data' => $result]);
    }
}
```

- [ ] **Step 4: Add schedule routes to api.php**

Add inside the `auth:sanctum` middleware group in `api/routes/api.php`:

```php
Route::get('races/{race}/schedule', [TrainingScheduleController::class, 'schedule']);
Route::get('races/{race}/schedule/current', [TrainingScheduleController::class, 'currentWeek']);
Route::get('training-days/{day}', [TrainingScheduleController::class, 'showDay']);
Route::get('training-days/{day}/result', [TrainingScheduleController::class, 'dayResult']);
```

Add the import:

```php
use App\Http\Controllers\TrainingScheduleController;
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/TrainingScheduleTest.php
```

Expected: All 5 tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/TrainingScheduleController.php api/routes/api.php api/tests/Feature/TrainingScheduleTest.php
git commit -m "feat: add training schedule read API"
```

---

### Task 9: Strava Webhook + Activity Sync

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller StravaWebhookController
php artisan make:controller StravaController
php artisan make:job ProcessStravaActivity
php artisan make:job SyncStravaHistory
php artisan make:test StravaWebhookTest
php artisan make:test StravaSyncTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/StravaWebhookController.php`
- Modify (generated): `api/app/Http/Controllers/StravaController.php`
- Modify (generated): `api/app/Jobs/ProcessStravaActivity.php`
- Modify (generated): `api/app/Jobs/SyncStravaHistory.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/StravaWebhookTest.php`
- Modify (generated): `api/tests/Feature/StravaSyncTest.php`

- [ ] **Step 1: Write failing webhook test**

Create `api/tests/Feature/StravaWebhookTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Jobs\ProcessStravaActivity;
use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class StravaWebhookTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_webhook_verification_challenge(): void
    {
        $response = $this->getJson('/api/v1/webhook/strava?' . http_build_query([
            'hub.mode' => 'subscribe',
            'hub.verify_token' => config('services.strava.webhook_verify_token'),
            'hub.challenge' => 'challenge_string',
        ]));

        $response->assertOk();
        $response->assertJson(['hub.challenge' => 'challenge_string']);
    }

    public function test_webhook_rejects_invalid_verify_token(): void
    {
        $response = $this->getJson('/api/v1/webhook/strava?' . http_build_query([
            'hub.mode' => 'subscribe',
            'hub.verify_token' => 'wrong_token',
            'hub.challenge' => 'challenge_string',
        ]));

        $response->assertForbidden();
    }

    public function test_webhook_dispatches_job_for_activity_create(): void
    {
        Queue::fake();

        $user = User::factory()->create(['strava_athlete_id' => 12345]);
        StravaToken::factory()->create(['user_id' => $user->id]);

        $response = $this->postJson('/api/v1/webhook/strava', [
            'object_type' => 'activity',
            'aspect_type' => 'create',
            'owner_id' => 12345,
            'object_id' => 98765,
        ]);

        $response->assertOk();
        Queue::assertPushed(ProcessStravaActivity::class, function ($job) {
            return $job->stravaActivityId === 98765;
        });
    }

    public function test_webhook_ignores_non_activity_events(): void
    {
        Queue::fake();

        $response = $this->postJson('/api/v1/webhook/strava', [
            'object_type' => 'athlete',
            'aspect_type' => 'update',
            'owner_id' => 12345,
            'object_id' => 12345,
        ]);

        $response->assertOk();
        Queue::assertNotPushed(ProcessStravaActivity::class);
    }
}
```

- [ ] **Step 2: Write failing sync test**

Create `api/tests/Feature/StravaSyncTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Models\StravaActivity;
use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class StravaSyncTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_manual_sync_dispatches_job(): void
    {
        Queue::fake();
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/strava/sync', [], $headers);

        $response->assertOk();
    }

    public function test_list_synced_activities(): void
    {
        [$user, $headers] = $this->authUser();
        StravaActivity::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/v1/strava/activities', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_strava_status(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/strava/status', $headers);

        $response->assertOk();
        $response->assertJsonStructure(['connected', 'last_sync']);
    }
}
```

- [ ] **Step 3: Run tests to verify they fail**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/StravaWebhookTest.php tests/Feature/StravaSyncTest.php
```

Expected: FAIL.

- [ ] **Step 4: Implement StravaWebhookController**

Create `api/app/Http/Controllers/StravaWebhookController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Jobs\ProcessStravaActivity;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StravaWebhookController extends Controller
{
    public function verify(Request $request): JsonResponse
    {
        if ($request->input('hub_verify_token') !== config('services.strava.webhook_verify_token')
            && $request->input('hub.verify_token') !== config('services.strava.webhook_verify_token')) {
            return response()->json(['error' => 'Invalid verify token'], 403);
        }

        $challenge = $request->input('hub_challenge') ?? $request->input('hub.challenge');

        return response()->json(['hub.challenge' => $challenge]);
    }

    public function handle(Request $request): JsonResponse
    {
        if ($request->input('object_type') !== 'activity') {
            return response()->json(['status' => 'ignored']);
        }

        if ($request->input('aspect_type') !== 'create') {
            return response()->json(['status' => 'ignored']);
        }

        $user = User::where('strava_athlete_id', $request->input('owner_id'))->first();

        if (! $user) {
            return response()->json(['status' => 'user not found']);
        }

        ProcessStravaActivity::dispatch(
            $user->id,
            (int) $request->input('object_id'),
        );

        return response()->json(['status' => 'ok']);
    }
}
```

- [ ] **Step 5: Implement ProcessStravaActivity job**

Create `api/app/Jobs/ProcessStravaActivity.php`:

```php
<?php

namespace App\Jobs;

use App\Models\StravaActivity;
use App\Models\User;
use App\Services\ComplianceScoringService;
use App\Services\StravaSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class ProcessStravaActivity implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $userId,
        public int $stravaActivityId,
    ) {}

    public function handle(StravaSyncService $stravaSyncService, ComplianceScoringService $complianceService): void
    {
        $user = User::findOrFail($this->userId);
        $token = $user->stravaToken;

        if (! $token) {
            return;
        }

        $activityData = $stravaSyncService->fetchActivity($token, $this->stravaActivityId);

        if ($activityData['type'] !== 'Run') {
            return;
        }

        $activity = StravaActivity::updateOrCreate(
            ['strava_id' => $activityData['id']],
            [
                'user_id' => $user->id,
                'type' => $activityData['type'],
                'name' => $activityData['name'],
                'distance_meters' => (int) $activityData['distance'],
                'moving_time_seconds' => $activityData['moving_time'],
                'elapsed_time_seconds' => $activityData['elapsed_time'],
                'average_heartrate' => $activityData['average_heartrate'] ?? null,
                'average_speed' => $activityData['average_speed'],
                'start_date' => $activityData['start_date'],
                'summary_polyline' => $activityData['map']['summary_polyline'] ?? null,
                'raw_data' => $activityData,
                'synced_at' => now(),
            ]
        );

        $complianceService->matchAndScore($user, $activity);
    }
}
```

- [ ] **Step 6: Implement SyncStravaHistory job**

Create `api/app/Jobs/SyncStravaHistory.php`:

```php
<?php

namespace App\Jobs;

use App\Models\StravaActivity;
use App\Models\User;
use App\Services\StravaSyncService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class SyncStravaHistory implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $userId,
    ) {}

    public function handle(StravaSyncService $stravaSyncService): void
    {
        $user = User::findOrFail($this->userId);
        $token = $user->stravaToken;

        if (! $token) {
            return;
        }

        $after = now()->subWeeks(8)->timestamp;
        $page = 1;

        do {
            $activities = $stravaSyncService->fetchActivities($token, $page, 30, $after);

            foreach ($activities as $activityData) {
                if ($activityData['type'] !== 'Run') {
                    continue;
                }

                StravaActivity::updateOrCreate(
                    ['strava_id' => $activityData['id']],
                    [
                        'user_id' => $user->id,
                        'type' => $activityData['type'],
                        'name' => $activityData['name'],
                        'distance_meters' => (int) $activityData['distance'],
                        'moving_time_seconds' => $activityData['moving_time'],
                        'elapsed_time_seconds' => $activityData['elapsed_time'],
                        'average_heartrate' => $activityData['average_heartrate'] ?? null,
                        'average_speed' => $activityData['average_speed'],
                        'start_date' => $activityData['start_date'],
                        'summary_polyline' => $activityData['map']['summary_polyline'] ?? null,
                        'raw_data' => $activityData,
                        'synced_at' => now(),
                    ]
                );
            }

            $page++;
        } while (count($activities) === 30);
    }
}
```

- [ ] **Step 7: Implement StravaController**

Create `api/app/Http/Controllers/StravaController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Jobs\SyncStravaHistory;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class StravaController extends Controller
{
    public function sync(Request $request): JsonResponse
    {
        SyncStravaHistory::dispatch($request->user()->id);

        return response()->json(['message' => 'Sync started']);
    }

    public function activities(Request $request): JsonResponse
    {
        $activities = $request->user()->stravaActivities()
            ->orderByDesc('start_date')
            ->paginate(30);

        return response()->json($activities);
    }

    public function status(Request $request): JsonResponse
    {
        $user = $request->user();
        $token = $user->stravaToken;
        $lastActivity = $user->stravaActivities()->orderByDesc('synced_at')->first();

        return response()->json([
            'connected' => $token !== null,
            'token_valid' => $token && ! $token->isExpired(),
            'last_sync' => $lastActivity?->synced_at,
        ]);
    }
}
```

- [ ] **Step 8: Add webhook and strava routes to api.php**

Add outside the auth middleware group (webhooks are public) in `api/routes/api.php`:

```php
// Strava webhook (no auth)
Route::get('webhook/strava', [StravaWebhookController::class, 'verify']);
Route::post('webhook/strava', [StravaWebhookController::class, 'handle']);
```

Add inside the `auth:sanctum` middleware group:

```php
Route::post('strava/sync', [StravaController::class, 'sync']);
Route::get('strava/activities', [StravaController::class, 'activities']);
Route::get('strava/status', [StravaController::class, 'status']);
```

Add the imports:

```php
use App\Http\Controllers\StravaController;
use App\Http\Controllers\StravaWebhookController;
```

- [ ] **Step 9: Create stub ComplianceScoringService (needed by ProcessStravaActivity)**

Create `api/app/Services/ComplianceScoringService.php` with a stub so the job compiles:

```php
<?php

namespace App\Services;

use App\Models\StravaActivity;
use App\Models\User;

class ComplianceScoringService
{
    public function matchAndScore(User $user, StravaActivity $activity): void
    {
        // Implemented in Task 10
    }
}
```

- [ ] **Step 10: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/StravaWebhookTest.php tests/Feature/StravaSyncTest.php
```

Expected: All 7 tests PASS.

- [ ] **Step 11: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/StravaWebhookController.php api/app/Http/Controllers/StravaController.php api/app/Jobs/ api/app/Services/ComplianceScoringService.php api/routes/api.php api/tests/Feature/StravaWebhookTest.php api/tests/Feature/StravaSyncTest.php
git commit -m "feat: add Strava webhook handler, activity sync, and status API"
```

---

### Task 10: Compliance Scoring Service

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:test ComplianceScoringTest
```

**Files:**
- Modify: `api/app/Services/ComplianceScoringService.php`
- Modify (generated): `api/tests/Feature/ComplianceScoringTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/ComplianceScoringTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Enums\RaceStatus;
use App\Enums\TrainingType;
use App\Models\Race;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Services\ComplianceScoringService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ComplianceScoringTest extends TestCase
{
    use LazilyRefreshDatabase;

    private ComplianceScoringService $service;

    protected function setUp(): void
    {
        parent::setUp();
        $this->service = new ComplianceScoringService();
    }

    private function createUserWithPlan(array $dayOverrides = []): array
    {
        $user = User::factory()->create();
        $race = Race::factory()->create([
            'user_id' => $user->id,
            'status' => RaceStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'starts_at' => now()->startOfWeek(),
        ]);
        $day = TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->toDateString(),
            'type' => TrainingType::Tempo,
            'target_km' => 8.0,
            'target_pace_seconds_per_km' => 285, // 4:45/km
            'target_heart_rate_zone' => 3,
        ], $dayOverrides));

        return [$user, $day];
    }

    public function test_perfect_compliance_scores_10(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'moving_time_seconds' => 2280, // exactly 4:45/km
            'average_heartrate' => 160, // zone 3
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertGreaterThanOrEqual(9.0, (float) $result->compliance_score);
    }

    public function test_no_matching_day_creates_no_result(): void
    {
        $user = User::factory()->create();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $this->assertDatabaseCount('training_results', 0);
    }

    public function test_missing_heart_rate_redistributes_weights(): void
    {
        [$user, $day] = $this->createUserWithPlan();

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 8000,
            'moving_time_seconds' => 2280,
            'average_heartrate' => null,
            'start_date' => now(),
        ]);

        $this->service->matchAndScore($user, $activity);

        $result = $day->fresh()->result;
        $this->assertNotNull($result);
        $this->assertNull($result->heart_rate_score);
        $this->assertGreaterThan(0, (float) $result->compliance_score);
    }

    public function test_rest_day_activity_matches_if_no_other_option(): void
    {
        [$user, $day] = $this->createUserWithPlan([
            'type' => TrainingType::Rest,
            'target_km' => null,
            'target_pace_seconds_per_km' => null,
        ]);

        $activity = StravaActivity::factory()->create([
            'user_id' => $user->id,
            'distance_meters' => 5000,
            'moving_time_seconds' => 1800,
            'start_date' => now(),
        ]);

        // Rest days don't get matched
        $this->service->matchAndScore($user, $activity);
        $this->assertNull($day->fresh()->result);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ComplianceScoringTest.php
```

Expected: FAIL — `matchAndScore` is a stub.

- [ ] **Step 3: Implement ComplianceScoringService**

Replace `api/app/Services/ComplianceScoringService.php`:

```php
<?php

namespace App\Services;

use App\Enums\RaceStatus;
use App\Enums\TrainingType;
use App\Models\StravaActivity;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\User;

class ComplianceScoringService
{
    private const NON_MATCHABLE_TYPES = [
        TrainingType::Rest,
        TrainingType::Mobility,
    ];

    public function matchAndScore(User $user, StravaActivity $activity): void
    {
        $day = $this->findMatchingDay($user, $activity);

        if (! $day) {
            return;
        }

        $paceScore = $this->calculatePaceScore($day, $activity);
        $distanceScore = $this->calculateDistanceScore($day, $activity);
        $heartRateScore = $this->calculateHeartRateScore($day, $activity);

        if ($heartRateScore !== null) {
            $overallScore = ($distanceScore * 0.3) + ($paceScore * 0.4) + ($heartRateScore * 0.3);
        } else {
            $overallScore = ($distanceScore * 0.45) + ($paceScore * 0.55);
        }

        TrainingResult::updateOrCreate(
            ['training_day_id' => $day->id],
            [
                'strava_activity_id' => $activity->id,
                'compliance_score' => round($overallScore, 1),
                'actual_km' => $activity->distanceInKm(),
                'actual_pace_seconds_per_km' => $activity->paceSecondsPerKm(),
                'actual_avg_heart_rate' => $activity->average_heartrate,
                'pace_score' => round($paceScore, 1),
                'distance_score' => round($distanceScore, 1),
                'heart_rate_score' => $heartRateScore !== null ? round($heartRateScore, 1) : null,
                'matched_at' => now(),
            ]
        );
    }

    private function findMatchingDay(User $user, StravaActivity $activity): ?TrainingDay
    {
        $activityDate = $activity->start_date->toDateString();

        $candidates = TrainingDay::whereHas('trainingWeek.race', function ($query) use ($user) {
            $query->where('user_id', $user->id)
                  ->where('status', RaceStatus::Active);
        })
        ->whereDoesntHave('result')
        ->whereBetween('date', [
            $activity->start_date->copy()->subDay()->toDateString(),
            $activity->start_date->copy()->addDay()->toDateString(),
        ])
        ->whereNotIn('type', array_map(fn ($t) => $t->value, self::NON_MATCHABLE_TYPES))
        ->get();

        if ($candidates->isEmpty()) {
            return null;
        }

        // Prefer exact date match
        $exactMatch = $candidates->where('date', $activityDate);
        if ($exactMatch->isNotEmpty()) {
            $candidates = $exactMatch;
        }

        // Pick closest by distance target
        return $candidates->sortBy(function ($day) use ($activity) {
            if (! $day->target_km) {
                return PHP_INT_MAX;
            }

            return abs($day->target_km - $activity->distanceInKm());
        })->first();
    }

    private function calculatePaceScore(TrainingDay $day, StravaActivity $activity): float
    {
        if (! $day->target_pace_seconds_per_km) {
            return 7.0; // default for days without pace target
        }

        $actualPace = $activity->paceSecondsPerKm();
        $targetPace = $day->target_pace_seconds_per_km;
        $deviationPercent = abs($actualPace - $targetPace) / $targetPace * 100;

        // 0% deviation = 10, 20%+ deviation = 1
        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 2.2)));
    }

    private function calculateDistanceScore(TrainingDay $day, StravaActivity $activity): float
    {
        if (! $day->target_km) {
            return 7.0;
        }

        $actualKm = $activity->distanceInKm();
        $ratio = $actualKm / $day->target_km;

        // Perfect = 1.0. Score drops for both under and over.
        $deviation = abs(1.0 - $ratio);

        return max(1.0, min(10.0, 10.0 - ($deviation * 15)));
    }

    private function calculateHeartRateScore(TrainingDay $day, StravaActivity $activity): ?float
    {
        if (! $activity->average_heartrate || ! $day->target_heart_rate_zone) {
            return null;
        }

        // Approximate zone boundaries (generic, could be personalized later)
        $zoneMidpoints = [1 => 120, 2 => 140, 3 => 155, 4 => 170, 5 => 185];
        $targetHr = $zoneMidpoints[$day->target_heart_rate_zone] ?? 150;

        $deviationPercent = abs($activity->average_heartrate - $targetHr) / $targetHr * 100;

        return max(1.0, min(10.0, 10.0 - ($deviationPercent / 1.5)));
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/ComplianceScoringTest.php
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Services/ComplianceScoringService.php api/tests/Feature/ComplianceScoringTest.php
git commit -m "feat: implement compliance scoring with activity matching"
```

---

### Task 11: AI Coach Service with Tool Definitions

No artisan generators for service classes — these are plain PHP classes.

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
mkdir -p app/Services/CoachTools
```

**Files:**
- Create: `api/app/Services/CoachChatService.php`
- Create: `api/app/Services/CoachTools/GetStravaSummaryTool.php`
- Create: `api/app/Services/CoachTools/GetCurrentScheduleTool.php`
- Create: `api/app/Services/CoachTools/CreateScheduleTool.php`
- Create: `api/app/Services/CoachTools/ModifyScheduleTool.php`
- Create: `api/app/Services/CoachTools/ProposeAlternativeWeekTool.php`
- Create: `api/app/Services/CoachTools/GetComplianceReportTool.php`
- Create: `api/app/Services/CoachTools/GetRaceReadinessTool.php`

- [ ] **Step 1: Implement GetStravaSummaryTool**

Create `api/app/Services/CoachTools/GetStravaSummaryTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Models\User;

class GetStravaSummaryTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'get_strava_summary',
                'description' => 'Get the user\'s running activity summary from the last 4-8 weeks. Returns average km per week, average pace, long run distances, heart rate trends, and total runs.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'weeks' => [
                            'type' => 'integer',
                            'description' => 'Number of weeks to look back (4-8)',
                        ],
                    ],
                    'required' => [],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        $weeks = min(8, max(4, $args['weeks'] ?? 6));
        $since = now()->subWeeks($weeks);

        $activities = $user->stravaActivities()
            ->where('start_date', '>=', $since)
            ->where('type', 'Run')
            ->orderByDesc('start_date')
            ->get();

        if ($activities->isEmpty()) {
            return ['message' => 'No running activities found in the last ' . $weeks . ' weeks.'];
        }

        $totalKm = $activities->sum(fn ($a) => $a->distanceInKm());
        $totalRuns = $activities->count();
        $avgKmPerWeek = round($totalKm / $weeks, 1);
        $avgPace = (int) $activities->avg(fn ($a) => $a->paceSecondsPerKm());
        $longestRun = $activities->max(fn ($a) => $a->distanceInKm());
        $avgHeartRate = $activities->whereNotNull('average_heartrate')->avg('average_heartrate');

        return [
            'period_weeks' => $weeks,
            'total_runs' => $totalRuns,
            'total_km' => $totalKm,
            'avg_km_per_week' => $avgKmPerWeek,
            'avg_pace_seconds_per_km' => $avgPace,
            'avg_pace_formatted' => floor($avgPace / 60) . ':' . str_pad($avgPace % 60, 2, '0', STR_PAD_LEFT) . '/km',
            'longest_run_km' => $longestRun,
            'avg_heart_rate' => $avgHeartRate ? round($avgHeartRate, 0) : null,
            'runs_per_week' => round($totalRuns / $weeks, 1),
        ];
    }
}
```

- [ ] **Step 2: Implement GetCurrentScheduleTool**

Create `api/app/Services/CoachTools/GetCurrentScheduleTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Enums\RaceStatus;
use App\Models\User;

class GetCurrentScheduleTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'get_current_schedule',
                'description' => 'Get the user\'s active training schedule with all weeks, days, and compliance results.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'race_id' => [
                            'type' => 'integer',
                            'description' => 'Specific race ID. Omit to get the active race.',
                        ],
                    ],
                    'required' => [],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        if (isset($args['race_id'])) {
            $race = $user->races()->find($args['race_id']);
        } else {
            $race = $user->races()->where('status', RaceStatus::Active)->latest()->first();
        }

        if (! $race) {
            return ['message' => 'No active race found.'];
        }

        $weeks = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->orderBy('week_number')
            ->get();

        return [
            'race' => [
                'id' => $race->id,
                'name' => $race->name,
                'distance' => $race->distance->value,
                'goal_time_seconds' => $race->goal_time_seconds,
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
                    'description' => $day->description,
                    'target_km' => $day->target_km,
                    'target_pace_seconds_per_km' => $day->target_pace_seconds_per_km,
                    'compliance_score' => $day->result?->compliance_score,
                    'completed' => $day->result !== null,
                ])->toArray(),
            ])->toArray(),
        ];
    }
}
```

- [ ] **Step 3: Implement CreateScheduleTool**

Create `api/app/Services/CoachTools/CreateScheduleTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Models\User;

class CreateScheduleTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'create_schedule',
                'description' => 'Create a new training schedule for a race. Returns a proposed plan that the user must approve before it is saved. The schedule should be a complete week-by-week training plan with specific sessions for each day.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'race_name' => ['type' => 'string', 'description' => 'Name of the race'],
                        'distance' => ['type' => 'string', 'enum' => ['5k', '10k', 'half_marathon', 'marathon', 'custom']],
                        'goal_time_seconds' => ['type' => 'integer', 'description' => 'Target finish time in seconds'],
                        'race_date' => ['type' => 'string', 'description' => 'Race date in YYYY-MM-DD format'],
                        'schedule' => [
                            'type' => 'object',
                            'description' => 'The complete training schedule',
                            'properties' => [
                                'weeks' => [
                                    'type' => 'array',
                                    'items' => [
                                        'type' => 'object',
                                        'properties' => [
                                            'week_number' => ['type' => 'integer'],
                                            'focus' => ['type' => 'string'],
                                            'total_km' => ['type' => 'number'],
                                            'days' => [
                                                'type' => 'array',
                                                'items' => [
                                                    'type' => 'object',
                                                    'properties' => [
                                                        'day_of_week' => ['type' => 'integer', 'description' => '1=Monday, 7=Sunday'],
                                                        'type' => ['type' => 'string', 'enum' => ['easy', 'tempo', 'interval', 'long_run', 'recovery', 'rest', 'mobility']],
                                                        'title' => ['type' => 'string'],
                                                        'description' => ['type' => 'string'],
                                                        'target_km' => ['type' => 'number', 'description' => 'null for rest days'],
                                                        'target_pace_seconds_per_km' => ['type' => 'integer', 'description' => 'null for rest days'],
                                                        'target_heart_rate_zone' => ['type' => 'integer', 'description' => '1-5, null for rest days'],
                                                    ],
                                                    'required' => ['day_of_week', 'type', 'title'],
                                                ],
                                            ],
                                        ],
                                        'required' => ['week_number', 'focus', 'total_km', 'days'],
                                    ],
                                ],
                            ],
                            'required' => ['weeks'],
                        ],
                    ],
                    'required' => ['race_name', 'distance', 'race_date', 'schedule'],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        // This tool returns a proposal payload — it does NOT save anything.
        // The CoachChatService wraps this in a CoachProposal for user approval.
        return [
            'requires_approval' => true,
            'proposal_type' => 'create_schedule',
            'payload' => $args,
        ];
    }
}
```

- [ ] **Step 4: Implement ModifyScheduleTool**

Create `api/app/Services/CoachTools/ModifyScheduleTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Models\User;

class ModifyScheduleTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'modify_schedule',
                'description' => 'Modify an existing training schedule. Can swap days, change intensity, move rest days, or restructure a week. Returns proposed changes for user approval.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'race_id' => ['type' => 'integer'],
                        'changes' => [
                            'type' => 'array',
                            'items' => [
                                'type' => 'object',
                                'properties' => [
                                    'training_day_id' => ['type' => 'integer', 'description' => 'ID of the day to change'],
                                    'type' => ['type' => 'string', 'enum' => ['easy', 'tempo', 'interval', 'long_run', 'recovery', 'rest', 'mobility']],
                                    'title' => ['type' => 'string'],
                                    'description' => ['type' => 'string'],
                                    'target_km' => ['type' => 'number'],
                                    'target_pace_seconds_per_km' => ['type' => 'integer'],
                                    'target_heart_rate_zone' => ['type' => 'integer'],
                                ],
                                'required' => ['training_day_id'],
                            ],
                        ],
                    ],
                    'required' => ['race_id', 'changes'],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        return [
            'requires_approval' => true,
            'proposal_type' => 'modify_schedule',
            'payload' => $args,
        ];
    }
}
```

- [ ] **Step 5: Implement ProposeAlternativeWeekTool**

Create `api/app/Services/CoachTools/ProposeAlternativeWeekTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Models\User;

class ProposeAlternativeWeekTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'propose_alternative_week',
                'description' => 'Propose an alternative training week to replace an existing week. Returns the proposed replacement for user approval.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'race_id' => ['type' => 'integer'],
                        'week_number' => ['type' => 'integer'],
                        'reason' => ['type' => 'string'],
                        'alternative_days' => [
                            'type' => 'array',
                            'items' => [
                                'type' => 'object',
                                'properties' => [
                                    'day_of_week' => ['type' => 'integer'],
                                    'type' => ['type' => 'string', 'enum' => ['easy', 'tempo', 'interval', 'long_run', 'recovery', 'rest', 'mobility']],
                                    'title' => ['type' => 'string'],
                                    'description' => ['type' => 'string'],
                                    'target_km' => ['type' => 'number'],
                                    'target_pace_seconds_per_km' => ['type' => 'integer'],
                                    'target_heart_rate_zone' => ['type' => 'integer'],
                                ],
                                'required' => ['day_of_week', 'type', 'title'],
                            ],
                        ],
                    ],
                    'required' => ['race_id', 'week_number', 'reason', 'alternative_days'],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        return [
            'requires_approval' => true,
            'proposal_type' => 'alternative_week',
            'payload' => $args,
        ];
    }
}
```

- [ ] **Step 6: Implement GetComplianceReportTool**

Create `api/app/Services/CoachTools/GetComplianceReportTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;

class GetComplianceReportTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'get_compliance_report',
                'description' => 'Get a compliance report showing how well the user has been following their training plan.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'period' => [
                            'type' => 'string',
                            'enum' => ['week', 'month', 'all'],
                            'description' => 'Time period for the report',
                        ],
                    ],
                    'required' => ['period'],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        $race = $user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return ['message' => 'No active race found.'];
        }

        $query = TrainingResult::whereHas('trainingDay.trainingWeek', function ($q) use ($race) {
            $q->where('race_id', $race->id);
        });

        $period = $args['period'] ?? 'all';
        if ($period === 'week') {
            $query->where('matched_at', '>=', now()->startOfWeek());
        } elseif ($period === 'month') {
            $query->where('matched_at', '>=', now()->subMonth());
        }

        $results = $query->get();

        if ($results->isEmpty()) {
            return ['message' => 'No completed training sessions found for this period.'];
        }

        return [
            'period' => $period,
            'total_sessions' => $results->count(),
            'avg_compliance_score' => round($results->avg('compliance_score'), 1),
            'avg_pace_score' => round($results->avg('pace_score'), 1),
            'avg_distance_score' => round($results->avg('distance_score'), 1),
            'avg_heart_rate_score' => round($results->whereNotNull('heart_rate_score')->avg('heart_rate_score'), 1),
            'best_session_score' => $results->max('compliance_score'),
            'lowest_session_score' => $results->min('compliance_score'),
        ];
    }
}
```

- [ ] **Step 7: Implement GetRaceReadinessTool**

Create `api/app/Services/CoachTools/GetRaceReadinessTool.php`:

```php
<?php

namespace App\Services\CoachTools;

use App\Enums\RaceStatus;
use App\Models\TrainingResult;
use App\Models\User;

class GetRaceReadinessTool
{
    public static function definition(): array
    {
        return [
            'type' => 'function',
            'function' => [
                'name' => 'get_race_readiness',
                'description' => 'Assess how ready the user is for their target race based on compliance, training volume, and trends.',
                'parameters' => [
                    'type' => 'object',
                    'properties' => [
                        'race_id' => ['type' => 'integer', 'description' => 'Omit for active race'],
                    ],
                    'required' => [],
                ],
            ],
        ];
    }

    public static function execute(User $user, array $args): array
    {
        if (isset($args['race_id'])) {
            $race = $user->races()->find($args['race_id']);
        } else {
            $race = $user->races()->where('status', RaceStatus::Active)->latest()->first();
        }

        if (! $race) {
            return ['message' => 'No active race found.'];
        }

        $totalDays = $race->trainingWeeks()->withCount('trainingDays')->get()->sum('training_days_count');
        $completedResults = TrainingResult::whereHas('trainingDay.trainingWeek', function ($q) use ($race) {
            $q->where('race_id', $race->id);
        })->get();

        $completionRate = $totalDays > 0 ? round($completedResults->count() / $totalDays * 100, 1) : 0;
        $avgCompliance = $completedResults->avg('compliance_score') ?? 0;

        // Recent trend: compare last 2 weeks to 2 weeks before that
        $recentResults = $completedResults->where('matched_at', '>=', now()->subWeeks(2));
        $olderResults = $completedResults->where('matched_at', '<', now()->subWeeks(2))
            ->where('matched_at', '>=', now()->subWeeks(4));

        $trend = 'stable';
        if ($recentResults->avg('compliance_score') && $olderResults->avg('compliance_score')) {
            $diff = $recentResults->avg('compliance_score') - $olderResults->avg('compliance_score');
            if ($diff > 0.5) {
                $trend = 'improving';
            } elseif ($diff < -0.5) {
                $trend = 'declining';
            }
        }

        return [
            'race' => $race->name,
            'race_date' => $race->race_date->toDateString(),
            'weeks_until_race' => $race->weeksUntilRace(),
            'completion_rate_percent' => $completionRate,
            'avg_compliance_score' => round($avgCompliance, 1),
            'total_sessions_completed' => $completedResults->count(),
            'total_sessions_planned' => $totalDays,
            'recent_trend' => $trend,
        ];
    }
}
```

- [ ] **Step 8: Implement CoachChatService**

Create `api/app/Services/CoachChatService.php`:

```php
<?php

namespace App\Services;

use App\Enums\MessageRole;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachConversation;
use App\Models\CoachMessage;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\CoachTools\CreateScheduleTool;
use App\Services\CoachTools\GetComplianceReportTool;
use App\Services\CoachTools\GetCurrentScheduleTool;
use App\Services\CoachTools\GetRaceReadinessTool;
use App\Services\CoachTools\GetStravaSummaryTool;
use App\Services\CoachTools\ModifyScheduleTool;
use App\Services\CoachTools\ProposeAlternativeWeekTool;
use OpenAI\Laravel\Facades\OpenAI;

class CoachChatService
{
    private const TOOL_MAP = [
        'get_strava_summary' => GetStravaSummaryTool::class,
        'get_current_schedule' => GetCurrentScheduleTool::class,
        'create_schedule' => CreateScheduleTool::class,
        'modify_schedule' => ModifyScheduleTool::class,
        'propose_alternative_week' => ProposeAlternativeWeekTool::class,
        'get_compliance_report' => GetComplianceReportTool::class,
        'get_race_readiness' => GetRaceReadinessTool::class,
    ];

    public function sendMessage(User $user, CoachConversation $conversation, string $content): array
    {
        // Store user message
        $userMessage = $conversation->messages()->create([
            'role' => MessageRole::User,
            'content' => $content,
        ]);

        // Build context and call AI
        $messages = $this->buildMessages($user, $conversation);
        $tools = $this->buildToolDefinitions();

        $response = $this->callAI($user, $messages, $tools);

        // Store assistant message
        $assistantMessage = $conversation->messages()->create([
            'role' => MessageRole::Assistant,
            'content' => $response['content'],
            'context_snapshot' => $response['context_snapshot'] ?? null,
        ]);

        // If the AI used a tool that requires approval, create a proposal
        $proposal = null;
        if (isset($response['proposal'])) {
            $proposal = CoachProposal::create([
                'coach_message_id' => $assistantMessage->id,
                'type' => ProposalType::from($response['proposal']['proposal_type']),
                'payload' => $response['proposal']['payload'],
                'status' => ProposalStatus::Pending,
            ]);
        }

        return [
            'message' => $assistantMessage,
            'proposal' => $proposal,
        ];
    }

    private function buildMessages(User $user, CoachConversation $conversation): array
    {
        $systemPrompt = $this->buildSystemPrompt($user);

        $messages = [
            ['role' => 'system', 'content' => $systemPrompt],
        ];

        foreach ($conversation->messages()->orderBy('created_at')->get() as $msg) {
            $messages[] = [
                'role' => $msg->role->value,
                'content' => $msg->content,
            ];
        }

        return $messages;
    }

    private function buildSystemPrompt(User $user): string
    {
        $style = $user->coach_style?->value ?? 'balanced';
        $level = $user->level?->value ?? 'intermediate';

        return <<<PROMPT
You are RunCoach, a personal running coach AI. You are {$style} in your coaching style.

The runner you are coaching is at {$level} level with a weekly capacity of {$user->weekly_km_capacity} km.

Your capabilities:
- You can view the runner's Strava activity history and analyze their fitness
- You can create training schedules for upcoming races
- You can modify existing schedules (swap days, adjust intensity, move rest days)
- You can propose alternative training weeks
- You can analyze compliance and race readiness

Important rules:
- Always use your tools to access data — never invent statistics or training data
- When creating or modifying schedules, always use the appropriate tool — the user must approve changes
- Ground all advice in the runner's actual data
- Be concise but helpful. Use the runner's actual numbers when giving advice.
- For schedule creation: design plans using periodization, the 80/20 rule (80% easy, 20% hard), and progressive overload principles
PROMPT;
    }

    private function buildToolDefinitions(): array
    {
        return array_map(
            fn ($toolClass) => $toolClass::definition(),
            self::TOOL_MAP
        );
    }

    private function callAI(User $user, array $messages, array $tools): array
    {
        $proposal = null;
        $maxIterations = 5; // prevent infinite tool-calling loops

        for ($i = 0; $i < $maxIterations; $i++) {
            $response = OpenAI::chat()->create([
                'model' => config('services.openai.model', 'gpt-4o'),
                'messages' => $messages,
                'tools' => $tools,
            ]);

            $choice = $response->choices[0];

            if ($choice->finishReason === 'stop') {
                return [
                    'content' => $choice->message->content,
                    'proposal' => $proposal,
                    'context_snapshot' => ['tools_called' => $i > 0],
                ];
            }

            if ($choice->finishReason === 'tool_calls') {
                // Add the assistant message with tool calls
                $messages[] = $choice->message->toArray();

                foreach ($choice->message->toolCalls as $toolCall) {
                    $toolName = $toolCall->function->name;
                    $toolArgs = json_decode($toolCall->function->arguments, true) ?? [];

                    $toolClass = self::TOOL_MAP[$toolName] ?? null;
                    if (! $toolClass) {
                        $toolResult = ['error' => "Unknown tool: {$toolName}"];
                    } else {
                        $toolResult = $toolClass::execute($user, $toolArgs);
                    }

                    // Check if this tool result is a proposal
                    if (isset($toolResult['requires_approval']) && $toolResult['requires_approval']) {
                        $proposal = $toolResult;
                    }

                    $messages[] = [
                        'role' => 'tool',
                        'tool_call_id' => $toolCall->id,
                        'content' => json_encode($toolResult),
                    ];
                }
            }
        }

        return [
            'content' => 'I ran into an issue processing your request. Could you try rephrasing?',
            'proposal' => $proposal,
        ];
    }

    public function applyProposal(CoachProposal $proposal): void
    {
        $payload = $proposal->payload;
        $user = $proposal->message->conversation->user;

        match ($proposal->type) {
            ProposalType::CreateSchedule => $this->applyCreateSchedule($user, $payload),
            ProposalType::ModifySchedule => $this->applyModifySchedule($user, $payload),
            ProposalType::AlternativeWeek => $this->applyAlternativeWeek($user, $payload),
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
            'status' => \App\Enums\RaceStatus::Active,
        ]);

        foreach ($payload['schedule']['weeks'] as $weekData) {
            $startsAt = \Carbon\Carbon::parse($payload['race_date'])
                ->subWeeks(count($payload['schedule']['weeks']) - $weekData['week_number'] + 1)
                ->startOfWeek();

            $week = $race->trainingWeeks()->create([
                'week_number' => $weekData['week_number'],
                'starts_at' => $startsAt,
                'total_km' => $weekData['total_km'],
                'focus' => $weekData['focus'],
            ]);

            foreach ($weekData['days'] as $dayData) {
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
        foreach ($payload['changes'] as $change) {
            $day = \App\Models\TrainingDay::whereHas('trainingWeek.race', function ($q) use ($user) {
                $q->where('user_id', $user->id);
            })->find($change['training_day_id']);

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

        // Delete existing days for this week (that don't have results)
        $week->trainingDays()->whereDoesntHave('result')->delete();

        foreach ($payload['alternative_days'] as $dayData) {
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

- [ ] **Step 9: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Services/CoachChatService.php api/app/Services/CoachTools/
git commit -m "feat: add AI coach service with 7 tool definitions and proposal system"
```

---

### Task 12: Coach Chat API + Proposal Endpoints

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller CoachController
php artisan make:request SendMessageRequest
php artisan make:test CoachChatTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/CoachController.php`
- Modify (generated): `api/app/Http/Requests/SendMessageRequest.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/CoachChatTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/CoachChatTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachConversation;
use App\Models\CoachMessage;
use App\Models\CoachProposal;
use App\Models\Race;
use App\Models\User;
use App\Services\CoachChatService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
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

    public function test_list_conversations(): void
    {
        [$user, $headers] = $this->authUser();
        CoachConversation::factory()->count(2)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/v1/coach/conversations', $headers);

        $response->assertOk();
        $this->assertCount(2, $response->json('data'));
    }

    public function test_create_conversation(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Training Chat',
        ], $headers);

        $response->assertCreated();
        $this->assertDatabaseHas('coach_conversations', [
            'user_id' => $user->id,
            'title' => 'Training Chat',
        ]);
    }

    public function test_get_conversation_messages(): void
    {
        [$user, $headers] = $this->authUser();
        $conversation = CoachConversation::factory()->create(['user_id' => $user->id]);
        CoachMessage::factory()->count(3)->create([
            'coach_conversation_id' => $conversation->id,
        ]);

        $response = $this->getJson("/api/v1/coach/conversations/{$conversation->id}", $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data.messages'));
    }

    public function test_send_message(): void
    {
        [$user, $headers] = $this->authUser();
        $conversation = CoachConversation::factory()->create(['user_id' => $user->id]);

        // Mock the CoachChatService to avoid real OpenAI calls
        $mock = Mockery::mock(CoachChatService::class);
        $mock->shouldReceive('sendMessage')
            ->once()
            ->andReturn([
                'message' => CoachMessage::factory()->create([
                    'coach_conversation_id' => $conversation->id,
                    'role' => 'assistant',
                    'content' => 'I can see you have been running well!',
                ]),
                'proposal' => null,
            ]);
        $this->app->instance(CoachChatService::class, $mock);

        $response = $this->postJson("/api/v1/coach/conversations/{$conversation->id}/messages", [
            'content' => 'How is my training going?',
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('data.message.content', 'I can see you have been running well!');
    }

    public function test_accept_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $conversation = CoachConversation::factory()->create(['user_id' => $user->id]);
        $message = CoachMessage::factory()->create([
            'coach_conversation_id' => $conversation->id,
        ]);
        $proposal = CoachProposal::factory()->create([
            'coach_message_id' => $message->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => [
                'race_name' => 'Test Race',
                'distance' => 'half_marathon',
                'race_date' => now()->addMonths(3)->toDateString(),
                'schedule' => ['weeks' => []],
            ],
        ]);

        $mock = Mockery::mock(CoachChatService::class);
        $mock->shouldReceive('applyProposal')->once();
        $this->app->instance(CoachChatService::class, $mock);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/accept", [], $headers);

        $response->assertOk();
    }

    public function test_reject_proposal(): void
    {
        [$user, $headers] = $this->authUser();
        $conversation = CoachConversation::factory()->create(['user_id' => $user->id]);
        $message = CoachMessage::factory()->create([
            'coach_conversation_id' => $conversation->id,
        ]);
        $proposal = CoachProposal::factory()->create([
            'coach_message_id' => $message->id,
        ]);

        $response = $this->postJson("/api/v1/coach/proposals/{$proposal->id}/reject", [], $headers);

        $response->assertOk();
        $this->assertSame(ProposalStatus::Rejected, $proposal->fresh()->status);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/CoachChatTest.php
```

Expected: FAIL.

- [ ] **Step 3: Implement SendMessageRequest**

Create `api/app/Http/Requests/SendMessageRequest.php`:

```php
<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SendMessageRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'content' => ['required', 'string', 'max:5000'],
        ];
    }
}
```

- [ ] **Step 4: Implement CoachController**

Create `api/app/Http/Controllers/CoachController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Enums\ProposalStatus;
use App\Http\Requests\SendMessageRequest;
use App\Models\CoachConversation;
use App\Models\CoachProposal;
use App\Services\CoachChatService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class CoachController extends Controller
{
    public function __construct(
        private CoachChatService $coachChatService,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $conversations = $request->user()->coachConversations()
            ->orderByDesc('updated_at')
            ->get();

        return response()->json(['data' => $conversations]);
    }

    public function store(Request $request): JsonResponse
    {
        $request->validate(['title' => 'sometimes|string|max:255']);

        $conversation = $request->user()->coachConversations()->create([
            'title' => $request->input('title', 'New Chat'),
        ]);

        return response()->json(['data' => $conversation], 201);
    }

    public function show(Request $request, int $conversationId): JsonResponse
    {
        $conversation = $request->user()->coachConversations()
            ->with('messages.proposal')
            ->findOrFail($conversationId);

        return response()->json(['data' => $conversation]);
    }

    public function sendMessage(SendMessageRequest $request, int $conversationId): JsonResponse
    {
        $conversation = $request->user()->coachConversations()->findOrFail($conversationId);

        $result = $this->coachChatService->sendMessage(
            $request->user(),
            $conversation,
            $request->validated()['content'],
        );

        return response()->json([
            'data' => [
                'message' => $result['message'],
                'proposal' => $result['proposal'],
            ],
        ]);
    }

    public function acceptProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::whereHas('message.conversation', function ($q) use ($request) {
            $q->where('user_id', $request->user()->id);
        })->where('status', ProposalStatus::Pending)->findOrFail($proposalId);

        $this->coachChatService->applyProposal($proposal);

        return response()->json(['message' => 'Proposal accepted and applied']);
    }

    public function rejectProposal(Request $request, int $proposalId): JsonResponse
    {
        $proposal = CoachProposal::whereHas('message.conversation', function ($q) use ($request) {
            $q->where('user_id', $request->user()->id);
        })->where('status', ProposalStatus::Pending)->findOrFail($proposalId);

        $proposal->update(['status' => ProposalStatus::Rejected]);

        return response()->json(['message' => 'Proposal rejected']);
    }
}
```

- [ ] **Step 5: Add coach routes to api.php**

Add inside the `auth:sanctum` middleware group in `api/routes/api.php`:

```php
Route::get('coach/conversations', [CoachController::class, 'index']);
Route::post('coach/conversations', [CoachController::class, 'store']);
Route::get('coach/conversations/{conversation}', [CoachController::class, 'show']);
Route::post('coach/conversations/{conversation}/messages', [CoachController::class, 'sendMessage']);
Route::post('coach/proposals/{proposal}/accept', [CoachController::class, 'acceptProposal']);
Route::post('coach/proposals/{proposal}/reject', [CoachController::class, 'rejectProposal']);
```

Add the import:

```php
use App\Http\Controllers\CoachController;
```

- [ ] **Step 6: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/CoachChatTest.php
```

Expected: All 6 tests PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/CoachController.php api/app/Http/Requests/SendMessageRequest.php api/routes/api.php api/tests/Feature/CoachChatTest.php
git commit -m "feat: add coach chat API with conversation, messaging, and proposal endpoints"
```

---

### Task 13: Dashboard Aggregate API

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:controller DashboardController --invokable
php artisan make:test DashboardTest
```

**Files:**
- Modify (generated): `api/app/Http/Controllers/DashboardController.php`
- Modify: `api/routes/api.php`
- Modify (generated): `api/tests/Feature/DashboardTest.php`

- [ ] **Step 1: Write failing test**

Create `api/tests/Feature/DashboardTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Enums\RaceStatus;
use App\Enums\TrainingType;
use App\Models\Race;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_dashboard_returns_weekly_summary(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create([
            'user_id' => $user->id,
            'status' => RaceStatus::Active,
        ]);
        $week = TrainingWeek::factory()->create([
            'race_id' => $race->id,
            'starts_at' => now()->startOfWeek(),
            'total_km' => 42.5,
        ]);

        $completedDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->subDay(),
            'type' => TrainingType::Easy,
        ]);
        TrainingResult::factory()->create([
            'training_day_id' => $completedDay->id,
            'actual_km' => 5.0,
            'compliance_score' => 8.5,
        ]);

        $nextDay = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->addDay(),
            'type' => TrainingType::Tempo,
        ]);

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $response->assertJsonStructure([
            'weekly_summary' => ['total_km_planned', 'total_km_completed', 'compliance_avg'],
            'next_training',
            'active_race',
        ]);
    }

    public function test_dashboard_with_no_active_race(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/dashboard', $headers);

        $response->assertOk();
        $this->assertNull($response->json('active_race'));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/DashboardTest.php
```

Expected: FAIL.

- [ ] **Step 3: Implement DashboardController**

Create `api/app/Http/Controllers/DashboardController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Enums\RaceStatus;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class DashboardController extends Controller
{
    public function __invoke(Request $request): JsonResponse
    {
        $user = $request->user();
        $race = $user->races()->where('status', RaceStatus::Active)->latest()->first();

        if (! $race) {
            return response()->json([
                'weekly_summary' => null,
                'next_training' => null,
                'active_race' => null,
                'coach_insight' => null,
            ]);
        }

        $currentWeek = $race->trainingWeeks()
            ->with('trainingDays.result')
            ->where('starts_at', '<=', now())
            ->orderByDesc('starts_at')
            ->first();

        $weeklySummary = null;
        $nextTraining = null;
        $coachInsight = null;

        if ($currentWeek) {
            $completedResults = $currentWeek->trainingDays
                ->filter(fn ($day) => $day->result !== null);

            $totalKmCompleted = $completedResults->sum(fn ($day) => $day->result->actual_km);
            $avgCompliance = $completedResults->count() > 0
                ? round($completedResults->avg(fn ($day) => $day->result->compliance_score), 1)
                : null;

            $weeklySummary = [
                'total_km_planned' => $currentWeek->total_km,
                'total_km_completed' => $totalKmCompleted,
                'sessions_completed' => $completedResults->count(),
                'sessions_total' => $currentWeek->trainingDays->count(),
                'compliance_avg' => $avgCompliance,
            ];

            $nextTraining = $currentWeek->trainingDays
                ->where('date', '>=', now()->toDateString())
                ->whereNull('result')
                ->sortBy('date')
                ->first();

            $coachInsight = $currentWeek->coach_notes;
        }

        return response()->json([
            'weekly_summary' => $weeklySummary,
            'next_training' => $nextTraining,
            'active_race' => [
                'id' => $race->id,
                'name' => $race->name,
                'distance' => $race->distance,
                'race_date' => $race->race_date->toDateString(),
                'weeks_until_race' => $race->weeksUntilRace(),
            ],
            'coach_insight' => $coachInsight,
        ]);
    }
}
```

- [ ] **Step 4: Add dashboard route to api.php**

Add inside the `auth:sanctum` middleware group in `api/routes/api.php`:

```php
Route::get('dashboard', DashboardController::class);
```

Add the import:

```php
use App\Http\Controllers\DashboardController;
```

- [ ] **Step 5: Run tests to verify they pass**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test tests/Feature/DashboardTest.php
```

Expected: All 2 tests PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Http/Controllers/DashboardController.php api/routes/api.php api/tests/Feature/DashboardTest.php
git commit -m "feat: add dashboard aggregate API endpoint"
```

---

### Task 14: AI Feedback Jobs

**Generate scaffolding:**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan make:job GenerateActivityFeedback
php artisan make:job GenerateWeeklyInsight
```

**Files:**
- Modify (generated): `api/app/Jobs/GenerateActivityFeedback.php`
- Modify (generated): `api/app/Jobs/GenerateWeeklyInsight.php`
- Modify: `api/app/Jobs/ProcessStravaActivity.php` (dispatch feedback job after scoring)

- [ ] **Step 1: Implement GenerateActivityFeedback job**

Create `api/app/Jobs/GenerateActivityFeedback.php`:

```php
<?php

namespace App\Jobs;

use App\Models\TrainingResult;
use OpenAI\Laravel\Facades\OpenAI;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateActivityFeedback implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $trainingResultId,
    ) {}

    public function handle(): void
    {
        $result = TrainingResult::with('trainingDay', 'stravaActivity')->find($this->trainingResultId);

        if (! $result || $result->ai_feedback) {
            return;
        }

        $day = $result->trainingDay;
        $context = "Training: {$day->title} ({$day->type->value}). "
            . "Target: {$day->target_km}km at {$day->target_pace_seconds_per_km}s/km. "
            . "Actual: {$result->actual_km}km at {$result->actual_pace_seconds_per_km}s/km. "
            . "Compliance score: {$result->compliance_score}/10. "
            . "Pace score: {$result->pace_score}, Distance score: {$result->distance_score}.";

        if ($result->actual_avg_heart_rate) {
            $context .= " Avg HR: {$result->actual_avg_heart_rate}.";
        }

        $response = OpenAI::chat()->create([
            'model' => config('services.openai.model', 'gpt-4o'),
            'messages' => [
                ['role' => 'system', 'content' => 'You are a running coach giving brief post-run feedback. Be specific, constructive, and concise (2-3 sentences max). Reference the actual numbers.'],
                ['role' => 'user', 'content' => $context],
            ],
        ]);

        $result->update([
            'ai_feedback' => $response->choices[0]->message->content,
        ]);
    }
}
```

- [ ] **Step 2: Implement GenerateWeeklyInsight job**

Create `api/app/Jobs/GenerateWeeklyInsight.php`:

```php
<?php

namespace App\Jobs;

use App\Models\TrainingWeek;
use OpenAI\Laravel\Facades\OpenAI;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;

class GenerateWeeklyInsight implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public int $trainingWeekId,
    ) {}

    public function handle(): void
    {
        $week = TrainingWeek::with('trainingDays.result', 'race')->find($this->trainingWeekId);

        if (! $week) {
            return;
        }

        $completedDays = $week->trainingDays->filter(fn ($d) => $d->result !== null);

        if ($completedDays->isEmpty()) {
            return;
        }

        $avgScore = round($completedDays->avg(fn ($d) => $d->result->compliance_score), 1);
        $totalKm = $completedDays->sum(fn ($d) => $d->result->actual_km);
        $sessionsCompleted = $completedDays->count();
        $sessionsTotal = $week->trainingDays->count();

        $context = "Week {$week->week_number} ({$week->focus}) for {$week->race->name}. "
            . "Completed {$sessionsCompleted}/{$sessionsTotal} sessions, {$totalKm}km total. "
            . "Average compliance: {$avgScore}/10. "
            . "Planned total: {$week->total_km}km.";

        $response = OpenAI::chat()->create([
            'model' => config('services.openai.model', 'gpt-4o'),
            'messages' => [
                ['role' => 'system', 'content' => 'You are a running coach giving a brief weekly insight. Be encouraging, specific, and concise (2-3 sentences max). Reference the runner\'s actual numbers and give one forward-looking tip.'],
                ['role' => 'user', 'content' => $context],
            ],
        ]);

        $week->update([
            'coach_notes' => $response->choices[0]->message->content,
        ]);
    }
}
```

- [ ] **Step 3: Update ProcessStravaActivity to dispatch feedback job**

Add at the end of the `handle()` method in `api/app/Jobs/ProcessStravaActivity.php`, after the `matchAndScore` call:

```php
$result = $activity->fresh()->trainingResult;
if ($result) {
    GenerateActivityFeedback::dispatch($result->id);
    GenerateWeeklyInsight::dispatch($result->trainingDay->training_week_id);
}
```

Add the import at the top:

```php
use App\Jobs\GenerateActivityFeedback;
use App\Jobs\GenerateWeeklyInsight;
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/app/Jobs/
git commit -m "feat: add AI feedback generation jobs for activities and weekly insights"
```

---

### Task 15: Complete API Routes File + Run Full Test Suite

**Files:**
- Modify: `api/routes/api.php` (verify completeness)

- [ ] **Step 1: Verify the complete routes file**

The final `api/routes/api.php` should contain all routes. Read it and verify it includes every endpoint from the spec:

```php
<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\CoachController;
use App\Http\Controllers\DashboardController;
use App\Http\Controllers\ProfileController;
use App\Http\Controllers\RaceController;
use App\Http\Controllers\StravaController;
use App\Http\Controllers\StravaWebhookController;
use App\Http\Controllers\TrainingScheduleController;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    // Auth (public)
    Route::get('auth/strava/redirect', [AuthController::class, 'redirect']);
    Route::get('auth/strava/callback', [AuthController::class, 'callback']);

    // Strava webhook (public, Strava-signed)
    Route::get('webhook/strava', [StravaWebhookController::class, 'verify']);
    Route::post('webhook/strava', [StravaWebhookController::class, 'handle']);

    // Authenticated routes
    Route::middleware('auth:sanctum')->group(function () {
        // Auth
        Route::post('auth/logout', [AuthController::class, 'logout']);

        // Profile
        Route::get('profile', [ProfileController::class, 'show']);
        Route::put('profile', [ProfileController::class, 'update']);
        Route::post('profile/onboarding', [ProfileController::class, 'onboarding']);

        // Dashboard
        Route::get('dashboard', DashboardController::class);

        // Races
        Route::apiResource('races', RaceController::class);

        // Training Schedule
        Route::get('races/{race}/schedule', [TrainingScheduleController::class, 'schedule']);
        Route::get('races/{race}/schedule/current', [TrainingScheduleController::class, 'currentWeek']);
        Route::get('training-days/{day}', [TrainingScheduleController::class, 'showDay']);
        Route::get('training-days/{day}/result', [TrainingScheduleController::class, 'dayResult']);

        // Strava
        Route::post('strava/sync', [StravaController::class, 'sync']);
        Route::get('strava/activities', [StravaController::class, 'activities']);
        Route::get('strava/status', [StravaController::class, 'status']);

        // AI Coach
        Route::get('coach/conversations', [CoachController::class, 'index']);
        Route::post('coach/conversations', [CoachController::class, 'store']);
        Route::get('coach/conversations/{conversation}', [CoachController::class, 'show']);
        Route::post('coach/conversations/{conversation}/messages', [CoachController::class, 'sendMessage']);
        Route::post('coach/proposals/{proposal}/accept', [CoachController::class, 'acceptProposal']);
        Route::post('coach/proposals/{proposal}/reject', [CoachController::class, 'rejectProposal']);
    });
});
```

- [ ] **Step 2: Run the full test suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test
```

Expected: All tests across all test files PASS.

- [ ] **Step 3: Verify route list**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan route:list --path=api/v1
```

Expected: 22 routes listed, matching the spec.

- [ ] **Step 4: Final commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api/routes/api.php
git commit -m "feat: finalize API routes and verify full test suite"
```

---

## Summary

| Task | What it builds | Tests |
|---|---|---|
| 1 | Laravel project scaffolding | Boot check |
| 2 | 8 enum definitions | — |
| 3 | 10 database migrations | Migration run |
| 4 | 10 Eloquent models + 10 factories | 9 relationship tests |
| 5 | Strava OAuth + StravaSyncService | 4 auth tests |
| 6 | Profile get/update/onboarding | 4 profile tests |
| 7 | Race CRUD | 6 race tests |
| 8 | Training schedule read endpoints | 5 schedule tests |
| 9 | Strava webhook + activity sync jobs | 7 webhook/sync tests |
| 10 | Compliance scoring service | 4 compliance tests |
| 11 | AI coach service + 7 tool definitions | — |
| 12 | Coach chat API + proposal endpoints | 6 coach tests |
| 13 | Dashboard aggregate API | 2 dashboard tests |
| 14 | AI feedback generation jobs | — |
| 15 | Route verification + full suite run | Full suite |

**Total: 15 tasks, ~47 tests, 22 API endpoints**

**Next plan:** Flutter mobile app (Plan 2 of 2) — will cover project setup, Riverpod providers, Retrofit API clients, all 15 screens, and the design system matching the warm earth-tone aesthetic.
