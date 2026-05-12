<?php

namespace Tests\Feature\Enums;

use App\Enums\TrainingType;
use Illuminate\Support\Facades\App;
use Tests\TestCase;

class TrainingTypeLabelTest extends TestCase
{
    public function test_english_labels(): void
    {
        App::setLocale('en');

        $this->assertSame('Easy', TrainingType::Easy->label());
        $this->assertSame('Tempo', TrainingType::Tempo->label());
        $this->assertSame('Intervals', TrainingType::Interval->label());
        $this->assertSame('Long run', TrainingType::LongRun->label());
        $this->assertSame('Threshold', TrainingType::Threshold->label());
    }

    public function test_dutch_labels(): void
    {
        App::setLocale('nl');

        $this->assertSame('Rustig', TrainingType::Easy->label());
        $this->assertSame('Lange duurloop', TrainingType::LongRun->label());
        $this->assertSame('Drempel', TrainingType::Threshold->label());
    }
}
