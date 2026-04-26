<?php

namespace Tests\Feature;

use App\Models\Goal;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DeleteAccountTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->deleteJson('/api/v1/profile')->assertStatus(401);
    }

    public function test_deletes_user_and_all_owned_rows(): void
    {
        $user = User::factory()->create();

        StravaToken::factory()->create(['user_id' => $user->id]);
        WearableActivity::factory()->create(['user_id' => $user->id]);
        UserRunningProfile::factory()->create(['user_id' => $user->id]);
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        TrainingResult::factory()->create(['training_day_id' => $day->id]);

        DB::table('agent_conversations')->insert([
            'id' => 'conv-'.$user->id,
            'user_id' => $user->id,
            'title' => 'Test conversation',
            'context' => 'coach',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('agent_conversation_messages')->insert([
            'id' => 'msg-'.$user->id,
            'conversation_id' => 'conv-'.$user->id,
            'user_id' => $user->id,
            'agent' => 'RunCoachAgent',
            'role' => 'user',
            'content' => 'hi',
            'attachments' => '[]',
            'tool_calls' => '[]',
            'tool_results' => '[]',
            'usage' => '{}',
            'meta' => '{}',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertNull(User::find($user->id));
        $this->assertSame(0, StravaToken::where('user_id', $user->id)->count());
        $this->assertSame(0, WearableActivity::where('user_id', $user->id)->count());
        $this->assertSame(0, UserRunningProfile::where('user_id', $user->id)->count());
        $this->assertSame(0, Goal::where('user_id', $user->id)->count());
        $this->assertSame(0, TrainingWeek::where('goal_id', $goal->id)->count());
        $this->assertSame(0, TrainingDay::where('training_week_id', $week->id)->count());
        $this->assertSame(0, TrainingResult::where('training_day_id', $day->id)->count());
        $this->assertSame(0, DB::table('agent_conversations')->where('user_id', $user->id)->count());
        $this->assertSame(0, DB::table('agent_conversation_messages')->where('conversation_id', 'conv-'.$user->id)->count());
    }

    public function test_deletes_sanctum_tokens_for_user(): void
    {
        $user = User::factory()->create();
        $user->createToken('device-1');
        $user->createToken('device-2');

        $this->assertSame(2, DB::table('personal_access_tokens')
            ->where('tokenable_id', $user->id)
            ->where('tokenable_type', User::class)
            ->count());

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertSame(0, DB::table('personal_access_tokens')
            ->where('tokenable_id', $user->id)
            ->where('tokenable_type', User::class)
            ->count());
    }

    public function test_does_not_delete_other_users_data(): void
    {
        $victim = User::factory()->create();
        $bystander = User::factory()->create();

        Goal::factory()->create(['user_id' => $victim->id]);
        $bystanderGoal = Goal::factory()->create(['user_id' => $bystander->id]);

        $this->actingAs($victim, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertNotNull(User::find($bystander->id));
        $this->assertNotNull(Goal::find($bystanderGoal->id));
    }

    public function test_preserves_anonymised_token_usage_history(): void
    {
        $user = User::factory()->create();
        DB::table('token_usages')->insert([
            'user_id' => $user->id,
            'agent_class' => 'App\\Ai\\Agents\\RunCoachAgent',
            'context' => 'coach',
            'provider' => 'anthropic',
            'model' => 'claude-sonnet-4-6',
            'prompt_tokens' => 100,
            'completion_tokens' => 50,
            'cache_read_input_tokens' => 0,
            'cache_write_input_tokens' => 0,
            'reasoning_tokens' => 0,
            'total_tokens' => 150,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertSame(1, DB::table('token_usages')->count());
        $this->assertNull(DB::table('token_usages')->first()->user_id);
    }
}
