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
            'type' => UserNotification::TYPE_PACE_ADJUSTMENT,
            'title' => 'Heads-up on your pace',
            'body' => 'Your heart rate was outside the target zone last run.',
            'action_data' => [
                'source_training_result_id' => null,
                'training_type' => 'easy',
                'pace_factor' => 1.05,
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
