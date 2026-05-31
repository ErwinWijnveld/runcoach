<?php

namespace Tests\Feature\Coach;

use App\Models\Goal;
use App\Models\TrainingWeek;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ScheduleWeekChatTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_lookup_returns_null_when_no_conversation_for_week(): void
    {
        $user = User::factory()->create();
        $week = $this->weekFor($user);

        Sanctum::actingAs($user);

        $response = $this->getJson("/api/v1/schedule/weeks/{$week->id}/chat");

        $response->assertOk();
        $this->assertNull($response->json('data'));
    }

    public function test_lookup_returns_existing_conversation_for_week(): void
    {
        $user = User::factory()->create();
        $week = $this->weekFor($user);

        $cid = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $cid,
            'user_id' => $user->id,
            'title' => 'Week 1 chat',
            'subject_type' => 'training_week',
            'subject_id' => $week->id,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        Sanctum::actingAs($user);

        $response = $this->getJson("/api/v1/schedule/weeks/{$week->id}/chat");

        $response->assertOk();
        $this->assertSame($cid, $response->json('data.id'));
    }

    public function test_lookup_403s_for_another_users_week(): void
    {
        $other = User::factory()->create();
        $week = $this->weekFor($other);

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->getJson("/api/v1/schedule/weeks/{$week->id}/chat")
            ->assertForbidden();
    }

    public function test_store_creates_week_scoped_conversation_with_subject_binding(): void
    {
        $user = User::factory()->create();
        $week = $this->weekFor($user);

        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Week 1 (12-18 May)',
            'subject_type' => 'training_week',
            'subject_id' => $week->id,
        ]);

        $response->assertCreated();
        $conversationId = $response->json('data.id');
        $this->assertIsString($conversationId);

        $row = DB::table('agent_conversations')->where('id', $conversationId)->first();
        $this->assertNotNull($row);
        $this->assertSame('training_week', $row->subject_type);
        $this->assertSame($week->id, (int) $row->subject_id);
        $this->assertSame($user->id, $row->user_id);
        $this->assertSame('Week 1 (12-18 May)', $row->title);
    }

    public function test_store_rejects_subject_binding_to_someone_elses_week(): void
    {
        $other = User::factory()->create();
        $week = $this->weekFor($other);

        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Week chat',
            'subject_type' => 'training_week',
            'subject_id' => $week->id,
        ])->assertForbidden();
    }

    public function test_store_rejects_unsupported_subject_type(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $this->postJson('/api/v1/coach/conversations', [
            'title' => 'Day chat',
            'subject_type' => 'training_day',
            'subject_id' => 1,
        ])->assertStatus(422);
    }

    public function test_store_still_creates_plain_chat_without_subject(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/coach/conversations', [
            'title' => 'New Chat',
        ]);

        $response->assertCreated();
        $cid = $response->json('data.id');
        $row = DB::table('agent_conversations')->where('id', $cid)->first();
        $this->assertNull($row->subject_type);
        $this->assertNull($row->subject_id);
    }

    public function test_list_includes_week_chats_but_excludes_workout_chats(): void
    {
        $user = User::factory()->create();
        $week = $this->weekFor($user);
        $now = now();

        // Plain coach chat
        DB::table('agent_conversations')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Plain chat',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Week-scoped chat — should appear
        DB::table('agent_conversations')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Week chat',
            'subject_type' => 'training_week',
            'subject_id' => $week->id,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Workout chat — should NOT appear
        DB::table('agent_conversations')->insert([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Workout chat',
            'subject_type' => 'training_day',
            'subject_id' => 999,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        Sanctum::actingAs($user);

        $titles = collect($this->getJson('/api/v1/coach/conversations')->json('data'))
            ->pluck('title')
            ->all();

        $this->assertContains('Plain chat', $titles);
        $this->assertContains('Week chat', $titles);
        $this->assertNotContains('Workout chat', $titles);
    }

    private function weekFor(User $user): TrainingWeek
    {
        $goal = Goal::factory()->create(['user_id' => $user->id]);

        return TrainingWeek::factory()->create([
            'goal_id' => $goal->id,
            'week_number' => 1,
            'starts_at' => now()->startOfWeek()->toDateString(),
        ]);
    }
}
