<?php

namespace Tests\Feature\Http;

use App\Ai\Tools\EditWorkout;
use App\Ai\Tools\EscalateToCoach;
use App\Ai\Tools\RescheduleWorkout;
use App\Enums\GoalStatus;
use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Services\PlanOptimizerService;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Ai\Tools\Request;
use Tests\TestCase;

class WorkoutChatControllerTest extends TestCase
{
    use LazilyRefreshDatabase;

    /**
     * @return array{0: User, 1: array<string,string>}
     */
    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    /**
     * @param  array<string, mixed>  $dayAttrs
     */
    private function scheduleDay(User $user, array $dayAttrs = [], ?Goal $goal = null): TrainingDay
    {
        $goal ??= Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'starts_at' => now()->startOfWeek()->toDateString(),
        ]);

        return TrainingDay::factory()->create(array_merge([
            'training_week_id' => $week->id,
            'date' => now()->addDay()->toDateString(),
            'type' => 'easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 390,
            'target_heart_rate_zone' => 2,
        ], $dayAttrs));
    }

    public function test_show_returns_null_when_no_conversation_exists_yet(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $response = $this->getJson("/api/v1/workout-chat/{$day->id}", $headers);

        $response->assertOk();
        $this->assertNull($response->json('data'));
    }

    public function test_show_returns_existing_conversation_for_this_day(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        $cid = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $cid,
            'user_id' => $user->id,
            'title' => 'Workout chat',
            'subject_type' => 'training_day',
            'subject_id' => $day->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->getJson("/api/v1/workout-chat/{$day->id}", $headers);

        $response->assertOk();
        $this->assertSame($cid, $response->json('data.id'));
        $this->assertSame($day->id, $response->json('data.training_day_id'));
    }

    public function test_show_404s_for_other_users_training_day(): void
    {
        $other = User::factory()->create();
        $day = $this->scheduleDay($other);

        [, $headers] = $this->authUser();

        $this->getJson("/api/v1/workout-chat/{$day->id}", $headers)
            ->assertNotFound();
    }

    public function test_workout_conversations_are_excluded_from_coach_chat_list(): void
    {
        [$user, $headers] = $this->authUser();
        $day = $this->scheduleDay($user);

        DB::table('agent_conversations')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Workout chat',
            'subject_type' => 'training_day',
            'subject_id' => $day->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        DB::table('agent_conversations')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Coach chat',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $response = $this->getJson('/api/v1/coach/conversations', $headers);

        $response->assertOk();
        $titles = collect($response->json('data'))->pluck('title');
        $this->assertContains('Coach chat', $titles);
        $this->assertNotContains('Workout chat', $titles);
    }

    public function test_escalate_to_coach_tool_returns_handoff_payload(): void
    {
        $tool = new EscalateToCoach;
        $raw = $tool->handle(new Request(['suggested_prompt' => 'Build me a marathon plan']));
        $result = json_decode($raw, true);

        $this->assertSame('handoff', $result['display']);
        $this->assertTrue($result['requires_handoff']);
        $this->assertSame('Build me a marathon plan', $result['suggested_prompt']);
    }

    public function test_escalate_to_coach_tool_rejects_empty_prompt(): void
    {
        $tool = new EscalateToCoach;
        $raw = $tool->handle(new Request(['suggested_prompt' => '   ']));
        $result = json_decode($raw, true);

        $this->assertArrayHasKey('error', $result);
    }

    public function test_reschedule_workout_tool_moves_day(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create(['user_id' => $user->id, 'target_date' => now()->addDays(60)]);
        $weekA = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek()->toDateString(),
        ]);
        TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 2,
            'starts_at' => now()->startOfWeek()->addDays(7)->toDateString(),
        ]);

        $day = TrainingDay::factory()->create([
            'training_week_id' => $weekA->id,
            'date' => now()->addDay()->toDateString(),
            'type' => 'easy',
            'target_km' => 5.0,
        ]);

        $tool = new RescheduleWorkout($user, $day);
        $newDate = now()->addDays(8)->toDateString();
        $raw = $tool->handle(new Request(['date' => $newDate]));
        $result = json_decode($raw, true);

        $this->assertTrue($result['rescheduled']);
        $this->assertSame($newDate, $result['date']);
        $this->assertSame(2, $result['week_number']);
        $this->assertSame('plan_mutated', $result['display']);
        $this->assertSame($newDate, $day->fresh()->date->toDateString());
    }

    public function test_reschedule_workout_tool_refuses_completed_day(): void
    {
        $user = User::factory()->create();
        $day = $this->scheduleDay($user);
        $activity = WearableActivity::factory()->create(['user_id' => $user->id]);
        TrainingResult::factory()->create([
            'training_day_id' => $day->id,
            'wearable_activity_id' => $activity->id,
        ]);

        $tool = new RescheduleWorkout($user, $day);
        $raw = $tool->handle(new Request(['date' => now()->addDays(2)->toDateString()]));
        $result = json_decode($raw, true);

        $this->assertArrayHasKey('error', $result);
        $this->assertStringContainsString('already has a result', $result['error']);
    }

    public function test_reschedule_workout_tool_refuses_race_day(): void
    {
        $user = User::factory()->create();
        $raceDate = now()->addDays(30)->startOfDay();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'target_date' => $raceDate,
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 5,
            'starts_at' => $raceDate->copy()->startOfWeek()->toDateString(),
        ]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => $raceDate->toDateString(),
            'type' => 'tempo',
            'target_km' => 21.1,
        ]);

        $tool = new RescheduleWorkout($user, $day);
        $raw = $tool->handle(new Request(['date' => now()->addDays(31)->toDateString()]));
        $result = json_decode($raw, true);

        $this->assertArrayHasKey('error', $result);
        $this->assertStringContainsString('goal/race day', $result['error']);
    }

    public function test_edit_workout_tool_creates_proposal_with_single_set_day_op(): void
    {
        $user = User::factory()->create();
        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'status' => GoalStatus::Active,
            'target_date' => now()->addDays(60),
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek()->toDateString(),
        ]);
        $dayDate = now()->addDays(2)->startOfDay();
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => $dayDate->toDateString(),
            'order' => 3,
            'type' => 'easy',
            'target_km' => 5.0,
            'target_pace_seconds_per_km' => 390,
        ]);

        $tool = new EditWorkout(
            $user,
            $day,
            app(PlanOptimizerService::class),
            app(ProposalService::class),
        );

        $raw = $tool->handle(new Request([
            'fields' => json_encode(['target_km' => 8.0]),
        ]));
        $result = json_decode($raw, true);

        $this->assertTrue($result['requires_approval'] ?? false, 'Expected requires_approval, got: '.$raw);
        $this->assertSame('edit_active_plan', $result['proposal_type']);

        $proposal = CoachProposal::find($result['proposal_id']);
        $this->assertNotNull($proposal);

        $diff = $proposal->payload['diff'] ?? null;
        $this->assertIsArray($diff);
        $this->assertCount(1, $diff);
        $this->assertSame('set_day', $diff[0]['op']);
        $this->assertSame(1, $diff[0]['week']);
        $this->assertSame(3, $diff[0]['day_of_week']);
        $this->assertEquals(8, $diff[0]['fields']['target_km']);
    }
}
