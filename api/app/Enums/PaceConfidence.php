<?php

namespace App\Enums;

use App\Enums\Concerns\HasValues;

/**
 * How confident `FitnessSnapshotService` is in the threshold pace it
 * derived for the runner. Drives both UI copy on the proposal card
 * ("based on your last 4 weeks…") and how aggressively
 * `TrainingPlanBuilder` ramps quality-day paces.
 */
enum PaceConfidence: string
{
    use HasValues;

    /** Recent (≤30d) threshold-quality effort observed. */
    case High = 'high';

    /** HR-zone-anchored fastest pace derivation succeeded with ≥2 anchors. */
    case Medium = 'medium';

    /** No HR signal — recent average pace used as a proxy. */
    case Low = 'low';

    /** No qualifying recent runs — fallback defaults used. */
    case None = 'none';
}
