# Async Plan Generation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Move onboarding plan generation off the synchronous HTTP request and onto the queue so the user can close/reopen the app mid-generation without losing progress, and so the Laravel Cloud edge timeout (which currently kills 100s+ requests after the worker has finished) stops causing visible "Plan generation failed" errors.

**Architecture:** A new `plan_generations` table tracks the lifecycle (`queued → processing → completed | failed`). `POST /onboarding/generate-plan` now creates a row, dispatches `GeneratePlan` job, and returns 202 immediately. The job runs the existing `OnboardingPlanGeneratorService` inside the worker. The Flutter generating screen polls `GET /onboarding/plan-generation/latest` every 3s. The `/me` and `/auth/strava/callback` responses include the latest user-actionable plan generation so the GoRouter redirect can resume the loading screen on cold start. A read-time watchdog auto-fails any row that has been stuck in `queued`/`processing` for >10 minutes (covers the case where the worker dies entirely without firing the `failed()` callback).

**Tech Stack:** Laravel 13 (database queue, FormRequest, Eloquent), MySQL, PHPUnit 12 + LazilyRefreshDatabase, Flutter (Riverpod codegen, Freezed 3.x, Dio + Retrofit, GoRouter).

---

## File Structure

**Backend (api/)**

| Status | Path | Responsibility |
|---|---|---|
| New | `app/Enums/PlanGenerationStatus.php` | `queued`, `processing`, `completed`, `failed` |
| New | `database/migrations/2026_04_25_000001_create_plan_generations_table.php` | Table schema |
| New | `app/Models/PlanGeneration.php` | Eloquent model + relations |
| New | `database/factories/PlanGenerationFactory.php` | Test factory |
| New | `app/Jobs/GeneratePlan.php` | Queued job: marks processing → calls service → marks completed/failed |
| Modify | `app/Models/User.php` | Adds `planGenerations()` relation + `pendingPlanGeneration()` watchdog method |
| Modify | `app/Http/Controllers/OnboardingController.php` | `generatePlan` returns 202; new `latestPlanGeneration` endpoint |
| Modify | `app/Http/Controllers/ProfileController.php` | `show` includes `pending_plan_generation` |
| Modify | `app/Http/Controllers/AuthController.php` | `callback` + `devLogin` include `pending_plan_generation` |
| Modify | `routes/api.php` | Adds `GET /onboarding/plan-generation/latest` |
| New | `tests/Feature/PlanGenerationLifecycleTest.php` | POST→job, GET latest, watchdog, /me payload |
| New | `tests/Feature/Jobs/GeneratePlanJobTest.php` | Job success path, failure path |
| Modify | `tests/Feature/OnboardingGeneratePlanTest.php` | Updated assertions for async behavior |

**Flutter (app/)**

| Status | Path | Responsibility |
|---|---|---|
| New | `lib/features/onboarding/models/plan_generation.dart` | Freezed `PlanGeneration` model + `PlanGenerationStatus` enum |
| Modify | `lib/features/auth/models/user.dart` | Adds `pendingPlanGeneration` field |
| Modify | `lib/features/onboarding/data/onboarding_api.dart` | `generatePlanCall` returns `PlanGeneration`; new `pollPlanGenerationCall` |
| Modify | `lib/features/onboarding/screens/onboarding_generating_screen.dart` | Poll instead of awaiting POST; reads pending generation from auth state on mount |
| Modify | `lib/router/app_router.dart` | Redirect rule: if user has pending plan generation, route to `/onboarding/generating` (or `/coach/chat/{cid}` if completed) |

**Ops**

- Laravel Cloud worker config: bump `--timeout=120` → `--timeout=600`. Done in the Laravel Cloud UI, not in repo. Documented as the final task.

---

## Behaviour reference (router redirect logic)

This is the contract the Flutter router consumes from `user.pendingPlanGeneration`. The backend `pendingPlanGeneration()` method returns null when no redirect is needed:

| Backend state | `pending_plan_generation` field | Flutter routing |
|---|---|---|
| No row exists | `null` | Existing behavior (`/onboarding` if `!hasCompletedOnboarding`) |
| Latest row `queued` or `processing` | `{id, status, ...}` | Force-route to `/onboarding/generating` |
| Latest row `failed` | `{id, status:'failed', error_message, ...}` | Force-route to `/onboarding/generating` (which renders error) |
| Latest row `completed`, proposal still `pending` | `{id, status:'completed', conversation_id, proposal_id, ...}` | Force-route to `/coach/chat/{conversation_id}` |
| Latest row `completed`, proposal accepted/rejected | `null` | No redirect (user has moved on; existing rules apply) |

---

## Task 1: Create `PlanGenerationStatus` enum

**Files:**
- Create: `api/app/Enums/PlanGenerationStatus.php`

- [ ] **Step 1: Write the file**

```php
<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum PlanGenerationStatus: string
{
    use HasValues;

    case Queued = 'queued';
    case Processing = 'processing';
    case Completed = 'completed';
    case Failed = 'failed';
}
```

- [ ] **Step 2: Confirm syntax with pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`
Expected: no errors

- [ ] **Step 3: Commit**

```bash
git add api/app/Enums/PlanGenerationStatus.php
git commit -m "feat(api): add PlanGenerationStatus enum"
```

---

## Task 2: Create `plan_generations` migration

**Files:**
- Create: `api/database/migrations/2026_04_25_000001_create_plan_generations_table.php`

- [ ] **Step 1: Write the migration**

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('plan_generations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('status')->default('queued');
            $table->json('payload');
            $table->string('conversation_id', 36)->nullable();
            $table->foreignId('proposal_id')
                ->nullable()
                ->constrained('coach_proposals')
                ->nullOnDelete();
            $table->text('error_message')->nullable();
            $table->timestamp('started_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status', 'created_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('plan_generations');
    }
};
```

- [ ] **Step 2: Run migrate:fresh and confirm**

Run: `cd api && php artisan migrate:fresh --seed`
Expected: ends with `INFO  Seeding database.` and no error mentioning `plan_generations`.

- [ ] **Step 3: Commit**

```bash
git add api/database/migrations/2026_04_25_000001_create_plan_generations_table.php
git commit -m "feat(api): add plan_generations table"
```

---

## Task 3: Create `PlanGeneration` model + factory

**Files:**
- Create: `api/app/Models/PlanGeneration.php`
- Create: `api/database/factories/PlanGenerationFactory.php`

- [ ] **Step 1: Write the model**

