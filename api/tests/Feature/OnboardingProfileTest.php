<?php

namespace Tests\Feature;

use App\Models\StravaActivity;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class OnboardingProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_syncing_when_no_activities_or_profile(): void
    {
        $user = User::factory()->create();

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/profile')
            ->assertStatus(202)
            ->assertJson(['status' => 'syncing']);
    }

    public function test_returns_ready_with_metrics_when_profile_exists(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::factory()->for($user)->create([
            'metrics' => [
                'weekly_avg_km' => 35.2,
                'weekly_avg_runs' => 4,
                'avg_pace_seconds_per_km' => 305,
                'session_avg_duration_seconds' => 3600,
            ],
            'narrative_summary' => 'Consistent weekly mileage with moderate pace.',
        ]);

        $this->actingAs($user)
            ->getJson('/api/v1/onboarding/profile')
            ->assertOk()
            ->assertJsonPath('status', 'ready')
            ->assertJsonPath('metrics.weekly_avg_km', 35.2)
            ->assertJsonPath('metrics.weekly_avg_runs', 4)
            ->assertJsonPath('narrative_summary', 'Consistent weekly mileage with moderate pace.');
    }

    public function test_rejects_unauthenticated(): void
    {
        $this->getJson('/api/v1/onboarding/profile')->assertUnauthorized();
    }

    public function test_does_not_leak_another_users_profile(): void
    {
        $owner = User::factory()->create();
        $viewer = User::factory()->create();
        UserRunningProfile::factory()->for($owner)->create();
        StravaActivity::factory()->for($owner)->count(2)->create();

        $this->actingAs($viewer)
            ->getJson('/api/v1/onboarding/profile')
            ->assertStatus(202)
            ->assertJson(['status' => 'syncing']);
    }
}
