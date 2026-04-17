<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum TrainingType: string
{
    use HasValues;

    case Easy = 'easy';
    case Tempo = 'tempo';
    case Threshold = 'threshold';
    case Interval = 'interval';
    case LongRun = 'long_run';
    case Recovery = 'recovery';
}
