<?php

namespace Database\Factories;

use App\Models\User;
use App\Models\UserNotification;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<UserNotification>
 */
class UserNotificationFactory extends Factory
{
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'type' => UserNotification::TYPE_PLAN_EVALUATION,
            'title' => 'Your 2-week check-in is ready',
            'body' => "We've suggested a small adjustment based on your last 2 weeks.",
            'action_data' => [
                'evaluation_id' => null,
            ],
            'status' => UserNotification::STATUS_PENDING,
            'acted_at' => null,
        ];
    }

    public function dismissed(): static
    {
        return $this->state(fn () => [
            'status' => UserNotification::STATUS_DISMISSED,
            'acted_at' => now(),
        ]);
    }

    public function accepted(): static
    {
        return $this->state(fn () => [
            'status' => UserNotification::STATUS_ACCEPTED,
            'acted_at' => now(),
        ]);
    }
}
