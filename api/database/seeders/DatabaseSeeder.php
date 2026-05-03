<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        $this->call(AdminUserSeeder::class);
        $this->call(DemoOrganizationSeeder::class);
        // Local-only — populates the dev-login user with a half-marathon
        // plan + last week's completed runs so the workout agent + schedule
        // UI have realistic data to render.
        $this->call(DevPlanSeeder::class);
    }
}
