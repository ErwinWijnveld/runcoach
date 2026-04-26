<?php

namespace Tests\Feature\Notifications;

use App\Models\DeviceToken;
use App\Models\User;
use App\Notifications\PlanGenerationCompleted;
use App\Notifications\PlanGenerationFailed;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use NotificationChannels\Apn\ApnChannel;
use NotificationChannels\Apn\ApnMessage;
use Tests\TestCase;

class PlanGenerationNotificationsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_completed_notification_targets_apn_with_conversation_payload(): void
    {
        $user = User::factory()->create();
        $cid = '1c3b7b80-4c1e-4f1a-9f5e-3e1f8a8b9b9b';
        $notification = new PlanGenerationCompleted($cid);

        $this->assertSame([ApnChannel::class], $notification->via($user));

        $message = $notification->toApn($user);

        $this->assertInstanceOf(ApnMessage::class, $message);
        $this->assertSame('Your training plan is ready', $message->title);
        $this->assertSame('plan_generation_completed', $message->custom['type']);
        $this->assertSame($cid, $message->custom['conversation_id']);
        $this->assertNotNull($message->expiresAt);
    }

    public function test_failed_notification_payload(): void
    {
        $user = User::factory()->create();
        $message = (new PlanGenerationFailed)->toApn($user);

        $this->assertSame('Plan generation hit a snag', $message->title);
        $this->assertSame('plan_generation_failed', $message->custom['type']);
    }

    public function test_route_notification_for_apn_returns_only_ios_tokens(): void
    {
        $user = User::factory()->create();
        $iosToken = str_repeat('a', 64);
        $androidToken = str_repeat('b', 64);

        DeviceToken::factory()->create([
            'user_id' => $user->id,
            'token' => $iosToken,
            'platform' => DeviceToken::PLATFORM_IOS,
        ]);
        DeviceToken::factory()->create([
            'user_id' => $user->id,
            'token' => $androidToken,
            'platform' => DeviceToken::PLATFORM_ANDROID,
        ]);

        $this->assertSame([$iosToken], $user->routeNotificationForApn());
    }
}