```php
<?php

namespace App\Models;

use App\Enums\PlanGenerationStatus;
use Database\Factories\PlanGenerationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'status',
    'payload',
    'conversation_id',
    'proposal_id',
    'error_message',
    'started_at',
    'completed_at',
])]
class PlanGeneration extends Model
{
    /** @use HasFactory<PlanGenerationFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'status' => PlanGenerationStatus::class,
            'payload' => 'array',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function proposal(): BelongsTo
    {
        return $this->belongsTo(CoachProposal::class, 'proposal_id');
    }

    public function isInFlight(): bool
    {
        return in_array($this->status, [
            PlanGenerationStatus::Queued,
            PlanGenerationStatus::Processing,
        ], true);
    }
}
```

- [ ] **Step 2: Write the factory**

```php
<?php

namespace Database\Factories;

use App\Enums\PlanGenerationStatus;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<PlanGeneration>
 */
class PlanGenerationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
            'conversation_id' => null,
            'proposal_id' => null,
            'error_message' => null,
            'started_at' => null,
            'completed_at' => null,
        ];
    }
}
```

- [ ] **Step 3: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`
Expected: no errors

- [ ] **Step 4: Smoke-test factory**

Run: `cd api && php artisan tinker --execute 'echo App\Models\PlanGeneration::factory()->make()->status->value;'`
Expected: `queued`

- [ ] **Step 5: Commit**

```bash
git add api/app/Models/PlanGeneration.php api/database/factories/PlanGenerationFactory.php
git commit -m "feat(api): add PlanGeneration model + factory"
```

---

## Task 4: Add `pendingPlanGeneration()` method to `User` (with read-time watchdog)

**Files:**
- Modify: `api/app/Models/User.php`
- Create: `api/tests/Feature/Models/UserPendingPlanGenerationTest.php`

The watchdog: when the latest in-flight row's `started_at ?? created_at` is older than 10 minutes, mark it `failed` in place with `error_message = 'Generation timed out'`. Belt-and-suspenders for the case where `GeneratePlan::failed()` itself never fires (worker host vanished).

- [ ] **Step 1: Write the failing tests**

```php
<?php

namespace Tests\Feature\Models;

use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserPendingPlanGenerationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_null_when_no_rows_exist(): void
    {
        $user = User::factory()->create();
        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_returns_in_flight_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subSeconds(30),
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertNotNull($result);
        $this->assertSame($row->id, $result->id);
    }

    public function test_returns_failed_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'error_message' => 'Boom',
            'completed_at' => now(),
        ]);

        $this->assertSame($row->id, $user->pendingPlanGeneration()->id);
    }

    public function test_returns_completed_row_when_proposal_still_pending(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
        ]);
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'completed_at' => now(),
        ]);

        $this->assertSame($row->id, $user->pendingPlanGeneration()->id);
    }

    public function test_returns_null_when_completed_row_proposal_already_accepted(): void
    {
        $user = User::factory()->create();
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Accepted,
            'applied_at' => now(),
        ]);
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Completed,
            'proposal_id' => $proposal->id,
            'completed_at' => now(),
        ]);

        $this->assertNull($user->pendingPlanGeneration());
    }

    public function test_watchdog_auto_fails_stuck_processing_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subMinutes(11),
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Failed, $result->status);
        $this->assertSame('Generation timed out', $result->error_message);
        $this->assertNotNull($result->completed_at);

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }

    public function test_watchdog_auto_fails_stuck_queued_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'created_at' => now()->subMinutes(11),
            'started_at' => null,
        ]);

        $result = $user->pendingPlanGeneration();
        $this->assertSame(PlanGenerationStatus::Failed, $result->status);
    }

    public function test_does_not_return_other_users_rows(): void
    {
        $other = User::factory()->create();
        PlanGeneration::factory()->for($other)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $me = User::factory()->create();
        $this->assertNull($me->pendingPlanGeneration());
    }
}
```

- [ ] **Step 2: Run the tests and confirm they fail**

Run: `cd api && php artisan test --compact tests/Feature/Models/UserPendingPlanGenerationTest.php`
Expected: all 8 tests fail with "Method `pendingPlanGeneration` does not exist".

- [ ] **Step 3: Add the relation + method to `User.php`**

In `api/app/Models/User.php`, add `use App\Enums\PlanGenerationStatus;` and `use App\Enums\ProposalStatus;` near the existing `use App\Enums\CoachStyle;`. Add the two methods at the end of the class (after `canAccessPanel`):

```php
public function planGenerations(): HasMany
{
    return $this->hasMany(PlanGeneration::class);
}

/**
 * Latest plan generation that requires the user's attention right now,
 * or null. Includes a read-time watchdog: any row stuck in queued/
 * processing for >10 minutes is auto-marked failed (covers worker
 * death where the job's own failed() callback never fires).
 */
public function pendingPlanGeneration(): ?PlanGeneration
{
    $latest = $this->planGenerations()
        ->with('proposal')
        ->orderByDesc('id')
        ->first();

    if ($latest === null) {
        return null;
    }

    if ($latest->isInFlight()) {
        $started = $latest->started_at ?? $latest->created_at;
        if ($started->lt(now()->subMinutes(10))) {
            $latest->update([
                'status' => PlanGenerationStatus::Failed,
                'error_message' => 'Generation timed out',
                'completed_at' => now(),
            ]);
        }
    }

    if ($latest->status === PlanGenerationStatus::Completed) {
        $proposal = $latest->proposal;
        if ($proposal === null || $proposal->status !== ProposalStatus::Pending) {
            return null;
        }
    }

    return $latest;
}
```

Make sure `PlanGeneration` and `HasMany` are imported (`use App\Models\PlanGeneration;` is on a sibling model so the same namespace already resolves; just add `use Illuminate\Database\Eloquent\Relations\HasMany;`).

- [ ] **Step 4: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 5: Re-run tests**

Run: `cd api && php artisan test --compact tests/Feature/Models/UserPendingPlanGenerationTest.php`
Expected: 8 passed.

- [ ] **Step 6: Commit**

```bash
git add api/app/Models/User.php api/tests/Feature/Models/UserPendingPlanGenerationTest.php
git commit -m "feat(api): add User::pendingPlanGeneration() with read-time watchdog"
```

---

## Task 5: Create `GeneratePlan` job

**Files:**
- Create: `api/app/Jobs/GeneratePlan.php`
- Create: `api/tests/Feature/Jobs/GeneratePlanJobTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature\Jobs;

