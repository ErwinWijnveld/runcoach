<?php

namespace Tests\Unit\Support\Onboarding;

use App\Enums\IntensityBias;
use App\Enums\RunnerLevel;
use App\Support\Onboarding\OnboardingFormInput;
use PHPUnit\Framework\TestCase;

class OnboardingFormInputTest extends TestCase
{
    public function test_from_array_parses_intensity_bias_take_it_easy(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'intensity_bias' => 'take_it_easy',
        ]);

        $this->assertSame(IntensityBias::TakeItEasy, $input->intensityBias);
    }

    public function test_from_array_parses_intensity_bias_push_me_harder(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'intensity_bias' => 'push_me_harder',
        ]);

        $this->assertSame(IntensityBias::PushMeHarder, $input->intensityBias);
    }

    public function test_from_array_defaults_intensity_bias_to_standard_when_missing(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
        ]);

        $this->assertSame(IntensityBias::Standard, $input->intensityBias);
    }

    public function test_from_array_defaults_intensity_bias_to_standard_for_invalid(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'intensity_bias' => 'nonsense',
        ]);

        $this->assertSame(IntensityBias::Standard, $input->intensityBias);
    }

    public function test_from_array_parses_runner_level_beginner(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'runner_level' => 'beginner',
        ]);

        $this->assertSame(RunnerLevel::Beginner, $input->runnerLevel);
    }

    public function test_from_array_parses_runner_level_sub_elite(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'runner_level' => 'sub_elite',
        ]);

        $this->assertSame(RunnerLevel::SubElite, $input->runnerLevel);
    }

    public function test_from_array_defaults_runner_level_to_intermediate_when_missing(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
        ]);

        $this->assertSame(RunnerLevel::Intermediate, $input->runnerLevel);
    }

    public function test_from_array_defaults_runner_level_to_intermediate_for_invalid(): void
    {
        $input = OnboardingFormInput::fromArray([
            'goal_type' => 'race',
            'days_per_week' => 4,
            'runner_level' => 'nonsense',
        ]);

        $this->assertSame(RunnerLevel::Intermediate, $input->runnerLevel);
    }
}
