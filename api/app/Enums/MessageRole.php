<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum MessageRole: string
{
    use HasValues;

    case User = 'user';
    case Assistant = 'assistant';
}
