<?php

namespace Tests\Feature\Coach;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class CoachListFilterTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_coach_conversation_list_excludes_onboarding_conversations(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $now = now();

        // Regular coach conversation (no context)
        $coachConvoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $coachConvoId,
            'user_id' => $user->id,
            'title' => 'Regular chat',
            'context' => null,
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        // Onboarding conversation
        $onboardingConvoId = (string) Str::uuid();
        DB::table('agent_conversations')->insert([
            'id' => $onboardingConvoId,
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'created_at' => $now,
            'updated_at' => $now,
        ]);

        $response = $this->getJson('/api/v1/coach/conversations');

        $response->assertOk();

        $ids = collect($response->json('data'))->pluck('id')->all();

        $this->assertContains($coachConvoId, $ids);
        $this->assertNotContains($onboardingConvoId, $ids);
    }
}
