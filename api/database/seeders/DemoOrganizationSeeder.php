<?php

namespace Database\Seeders;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Enums\OrganizationStatus;
use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;

class DemoOrganizationSeeder extends Seeder
{
    private const PASSWORD = 'password';

    public function run(): void
    {
        // Two demo orgs so the multi-org admin view has something to show.
        $amsterdam = $this->createOrganization(
            name: 'Amsterdam Running Club',
            slug: 'amsterdam-running-club',
            description: 'A friendly running club based in Amsterdam.',
            coachesOwnPlans: true,
        );

        $berlin = $this->createOrganization(
            name: 'Berlin Striders',
            slug: 'berlin-striders',
            description: 'Performance-focused training group in Berlin.',
            coachesOwnPlans: true,
        );

        // Per-org admins, coaches, clients
        $this->seedOrg(
            organization: $amsterdam,
            adminEmail: 'admin@amsterdam.test',
            coachEmails: ['sarah@amsterdam.test', 'mark@amsterdam.test'],
            clientCount: 4,
        );

        $this->seedOrg(
            organization: $berlin,
            adminEmail: 'admin@berlin.test',
            coachEmails: ['lisa@berlin.test'],
            clientCount: 3,
        );

        // Solo (unaffiliated) demo runner so you can test the request-to-join flow.
        $this->createUser('solo@runcoach.test', 'Solo Runner');

        // A pending invite to a brand-new email so you can test invite acceptance
        // either via deep link or the in-app invite list (after sign-up).
        OrganizationMembership::firstOrCreate(
            [
                'invite_email' => 'invitee@example.test',
                'organization_id' => $amsterdam->id,
                'status' => MembershipStatus::Invited,
            ],
            [
                'role' => OrganizationRole::Client,
                'status' => MembershipStatus::Invited,
                'invite_token' => 'demo-invite-token-amsterdam',
                'invite_email' => 'invitee@example.test',
                'invited_at' => now(),
            ],
        );

        $this->command?->info('');
        $this->command?->info('Demo orgs seeded. All passwords = "password".');
        $this->printCredentialTable();
    }

    private function createOrganization(
        string $name,
        string $slug,
        string $description,
        bool $coachesOwnPlans,
    ): Organization {
        return Organization::firstOrCreate(
            ['slug' => $slug],
            [
                'name' => $name,
                'description' => $description,
                'status' => OrganizationStatus::Active,
                'coaches_own_plans' => $coachesOwnPlans,
            ],
        );
    }

    /**
     * @param  list<string>  $coachEmails
     */
    private function seedOrg(
        Organization $organization,
        string $adminEmail,
        array $coachEmails,
        int $clientCount,
    ): void {
        $admin = $this->createUser($adminEmail, $organization->name.' Admin');
        $this->ensureMembership($organization, $admin, OrganizationRole::OrgAdmin);

        $coaches = [];
        foreach ($coachEmails as $email) {
            $coach = $this->createUser($email, $this->emailToName($email));
            $this->ensureMembership($organization, $coach, OrganizationRole::Coach);
            $coaches[] = $coach;
        }

        // Distribute clients round-robin across the org's coaches.
        for ($i = 1; $i <= $clientCount; $i++) {
            $coach = $coaches[($i - 1) % count($coaches)];
            $email = sprintf('client%d.%s@runcoach.test', $i, $organization->slug);
            $client = $this->createUser($email, sprintf('%s Client %d', $organization->name, $i));

            $this->ensureMembership($organization, $client, OrganizationRole::Client, coach: $coach);

            // Half get an active goal + a real-looking 4-week plan so the schedule
            // editor in the coach panel has data to render.
            if ($i % 2 === 1) {
                $this->seedSampleGoalWithPlan($client, weeks: 4);
            }
        }
    }

    private function createUser(string $email, string $name): User
    {
        return User::firstOrCreate(
            ['email' => $email],
            [
                'name' => $name,
                'password' => Hash::make(self::PASSWORD),
                'has_completed_onboarding' => true,
                'email_verified_at' => now(),
                'coach_style' => 'balanced',
            ],
        );
    }

