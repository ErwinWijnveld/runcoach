<?php

namespace App\Enums;

/**
 * Tracks how the user's heart_rate_zones row got there. Drives onboarding
 * UI copy ("based on N runs" vs "estimated from your age") and lets future
 * scheduled re-derivation skip rows the user explicitly hand-tuned.
 *
 * - Default: column default; never written by app code. heart_rate_zones is
 *   typically null in this state — HeartRateZones::forUser falls through to
 *   the static DEFAULTS table.
 * - DerivedEmpirical: median-of-top-N max_heartrate from the runner's own
 *   recent qualifying runs. Highest confidence.
 * - DerivedAge: Tanaka or Karvonen estimate from HealthKit dateOfBirth +
 *   restingHeartRate when there isn't enough run data yet.
 * - Manual: user edited via HeartRateZonesSheet. We never auto-overwrite
 *   this. Explicit recalculate from the sheet's "Recompute" button DOES
 *   overwrite — that's a deliberate user action.
 */
enum HeartRateZonesSource: string
{
    case Default = 'default';

    /**
     * @deprecated The empirical-as-primary path was removed after v0
     * shipped — observed max from training systematically underestimated
     * true max HR. Kept here so existing rows in `users.heart_rate_zones_source`
     * still hydrate; the deriver no longer produces this value. Next
     * recompute flips the row to `DerivedAge`.
     */
    case DerivedEmpirical = 'derived_empirical';
    case DerivedAge = 'derived_age';
    case Manual = 'manual';
}
