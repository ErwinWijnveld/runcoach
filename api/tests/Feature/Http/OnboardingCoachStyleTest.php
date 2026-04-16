<?php

namespace Tests\Feature\Http;

use App\Jobs\RunOnboardingPlanAgentJob;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Queue;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingCoachStyleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_coach_style_choice_stores_on_user_and_enqueues_plan_generation(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $convoId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode([
                'onboarding_step' => 'awaiting_coach_style',
                'path' => 'race',
                'race_details_raw' => 'Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week',
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Balanced',
            'chip_value' => 'balanced',
        ])->assertOk();

        $user->refresh();
        $this->assertEquals('balanced', $user->coach_style->value);

        $updated = DB::table('agent_conversations')->where('id', $convoId)->first();
        $meta = json_decode($updated->meta, true);
        $this->assertEquals('plan_generating', $meta['onboarding_step']);
        $this->assertEquals('balanced', $meta['coach_style']);

        $last = DB::table('agent_conversation_messages')
            ->where('conversation_id', $convoId)
            ->where('role', 'assistant')->orderByDesc('created_at')->first();
        $lastMeta = json_decode($last->meta, true);
        $this->assertEquals('loading_card', $lastMeta['message_type']);
        $this->assertEquals('Working on your plan', $lastMeta['message_payload']['label']);

        Queue::assertPushed(RunOnboardingPlanAgentJob::class);
    }
}
