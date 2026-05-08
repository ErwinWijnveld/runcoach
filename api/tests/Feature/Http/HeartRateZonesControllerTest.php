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

    public function test_dob_persists_derived_age(): void
    {
        [$user, $headers] = $this->authUser();

        $dob = now()->subYears(35)->subDays(40)->toDateString();

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => $dob,
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);

        $user->refresh();
        $this->assertSame(HeartRateZonesSource::DerivedAge, $user->heart_rate_zones_source);
        $this->assertNotNull($user->heart_rate_zones);
        $this->assertCount(5, $user->heart_rate_zones);
        $this->assertSame($dob, $user->date_of_birth->toDateString());
    }

    public function test_recompute_overwrites_manual_source_when_dob_supplied(): void
    {
        // Explicit user-triggered recompute (e.g. "Recompute" button on
        // HeartRateZonesSheet) MUST overwrite even when the user
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
            'date_of_birth' => now()->subYears(35)->toDateString(),
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
            'date_of_birth' => now()->subYears(35)->toDateString(),
        ], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);
        // Median of [195, 193, 191] = 193
        $response->assertJsonPath('max_hr', 193);
        $response->assertJsonPath('sample_count', 3);
    }

    public function test_dob_in_body_persists_on_user(): void
    {
        // After the runner picks a DOB once, the controller stashes it
        // so the picker prefills (or the deriver uses it directly) on
        // subsequent recomputes.
        [$user, $headers] = $this->authUser();

        $dob = now()->subYears(35)->toDateString();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => $dob,
        ], $headers)->assertOk();

        $this->assertSame($dob, $user->refresh()->date_of_birth->toDateString());
    }

    public function test_uses_stored_dob_when_body_omits_it(): void
    {
        // Second-call scenario: HealthKit still can't surface DOB, but
        // the runner already picked one. Backend must derive from
        // the stored value without re-prompting.
        $dob = now()->subYears(35)->subMonths(2)->toDateString();
        [$user, $headers] = $this->authUser();
        $user->update(['date_of_birth' => $dob]);

        $response = $this->postJson('/api/v1/profile/heart-rate-zones/derive', [], $headers);

        $response->assertOk();
        $response->assertJsonPath('source', HeartRateZonesSource::DerivedAge->value);
        $response->assertJsonPath('age', 35);
    }

    public function test_body_dob_overrides_stored_dob(): void
    {
        // Edge case: stored DOB is wrong, runner re-picks. Body wins.
        [$user, $headers] = $this->authUser();
        $user->update(['date_of_birth' => '1980-01-01']);

        $newDob = now()->subYears(35)->toDateString();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => $newDob,
        ], $headers)->assertOk();

        $this->assertSame($newDob, $user->refresh()->date_of_birth->toDateString());
    }

    public function test_profile_exposes_date_of_birth(): void
    {
        $dob = now()->subYears(35)->toDateString();
        [$user, $headers] = $this->authUser();
        $user->update(['date_of_birth' => $dob]);

        $response = $this->getJson('/api/v1/profile', $headers);

        $response->assertOk();
        // Eloquent serialises 'date' cast as ISO 8601 with time component;
        // the wire shape is the full datetime string. Just sanity-check
        // the date portion.
        $value = $response->json('user.date_of_birth');
        $this->assertNotNull($value);
        $this->assertStringStartsWith($dob, (string) $value);
    }

    public function test_validates_dob_today_is_rejected(): void
    {
        // The Cupertino picker clamps maxDate to (today − 5y), so this
        // path is guarded client-side. Backend's `before:today` rule is
        // the belt-and-suspenders second layer: belt-and-suspenders
        // catches anyone bypassing the picker (manual API call, future
        // alternate UI, etc).
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => now()->toDateString(),
        ], $headers)->assertUnprocessable();
    }

    public function test_validates_dob_in_the_future_is_rejected(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => now()->addYears(1)->toDateString(),
        ], $headers)->assertUnprocessable();
    }

    public function test_response_includes_was_corrected_flag(): void
    {
        // Wire-shape contract for the Flutter UI — without the flag,
        // copy variants like "based on your hardest recent runs" can't
        // distinguish "Tanaka prior" from "upward correction applied".
        [$user, $headers] = $this->authUser();

        // 3 high-effort runs above Tanaka(184) + 5.
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

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => now()->subYears(35)->toDateString(),
        ], $headers)
            ->assertOk()
            ->assertJsonPath('was_corrected', true);
    }

    public function test_response_includes_was_corrected_false_for_pure_tanaka(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => now()->subYears(35)->toDateString(),
        ], $headers)
            ->assertOk()
            ->assertJsonPath('was_corrected', false);
    }

    public function test_validates_implausibly_old_dob_is_rejected(): void
    {
        [, $headers] = $this->authUser();

        $this->postJson('/api/v1/profile/heart-rate-zones/derive', [
            'date_of_birth' => '1850-01-01',
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
