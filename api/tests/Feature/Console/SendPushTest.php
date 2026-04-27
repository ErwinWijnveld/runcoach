<?php

namespace Tests\Feature\Console;

use App\Models\DeviceToken;
use App\Models\User;
use App\Notifications\AdhocPush;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Tests\TestCase;

class SendPushTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_sends_adhoc_push_to_existing_user_with_token(): void
    {
        Notification::fake();

        $user = User::factory()->create();
        DeviceToken::factory()->for($user)->create();

        $this->artisan('push:send', [
            'user' => $user->id,
            'title' => 'Hello',
            'body' => 'World',
        ])->assertSuccessful();

        Notification::assertSentTo(
            $user,
            AdhocPush::class,
            fn (AdhocPush $n) => $n->titleText === 'Hello' && $n->bodyText === 'World',
        );
    }

    public function test_fails_when_user_does_not_exist(): void
    {
        Notification::fake();

        $this->artisan('push:send', [
            'user' => 999,
            'title' => 'Hello',
            'body' => 'World',
        ])->assertFailed();

        Notification::assertNothingSent();
    }

    public function test_fails_when_user_has_no_ios_tokens(): void
    {
        Notification::fake();

        $user = User::factory()->create();

        $this->artisan('push:send', [
            'user' => $user->id,
            'title' => 'Hello',
            'body' => 'World',
        ])->assertFailed();

        Notification::assertNothingSent();
    }
}
