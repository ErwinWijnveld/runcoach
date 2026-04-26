<?php

namespace Database\Factories;

use App\Models\DeviceToken;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<DeviceToken>
 */
class DeviceTokenFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'token' => bin2hex(random_bytes(32)),
            'platform' => DeviceToken::PLATFORM_IOS,
            'app_version' => '1.0.0+7',
            'last_seen_at' => now(),
        ];
    }
}
