<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum PlanGenerationStatus: string
{
    use HasValues;

    case Queued = 'queued';
    case Processing = 'processing';
    case Completed = 'completed';
    case Failed = 'failed';
}
