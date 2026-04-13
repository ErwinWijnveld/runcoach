<?php

namespace Tests\Feature;

use App\Jobs\ProcessStravaActivity;
use App\Models\StravaToken;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class StravaWebhookTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_webhook_verification_challenge(): void
    {
        $response = $this->getJson('/api/v1/webhook/strava?'.http_build_query([
            'hub.mode' => 'subscribe',
            'hub.verify_token' => config('services.strava.webhook_verify_token'),
            'hub.challenge' => 'challenge_string',
        ]));

        $response->assertOk();
        $response->assertJson(['hub.challenge' => 'challenge_string']);
    }

    public function test_webhook_rejects_invalid_verify_token(): void
    {
        $response = $this->getJson('/api/v1/webhook/strava?'.http_build_query([
            'hub.mode' => 'subscribe',
            'hub.verify_token' => 'wrong_token',
            'hub.challenge' => 'challenge_string',
        ]));

        $response->assertForbidden();
    }

    public function test_webhook_dispatches_job_for_activity_create(): void
    {
        Queue::fake();

        $user = User::factory()->create(['strava_athlete_id' => 12345]);
        StravaToken::factory()->create(['user_id' => $user->id]);

        $response = $this->postJson('/api/v1/webhook/strava', [
            'object_type' => 'activity',
            'aspect_type' => 'create',
            'owner_id' => 12345,
            'object_id' => 98765,
        ]);

        $response->assertOk();
        Queue::assertPushed(ProcessStravaActivity::class, function ($job) {
            return $job->stravaActivityId === 98765;
        });
    }

    public function test_webhook_ignores_non_activity_events(): void
    {
        Queue::fake();

        $response = $this->postJson('/api/v1/webhook/strava', [
            'object_type' => 'athlete',
            'aspect_type' => 'update',
            'owner_id' => 12345,
            'object_id' => 12345,
        ]);

        $response->assertOk();
        Queue::assertNotPushed(ProcessStravaActivity::class);
    }
}
