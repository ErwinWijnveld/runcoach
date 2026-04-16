<?php

namespace App\Enums;

enum TrainingType: string
{
    case Easy = 'easy';
    case Tempo = 'tempo';
    case Threshold = 'threshold';
    case Interval = 'interval';
    case LongRun = 'long_run';
    case Recovery = 'recovery';
}
