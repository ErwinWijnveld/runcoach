<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

enum TrainingType: string
{
    use HasValues;

    case Easy = 'easy';
    case Tempo = 'tempo';
    case Interval = 'interval';
    case LongRun = 'long_run';
    case Threshold = 'threshold';

    /**
     * Training types the agent is allowed to generate in new plans.
     *
     * @return list<string>
     */
    public static function activeValues(): array
    {
        return [
            self::Easy->value,
            self::Tempo->value,
            self::Interval->value,
            self::LongRun->value,
            self::Threshold->value,
        ];
    }

    /**
     * Pipe-joined active values — convenient for prompt "a|b|c" unions.
     */
    public static function activeValuesAsPipe(): string
    {
        return implode('|', self::activeValues());
    }
}
