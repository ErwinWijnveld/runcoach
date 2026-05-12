<?php

namespace Tests\Feature\Models;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_locale_column_persists_and_round_trips(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->assertSame('nl', $user->fresh()->locale);
    }

    public function test_locale_defaults_to_null(): void
    {
        $user = User::factory()->create();

        $this->assertNull($user->fresh()->locale);
    }

    public function test_preferred_locale_returns_stored_locale_when_set(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->assertSame('nl', $user->preferredLocale());
    }

    public function test_preferred_locale_falls_back_to_app_fallback_when_null(): void
    {
        config(['app.fallback_locale' => 'en']);
        $user = User::factory()->create(['locale' => null]);

        $this->assertSame('en', $user->preferredLocale());
    }
}
