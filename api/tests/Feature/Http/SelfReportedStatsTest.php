<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class SelfReportedStatsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_requires_authentication(): void
    {
        $this->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 25,
            'easy_pace_seconds_per_km' => 360,
        ])->assertUnauthorized();
    }

    public function test_persists_both_fields_and_timestamp(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 25.5,
            'easy_pace_seconds_per_km' => 360,
        ])->assertOk();

        $user->refresh();
        $this->assertSame('25.5', (string) $user->self_reported_weekly_km);
        $this->assertSame(360, $user->self_reported_easy_pace_seconds_per_km);
        $this->assertNotNull($user->self_reported_stats_at);
    }

    public function test_allows_either_field_to_be_null(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => null,
            'easy_pace_seconds_per_km' => 330,
        ])->assertOk();

        $user->refresh();
        $this->assertNull($user->self_reported_weekly_km);
        $this->assertSame(330, $user->self_reported_easy_pace_seconds_per_km);
        $this->assertNotNull($user->self_reported_stats_at);
    }

    public function test_clears_timestamp_when_both_null(): void
    {
        $user = User::factory()->create([
            'self_reported_weekly_km' => 20,
            'self_reported_easy_pace_seconds_per_km' => 360,
            'self_reported_stats_at' => now()->subDay(),
        ]);

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => null,
            'easy_pace_seconds_per_km' => null,
        ])->assertOk();

        $user->refresh();
        $this->assertNull($user->self_reported_weekly_km);
        $this->assertNull($user->self_reported_easy_pace_seconds_per_km);
        $this->assertNull($user->self_reported_stats_at);
    }

    public function test_rejects_out_of_range_pace(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 20,
            'easy_pace_seconds_per_km' => 90,
        ])->assertStatus(422);
    }

    public function test_rejects_out_of_range_km(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)->postJson('/api/v1/onboarding/self-reported-stats', [
            'weekly_km' => 500,
            'easy_pace_seconds_per_km' => 360,
        ])->assertStatus(422);
    }
}
