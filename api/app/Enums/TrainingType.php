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

    public function label(): string
    {
        return match ($this) {
            self::Easy => 'Easy',
            self::Tempo => 'Tempo',
            self::Interval => 'Intervals',
            self::LongRun => 'Long run',
            self::Threshold => 'Threshold',
        };
    }

    /**
     * Tailwind color name used by Filament/Tailwind for badges and the
     * left accent bar on each day card. Matches the project palette.
     */
    public function color(): string
    {
        return match ($this) {
            self::Easy => 'emerald',
            self::Tempo => 'amber',
            self::Interval => 'rose',
            self::LongRun => 'sky',
            self::Threshold => 'violet',
        };
    }

    public function emoji(): string
    {
        return match ($this) {
            self::Easy => '🌿',
            self::Tempo => '🔥',
            self::Interval => '⚡',
            self::LongRun => '🏔',
            self::Threshold => '💪',
        };
    }

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
