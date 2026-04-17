<?php

namespace App\Enums\Concerns;

trait HasValues
{
    /**
     * All backed values as an array.
     *
     * @return list<string>
     */
    public static function values(): array
    {
        return array_column(self::cases(), 'value');
    }

    /**
     * All backed values joined with '|' — handy for pipe-separated
     * unions in AI tool descriptions and prompts.
     */
    public static function valuesAsPipe(): string
    {
        return implode('|', self::values());
    }
}
