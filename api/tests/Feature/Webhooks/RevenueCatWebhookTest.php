<?php

namespace Tests\Feature\Webhooks;

use App\Jobs\Subscription\ProcessRevenueCatWebhookEvent;
use App\Models\RevenueCatWebhookEvent;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Tests\TestCase;

class RevenueCatWebhookTest extends TestCase
{
    use LazilyRefreshDatabase;

    private const SECRET = 'rc-test-secret-32-bytes-long-xx';

    protected function setUp(): void
    {
        parent::setUp();
        config()->set('services.revenuecat.webhook_secret', self::SECRET);
    }

    public function test_rejects_bad_auth_header(): void
    {
        $response = $this->postJson('/api/webhooks/revenuecat', $this->validPayload(), [
            'Authorization' => 'wrong-secret',
        ]);

        $response->assertStatus(401);
        $this->assertDatabaseCount('revenuecat_webhook_events', 0);
    }

    public function test_rejects_missing_auth_when_secret_configured(): void
    {
        $response = $this->postJson('/api/webhooks/revenuecat', $this->validPayload());

        $response->assertStatus(401);
    }

    public function test_returns_422_for_malformed_event(): void
    {
        $response = $this->postJson('/api/webhooks/revenuecat', ['event' => ['id' => 'x']], [
            'Authorization' => self::SECRET,
        ]);

        $response->assertStatus(422);
    }

    public function test_accepts_valid_event_and_dispatches_job(): void
    {
        Queue::fake();

        $response = $this->postJson('/api/webhooks/revenuecat', $this->validPayload(), [
            'Authorization' => self::SECRET,
        ]);

        $response->assertOk();
        $this->assertDatabaseCount('revenuecat_webhook_events', 1);

        $row = RevenueCatWebhookEvent::first();
        $this->assertSame('evt_initial_1', $row->event_id);
        $this->assertSame('INITIAL_PURCHASE', $row->event_type);
        $this->assertNull($row->processed_at);

        Queue::assertPushed(ProcessRevenueCatWebhookEvent::class, fn ($job) => $job->eventId === $row->id);
    }

    public function test_duplicate_event_id_is_ignored(): void
    {
        Queue::fake();
        $payload = $this->validPayload();

        $first = $this->postJson('/api/webhooks/revenuecat', $payload, ['Authorization' => self::SECRET]);
        $second = $this->postJson('/api/webhooks/revenuecat', $payload, ['Authorization' => self::SECRET]);

        $first->assertOk();
        $second->assertOk();
        $this->assertDatabaseCount('revenuecat_webhook_events', 1);
        Queue::assertPushed(ProcessRevenueCatWebhookEvent::class, 1);
    }

    /**
     * @return array<string, mixed>
     */
    private function validPayload(): array
    {
        return [
            'api_version' => '1.0',
            'event' => [
                'id' => 'evt_initial_1',
                'type' => 'INITIAL_PURCHASE',
                'app_user_id' => '1',
                'product_id' => 'runcoach_pro_yearly',
                'expiration_at_ms' => now()->addYear()->getTimestampMs(),
                'purchased_at_ms' => now()->getTimestampMs(),
                'environment' => 'SANDBOX',
                'period_type' => 'TRIAL',
                'store' => 'APP_STORE',
            ],
        ];
    }
}
