<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingRacePathTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_race_details_transitions_to_coach_style(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $convoId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode([
                'onboarding_step' => 'awaiting_race_details',
                'path' => 'race',
            ]),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week',
        ])->assertOk();

        $last = DB::table('agent_conversation_messages')
            ->where('conversation_id', $convoId)
            ->where('role', 'assistant')
            ->orderByDesc('created_at')
            ->first();

        $lastMeta = json_decode($last->meta, true);
        $this->assertEquals('chip_suggestions', $lastMeta['message_type']);
        $chipValues = array_column($lastMeta['message_payload']['chips'], 'value');
        $this->assertEquals(['strict', 'balanced', 'flexible'], $chipValues);

        $updated = DB::table('agent_conversations')->where('id', $convoId)->first();
        $meta = json_decode($updated->meta, true);
        $this->assertEquals('awaiting_coach_style', $meta['onboarding_step']);
        $this->assertEquals('Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week', $meta['race_details_raw']);
    }

    public function test_branch_selection_also_stores_path(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $convoId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode(['onboarding_step' => 'awaiting_branch']),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Race coming up!',
            'chip_value' => 'race',
        ])->assertOk();

        $updated = DB::table('agent_conversations')->where('id', $convoId)->first();
        $meta = json_decode($updated->meta, true);
        $this->assertEquals('race', $meta['path']);
        $this->assertEquals('awaiting_race_details', $meta['onboarding_step']);
    }
}
