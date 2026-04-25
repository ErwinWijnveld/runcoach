<?php

namespace Tests\Feature\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\PlanOptimizerService;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class PlanOptimizerServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    private PlanOptimizerService $optimizer;

    protected function setUp(): void
    {
        parent::setUp();
        $this->optimizer = app(PlanOptimizerService::class);
    }

    public function test_recalculates_weekly_totals_from_day_distances(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'total_km' => 999.0, // AI nonsense — optimizer should overwrite
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 3, 'type' => 'easy', 'target_km' => 4.0],
                        ['day_of_week' => 6, 'type' => 'easy', 'target_km' => 10.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame(19.0, $result['schedule']['weeks'][0]['total_km']);
    }

    public function test_demotes_long_run_shorter_than_six_km_to_easy(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 3.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 4.1], // too short
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame('easy', $result['schedule']['weeks'][0]['days'][1]['type']);
    }

    public function test_demotes_long_run_that_is_not_the_longest_day(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'build',
                    'days' => [
                        ['day_of_week' => 2, 'type' => 'long_run', 'target_km' => 8.0], // not longest
                        ['day_of_week' => 4, 'type' => 'tempo', 'target_km' => 10.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 18.0], // longest — keeps
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame('easy', $result['schedule']['weeks'][0]['days'][0]['type']);
        $this->assertSame('tempo', $result['schedule']['weeks'][0]['days'][1]['type']);
        $this->assertSame('long_run', $result['schedule']['weeks'][0]['days'][2]['type']);
    }

    public function test_generates_paces_calibrated_to_user_baseline(): void
    {
        $user = $this->userWithBaseline(360); // 6:00/km baseline

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 3, 'type' => 'tempo', 'target_km' => 6.0],
                        ['day_of_week' => 5, 'type' => 'interval', 'target_km' => 8.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 12.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $days = $result['schedule']['weeks'][0]['days'];
        $this->assertSame(390, $days[0]['target_pace_seconds_per_km']); // 360+30 easy
        $this->assertSame(335, $days[1]['target_pace_seconds_per_km']); // 360-25 tempo
        $this->assertSame(310, $days[2]['target_pace_seconds_per_km']); // 360-50 interval
        $this->assertSame(375, $days[3]['target_pace_seconds_per_km']); // 360+15 long_run
    }

    public function test_preserves_explicitly_set_pace(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        [
                            'day_of_week' => 1,
                            'type' => 'easy',
                            'target_km' => 5.0,
                            'target_pace_seconds_per_km' => 270, // user override
                        ],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame(270, $result['schedule']['weeks'][0]['days'][0]['target_pace_seconds_per_km']);
    }

    public function test_falls_back_to_default_pace_when_user_has_no_profile(): void
    {
        $user = User::factory()->create();

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // Default baseline 330 + easy delta 30 = 360
        $this->assertSame(360, $result['schedule']['weeks'][0]['days'][0]['target_pace_seconds_per_km']);
    }

    public function test_generates_titles_from_type_and_distance(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Big Race',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 6.0],
                        ['day_of_week' => 3, 'type' => 'tempo', 'target_km' => 8.5],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 15.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $days = $result['schedule']['weeks'][0]['days'];
        $this->assertSame('Easy', $days[0]['title']);
        $this->assertSame('Tempo', $days[1]['title']);
        // Last day is the race day → title overridden to goal_name
        $this->assertSame('Big Race', $days[2]['title']);
    }

    public function test_generates_interval_title_from_work_segments(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'build',
                    'days' => [
                        [
                            'day_of_week' => 3,
                            'type' => 'interval',
                            'target_km' => 8.0,
                            'intervals' => [
                                ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => 1000],
                                ['kind' => 'work', 'label' => '800m rep', 'distance_m' => 800],
                                ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => 400],
                                ['kind' => 'work', 'label' => '800m rep', 'distance_m' => 800],
                                ['kind' => 'recovery', 'label' => 'Recovery', 'distance_m' => 400],
                                ['kind' => 'work', 'label' => '800m rep', 'distance_m' => 800],
                                ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => 1000],
                            ],
                        ],
                        // Ensure the interval is NOT the last day so the race-day
                        // override doesn't hijack its title.
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 12.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame('Intervals', $result['schedule']['weeks'][0]['days'][0]['title']);
    }

    public function test_last_day_in_plan_is_always_titled_with_goal_name(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Amsterdam Marathon',
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'base',
                        'days' => [
                            ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 15.0],
                        ],
                    ],
                    [
                        'week_number' => 2,
                        'focus' => 'race',
                        'days' => [
                            ['day_of_week' => 7, 'type' => 'tempo', 'target_km' => 42.2],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $this->assertSame('Long run', $result['schedule']['weeks'][0]['days'][0]['title']);
        $this->assertSame('Amsterdam Marathon', $result['schedule']['weeks'][1]['days'][0]['title']);
    }

    public function test_fills_in_interval_segment_paces(): void
    {
        $user = $this->userWithBaseline(300); // 5:00/km baseline

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'build',
                    'days' => [
                        [
                            'day_of_week' => 3,
                            'type' => 'interval',
                            'target_km' => 6.0,
                            'intervals' => [
                                ['kind' => 'warmup', 'label' => 'Warm up', 'distance_m' => 1000],
                                ['kind' => 'work', 'label' => '400m rep', 'distance_m' => 400],
                                ['kind' => 'recovery', 'label' => 'Jog', 'distance_m' => 200],
                                ['kind' => 'cooldown', 'label' => 'Cool down', 'distance_m' => 800],
                            ],
                        ],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $intervals = $result['schedule']['weeks'][0]['days'][0]['intervals'];
        $this->assertSame(330, $intervals[0]['target_pace_seconds_per_km']); // warmup = easy = 300+30
        $this->assertSame(250, $intervals[1]['target_pace_seconds_per_km']); // work = interval = 300-50
        $this->assertSame(360, $intervals[2]['target_pace_seconds_per_km']); // recovery = 300+60
        $this->assertSame(330, $intervals[3]['target_pace_seconds_per_km']); // cooldown = easy
    }

    public function test_keeps_user_stated_target_date_and_drops_days_past_it(): void
    {
        Carbon::setTestNow('2026-04-24'); // Friday
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test Race',
            'goal_type' => 'race',
            'distance' => '10k',
            'target_date' => '2026-04-30', // Thursday of wk2 — authoritative
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'base',
                        'days' => [
                            ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ],
                    ],
                    [
                        'week_number' => 2,
                        'focus' => 'race week',
                        'days' => [
                            ['day_of_week' => 4, 'type' => 'tempo', 'target_km' => 10.0],
                        ],
                    ],
                    [
                        'week_number' => 3,
                        'focus' => 'should be dropped — past target',
                        'days' => [
                            ['day_of_week' => 7, 'type' => 'tempo', 'target_km' => 10.0],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // Stated target_date is preserved verbatim.
        $this->assertSame('2026-04-30', $result['target_date']);
        // Week 3 falls entirely after target_date and is dropped wholesale.
        $this->assertCount(2, $result['schedule']['weeks']);
        $this->assertSame(1, $result['schedule']['weeks'][0]['week_number']);
        $this->assertSame(2, $result['schedule']['weeks'][1]['week_number']);

        Carbon::setTestNow();
    }

    public function test_aligns_target_date_to_last_day_when_none_provided(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Fitness',
            'goal_type' => 'general_fitness',
            'target_date' => null,
            'schedule' => [
                'weeks' => [[
                    'week_number' => 2,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 3, 'type' => 'easy', 'target_km' => 5.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // Plan start Mon 2026-04-20, week 2 starts 2026-04-27, Wednesday = 2026-04-29
        $this->assertSame('2026-04-29', $result['target_date']);

        Carbon::setTestNow();
    }

    public function test_enforces_race_day_distance_pace_and_type(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(342); // ~5:42/km baseline

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Local 10k',
            'distance' => '10k',
            'goal_time_seconds' => 2400, // 40:00 for 10k = 4:00/km
            'target_date' => '2026-05-01', // Friday of week 2
            'schedule' => [
                'weeks' => [[
                    'week_number' => 2,
                    'focus' => 'race week',
                    // AI wrongly scheduled 4km easy on race day.
                    'days' => [
                        [
                            'day_of_week' => 5,
                            'type' => 'easy',
                            'target_km' => 4.0,
                            'description' => 'Easy taper run',
                        ],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        $day = $result['schedule']['weeks'][0]['days'][0];
        $this->assertSame('tempo', $day['type']);
        $this->assertSame(10.0, (float) $day['target_km']);
        $this->assertSame(240, $day['target_pace_seconds_per_km']); // 2400/10
        $this->assertSame('Local 10k', $day['title']);

        Carbon::setTestNow();
    }

    public function test_is_idempotent(): void
    {
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_name' => 'Test',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 3, 'type' => 'tempo', 'target_km' => 7.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 12.0],
                    ],
                ]],
            ],
        ];

        $once = $this->optimizer->optimize($payload, $user);
        $twice = $this->optimizer->optimize($once, $user);

        $this->assertSame($once, $twice);
    }

    public function test_drops_days_violating_preferred_weekdays(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(300);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test',
            'distance' => '10k',
            'target_date' => '2026-05-15',
            'preferred_weekdays' => [1, 3, 5], // Mon, Wed, Fri
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 6, 'type' => 'long_run', 'target_km' => 8.0], // Sat — not allowed
                        ['day_of_week' => 3, 'type' => 'tempo', 'target_km' => 6.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        $days = $result['schedule']['weeks'][0]['days'];
        $dows = array_map(fn ($d) => $d['day_of_week'], $days);

        $this->assertNotContains(6, $dows, 'Saturday should have been dropped (not in preferred_weekdays).');
        $this->assertContains(1, $dows);
        $this->assertContains(3, $dows);

        Carbon::setTestNow();
    }

    public function test_adds_race_day_entry_when_plan_ends_before_target(): void
    {
        Carbon::setTestNow('2026-04-24'); // Friday
        $user = $this->userWithBaseline(342);

        // Plan has 2 weeks; target_date is in week 3.
        // Week 1 Mon = 2026-04-20. Week 3 Fri = 2026-05-08.
        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test Race',
            'distance' => '10k',
            'goal_time_seconds' => 2400,
            'target_date' => '2026-05-08',
            'preferred_weekdays' => [1, 5],
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'base',
                        'days' => [
                            ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ],
                    ],
                    [
                        'week_number' => 2,
                        'focus' => 'build',
                        'days' => [
                            ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 6.0],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // A week 3 should now exist with a Friday race-day entry.
        $weeks = collect($result['schedule']['weeks']);
        $raceWeek = $weeks->firstWhere('week_number', 3);
        $this->assertNotNull($raceWeek, 'A week containing target_date should be added.');
        $this->assertCount(1, $raceWeek['days']);
        $raceDay = $raceWeek['days'][0];
        $this->assertSame(5, $raceDay['day_of_week']); // Friday
        $this->assertSame('tempo', $raceDay['type']);
        $this->assertSame(10.0, (float) $raceDay['target_km']);
        $this->assertSame(240, $raceDay['target_pace_seconds_per_km']); // 2400/10
        $this->assertSame('Test Race', $raceDay['title']);

        Carbon::setTestNow();
    }

    public function test_salvages_misplaced_race_day_description_into_target_slot(): void
    {
        // Regression: when the agent miscounts weeks and places the race
        // entry past target_date (e.g. week 10 day 6 when target_date sits
        // on week 9 day 6), dropDaysPastTarget would discard the agent's
        // detailed description and ensureRaceDayEntry would fall back to
        // a generic skeleton ("Goal day. Execute your plan.").
        // The salvage step should detect the misplaced tempo-typed
        // race-distance day and relocate it to target_date instead.
        Carbon::setTestNow('2026-04-25');
        $user = $this->userWithBaseline(342);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'My Race',
            'distance' => '10k',
            'goal_time_seconds' => 2400,
            'target_date' => '2026-06-20', // Sat, week 9 day 6
            'preferred_weekdays' => [1, 3, 5, 6, 7],
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'base',
                        'days' => [
                            ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ],
                    ],
                    [
                        // Agent miscounted — race day landed here on the
                        // wrong calendar date (2026-06-27, after target).
                        'week_number' => 10,
                        'focus' => 'race',
                        'days' => [
                            [
                                'day_of_week' => 6,
                                'type' => 'tempo',
                                'target_km' => 10.0,
                                'target_pace_seconds_per_km' => 240,
                                'description' => 'Race day! Run your 10k at goal pace. Trust your training!',
                                'target_heart_rate_zone' => 4,
                            ],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // Race day should now sit on week 9 day 6 (target_date) and
        // carry the agent's description, not the generic skeleton.
        $weeks = collect($result['schedule']['weeks']);
        $raceWeek = $weeks->firstWhere('week_number', 9);
        $this->assertNotNull($raceWeek);
        $raceDay = collect($raceWeek['days'])->firstWhere('day_of_week', 6);
        $this->assertNotNull($raceDay);
        $this->assertSame('Race day! Run your 10k at goal pace. Trust your training!', $raceDay['description']);
        $this->assertSame('My Race', $raceDay['title']);
        $this->assertSame(10.0, (float) $raceDay['target_km']);

        // And week 10 should be gone (dropped past target).
        $this->assertNull($weeks->firstWhere('week_number', 10));

        Carbon::setTestNow();
    }

    public function test_does_not_salvage_long_run_as_race_day(): void
    {
        // Long runs typically have km close to the goal distance for
        // shorter races (e.g. 10km long run for a 10k race). They must
        // NOT be misidentified as the race entry. The type-tempo gate
        // is what protects against this.
        Carbon::setTestNow('2026-04-25');
        $user = $this->userWithBaseline(342);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'My Race',
            'distance' => '10k',
            'goal_time_seconds' => 2400,
            'target_date' => '2026-06-20',
            'preferred_weekdays' => [1, 3, 5, 6, 7],
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 6,
                        'focus' => 'build',
                        'days' => [
                            // 10km long run — same km as goal but type=long_run.
                            ['day_of_week' => 7, 'type' => 'long_run', 'target_km' => 10.0],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);

        // Long run should still be present in week 6 (not stolen as race day).
        $weeks = collect($result['schedule']['weeks']);
        $week6 = $weeks->firstWhere('week_number', 6);
        $longRun = collect($week6['days'])->firstWhere('day_of_week', 7);
        $this->assertNotNull($longRun);
        $this->assertSame('long_run', $longRun['type']);

        // Race day should still be inserted as a skeleton on week 9 day 6.
        $raceWeek = $weeks->firstWhere('week_number', 9);
        $raceDay = collect($raceWeek['days'])->firstWhere('day_of_week', 6);
        $this->assertNotNull($raceDay);
        $this->assertSame('My Race', $raceDay['title']);

        Carbon::setTestNow();
    }

    public function test_race_day_keeps_goal_name_title_on_edit_pass(): void
    {
        // Regression: on edit-pass optimize calls (alignRaceDay=false) the
        // race day's title was being clobbered to "{km}km Tempo" because
        // enforceRaceDay nulls the title and generateTitles wasn't given
        // goal_name to recover it. The title must always come back as the
        // goal_name regardless of whether the optimizer is in create or
        // edit mode.
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(342);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => '10k Race — test',
            'distance' => '10k',
            'goal_time_seconds' => 2400,
            'target_date' => '2026-05-08',
            'preferred_weekdays' => [1, 5],
            'schedule' => [
                'weeks' => [
                    [
                        'week_number' => 1,
                        'focus' => 'base',
                        'days' => [
                            ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                        ],
                    ],
                    [
                        'week_number' => 3,
                        'focus' => 'race',
                        'days' => [
                            ['day_of_week' => 5, 'type' => 'tempo', 'target_km' => 10.0, 'title' => 'Stale tempo label'],
                        ],
                    ],
                ],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user, alignRaceDay: false);

        $raceWeek = collect($result['schedule']['weeks'])->firstWhere('week_number', 3);
        $raceDay = $raceWeek['days'][0];
        $this->assertSame('10k Race — test', $raceDay['title']);

        Carbon::setTestNow();
    }

    public function test_promotes_weekly_longest_easy_day_to_long_run(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(300);

        // All easy days — no long_run. Optimizer should promote the 8km day.
        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test',
            'distance' => '10k',
            'target_date' => '2026-06-19',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 2,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 4.0],
                        ['day_of_week' => 3, 'type' => 'easy', 'target_km' => 5.0],
                        ['day_of_week' => 6, 'type' => 'easy', 'target_km' => 8.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        $days = $result['schedule']['weeks'][0]['days'];

        $this->assertSame('easy', $days[0]['type']);
        $this->assertSame('easy', $days[1]['type']);
        $this->assertSame('long_run', $days[2]['type'], 'The 8km day should have been promoted to long_run.');

        Carbon::setTestNow();
    }

    public function test_long_run_promotion_skips_weeks_under_six_km(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(300);

        // Longest is 5km — below MIN_LONG_RUN_KM. Should NOT be promoted.
        $payload = [
            'goal_type' => 'general_fitness',
            'goal_name' => 'Fitness',
            'target_date' => null,
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 3.0],
                        ['day_of_week' => 3, 'type' => 'easy', 'target_km' => 5.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        foreach ($result['schedule']['weeks'][0]['days'] as $day) {
            $this->assertSame('easy', $day['type']);
        }

        Carbon::setTestNow();
    }

    public function test_bumps_too_short_runs_to_runner_specific_minimum(): void
    {
        Carbon::setTestNow('2026-04-24');
        // Runner with 8.6 km/run × 1 run/week. Min = max(4, min(6, 8.6*0.4)) = 4
        $user = User::factory()->create();
        UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => [
                'avg_pace_seconds_per_km' => 342,
                'weekly_avg_km' => 8.6,
                'weekly_avg_runs' => 1,
            ],
        ]);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test',
            'distance' => '10k',
            'target_date' => '2026-05-15',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 3.0], // too short
                        ['day_of_week' => 3, 'type' => 'easy', 'target_km' => 2.0], // too short
                        ['day_of_week' => 5, 'type' => 'easy', 'target_km' => 8.0], // fine
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        $days = $result['schedule']['weeks'][0]['days'];

        $this->assertSame(4.0, (float) $days[0]['target_km']);
        $this->assertSame(4.0, (float) $days[1]['target_km']);
        $this->assertSame(8.0, (float) $days[2]['target_km']);

        Carbon::setTestNow();
    }

    public function test_minimum_run_length_caps_at_six_for_high_mileage_runners(): void
    {
        Carbon::setTestNow('2026-04-24');
        // Marathon runner: 100 km/week ÷ 5 runs = 20 km/run. 20*0.4=8, capped to 6.
        $user = User::factory()->create();
        UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => [
                'avg_pace_seconds_per_km' => 270,
                'weekly_avg_km' => 100.0,
                'weekly_avg_runs' => 5,
            ],
        ]);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Marathon',
            'distance' => 'marathon',
            'target_date' => '2026-07-10',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'base',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 4.0], // short shakeout
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        // Bumped to 6 (capped), not to 8 (0.4*20).
        $this->assertSame(6.0, (float) $result['schedule']['weeks'][0]['days'][0]['target_km']);

        Carbon::setTestNow();
    }

    public function test_preserves_ai_set_progressive_tempo_paces(): void
    {
        // Progression is the agent's job, not the optimizer's. When the AI
        // sets target_pace_seconds_per_km on a quality day, we MUST keep
        // that exact value — only backfill baseline-relative on null.
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(342);

        $payload = [
            'goal_type' => 'race',
            'goal_name' => 'Test',
            'distance' => '10k',
            'goal_time_seconds' => 2400,
            'target_date' => '2026-05-15',
            'schedule' => [
                'weeks' => [[
                    'week_number' => 2,
                    'focus' => 'build',
                    'days' => [
                        // Early-build tempo: AI sets goal + 25s = 265.
                        ['day_of_week' => 3, 'type' => 'tempo', 'target_km' => 6.0, 'target_pace_seconds_per_km' => 265],
                        // Later interval: AI sets goal + 5s = 245.
                        ['day_of_week' => 5, 'type' => 'interval', 'target_km' => 6.0, 'target_pace_seconds_per_km' => 245],
                        // Easy unset → server fills baseline + 30 = 372.
                        ['day_of_week' => 1, 'type' => 'easy', 'target_km' => 5.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        $days = $result['schedule']['weeks'][0]['days'];

        $this->assertSame(265, $days[0]['target_pace_seconds_per_km']);
        $this->assertSame(245, $days[1]['target_pace_seconds_per_km']);
        $this->assertSame(372, $days[2]['target_pace_seconds_per_km']);

        Carbon::setTestNow();
    }

    public function test_backfills_baseline_tempo_pace_when_ai_left_it_null(): void
    {
        Carbon::setTestNow('2026-04-24');
        $user = $this->userWithBaseline(360);

        $payload = [
            'goal_type' => 'general_fitness',
            'goal_name' => 'Fitness',
            'target_date' => null,
            'schedule' => [
                'weeks' => [[
                    'week_number' => 1,
                    'focus' => 'build',
                    'days' => [
                        ['day_of_week' => 1, 'type' => 'tempo', 'target_km' => 6.0],
                    ],
                ]],
            ],
        ];

        $result = $this->optimizer->optimize($payload, $user);
        // Null tempo pace → baseline-relative backfill: 360 - 25 = 335.
        $this->assertSame(335, $result['schedule']['weeks'][0]['days'][0]['target_pace_seconds_per_km']);

        Carbon::setTestNow();
    }

    private function userWithBaseline(int $paceSeconds): User
    {
        $user = User::factory()->create();
        UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => ['avg_pace_seconds_per_km' => $paceSeconds],
        ]);

        return $user;
    }
}
