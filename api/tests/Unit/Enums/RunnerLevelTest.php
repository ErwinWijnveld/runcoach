<?php

namespace Tests\Unit\Enums;

use App\Enums\RunnerLevel;
use App\Enums\RunnerToneBucket;
use PHPUnit\Framework\TestCase;

class RunnerLevelTest extends TestCase
{
    public function test_beginner_maps_to_novice_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Novice, RunnerLevel::Beginner->toneBucket());
    }

    public function test_intermediate_maps_to_standard_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Standard, RunnerLevel::Intermediate->toneBucket());
    }

    public function test_advanced_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::Advanced->toneBucket());
    }

    public function test_sub_elite_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::SubElite->toneBucket());
    }

    public function test_elite_maps_to_expert_tone(): void
    {
        $this->assertSame(RunnerToneBucket::Expert, RunnerLevel::Elite->toneBucket());
    }
}
