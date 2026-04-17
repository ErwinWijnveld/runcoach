<?php

namespace Tests\Feature\Services;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use App\Models\CoachProposal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;
use Tests\TestCase;

class ProposalServiceScheduleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_apply_create_schedule_drops_training_days_before_today(): void
    {
        // Freeze to a Thursday so day_of_week 1..3 (Mon..Wed) are in the past.
        Carbon::setTestNow(Carbon::parse('2026-04-16')); // Thursday

        $user = User::factory()->create(['has_completed_onboarding' => true]);

        $proposal = CoachProposal::create([
            'agent_message_id' => Str::uuid()->toString(),
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => [
                'goal_type' => 'general_fitness',
                'goal_name' => 'Test Plan',
                'target_date' => null,
                'distance' => null,
                'goal_time_seconds' => null,
                'schedule' => [
                    'weeks' => [
                        [
                            'week_number' => 1,
                            'total_km' => 20,
                            'focus' => 'base',
                            'days' => [
                                ['day_of_week' => 1, 'type' => 'easy', 'title' => 'Past Mon'],
                                ['day_of_week' => 2, 'type' => 'easy', 'title' => 'Past Tue'],
                                ['day_of_week' => 4, 'type' => 'easy', 'title' => 'Today Thu'],
                                ['day_of_week' => 6, 'type' => 'long_run', 'title' => 'Future Sat'],
                            ],
                        ],
                    ],
                ],
            ],
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $days = $user->goals()->first()
            ->trainingWeeks()->first()
            ->trainingDays()
            ->orderBy('date')
            ->pluck('title')
            ->all();

        $this->assertSame(['Today Thu', 'Future Sat'], $days);
    }

    public function test_apply_create_schedule_persists_interval_splits_for_interval_days(): void
    {
        Carbon::setTestNow(Carbon::parse('2026-04-13')); // Monday

        $user = User::factory()->create(['has_completed_onboarding' => true]);

        $proposal = CoachProposal::create([
            'agent_message_id' => Str::uuid()->toString(),
            'user_id' => $user->id,
            'type' => ProposalType::CreateSchedule,
            'payload' => [
                'goal_type' => 'pr_attempt',
                'goal_name' => '10k PR attempt',
                'target_date' => null,
                'distance' => '10k',
                'goal_time_seconds' => 2700,
                'schedule' => [
                    'weeks' => [
                        [
                            'week_number' => 1,
                            'total_km' => 30,
                            'focus' => 'speed work',
                            'days' => [
                                [
                                    'day_of_week' => 3, // Wed
                                    'type' => 'interval',
                                    'title' => '6x800m',
                                    'target_km' => 10.0,
                                    'intervals' => [
                                        ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => 1500, 'duration_seconds' => 540, 'target_pace_seconds_per_km' => 360],
                                        ['kind' => 'work', 'label' => '800m @ 10k pace', 'distance_m' => 800, 'duration_seconds' => 216, 'target_pace_seconds_per_km' => 270],
                                        ['kind' => 'recovery', 'label' => 'Recovery jog', 'distance_m' => 400, 'duration_seconds' => 180, 'target_pace_seconds_per_km' => 450],
                                        ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => 1000, 'duration_seconds' => 360, 'target_pace_seconds_per_km' => 360],
                                    ],
                                ],
                                [
                                    'day_of_week' => 5, // Fri — no intervals field
                                    'type' => 'easy',
                                    'title' => 'Easy run',
                                    'target_km' => 6.0,
                                ],
                            ],
                        ],
                    ],
                ],
            ],
            'status' => ProposalStatus::Pending,
            'applied_at' => null,
        ]);

        app(ProposalService::class)->apply($proposal, $user);

        $days = $user->goals()->first()
            ->trainingWeeks()->first()
            ->trainingDays()
            ->orderBy('order')
            ->get();

        $this->assertCount(2, $days);

        $intervalDay = $days->firstWhere('title', '6x800m');
        $this->assertNotNull($intervalDay->intervals_json);
        $this->assertCount(4, $intervalDay->intervals_json);
        $this->assertSame('warmup', $intervalDay->intervals_json[0]['kind']);
        $this->assertSame(800, $intervalDay->intervals_json[1]['distance_m']);

        $easyDay = $days->firstWhere('title', 'Easy run');
        $this->assertNull($easyDay->intervals_json);
    }
}
