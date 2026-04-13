<?php

namespace Tests\Feature;

use App\Models\Race;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class RaceTest extends TestCase
{
    use LazilyRefreshDatabase;

    private function authUser(): array
    {
        $user = User::factory()->create();
        $token = $user->createToken('api')->plainTextToken;

        return [$user, ['Authorization' => "Bearer $token"]];
    }

    public function test_list_races(): void
    {
        [$user, $headers] = $this->authUser();
        Race::factory()->count(3)->create(['user_id' => $user->id]);

        $response = $this->getJson('/api/v1/races', $headers);

        $response->assertOk();
        $this->assertCount(3, $response->json('data'));
    }

    public function test_create_race(): void
    {
        [$user, $headers] = $this->authUser();

        $response = $this->postJson('/api/v1/races', [
            'name' => 'Amsterdam Marathon',
            'distance' => 'marathon',
            'goal_time_seconds' => 12600,
            'race_date' => now()->addMonths(3)->format('Y-m-d'),
        ], $headers);

        $response->assertCreated();
        $this->assertDatabaseHas('races', ['name' => 'Amsterdam Marathon']);
    }

    public function test_show_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->getJson("/api/v1/races/{$race->id}", $headers);

        $response->assertOk();
        $response->assertJsonFragment(['name' => $race->name]);
    }

    public function test_update_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->putJson("/api/v1/races/{$race->id}", [
            'name' => 'Updated Race Name',
        ], $headers);

        $response->assertOk();
        $this->assertDatabaseHas('races', ['name' => 'Updated Race Name']);
    }

    public function test_cancel_race(): void
    {
        [$user, $headers] = $this->authUser();
        $race = Race::factory()->create(['user_id' => $user->id]);

        $response = $this->deleteJson("/api/v1/races/{$race->id}", [], $headers);

        $response->assertOk();
        $this->assertDatabaseHas('races', ['id' => $race->id, 'status' => 'cancelled']);
    }

    public function test_cannot_access_other_users_race(): void
    {
        [$user, $headers] = $this->authUser();
        $otherRace = Race::factory()->create();

        $response = $this->getJson("/api/v1/races/{$otherRace->id}", $headers);

        $response->assertForbidden();
    }
}