use App\Ai\Agents\RunCoachAgent;
use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Jobs\GeneratePlan;
use App\Models\CoachProposal;
use App\Models\PlanGeneration;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use RuntimeException;
use Tests\TestCase;

class GeneratePlanJobTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_marks_processing_then_completed_on_success(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create();

        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
        ]);

        RunCoachAgent::fake(['Plan ready.']);
        $proposal = CoachProposal::factory()->create([
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'status' => ProposalStatus::Pending,
        ]);
        $this->instance(
            ProposalService::class,
            Mockery::mock(ProposalService::class, function ($mock) use ($proposal): void {
                $mock->shouldReceive('detectProposalFromConversation')->andReturn($proposal);
            })
        );

        (new GeneratePlan($row->id))->handle(app(\App\Services\OnboardingPlanGeneratorService::class));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Completed, $row->status);
        $this->assertNotNull($row->started_at);
        $this->assertNotNull($row->completed_at);
        $this->assertSame($proposal->id, $row->proposal_id);
        $this->assertNotNull($row->conversation_id);
    }

    public function test_marks_failed_when_service_throws(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Queued,
            'payload' => [
                'goal_type' => 'fitness',
                'days_per_week' => 3,
                'coach_style' => 'flexible',
            ],
        ]);

        $this->instance(
            \App\Services\OnboardingPlanGeneratorService::class,
            Mockery::mock(\App\Services\OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldReceive('generate')->andThrow(new RuntimeException('boom'));
            })
        );

        try {
            (new GeneratePlan($row->id))->handle(app(\App\Services\OnboardingPlanGeneratorService::class));
            $this->fail('Expected exception');
        } catch (RuntimeException) {
            // expected — handle() rethrows so Laravel records the failure
        }

        // Job's failed() callback runs separately when Laravel records the failure.
        (new GeneratePlan($row->id))->failed(new RuntimeException('boom'));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
        $this->assertSame('boom', $row->error_message);
        $this->assertNotNull($row->completed_at);
    }

    public function test_handle_is_noop_when_row_no_longer_in_flight(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'completed_at' => now(),
        ]);

        // Service should NOT be called.
        $this->instance(
            \App\Services\OnboardingPlanGeneratorService::class,
            Mockery::mock(\App\Services\OnboardingPlanGeneratorService::class, function ($mock): void {
                $mock->shouldNotReceive('generate');
            })
        );

        (new GeneratePlan($row->id))->handle(app(\App\Services\OnboardingPlanGeneratorService::class));

        $row->refresh();
        $this->assertSame(PlanGenerationStatus::Failed, $row->status);
    }
}
```

- [ ] **Step 2: Run the test, confirm it fails**

Run: `cd api && php artisan test --compact tests/Feature/Jobs/GeneratePlanJobTest.php`
Expected: fails with "Class App\Jobs\GeneratePlan does not exist".

- [ ] **Step 3: Write the job**

Create `api/app/Jobs/GeneratePlan.php`:

```php
<?php

namespace App\Jobs;

