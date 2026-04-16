<?php

namespace Tests\Feature\Models;

use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserRunningProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_belongs_to_user(): void
    {
        $user = User::factory()->create();
        $profile = UserRunningProfile::create([
            'user_id' => $user->id,
            'analyzed_at' => now(),
            'data_start_date' => now()->subYear(),
            'data_end_date' => now(),
            'metrics' => ['weekly_avg_km' => 25.0],
            'narrative_summary' => 'Consistent year.',
        ]);

        $this->assertEquals($user->id, $profile->user->id);
        $this->assertEquals(25.0, $profile->metrics['weekly_avg_km']);
    }
}
