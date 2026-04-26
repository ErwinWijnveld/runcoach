<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class WearablePersonalRecordsIngestionTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function headers(User $user): array
    {
        $token = $user->createToken('api')->plainTextToken;

        return ['Authorization' => "Bearer $token"];
    }

    public function test_records_keyed_by_meters_round_trip_intact(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/v1/wearable/personal-records', [
            'records' => [
                '5000' => [
                    'duration_seconds' => 1685,
                    'distance_meters' => 5023,
                    'date' => '2025-09-12T07:30:00Z',
                    'source_activity_id' => 'workout-uuid-1',
                ],
                '10000' => [
                    'duration_seconds' => 3620,
                    'distance_meters' => 10120,
                    'date' => '2025-08-01T07:30:00Z',
                    'source_activity_id' => 'workout-uuid-2',
                ],
            ],
        ], $this->headers($user))->assertOk();

        $stored = $user->fresh()->personal_records;
        $this->assertSame(['5000', '10000'], array_map('strval', array_keys($stored)));
        $this->assertSame(1685, $stored['5000']['duration_seconds']);
    }

    public function test_empty_records_payload_does_not_persist_empty_array(): void
    {
        $user = User::factory()->create();
        $user->forceFill(['personal_records' => null])->save();

        $this->postJson('/api/v1/wearable/personal-records', [
            'records' => [],
        ], $this->headers($user))->assertStatus(422); // 'required|array' with empty fails

        $this->assertNull($user->fresh()->personal_records);
    }

    public function test_garbage_keys_are_filtered_and_stored_as_null_when_nothing_valid_remains(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/v1/wearable/personal-records', [
            'records' => [
                'foobar' => [
                    'duration_seconds' => 100,
                    'distance_meters' => 100,
                    'date' => '2025-01-01T00:00:00Z',
                ],
            ],
        ], $this->headers($user))->assertOk();

        $this->assertNull($user->fresh()->personal_records);
    }

    public function test_profile_response_returns_object_shape_for_personal_records(): void
    {
        $user = User::factory()->create();

        $this->postJson('/api/v1/wearable/personal-records', [
            'records' => [
                '5000' => [
                    'duration_seconds' => 1685,
                    'distance_meters' => 5023,
                    'date' => '2025-09-12T07:30:00Z',
                ],
            ],
        ], $this->headers($user))->assertOk();

        $response = $this->getJson('/api/v1/onboarding/profile', $this->headers($user))->assertOk();

        $body = $response->getContent();
        // Must serialize as a JSON object, not array.
        $this->assertStringContainsString('"personal_records":{"5000"', $body);
    }

    public function test_profile_response_returns_null_personal_records_when_unset(): void
    {
        $user = User::factory()->create();
        $user->forceFill(['personal_records' => null])->save();

        $response = $this->getJson('/api/v1/onboarding/profile', $this->headers($user))->assertOk();

        $this->assertNull($response->json('personal_records'));
    }

    public function test_profile_response_coerces_legacy_empty_array_to_null(): void
    {
        $user = User::factory()->create();
        // Simulate a row written by the buggy storePersonalRecords (pre-fix)
        // that stored an empty PHP array. Profile endpoint must not return
        // it as JSON `[]` because Flutter parses this as a Map.
        $user->forceFill(['personal_records' => []])->save();

        $response = $this->getJson('/api/v1/onboarding/profile', $this->headers($user))->assertOk();

        $this->assertNull($response->json('personal_records'));
    }
}
