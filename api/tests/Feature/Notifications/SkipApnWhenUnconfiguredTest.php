<?php

namespace Tests\Feature\Notifications;

use App\Models\User;
use App\Notifications\PlanGenerationCompleted;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Notifications\Events\NotificationSending;
use Illuminate\Support\Facades\Event;
use NotificationChannels\Apn\ApnChannel;
use Tests\TestCase;

class SkipApnWhenUnconfiguredTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_apn_send_is_halted_when_no_signing_key_is_configured(): void
    {
        config([
            'broadcasting.connections.apn.private_key_content' => null,
            'broadcasting.connections.apn.private_key_path' => '/nonexistent/AuthKey.p8',
        ]);

        $user = User::factory()->create();
        $event = new NotificationSending($user, new PlanGenerationCompleted('conv-uuid'), ApnChannel::class);

        $this->assertFalse(Event::until($event));
    }

    public function test_apn_send_proceeds_when_inline_key_content_is_present(): void
    {
        config([
            'broadcasting.connections.apn.private_key_content' => '-----BEGIN PRIVATE KEY-----fake-----END PRIVATE KEY-----',
            'broadcasting.connections.apn.private_key_path' => null,
        ]);

        $user = User::factory()->create();
        $event = new NotificationSending($user, new PlanGenerationCompleted('conv-uuid'), ApnChannel::class);

        // No listener halts the send → null (not false) means "carry on".
        $this->assertNotFalse(Event::until($event));
    }

    public function test_non_apn_channels_are_never_halted(): void
    {
        config([
            'broadcasting.connections.apn.private_key_content' => null,
            'broadcasting.connections.apn.private_key_path' => '/nonexistent/AuthKey.p8',
        ]);

        $user = User::factory()->create();
        $event = new NotificationSending($user, new PlanGenerationCompleted('conv-uuid'), 'database');

        $this->assertNotFalse(Event::until($event));
    }
}
