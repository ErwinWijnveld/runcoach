<?php

namespace Tests\Feature;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class ProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(?User $user = null): array
    {
        $user ??= User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_get_profile(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/profile', $headers);

        $response->assertOk();
        $response->assertJsonFragment(['name' => $user->name]);
    }

    public function test_update_profile(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'level' => 'advanced',
            'coach_style' => 'analytical',
            'weekly_km_capacity' => 55.0,
        ], $headers);

        $response->assertOk();
        $user->refresh();
        $this->assertSame(RunnerLevel::Advanced, $user->level);
        $this->assertSame(CoachStyle::Analytical, $user->coach_style);
        $this->assertEquals(55.0, $user->weekly_km_capacity);
    }

    public function test_complete_onboarding(): void
    {
        [$user, $headers] = $this->authUser(
            User::factory()->create(['level' => null])
        );

        $response = $this->postJson('/api/v1/profile/onboarding', [
            'level' => 'beginner',
            'coach_style' => 'motivational',
            'weekly_km_capacity' => 20.0,
        ], $headers);

        $response->assertOk();
        $user->refresh();
        $this->assertSame(RunnerLevel::Beginner, $user->level);
    }

    public function test_unauthenticated_profile_returns_401(): void
    {
        $response = $this->getJson('/api/v1/profile');
        $response->assertUnauthorized();
    }
}
