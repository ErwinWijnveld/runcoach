<?php

namespace Tests\Feature\Notifications;

use App\Models\User;
use App\Notifications\PlanGenerationCompleted;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Str;
use Tests\TestCase;

/**
 * Confirms the notification copy switches with the active locale.
 *
 * Production behaviour: Illuminate\Notifications\NotificationSender
 * calls $user->preferredLocale() (via HasLocalePreference, see the User
 * model) and runs toApn() inside withLocale(...). The test mirrors that
 * by setting App::setLocale() directly before invoking toApn().
 */
class PlanGenerationCompletedLocalizationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_renders_dutch_when_user_locale_is_nl(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);
        $notification = new PlanGenerationCompleted(Str::uuid()->toString());

        App::setLocale($user->preferredLocale());
        $message = $notification->toApn($user);

        $this->assertSame('Je trainingsplan staat klaar', $message->title);
        $this->assertSame('Tik om te bekijken en goed te keuren.', $message->body);
    }

    public function test_renders_english_when_user_locale_is_null(): void
    {
        $user = User::factory()->create(['locale' => null]);
        $notification = new PlanGenerationCompleted(Str::uuid()->toString());

        App::setLocale($user->preferredLocale());
        $message = $notification->toApn($user);

        $this->assertSame('Your training plan is ready', $message->title);
        $this->assertSame('Tap to review and accept your plan.', $message->body);
    }
}
