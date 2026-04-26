<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class AdminUserSeeder extends Seeder
{
    public function run(): void
    {
        $email = env('ADMIN_SEED_EMAIL', 'admin@runcoach.local');
        $password = env('ADMIN_SEED_PASSWORD', 'admin');

        User::updateOrCreate(
            ['email' => $email],
            [
                'name' => 'Admin',
                'password' => Hash::make($password),
                'has_completed_onboarding' => true,
                'email_verified_at' => now(),
                'is_superadmin' => true,
            ],
        );

        $this->command?->info("Admin user ready: {$email} / {$password}");
    }
}
