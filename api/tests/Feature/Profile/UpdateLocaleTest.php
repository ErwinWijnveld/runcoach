<?php

namespace Tests\Feature\Profile;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UpdateLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_authenticated_user_can_set_locale_to_dutch(): void
    {
        $user = User::factory()->create(['locale' => null]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => 'nl'])
            ->assertOk();

        $this->assertSame('nl', $user->fresh()->locale);
    }

    public function test_locale_can_be_cleared_by_passing_null(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => null])
            ->assertOk();

        $this->assertNull($user->fresh()->locale);
    }

    public function test_unsupported_locale_is_rejected(): void
    {
        $user = User::factory()->create(['locale' => null]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => 'fr'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['locale']);
    }
}
