<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * Which path through the derivation cascade produced the snapshot's
 * threshold pace. Surfaced for diagnostics + Filament admin so we can
 * see why a particular plan got the paces it did.
 */
enum PaceDerivation: string
{
    use HasValues;

    /** Tier 1 — a single recent run looked like a tempo / time-trial effort. */
    case RecentThresholdEffort = 'recent_threshold_effort';

    /** Tier 2 — fastest sustained pace per HR zone, last 90 days. */
    case HrZonePace = 'hr_zone_pace';

    /** Tier 3 — recent (30d) average pace + heuristic offsets. */
    case RecentAverage = 'recent_average';

    /** Tier 4 — provider defaults; no recent activity signal at all. */
    case Fallback = 'fallback';
}
