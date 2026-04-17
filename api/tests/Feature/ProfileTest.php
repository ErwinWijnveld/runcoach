<?php

namespace Tests\Feature;

use App\Enums\CoachStyle;
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
        $response->assertJsonStructure(['user' => ['has_completed_onboarding', 'coach_style']]);
    }

    public function test_update_profile(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'coach_style' => 'analytical',
            'has_completed_onboarding' => true,
        ], $headers);

        $response->assertOk();
        $user->refresh();
        $this->assertSame(CoachStyle::Analytical, $user->coach_style);
        $this->assertTrue($user->has_completed_onboarding);
    }

    public function test_unauthenticated_profile_returns_401(): void
    {
        $response = $this->getJson('/api/v1/profile');
        $response->assertUnauthorized();
    }
}
