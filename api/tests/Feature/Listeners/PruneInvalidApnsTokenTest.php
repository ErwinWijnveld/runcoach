<?php

namespace Tests\Feature\Listeners;

use App\Models\DeviceToken;
use App\Models\User;
use App\Notifications\PlanGenerationCompleted;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Notifications\Events\NotificationFailed;
use Illuminate\Support\Facades\Event;
use NotificationChannels\Apn\ApnChannel;
use Tests\TestCase;

class PruneInvalidApnsTokenTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_unregistered_token_is_deleted(): void
    {
        $user = User::factory()->create();
        $row = DeviceToken::factory()->create([
            'user_id' => $user->id,
            'token' => str_repeat('a', 64),
        ]);

        Event::dispatch(new NotificationFailed(
            $user,
            new PlanGenerationCompleted('cid'),
            ApnChannel::class,
            ['token' => $row->token, 'error' => 'Unregistered'],
        ));

        $this->assertDatabaseMissing('device_tokens', ['id' => $row->id]);
    }

    public function test_bad_device_token_is_deleted(): void
    {
        $user = User::factory()->create();
        $row = DeviceToken::factory()->create(['user_id' => $user->id]);

        Event::dispatch(new NotificationFailed(
            $user,
            new PlanGenerationCompleted('cid'),
            ApnChannel::class,
            ['token' => $row->token, 'error' => 'BadDeviceToken'],
        ));

        $this->assertDatabaseMissing('device_tokens', ['id' => $row->id]);
    }

    public function test_other_failure_reasons_keep_the_token(): void
    {
        $user = User::factory()->create();
        $row = DeviceToken::factory()->create(['user_id' => $user->id]);

        Event::dispatch(new NotificationFailed(
            $user,
            new PlanGenerationCompleted('cid'),
            ApnChannel::class,
            ['token' => $row->token, 'error' => 'PayloadTooLarge'],
        ));

        $this->assertDatabaseHas('device_tokens', ['id' => $row->id]);
    }

    public function test_non_apn_channel_failures_are_ignored(): void
    {
        $user = User::factory()->create();
        $row = DeviceToken::factory()->create(['user_id' => $user->id]);

        Event::dispatch(new NotificationFailed(
            $user,
            new PlanGenerationCompleted('cid'),
            'mail',
            ['token' => $row->token, 'error' => 'Unregistered'],
        ));

        $this->assertDatabaseHas('device_tokens', ['id' => $row->id]);
    }
}
