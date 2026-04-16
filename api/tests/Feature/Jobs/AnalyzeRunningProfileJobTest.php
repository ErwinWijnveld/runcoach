<?php

namespace Tests\Feature\Jobs;

use App\Jobs\AnalyzeRunningProfileJob;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Mockery;
use Tests\TestCase;

class AnalyzeRunningProfileJobTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_job_creates_profile_and_appends_four_scripted_messages(): void
    {
        $user = User::factory()->create();
        $conversationId = (string) \Str::uuid();

        DB::table('agent_conversations')->insert([
            'id' => $conversationId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode(['onboarding_step' => 'pending_analysis']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $profile = UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => [
                'weekly_avg_km' => 12.5,
                'weekly_avg_runs' => 3,
                'avg_pace_seconds_per_km' => 295,
                'session_avg_duration_seconds' => 2694,
            ],
            'narrative_summary' => 'Consistent year.',
        ]);

        $service = Mockery::mock(RunningProfileService::class);
        $service->shouldReceive('analyze')->once()->with(Mockery::on(fn ($u) => $u->id === $user->id))->andReturn($profile);

        $this->app->instance(RunningProfileService::class, $service);

        (new AnalyzeRunningProfileJob($conversationId, $user->id))->handle($service);

        $messages = DB::table('agent_conversation_messages')
            ->where('conversation_id', $conversationId)
            ->orderBy('created_at')
            ->get();

        $this->assertCount(4, $messages);  // text + stats_card + text + chip_suggestions

        $msg0Meta = json_decode($messages[0]->meta, true);
        $this->assertEquals('text', $msg0Meta['message_type']);
        $this->assertEquals('Consistent year.', $messages[0]->content);

        $msg1Meta = json_decode($messages[1]->meta, true);
        $this->assertEquals('stats_card', $msg1Meta['message_type']);
        $this->assertEquals(12.5, $msg1Meta['message_payload']['metrics']['weekly_avg_km']);

        $msg2Meta = json_decode($messages[2]->meta, true);
        $this->assertEquals('text', $msg2Meta['message_type']);
        $this->assertStringContainsString('training for', $messages[2]->content);

        $msg3Meta = json_decode($messages[3]->meta, true);
        $this->assertEquals('chip_suggestions', $msg3Meta['message_type']);
        $this->assertCount(3, $msg3Meta['message_payload']['chips']);

        $conversation = DB::table('agent_conversations')->where('id', $conversationId)->first();
        $conversationMeta = json_decode($conversation->meta, true);
        $this->assertEquals('awaiting_branch', $conversationMeta['onboarding_step']);
    }
}