use App\Enums\PlanGenerationStatus;
use App\Models\PlanGeneration;
use App\Services\OnboardingPlanGeneratorService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class GeneratePlan implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 600;
    public int $tries = 1;

    public function __construct(public int $planGenerationId) {}

    public function handle(OnboardingPlanGeneratorService $generator): void
    {
        $row = PlanGeneration::with('user')->find($this->planGenerationId);

        if ($row === null || ! $row->isInFlight()) {
            return;
        }

        $row->update([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $result = $generator->generate($row->user, $row->payload);

        $row->update([
            'status' => PlanGenerationStatus::Completed,
            'conversation_id' => $result['conversation_id'],
            'proposal_id' => $result['proposal_id'],
            'completed_at' => now(),
        ]);
    }

    public function failed(Throwable $e): void
    {
        $row = PlanGeneration::find($this->planGenerationId);

        if ($row === null) {
            return;
        }

        $row->update([
            'status' => PlanGenerationStatus::Failed,
            'error_message' => $e->getMessage(),
            'completed_at' => now(),
        ]);
    }
}
```

- [ ] **Step 4: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 5: Re-run tests**

Run: `cd api && php artisan test --compact tests/Feature/Jobs/GeneratePlanJobTest.php`
Expected: 3 passed.

- [ ] **Step 6: Commit**

```bash
git add api/app/Jobs/GeneratePlan.php api/tests/Feature/Jobs/GeneratePlanJobTest.php
git commit -m "feat(api): add GeneratePlan queued job with watchdog-friendly lifecycle"
```

---

## Task 6: Refactor `OnboardingController::generatePlan` to async + add `latestPlanGeneration` endpoint

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php`
- Modify: `api/routes/api.php`
- Replace: `api/tests/Feature/OnboardingGeneratePlanTest.php`

The new behavior:
- POST creates a `PlanGeneration` row in `queued`, dispatches `GeneratePlan`, returns 202 with the row.
- POST is **idempotent**: if there's an in-flight row already, return that row instead of dispatching a second job.
- New `GET /onboarding/plan-generation/latest` returns the user's pending row (or 204 if null) — same shape as the field embedded in `/me`.

- [ ] **Step 1: Write the failing test (replace the file)**

Replace the entire contents of `api/tests/Feature/OnboardingGeneratePlanTest.php` with:

```php
<?php

namespace Tests\Feature;

use App\Enums\PlanGenerationStatus;
use App\Jobs\GeneratePlan;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class OnboardingGeneratePlanTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_creates_row_and_dispatches_job_for_race_goal(): void
    {
        Queue::fake();
        $user = User::factory()->create();

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'race',
            'goal_name' => 'Rotterdam Half',
            'distance_meters' => 21097,
            'target_date' => now()->addMonths(4)->toDateString(),
            'goal_time_seconds' => 6300,
            'days_per_week' => 4,
            'coach_style' => 'balanced',
        ]);

        $response->assertStatus(202)
            ->assertJsonStructure(['id', 'status', 'conversation_id', 'proposal_id', 'error_message']);

        $this->assertDatabaseCount('plan_generations', 1);
        $row = PlanGeneration::firstOrFail();
        $this->assertSame($user->id, $row->user_id);
        $this->assertSame(PlanGenerationStatus::Queued, $row->status);
        $this->assertSame('race', $row->payload['goal_type']);

        Queue::assertPushed(GeneratePlan::class, fn ($job) => $job->planGenerationId === $row->id);
    }

    public function test_returns_existing_row_when_in_flight(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        $existing = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now()->subSeconds(20),
        ]);

        $response = $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ]);

        $response->assertStatus(202)->assertJsonPath('id', $existing->id);
        $this->assertDatabaseCount('plan_generations', 1);
        Queue::assertNotPushed(GeneratePlan::class);
    }

    public function test_creates_new_row_after_previous_failed(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Failed,
            'completed_at' => now()->subMinute(),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertStatus(202);

        $this->assertDatabaseCount('plan_generations', 2);
        Queue::assertPushed(GeneratePlan::class);
    }

    public function test_rejects_race_without_target_date(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->postJson('/api/v1/onboarding/generate-plan', [
                'goal_type' => 'race',
                'distance_meters' => 10000,
                'days_per_week' => 4,
                'coach_style' => 'balanced',
            ])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['target_date']);
    }

    public function test_rejects_unauthenticated(): void
    {
        $this->postJson('/api/v1/onboarding/generate-plan', [
            'goal_type' => 'fitness',
            'days_per_week' => 3,
            'coach_style' => 'flexible',
        ])->assertUnauthorized();
    }

    public function test_get_latest_returns_pending_row(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertOk()
            ->assertJsonPath('id', $row->id)
            ->assertJsonPath('status', 'processing');
    }

    public function test_get_latest_returns_204_when_nothing_pending(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/plan-generation/latest')
            ->assertNoContent();
    }
}
```

- [ ] **Step 2: Run the test, confirm it fails**

Run: `cd api && php artisan test --compact tests/Feature/OnboardingGeneratePlanTest.php`
Expected: failures pointing at controller behavior + missing route.

- [ ] **Step 3: Update the controller**

Replace `api/app/Http/Controllers/OnboardingController.php`'s `generatePlan` method and add a new method + import. The full updated file:

```php
<?php

namespace App\Http\Controllers;

use App\Http\Requests\GeneratePlanRequest;
use App\Jobs\GeneratePlan;
use App\Models\PlanGeneration;
use App\Services\RunningProfileService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class OnboardingController extends Controller
{
    /**
     * @deprecated — the form-based onboarding flow replaces this. Kept for
     * older app builds.
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
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        return response()->json(['conversation_id' => $conversationId]);
    }

    public function profile(Request $request, RunningProfileService $profiles): JsonResponse
    {
        $profile = $profiles->getOrAnalyze($request->user());

        if ($profile === null) {
            return response()->json(['status' => 'syncing'], 202);
        }

        return response()->json([
            'status' => 'ready',
            'analyzed_at' => $profile->analyzed_at,
            'data_start_date' => $profile->data_start_date,
            'data_end_date' => $profile->data_end_date,
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }

    /**
     * Enqueue plan generation. Idempotent: if a row is already in flight for
     * this user, returns it without dispatching a second job.
     */
    public function generatePlan(GeneratePlanRequest $request): JsonResponse
    {
        $user = $request->user();
        $existing = $user->pendingPlanGeneration();

        if ($existing !== null && $existing->isInFlight()) {
            return response()->json($this->serialize($existing), 202);
        }

        $row = PlanGeneration::create([
            'user_id' => $user->id,
            'status' => 'queued',
            'payload' => $request->validated(),
        ]);

        GeneratePlan::dispatch($row->id);

        return response()->json($this->serialize($row), 202);
    }

    /**
     * Return the user's latest pending plan generation, or 204 if none.
     */
    public function latestPlanGeneration(Request $request): JsonResponse|Response
    {
        $row = $request->user()->pendingPlanGeneration();

        if ($row === null) {
            return response()->noContent();
        }

        return response()->json($this->serialize($row));
    }

    /**
     * @return array<string, mixed>
     */
    public static function serialize(PlanGeneration $row): array
    {
        return [
            'id' => $row->id,
            'status' => $row->status->value,
            'conversation_id' => $row->conversation_id,
            'proposal_id' => $row->proposal_id,
            'error_message' => $row->error_message,
        ];
    }
}
```

- [ ] **Step 4: Add the route**

In `api/routes/api.php`, inside the `Route::prefix('onboarding')` group, add the new GET above the deprecated `start`:

```php
Route::prefix('onboarding')->group(function () {
    Route::get('/profile', [OnboardingController::class, 'profile']);
    Route::post('/generate-plan', [OnboardingController::class, 'generatePlan']);
    Route::get('/plan-generation/latest', [OnboardingController::class, 'latestPlanGeneration']);
    Route::post('/start', [OnboardingController::class, 'start']); // DEPRECATED
});
```

- [ ] **Step 5: Pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 6: Re-run tests**

Run: `cd api && php artisan test --compact tests/Feature/OnboardingGeneratePlanTest.php`
Expected: 7 passed.

- [ ] **Step 7: Commit**

```bash
git add api/app/Http/Controllers/OnboardingController.php api/routes/api.php api/tests/Feature/OnboardingGeneratePlanTest.php
git commit -m "feat(api): make onboarding plan generation async + add latest endpoint"
```

---

## Task 7: Include `pending_plan_generation` in `/profile`, `/auth/strava/callback`, and `/auth/dev-login`

**Files:**
- Modify: `api/app/Http/Controllers/ProfileController.php`
- Modify: `api/app/Http/Controllers/AuthController.php`
- Create: `api/tests/Feature/UserPayloadTest.php`

- [ ] **Step 1: Write the failing test**

```php
<?php

namespace Tests\Feature;

use App\Enums\PlanGenerationStatus;
use App\Models\PlanGeneration;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserPayloadTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_includes_pending_plan_generation_when_in_flight(): void
    {
        $user = User::factory()->create();
        $row = PlanGeneration::factory()->for($user)->create([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('user.pending_plan_generation.id', $row->id)
            ->assertJsonPath('user.pending_plan_generation.status', 'processing');
    }

    public function test_profile_pending_plan_generation_is_null_when_none(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->getJson('/api/v1/profile')
            ->assertOk()
            ->assertJsonPath('user.pending_plan_generation', null);
    }
}
```

- [ ] **Step 2: Run, confirm failure**

Run: `cd api && php artisan test --compact tests/Feature/UserPayloadTest.php`
Expected: fail (key missing).

- [ ] **Step 3: Update `ProfileController.php`**

Add `use App\Http\Controllers\OnboardingController;` (yes, controllers can call sibling controllers' static helpers — alternative is extracting to a UserResource, but for one helper a static method is leaner). Then update both `show` and `update`:

```php
public function show(Request $request): JsonResponse
{
    return response()->json([
        'user' => $this->serialize($request->user()),
    ]);
}

public function update(UpdateProfileRequest $request): JsonResponse
{
    $request->user()->update($request->validated());

    return response()->json([
        'user' => $this->serialize($request->user()->fresh()),
    ]);
}

/**
 * @return array<string, mixed>
 */
private function serialize(User $user): array
{
    $pending = $user->pendingPlanGeneration();

    return [
        ...$user->only([
            'id', 'name', 'email', 'strava_athlete_id', 'strava_profile_url',
            'coach_style', 'has_completed_onboarding',
        ]),
        'pending_plan_generation' => $pending !== null
            ? OnboardingController::serialize($pending)
            : null,
    ];
}
```

- [ ] **Step 4: Update `AuthController.php`**

Both `callback` and `devLogin` build `'user' => $user->only([...])`. Update both to use the same helper:

```php
'user' => $this->serializeUser($user),
```

And add a private method at the bottom of `AuthController`:

```php
/**
 * @return array<string, mixed>
 */
private function serializeUser(User $user): array
{
    $pending = $user->pendingPlanGeneration();

    return [
        ...$user->only(['id', 'name', 'email', 'coach_style', 'has_completed_onboarding']),
        'pending_plan_generation' => $pending !== null
            ? OnboardingController::serialize($pending)
            : null,
    ];
}
```

Add `use App\Http\Controllers\OnboardingController;` if missing.

- [ ] **Step 5: Pint + re-run tests**

```bash
cd api && vendor/bin/pint --dirty --format agent
php artisan test --compact tests/Feature/UserPayloadTest.php
```
Expected: 2 passed.

- [ ] **Step 6: Run the entire suite to catch regressions**

Run: `cd api && php artisan test --compact`
Expected: all green. If any other test asserts the user payload shape, update it to allow the new key (or just re-snapshot).

- [ ] **Step 7: Commit**

```bash
git add api/app/Http/Controllers/ProfileController.php api/app/Http/Controllers/AuthController.php api/tests/Feature/UserPayloadTest.php
git commit -m "feat(api): include pending_plan_generation in user payload"
```

---

## Task 8: Update CLAUDE.md docs to reflect async pipeline

**Files:**
- Modify: `api/CLAUDE.md`
- Modify: `CLAUDE.md` (root)

- [ ] **Step 1: Find the "Plan generation pipeline" section**

In `api/CLAUDE.md`, the section starts around line 242 (`### Plan generation pipeline`). The "Top-down flow" diagram begins with `[Flutter onboarding form] → POST /onboarding/finalize → OnboardingPlanGeneratorService::generate()` — note that's already wrong (the route is `generate-plan`, not `finalize`). Replace the first ~12 lines of the diagram with:

```
[Flutter onboarding form]
    │
    ▼
POST /onboarding/generate-plan
    │   1. Reject re-entry if a PlanGeneration is already in flight
    │   2. Insert PlanGeneration(status=queued, payload=form)
    │   3. Dispatch GeneratePlan job
    │   4. Return 202 {id, status:'queued', ...}
    │
    ▼
[Queue worker] GeneratePlan::handle()
    │   1. Mark row processing, set started_at
    │   2. OnboardingPlanGeneratorService::generate($user, $row->payload)
    │   3. Mark row completed with {conversation_id, proposal_id}
    │      (on Throwable: failed() callback marks row failed)
    │
    ▼
[Flutter] OnboardingGeneratingScreen polls
    GET /onboarding/plan-generation/latest every 3s
    completed → /coach/chat/{conversation_id}
    failed    → error UI with Try again
```

- [ ] **Step 2: Add a "Plan generation lifecycle" sub-section**

Right after the diagram, add:

```markdown
#### Plan generation lifecycle (async)

`plan_generations` table is the single source of truth for first-time
onboarding plan generation. Lifecycle: `queued → processing → completed | failed`.

- **Single in-flight per user**: POST is idempotent — returns the existing row
  if `pendingPlanGeneration()` is non-null.
- **Watchdog**: `User::pendingPlanGeneration()` auto-fails any row stuck in
  queued/processing for >10 minutes (covers worker death where `failed()`
  never fires). The check runs read-time inside the accessor — no scheduled
  command needed.
- **Field on /profile + auth responses**: `pending_plan_generation` is
  non-null only when the user should be redirected to the loading screen
  or the proposal chat. Once the proposal is accepted/rejected, the field
  goes back to null and normal routing resumes.
- **Queue worker timeout**: deploy command must use `--timeout=600` (or higher).
  120s is the historical value and will kill plan generation mid-loop.
```

- [ ] **Step 3: Update root `CLAUDE.md`**

Find the "What the app does" section. Update step 3 from:

> 3. User talks to an AI coach...

to clarify that the FIRST plan is generated via async onboarding — actually, leave the high-level summary alone (it's still accurate). Instead, find the "Data flow" subsection and add this bullet:

```markdown
- **Onboarding plan generation**: `POST /onboarding/generate-plan` returns 202 + a `plan_generations` row id → `GeneratePlan` job runs the agent loop in the worker → Flutter `OnboardingGeneratingScreen` polls `GET /onboarding/plan-generation/latest` every 3s → on completion navigates to `/coach/chat/{conversation_id}`. The `pending_plan_generation` field on `/profile` lets the router resume the loading screen on cold start.
```

- [ ] **Step 4: Commit**

```bash
git add api/CLAUDE.md CLAUDE.md
git commit -m "docs: document async plan generation pipeline"
```

---

## Task 9: Flutter — `PlanGeneration` model

**Files:**
- Create: `app/lib/features/onboarding/models/plan_generation.dart`

- [ ] **Step 1: Write the model**

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_generation.freezed.dart';
part 'plan_generation.g.dart';

enum PlanGenerationStatus {
  @JsonValue('queued') queued,
  @JsonValue('processing') processing,
  @JsonValue('completed') completed,
  @JsonValue('failed') failed,
}

@freezed
sealed class PlanGeneration with _$PlanGeneration {
  const factory PlanGeneration({
    required int id,
    required PlanGenerationStatus status,
    @JsonKey(name: 'conversation_id') String? conversationId,
    @JsonKey(name: 'proposal_id') int? proposalId,
    @JsonKey(name: 'error_message') String? errorMessage,
  }) = _PlanGeneration;

  factory PlanGeneration.fromJson(Map<String, dynamic> json) =>
      _$PlanGenerationFromJson(json);
}
```

- [ ] **Step 2: Run codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: generates `plan_generation.freezed.dart` and `plan_generation.g.dart`.

- [ ] **Step 3: Commit**

```bash
git add app/lib/features/onboarding/models/plan_generation.dart app/lib/features/onboarding/models/plan_generation.freezed.dart app/lib/features/onboarding/models/plan_generation.g.dart
git commit -m "feat(app): add PlanGeneration model"
```

---

## Task 10: Flutter — extend `User` model with `pendingPlanGeneration`

**Files:**
- Modify: `app/lib/features/auth/models/user.dart`

- [ ] **Step 1: Add the field**

Edit `user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'strava_athlete_id') int? stravaAthleteId,
    @JsonKey(name: 'strava_profile_url') String? stravaProfileUrl,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
    @JsonKey(name: 'pending_plan_generation') PlanGeneration? pendingPlanGeneration,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

- [ ] **Step 2: Re-run codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 3: Verify analyzer is clean**

Run: `cd app && flutter analyze`
Expected: no new errors.

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/auth/models/user.dart app/lib/features/auth/models/user.freezed.dart app/lib/features/auth/models/user.g.dart
git commit -m "feat(app): expose pendingPlanGeneration on User"
```

---

## Task 11: Flutter — update `onboarding_api.dart`

**Files:**
- Modify: `app/lib/features/onboarding/data/onboarding_api.dart`
- Modify: `app/lib/features/onboarding/models/generate_plan_response.dart` — DELETE
- Modify: any imports of `GeneratePlanResponse`

The new shape: `generatePlanCall` returns a `PlanGeneration` directly. Add a new `pollPlanGenerationCall` for GET `/onboarding/plan-generation/latest`. The dedicated 4-minute Dio override for `generatePlanCall` can drop back to the default (POST returns in <1s now).

- [ ] **Step 1: Replace `onboarding_api.dart` body**

Keep the file's existing `getProfile` / `getProfileCall` exactly as they are. Replace `generatePlanCall` and ADD a new poll function. The whole new file:

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';

part 'onboarding_api.g.dart';

@RestApi()
abstract class OnboardingApi {
  factory OnboardingApi(Dio dio) = _OnboardingApi;

  @GET('/onboarding/profile')
  Future<dynamic> getProfile();
}

@riverpod
OnboardingApi onboardingApi(Ref ref) => OnboardingApi(ref.watch(dioProvider));

/// First call hits the inline Strava sync on the backend (30-90s).
@riverpod
Future<Map<String, dynamic>> Function() getProfileCall(Ref ref) {
  final dio = ref.watch(dioProvider);
  return () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/onboarding/profile',
      options: Options(receiveTimeout: const Duration(minutes: 2)),
    );
    return response.data ?? const {};
  };
}

/// Enqueues plan generation. Returns the PlanGeneration row in queued state
/// (or the existing in-flight row, if there is one). The screen polls
/// [pollPlanGenerationCall] for status updates.
@riverpod
Future<PlanGeneration> Function(Map<String, dynamic> body) generatePlanCall(
  Ref ref,
) {
  final dio = ref.watch(dioProvider);
  return (body) async {
    final response = await dio.post<Map<String, dynamic>>(
      '/onboarding/generate-plan',
      data: body,
    );
    return PlanGeneration.fromJson(response.data!);
  };
}

/// Polls the latest pending plan generation. Returns null when the server
/// responds 204 (nothing pending). The screen interprets null mid-flight as
/// an error condition (the row was unexpectedly cleared).
@riverpod
Future<PlanGeneration?> Function() pollPlanGenerationCall(Ref ref) {
  final dio = ref.watch(dioProvider);
  return () async {
    final response = await dio.get<Map<String, dynamic>>(
      '/onboarding/plan-generation/latest',
      options: Options(
        validateStatus: (s) => s != null && s >= 200 && s < 300,
      ),
    );
    if (response.statusCode == 204 || response.data == null) return null;
    return PlanGeneration.fromJson(response.data!);
  };
}
```

- [ ] **Step 2: Delete the obsolete model**

```bash
rm app/lib/features/onboarding/models/generate_plan_response.dart \
   app/lib/features/onboarding/models/generate_plan_response.freezed.dart \
   app/lib/features/onboarding/models/generate_plan_response.g.dart
```

- [ ] **Step 3: Find and remove imports of GeneratePlanResponse**

Run: `cd app && grep -rn "generate_plan_response\|GeneratePlanResponse" lib`
Expected: only the now-stale import in `onboarding_generating_screen.dart` (which we're rewriting in Task 12). If anything else surfaces, delete those imports — leave the file in a state where Task 12's replacement compiles cleanly.

- [ ] **Step 4: Re-run codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`

- [ ] **Step 5: Commit (analyzer will be red until Task 12 — don't run flutter analyze yet)**

```bash
git add app/lib/features/onboarding/data/onboarding_api.dart app/lib/features/onboarding/data/onboarding_api.g.dart
git rm app/lib/features/onboarding/models/generate_plan_response.dart app/lib/features/onboarding/models/generate_plan_response.freezed.dart app/lib/features/onboarding/models/generate_plan_response.g.dart
git commit -m "feat(app): switch onboarding API to async + poll endpoints"
```

---

## Task 12: Flutter — rewrite `OnboardingGeneratingScreen` to poll

**Files:**
- Modify: `app/lib/features/onboarding/screens/onboarding_generating_screen.dart`

Behavior:
1. On mount: read `auth.user.pendingPlanGeneration` from state. If present, adopt its id (the user reopened mid-generation). Else POST to enqueue.
2. Poll `pollPlanGenerationCall()` every 3 seconds.
3. On `completed` → `context.go('/coach/chat/{conversationId}')`.
4. On `failed` → swap to error body. "Try again" enqueues a new row (POST again). "Back to form" goes to `/onboarding/form`.
5. If polling returns null (no row found server-side, edge case) → treat as failure with generic message.
6. Cancel poll timer on dispose.

- [ ] **Step 1: Replace the screen**

```dart
import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';
import 'package:app/features/onboarding/models/onboarding_form_data.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/onboarding/providers/onboarding_form_provider.dart';

const _pollInterval = Duration(seconds: 3);

class OnboardingGeneratingScreen extends ConsumerStatefulWidget {
  const OnboardingGeneratingScreen({super.key});

  @override
  ConsumerState<OnboardingGeneratingScreen> createState() =>
      _OnboardingGeneratingScreenState();
}

class _OnboardingGeneratingScreenState
    extends ConsumerState<OnboardingGeneratingScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress;
  Timer? _pollTimer;
  String _stage = 'Analyzing your Strava history…';
  String? _errorMessage;
  bool _completed = false;
  PlanGeneration? _current;

  @override
  void initState() {
    super.initState();
    final form = ref.read(onboardingFormProvider);
    final estimated = _estimateSeconds(form);

    _progress = AnimationController(
      vsync: this,
      duration: Duration(seconds: estimated),
      upperBound: 0.95,
    );
    _progress.addListener(_updateStage);
    _progress.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _progress.dispose();
    super.dispose();
  }

  int _estimateSeconds(OnboardingFormData form) {
    int weeks = 6;
    if (form.targetDate != null) {
      final target = DateTime.parse(form.targetDate!);
      final diffDays = target.difference(DateTime.now()).inDays;
      weeks = ((diffDays / 7).ceil()).clamp(3, 26);
    }
    return (weeks * 10).clamp(30, 180);
  }

  void _updateStage() {
    final v = _progress.value;
    final stage = v < 0.3
        ? 'Analyzing your Strava history…'
        : v < 0.6
            ? 'Designing your weekly structure…'
            : v < 0.9
                ? 'Placing training sessions…'
                : 'Finalizing your plan…';
    if (stage != _stage) {
      setState(() => _stage = stage);
    }
  }

  /// Decide whether to enqueue a new generation or adopt an in-flight one
  /// the server already knows about. Then start polling.
  Future<void> _bootstrap() async {
    final pending = ref.read(authProvider).value?.pendingPlanGeneration;

    if (pending != null && pending.status != PlanGenerationStatus.failed) {
      // Adopting a row the server already has (user reopened mid-flight, or
      // came back after completion to view the proposal). For `completed`
      // the poll loop will navigate immediately on the first tick.
      _current = pending;
      _startPolling();
      return;
    }

    // No in-flight row (or last attempt failed) — enqueue a fresh one.
    await _enqueue();
  }

  Future<void> _enqueue() async {
    setState(() {
      _errorMessage = null;
      _completed = false;
    });
    _progress.reset();
    _progress.forward();

    try {
      final form = ref.read(onboardingFormProvider.notifier);
      final payload = form.toPayload();
      final generate = ref.read(generatePlanCallProvider);
      final result = await generate(payload);

      if (!mounted) return;
      _current = result;

      if (result.status == PlanGenerationStatus.completed) {
        await _navigateToChat(result);
        return;
      }

      _startPolling();
    } catch (e) {
      if (mounted) setState(() => _errorMessage = _humanize(e));
    }
  }

  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => _poll());
    // Fire one immediately too so a freshly-completed adopt path navigates fast.
    _poll();
  }

  Future<void> _poll() async {
    if (!mounted) return;
    try {
      final poll = ref.read(pollPlanGenerationCallProvider);
      final result = await poll();

      if (!mounted) return;

      if (result == null) {
        // Server says nothing pending. If we never saw it complete here,
        // something went wrong — treat as a transient error and let the
        // user retry.
        setState(() => _errorMessage = 'Lost track of the generation. Try again?');
        _pollTimer?.cancel();
        return;
      }

      _current = result;

      if (result.status == PlanGenerationStatus.completed) {
        _pollTimer?.cancel();
        await _navigateToChat(result);
        return;
      }

      if (result.status == PlanGenerationStatus.failed) {
        _pollTimer?.cancel();
        setState(() => _errorMessage = result.errorMessage ?? 'Generation failed.');
      }
    } catch (e) {
      // Network blip on a poll — keep polling. Surface only after multiple
      // consecutive failures? Out of scope; let the timer try again in 3s.
    }
  }

  Future<void> _navigateToChat(PlanGeneration row) async {
    if (row.conversationId == null) {
      setState(() => _errorMessage = 'Plan ready but conversation id missing.');
      return;
    }

    setState(() => _completed = true);
    await _progress.animateTo(1.0, duration: const Duration(milliseconds: 350));
    if (!mounted) return;
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    ref.read(onboardingFormProvider.notifier).reset();
    // Refresh the user payload so the router redirect logic sees the
    // updated pendingPlanGeneration on next evaluation.
    await ref.read(authProvider.notifier).loadProfile();

    if (!mounted) return;
    context.go('/coach/chat/${row.conversationId}');
  }

  String _humanize(Object e) =>
      "Couldn't reach the server. Check your connection.";

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: CupertinoColors.transparent,
      child: DecoratedBox(
        decoration: const BoxDecoration(gradient: AppColors.onboardingGradient),
        child: SafeArea(
          child: _errorMessage != null
              ? _ErrorBody(
                  message: _errorMessage!,
                  onRetry: _enqueue,
                  onBack: () => context.go('/onboarding/form'),
                )
              : _LoadingBody(
                  progress: _progress,
                  stage: _stage,
                  completed: _completed,
                ),
        ),
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  final AnimationController progress;
  final String stage;
  final bool completed;

  const _LoadingBody({
    required this.progress,
    required this.stage,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 8, 32, 32),
      child: Column(
        children: [
          const SizedBox(
            height: 56,
            child: Center(child: RunCoreLogo(starSize: 22, textSize: 22, gap: 8)),
          ),
          const Spacer(),
          Text(
            'Building your plan',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 36).copyWith(height: 1.1),
          ),
          const SizedBox(height: 12),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 400),
            child: Text(
              stage,
              key: ValueKey(stage),
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.inkMuted,
              ),
            ),
          ),
          const SizedBox(height: 36),
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) => _ProgressBar(value: progress.value),
          ),
          const SizedBox(height: 12),
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) => Text(
              '${(progress.value * 100).round()}%',
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const Spacer(),
          Text(
            completed
                ? 'Loading your plan…'
                : "Sit tight. This usually takes under a minute. You can close the app — we'll keep working in the background.",
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.inkMuted,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double value;
  const _ProgressBar({required this.value});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              height: 6,
              width: constraints.maxWidth * value,
              decoration: BoxDecoration(
                color: AppColors.secondary,
                borderRadius: BorderRadius.circular(3),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.secondary.withValues(alpha: 0.35),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ErrorBody extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Plan generation failed',
            textAlign: TextAlign.center,
            style: RunCoreText.serifTitle(size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: AppColors.inkMuted,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          CupertinoButton.filled(onPressed: onRetry, child: const Text('Try again')),
          const SizedBox(height: 8),
          CupertinoButton(
            onPressed: onBack,
            child: Text('Back to form',
                style: GoogleFonts.inter(color: AppColors.inkMuted)),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Run analyzer**

Run: `cd app && flutter analyze`
Expected: clean. If any unrelated errors surface from the obsolete `GeneratePlanResponse` import, fix them.

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/onboarding/screens/onboarding_generating_screen.dart
git commit -m "feat(app): poll plan generation status; resume across app restarts"
```

---

## Task 13: Flutter — router redirect for in-flight / completed-pending generation

**Files:**
- Modify: `app/lib/router/app_router.dart`

The new redirect rule (added inside the existing `redirect:` callback, after the existing `needsOnboarding` check):

```dart
// If a plan generation is in flight, completed-but-not-accepted, or failed,
// route the user back to the loading screen (or the chat with the proposal).
// This lets the user close the app mid-generation and resume on reopen.
final pending = user?.pendingPlanGeneration;
if (pending != null) {
  switch (pending.status) {
    case PlanGenerationStatus.queued:
    case PlanGenerationStatus.processing:
    case PlanGenerationStatus.failed:
      if (state.matchedLocation != '/onboarding/generating') {
        return '/onboarding/generating';
      }
      break;
    case PlanGenerationStatus.completed:
      final cid = pending.conversationId;
      if (cid != null && !state.matchedLocation.startsWith('/coach/chat/')) {
        return '/coach/chat/$cid';
      }
      break;
  }
}
```

- [ ] **Step 1: Add the import**

At the top of `app_router.dart`:

```dart
import 'package:app/features/onboarding/models/plan_generation.dart';
```

- [ ] **Step 2: Insert the redirect block**

Find the `redirect:` block (around line ~40 in the current file). After the existing `if (isLoggedIn && user?.hasCompletedOnboarding == false …)` block, **before** the final `return null;`, paste the new block above.

Important: the new block must come AFTER the `hasCompletedOnboarding` block but only fires when `pending != null`, so users without a plan_generation row hit the existing `/onboarding` redirect (form flow). Users WITH a row jump straight to the right destination.

Also remove the `&& !state.matchedLocation.startsWith('/coach/chat/')` clause from the `hasCompletedOnboarding` redirect — the new logic owns the chat-redirect case for completed proposals. Updated existing block:

```dart
if (isLoggedIn &&
    user?.hasCompletedOnboarding == false &&
    !state.matchedLocation.startsWith('/onboarding')) {
  // Default for new users: form-based onboarding. The pending-plan-generation
  // block below overrides this when there's an in-flight or completed row.
  // (Don't return here yet — let the next block check for pending state.)
  if (user?.pendingPlanGeneration == null) {
    return '/onboarding';
  }
}
```

- [ ] **Step 3: Run analyzer**

Run: `cd app && flutter analyze`
Expected: clean.

- [ ] **Step 4: Manual test (simulator)**

```bash
cd app && flutter run
```

Smoke checks:
1. Fresh user: navigate through form, hit "Generate" → loading screen appears. Verify request hits `/onboarding/generate-plan` and returns 202 quickly (DevTools network tab).
2. Force-quit the app while loading screen shows.
3. Reopen app → router immediately puts you back on the loading screen (no flash of dashboard / form).
4. Wait until completion → screen advances to `/coach/chat/{cid}`.
5. Force-quit again BEFORE accepting the proposal → reopen → router puts you straight in the chat (proposal still pending).
6. Accept the proposal → app navigates normally; subsequent cold-starts go to dashboard.
7. Trigger a server failure (easiest: temporarily change `OnboardingPlanGeneratorService::generate()` to `throw new \RuntimeException('test');`, dispatch, revert): screen shows "Plan generation failed" + Try again, both buttons work.

- [ ] **Step 5: Commit**

```bash
git add app/lib/router/app_router.dart
git commit -m "feat(app): router redirects on pending plan generation"
```

---

## Task 14: Ops — bump queue worker timeout

**Files:**
- (none — Laravel Cloud UI change)

The deploy command in Laravel Cloud currently runs `php artisan queue:work database --tries=1 --sleep=30 --timeout=120 --quiet` (visible in the prod logs supplied with this plan). 120s is shorter than a typical plan generation (108s observed in prod). The job's own `$timeout = 600;` property already declares the desired worker timeout, but the worker's `--timeout` flag wins if it's lower.

- [ ] **Step 1: Update the worker command in Laravel Cloud UI**

Navigate to: Laravel Cloud → the runcoach environment → Process / Worker config (the page that defines the `queue:work` invocation). Change `--timeout=120` to `--timeout=600`. Save.

- [ ] **Step 2: Trigger a deploy and verify**

Push the branch / merge → wait for the new release. Confirm in the deploy logs that the worker line now shows `--timeout=600`.

- [ ] **Step 3: Smoke-test in prod**

Hit the onboarding flow on TestFlight with a real user. Watch logs for:

```
[onboarding:start] user_id=…
[ai:usage] PlanVerifierAgent …
```

Confirm the eventual success — no "Plan generation failed" toast in the app, proposal lands in the chat.

---

## Self-review

- [x] **Spec coverage** — every section of the design from brainstorming maps to a task: data model (Tasks 1–3), API surface (Tasks 5–7), Flutter (9–13), watchdog (Task 4 + 5), worker timeout (Task 14), CLAUDE.md docs (Task 8).
- [x] **No placeholders** — every code block is complete; commands include exact paths and expected output.
- [x] **Type consistency** — `PlanGenerationStatus` enum identical on backend (`queued|processing|completed|failed`) and Flutter (matched via `@JsonValue`); field names (`pending_plan_generation`, `conversation_id`, `proposal_id`, `error_message`) consistent across migration, controller serialization, Flutter models, and router; `PlanGeneration::isInFlight()` used identically in `User::pendingPlanGeneration()` and `GeneratePlan::handle()`.
- [x] **Dead-end audit** — covered: (1) crash mid-flight resumes loading screen, (2) gen completes while app closed routes to chat, (3) gen fails while app closed shows error UI, (4) worker dies → 10-min watchdog auto-fails, (5) retry after failure creates fresh row, (6) network blip during polling keeps polling silently, (7) row goes missing during polling shows generic error with retry, (8) router redirects on cold-start so user can never land on dashboard with a pending generation.

---

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-04-25-async-plan-generation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration.

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints.

Which approach?
