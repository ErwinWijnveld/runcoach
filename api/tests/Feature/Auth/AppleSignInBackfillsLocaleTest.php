<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use App\Services\Auth\AppleIdentityTokenVerifier;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class AppleSignInBackfillsLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function fakeAppleVerifier(string $sub, ?string $email = null): void
    {
        $mock = Mockery::mock(AppleIdentityTokenVerifier::class);
        $mock->shouldReceive('verify')->andReturn([
            'sub' => $sub,
            'email' => $email ?? 'runner@example.com',
            'email_verified' => true,
        ]);

        $this->app->instance(AppleIdentityTokenVerifier::class, $mock);
    }

    public function test_backfills_dutch_locale_on_first_sign_in_when_header_indicates_dutch(): void
    {
        $this->fakeAppleVerifier('apple-sub-locale-1');

        $this->withHeader('Accept-Language', 'nl-NL,nl;q=0.9,en;q=0.8')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake.jwt'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-locale-1')->firstOrFail();
        $this->assertSame('nl', $user->locale);
    }

    public function test_backfills_english_when_header_indicates_unsupported_language(): void
    {
        $this->fakeAppleVerifier('apple-sub-locale-2');

        $this->withHeader('Accept-Language', 'de-DE,fr;q=0.8')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake.jwt'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-locale-2')->firstOrFail();
        $this->assertSame('en', $user->locale);
    }

    public function test_does_not_overwrite_existing_locale_on_subsequent_sign_ins(): void
    {
        User::factory()->create([
            'apple_sub' => 'apple-sub-locale-3',
            'locale' => 'nl',
        ]);
        $this->fakeAppleVerifier('apple-sub-locale-3');

        $this->withHeader('Accept-Language', 'en-US')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake.jwt'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-locale-3')->firstOrFail();
        $this->assertSame('nl', $user->locale, 'existing locale must not be overwritten');
    }
}
