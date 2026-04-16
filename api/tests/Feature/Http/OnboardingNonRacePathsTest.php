<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingNonRacePathsTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function createOnboardingConversation(User $user, array $meta): string
    {
        $id = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $id,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => json_encode($meta),
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        return $id;
    }

    private function metaOf(string $convoId): array
    {
        $row = DB::table('agent_conversations')->where('id', $convoId)->first();

        return json_decode($row->meta, true) ?? [];
    }

    public function test_general_fitness_path_asks_days_per_week(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = $this->createOnboardingConversation($user, ['onboarding_step' => 'awaiting_branch']);

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'General fitness', 'chip_value' => 'general_fitness',
        ])->assertOk();

        $meta = $this->metaOf($convoId);
        $this->assertEquals('awaiting_fitness_days', $meta['onboarding_step']);

        $last = DB::table('agent_conversation_messages')
            ->where('conversation_id', $convoId)
            ->where('role', 'assistant')
            ->orderByDesc('created_at')->first();
        $lastMeta = json_decode($last->meta, true);
        $this->assertEquals('chip_suggestions', $lastMeta['message_type']);
        $this->assertCount(5, $lastMeta['message_payload']['chips']);
    }

    public function test_general_fitness_days_transitions_to_coach_style(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = $this->createOnboardingConversation($user, [
            'onboarding_step' => 'awaiting_fitness_days',
            'path' => 'general_fitness',
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => '4 days', 'chip_value' => '4',
        ])->assertOk();

        $meta = $this->metaOf($convoId);
        $this->assertEquals('awaiting_coach_style', $meta['onboarding_step']);
        $this->assertEquals(4, $meta['days_per_week']);
    }

    public function test_pr_attempt_path_walks_distance_pr_days(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convoId = $this->createOnboardingConversation($user, ['onboarding_step' => 'awaiting_branch']);

        // Step 1: Get faster
        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'Get faster', 'chip_value' => 'pr_attempt',
        ])->assertOk();
        $this->assertEquals('awaiting_faster_distance', $this->metaOf($convoId)['onboarding_step']);

        // Step 2: pick 5k
        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => '5k', 'chip_value' => '5k',
        ])->assertOk();
        $this->assertEquals('awaiting_faster_pr_target', $this->metaOf($convoId)['onboarding_step']);
        $this->assertEquals('5k', $this->metaOf($convoId)['distance']);

        // Step 3: PR + target free text
        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => 'currently 22:30, target 20:00',
        ])->assertOk();
        $this->assertEquals('awaiting_faster_days', $this->metaOf($convoId)['onboarding_step']);
        $this->assertEquals('currently 22:30, target 20:00', $this->metaOf($convoId)['pr_target_raw']);

        // Step 4: days chip
        $this->postJson("/api/v1/onboarding/conversations/{$convoId}/messages", [
            'text' => '4 days', 'chip_value' => '4',
        ])->assertOk();
        $this->assertEquals('awaiting_coach_style', $this->metaOf($convoId)['onboarding_step']);
    }
}
