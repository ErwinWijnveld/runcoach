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
        // Local-only — pick ONE of the two below depending on which dev
        // flow you want.
        //
        // DevOnboardingSeeder (default): drops the dev-login user into a
        // pre-onboarding state with 12 months of realistic run history +
        // age-derived HR zones, so `run-dev.sh` lands them on
        // /onboarding/connect-health with real data feeding the overview
        // screen's metrics + narrative.
        //
        // DevPlanSeeder: post-onboarding flow — seeds a half-marathon
        // plan with last week's completed runs so the workout agent +
        // schedule UI have realistic data to render.
        // $this->call(DevOnboardingSeeder::class);
        $this->call(DevPlanSeeder::class);
    }
}
