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
}
