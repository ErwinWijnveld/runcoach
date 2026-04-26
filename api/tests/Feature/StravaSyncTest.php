<?php

namespace Tests\Feature;

use App\Models\StravaToken;
use App\Models\User;
use App\Models\WearableActivity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class StravaSyncTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        StravaToken::factory()->create(['user_id' => $user->id]);
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_manual_sync_dispatches_job(): void
    {
        Queue::fake();
        [, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/strava/sync', [], $headers);

        $response->assertOk();
    }

    public function test_list_synced_activities(): void
    {
        [$user, $headers] = $this->authUser();
        WearableActivity::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/v1/strava/activities', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_strava_status(): void
    {
        [, $headers] = $this->authUser();

        $response = $this->getJson('/api/v1/strava/status', $headers);

        $response->assertOk();
        $response->assertJsonStructure(['connected', 'last_sync']);
    }
}
