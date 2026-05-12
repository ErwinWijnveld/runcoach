<?php

namespace Tests\Feature\Middleware;

use App\Http\Middleware\SetLocale;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class SetLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Route::middleware([SetLocale::class])
            ->get('/test-locale', fn () => [
                'app_locale' => App::getLocale(),
                'carbon_locale' => Carbon::getLocale(),
            ]);
    }

    public function test_resolves_dutch_from_accept_language_header(): void
    {
        $this->withHeader('Accept-Language', 'nl-NL,nl;q=0.9,en;q=0.8')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'nl', 'carbon_locale' => 'nl']);
    }

    public function test_falls_back_to_app_fallback_when_header_unsupported(): void
    {
        config(['app.fallback_locale' => 'en']);

        $this->withHeader('Accept-Language', 'de-DE,fr;q=0.8')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'en']);
    }

    public function test_authenticated_user_locale_overrides_header(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->actingAs($user)
            ->withHeader('Accept-Language', 'en-US')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'nl']);
    }

    public function test_no_header_no_user_falls_back(): void
    {
        config(['app.fallback_locale' => 'en']);

        $this->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'en']);
    }
}