    private function ensureMembership(
        Organization $organization,
        User $user,
        OrganizationRole $role,
        ?User $coach = null,
    ): OrganizationMembership {
        return OrganizationMembership::updateOrCreate(
            [
                'organization_id' => $organization->id,
                'user_id' => $user->id,
            ],
            [
                'role' => $role,
                'status' => MembershipStatus::Active,
                'coach_user_id' => $role === OrganizationRole::Client ? $coach?->id : null,
                'joined_at' => now(),
            ],
        );
    }

    private function seedSampleGoalWithPlan(User $user, int $weeks): void
    {
        if ($user->goals()->where('status', GoalStatus::Active)->exists()) {
            return;
        }

        $goal = Goal::create([
            'user_id' => $user->id,
            'type' => GoalType::Race,
            'name' => 'Spring Half Marathon',
            'distance' => GoalDistance::HalfMarathon,
            'goal_time_seconds' => 6300, // 1h45
            'target_date' => CarbonImmutable::now()->addWeeks($weeks)->startOfWeek()->addDays(5),
            'status' => GoalStatus::Active,
        ]);

        $weekStart = CarbonImmutable::now()->startOfWeek();

        for ($w = 1; $w <= $weeks; $w++) {
            $week = TrainingWeek::create([
                'goal_id' => $goal->id,
                'week_number' => $w,
                'starts_at' => $weekStart->addWeeks($w - 1),
                'total_km' => 30 + ($w * 4),
                'focus' => match (true) {
                    $w === $weeks => 'taper',
                    $w === $weeks - 1 => 'race-pace tune-up',
                    default => 'base building',
                },
                'coach_notes' => $w === 1 ? 'Welcome week. Keep efforts conversational.' : null,
            ]);

            $this->seedWeekDays($week);
        }
    }

    private function seedWeekDays(TrainingWeek $week): void
    {
        $days = [
            ['day_offset' => 1, 'type' => TrainingType::Easy, 'km' => 6, 'title' => 'Easy', 'pace' => 360],
            ['day_offset' => 2, 'type' => TrainingType::Tempo, 'km' => 8, 'title' => 'Tempo', 'pace' => 280],
            ['day_offset' => 4, 'type' => TrainingType::Easy, 'km' => 5, 'title' => 'Recovery', 'pace' => 380],
            ['day_offset' => 5, 'type' => TrainingType::Interval, 'km' => 6, 'title' => 'Intervals', 'pace' => 240],
            ['day_offset' => 6, 'type' => TrainingType::LongRun, 'km' => 14, 'title' => 'Long run', 'pace' => 340],
        ];

        foreach ($days as $i => $d) {
            TrainingDay::create([
                'training_week_id' => $week->id,
                'date' => $week->starts_at->copy()->addDays($d['day_offset']),
                'type' => $d['type'],
                'title' => $d['title'],
                'description' => null,
                'target_km' => $d['km'],
                'target_pace_seconds_per_km' => $d['pace'],
                'target_heart_rate_zone' => null,
                'order' => $i + 1,
            ]);
        }
    }

    private function emailToName(string $email): string
    {
        $local = Str::before($email, '@');

        return Str::title(str_replace(['.', '_', '-'], ' ', $local));
    }

    private function printCredentialTable(): void
    {
        if ($this->command === null) {
            return;
        }

        $rows = [];
        foreach (Organization::with('memberships.user')->get() as $org) {
            foreach ($org->memberships as $m) {
                if ($m->user === null) {
                    continue;
                }
                $rows[] = [$org->name, $m->role->label(), $m->user->email, 'password'];
            }
        }

        $solo = User::where('email', 'solo@runcoach.test')->first();
        if ($solo) {
            $rows[] = ['—', 'Solo runner', $solo->email, 'password'];
        }

        $this->command->table(
            ['Organization', 'Role', 'Email', 'Password'],
            $rows,
        );
    }
}
