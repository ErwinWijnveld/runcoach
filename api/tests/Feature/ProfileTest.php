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

    public function test_update_profile_accepts_name(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'name' => 'Erwin Runner',
        ], $headers);

        $response->assertOk();
        $this->assertSame('Erwin Runner', $user->refresh()->name);
    }

    public function test_unauthenticated_profile_returns_401(): void
    {
        $response = $this->getJson('/api/v1/profile');
        $response->assertUnauthorized();
    }

    public function test_update_profile_accepts_heart_rate_zones(): void
    {
        [$user, $headers] = $this->authUser();

        $zones = [
            ['min' => 0, 'max' => 110],
            ['min' => 110, 'max' => 145],
            ['min' => 145, 'max' => 165],
            ['min' => 165, 'max' => 180],
            ['min' => 180, 'max' => -1],
        ];

        $response = $this->putJson('/api/v1/profile', [
            'heart_rate_zones' => $zones,
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('user.heart_rate_zones', $zones);
        $this->assertSame($zones, $user->refresh()->heart_rate_zones);
    }

    public function test_update_profile_rejects_non_contiguous_zones(): void
    {
        [, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'heart_rate_zones' => [
                ['min' => 0, 'max' => 110],
                ['min' => 115, 'max' => 145],
                ['min' => 145, 'max' => 165],
                ['min' => 165, 'max' => 180],
                ['min' => 180, 'max' => -1],
            ],
        ], $headers);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['heart_rate_zones.1.min']);
    }

    public function test_update_profile_rejects_zone_5_with_finite_max(): void
    {
        [, $headers] = $this->authUser();

        $response = $this->putJson('/api/v1/profile', [
            'heart_rate_zones' => [
                ['min' => 0, 'max' => 110],
                ['min' => 110, 'max' => 145],
                ['min' => 145, 'max' => 165],
                ['min' => 165, 'max' => 180],
                ['min' => 180, 'max' => 220],
            ],
        ], $headers);

        $response->assertUnprocessable();
        $response->assertJsonValidationErrors(['heart_rate_zones.4.max']);
    }
}
