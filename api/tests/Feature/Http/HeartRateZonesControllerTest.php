<?php

namespace Tests\Feature\Http;

use App\Enums\HeartRateZonesSource;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class HeartRateZonesControllerTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(?User $user = null): array
    {
        $user ??= User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_unauthenticated_returns_401(): void
    {
        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', []);
        $response->assertUnauthorized();
    }

    public function test_returns_default_when_no_data_no_age(): void
    {
        [, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::Default->value);
        $response->assertJsonPath('max_hr', null);
    }

    public function test_default_path_does_not_persist(): void
    {
        [$user, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [], $headers)->assertOk();

        // Avoid writing the static fallback to the user's row — leaves
        // heart_rate_zones null so HeartRateZones::forUser keeps falling
        // through to the static DEFAULTS at read time.
        $this->assertNull($user->refresh()->heart_rate_zones);
        $this->assertSame(HeartRateZonesSource::Default, $user->heart_rate_zones_source);
    }

    public function test_age_only_persists_derived_age(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 35,
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);

        $user->refresh();
        $this->assertSame(HeartRateZonesSource::DerivedAge, $user->heart_rate_zones_source);
        $this->assertNotNull($user->heart_rate_zones);
        $this->assertCount(5, $user->heart_rate_zones);
    }

    public function test_recompute_overwrites_manual_source_when_age_supplied(): void
    {
        // Explicit user-triggered recompute (e.g. "Recompute from your runs"
        // button on HeartRateZonesSheet) MUST overwrite even when the user
        // previously saved manually. Manual is sticky against automatic
        // flows but not against deliberate user actions.
        [$user, $headers] = $this->authUser();
        $user->update([
            'heart_rate_zones' => [
                ['min' => 0, 'max' => 100],
                ['min' => 100, 'max' => 130],
                ['min' => 130, 'max' => 150],
                ['min' => 150, 'max' => 170],
                ['min' => 170, 'max' => -1],
            ],
            'heart_rate_zones_source' => HeartRateZonesSource::Manual,
        ]);

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 35,
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);

        $user->refresh();
        $this->assertSame(HeartRateZonesSource::DerivedAge, $user->heart_rate_zones_source);
    }

    public function test_observed_high_efforts_correct_max_upward(): void
    {
        [$user, $headers] = $this->authUser();
        // Three race-day or VO2max efforts above Tanaka (184 for age 35) + 5.
        foreach ([195, 193, 191] as $i => $max) {
            WearableActivity::factory()->create([
                'user_id' => $user->id,
                'type' => 'Run',
                'max_heartrate' => $max,
                'average_heartrate' => 165,
                'duration_seconds' => 1800,
                'start_date' => now()->subDays($i * 7 + 1),
            ]);
        }

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 35,
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);
        // Median of [195, 193, 191] = 193
        $response->assertJsonPath('max_hr', 193);
        $response->assertJsonPath('sample_count', 3);
    }

    public function test_age_in_body_persists_birth_year(): void
    {
        // After the runner enters their age once via the manual dialog,
        // the controller stashes birth_year so the dialog never has to
        // open again on subsequent recomputes.
        [$user, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 35,
        ], $headers)->assertOk();

        $expected = now()->year - 35;
        $this->assertSame($expected, $user->refresh()->birth_year);
    }

    public function test_uses_stored_birth_year_when_no_age_in_body(): void
    {
        // Second-call scenario: HealthKit still can't surface DOB, but
        // the runner already typed their age once. Backend must derive
        // from the stored birth_year without prompting again.
        $birthYear = now()->year - 35;
        [$user, $headers] = $this->authUser();
        $user->update(['birth_year' => $birthYear]);

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);
        $response->assertJsonPath('age', 35);
    }

    public function test_body_age_overrides_stored_birth_year(): void
    {
        // Edge case: stored birth_year is wrong (user typed by mistake)
        // and now retypes a different age. Body wins, birth_year updates.
        [$user, $headers] = $this->authUser();
        $user->update(['birth_year' => 1980]); // age 46-ish

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 35,
        ], $headers)->assertOk();

        $expected = now()->year - 35;
        $this->assertSame($expected, $user->refresh()->birth_year);
    }

    public function test_profile_exposes_birth_year(): void
    {
        $birthYear = now()->year - 35;
        [$user, $headers] = $this->authUser();
        $user->update(['birth_year' => $birthYear]);

        $response = $this->getJson('/api/v1/profile', $headers);

        $response->assertOk();
        $response->assertJsonPath('user.birth_year', $birthYear);
    }

    public function test_validates_age_range(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => 200,
        ], $headers)->assertUnprocessable();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'age' => -5,
        ], $headers)->assertUnprocessable();
    }

    public function test_validates_resting_hr_range(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'resting_heart_rate' => 5,
        ], $headers)->assertUnprocessable();
    }
}
