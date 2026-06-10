<?php

namespace Tests\Feature\Filament;

use App\Filament\Resources\Users\Pages\ListUsers;
use App\Models\DeviceToken;
use App\Models\User;
use App\Notifications\AdhocPush;
use Filament\Actions\Testing\TestAction;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Notification;
use Livewire\Livewire;
use Tests\TestCase;

class UserResourceSendPushTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_send_push_action_queues_notification_for_user_with_device(): void
    {
        Notification::fake();

        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create();
        DeviceToken::factory()->create(['user_id' => $runner->id]);
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('sendPush', $runner, data: [
                'title' => 'Hello',
                'body' => 'Test message from admin',
            ]);

        Notification::assertSentTo(
            $runner,
            AdhocPush::class,
            fn (AdhocPush $push): bool => $push->titleText === 'Hello'
                && $push->bodyText === 'Test message from admin',
        );
    }

    public function test_send_push_action_skips_user_without_device_tokens(): void
    {
        Notification::fake();

        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create();
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('sendPush', $runner, data: [
                'title' => 'Hello',
                'body' => 'Test message',
            ]);

        Notification::assertNothingSent();
    }

    public function test_send_push_action_requires_title_and_body(): void
    {
        Notification::fake();

        $admin = User::factory()->create(['is_superadmin' => true]);
        $runner = User::factory()->create();
        DeviceToken::factory()->create(['user_id' => $runner->id]);
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->callTableAction('sendPush', $runner, data: [
                'title' => '',
                'body' => '',
            ])
            ->assertHasTableActionErrors(['title', 'body']);

        Notification::assertNothingSent();
    }

    public function test_bulk_send_push_queues_for_selected_users_with_devices(): void
    {
        Notification::fake();

        $admin = User::factory()->create(['is_superadmin' => true]);
        $withDevice = User::factory()->create();
        DeviceToken::factory()->create(['user_id' => $withDevice->id]);
        $withoutDevice = User::factory()->create();
        $this->actingAs($admin);

        Livewire::test(ListUsers::class)
            ->selectTableRecords([$withDevice->id, $withoutDevice->id])
            ->callAction(TestAction::make('sendPushBulk')->table()->bulk(), data: [
                'title' => 'Hello all',
                'body' => 'Bulk message',
            ]);

        Notification::assertSentTo($withDevice, AdhocPush::class);
        Notification::assertNotSentTo($withoutDevice, AdhocPush::class);
    }
}
