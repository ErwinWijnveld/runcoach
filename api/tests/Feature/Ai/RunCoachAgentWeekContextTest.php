<?php

namespace Tests\Feature\Ai;

use App\Ai\Agents\RunCoachAgent;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Tests\TestCase;

class RunCoachAgentWeekContextTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_plain_conversation_has_no_week_context_section(): void
    {
        $user = User::factory()->create();
        $cid = $this->insertConversation($user->id);

        $instructions = RunCoachAgent::make($user)
            ->continue($cid, as: $user)
            ->instructions();

        $this->assertStringNotContainsString('## Current view context', $instructions);
        $this->assertStringNotContainsString('viewing this week', $instructions);
    }

    public function test_week_bound_conversation_injects_week_summary(): void
    {
        $user = User::factory()->create();

        $goal = Goal::factory()->create([
            'user_id' => $user->id,
            'name' => 'Half Marathon — Spring',
            'target_date' => now()->addDays(60)->toDateString(),
        ]);
        $week = TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 3,
            'starts_at' => '2026-05-11',
            'total_km' => 38.5,
            'focus' => 'Tempo block',
        ]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => '2026-05-12',
            'type' => 'easy',
            'target_km' => 6.0,
            'target_pace_seconds_per_km' => 360,
            'target_heart_rate_zone' => 2,
        ]);
        TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => '2026-05-17',
            'type' => 'long_run',
            'target_km' => 14.0,
            'target_pace_seconds_per_km' => 380,
        ]);

        $cid = $this->insertConversation($user->id, [
            'subject_type' => 'training_week',
            'subject_id' => $week->id,
        ]);

        $instructions = RunCoachAgent::make($user)
            ->continue($cid, as: $user)
            ->instructions();

        $this->assertStringContainsString('## Current view context', $instructions);
        $this->assertStringContainsString('week_number: 3', $instructions);
        $this->assertStringContainsString('2026-05-11 to 2026-05-17', $instructions);
        $this->assertStringContainsString('Tempo block', $instructions);
        $this->assertStringContainsString('Half Marathon — Spring', $instructions);
        $this->assertStringContainsString('## Days in this week', $instructions);
        // target_km is cast decimal:1 → "6.0km" / "14.0km"
        $this->assertStringContainsString('6.0km', $instructions);
        $this->assertStringContainsString('14.0km', $instructions);
    }

    public function test_training_day_subject_is_not_resolved_by_runcoach_agent(): void
    {
        $user = User::factory()->create();

        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create([
            'training_week_id' => $week->id,
            'date' => now()->addDay()->toDateString(),
        ]);

        $cid = $this->insertConversation($user->id, [
            'subject_type' => 'training_day',
            'subject_id' => $day->id,
        ]);

        $instructions = RunCoachAgent::make($user)
            ->continue($cid, as: $user)
            ->instructions();

        $this->assertStringNotContainsString('## Current view context', $instructions);
    }

    public function test_missing_week_falls_back_to_plain_prompt(): void
    {
        $user = User::factory()->create();

        $cid = $this->insertConversation($user->id, [
            'subject_type' => 'training_week',
            'subject_id' => 99999,
        ]);

        $instructions = RunCoachAgent::make($user)
            ->continue($cid, as: $user)
            ->instructions();

        $this->assertStringNotContainsString('## Current view context', $instructions);
    }

    /**
     * @param  array<string, mixed>  $overrides
     */
    private function insertConversation(int $userId, array $overrides = []): string
    {
        $cid = (string) Str::uuid();
        DB::table('agent_conversations')->insert(array_merge([
            'id' => $cid,
            'user_id' => $userId,
            'title' => 'Test chat',
            'context' => null,
            'subject_type' => null,
            'subject_id' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ], $overrides));

        return $cid;
    }
}
