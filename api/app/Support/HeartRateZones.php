<?php

namespace App\Support;

use App\Models\User;

/**
 * Single source of truth for HR zone math used by both the compliance
 * scorer (matches an activity against a zone) and the pace-adjustment
 * evaluator (estimates zone midpoint to size a pace shift). Each user can
 * override their zones via `users.heart_rate_zones`; this helper falls
 * back to a generic untrained-athlete table when they haven't.
 *
 * @phpstan-type Zone array{min: int|float, max: int|float}
 */
class HeartRateZones
{
    /**
     * Untrained-athlete defaults (matches Strava's reference table). Five
     * zones, ordered Z1..Z5. Z5's `max = -1` means open-ended (any HR
     * above the lower bound counts as Z5).
     *
     * @var list<Zone>
     */
    public const DEFAULTS = [
        ['min' => 0, 'max' => 115],
        ['min' => 115, 'max' => 152],
        ['min' => 152, 'max' => 171],
        ['min' => 171, 'max' => 190],
        ['min' => 190, 'max' => -1],
    ];

    /**
     * Resolve the zone table for a user. Prefers their stored zones,
     * falls back to defaults if absent or malformed (anything shorter
     * than 5 entries).
     *
     * @return list<Zone>
     */
    public static function forUser(?User $user): array
    {
        $stored = $user?->heart_rate_zones;
        if (is_array($stored) && count($stored) >= 5) {
            return array_values($stored);
        }

        return self::DEFAULTS;
    }

    /**
     * Look up a single zone by 1-based index (Z1..Z5). Returns null when
     * the index is out of range — callers can decide whether that's an
     * error or just "we don't have HR data for this day".
     *
     * @return Zone|null
     */
    public static function zoneFor(?User $user, int $oneBasedIndex): ?array
    {
        $zones = self::forUser($user);

        return $zones[$oneBasedIndex - 1] ?? null;
    }

    /**
     * Midpoint of a zone in bpm. For the open-ended Z5 (max=-1) we use
     * `min + 10` as a conservative estimate — anyone running there is
     * clearly above the rest of the table.
     */
    public static function zoneMidpoint(?User $user, int $oneBasedIndex): ?float
    {
        $zone = self::zoneFor($user, $oneBasedIndex);
        if ($zone === null) {
            return null;
        }

        $min = (float) $zone['min'];
        $max = (float) $zone['max'];

        if ($max < 0) {
            return $min + 10.0;
        }

        return ($min + $max) / 2.0;
    }
}
