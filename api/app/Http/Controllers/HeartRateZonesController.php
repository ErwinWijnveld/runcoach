<?php

namespace App\Http\Controllers;

use App\Enums\HeartRateZonesSource;
use App\Support\HeartRateZoneDeriver;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class HeartRateZonesController extends Controller
{
    /**
     * Compute and persist a fresh five-zone HR table for the authenticated
     * user. Uses Tanaka (`208 − 0.7·age`) + optional Karvonen (when RHR
     * available) + optional upward correction from observed peaks. See
     * `HeartRateZoneDeriver` for the algorithm.
     *
     * Called from two places:
     *   - End of onboarding, between connect-health and overview, to set
     *     up the runner's first set of zones automatically.
     *   - The "Recompute" button on HeartRateZonesSheet, which deliberately
     *     overrides any prior 'manual' source — explicit user action.
     *
     * Date-of-birth resolution chain (first hit wins):
     *   1. `date_of_birth` in request body — typically read from HealthKit
     *      `dateOfBirth` on the device, OR picked by the runner in the
     *      manual DOB sheet when HealthKit can't surface it.
     *   2. `user.date_of_birth` — persisted from a previous derive call.
     *      Spares the runner from re-entering DOB every time.
     *   3. null → deriver returns Default, controller doesn't persist.
     *
     * Whenever a fresh `date_of_birth` arrives, we persist it. Age is
     * computed from DOB at runtime (so it stays accurate over years +
     * triggers the yearly birthday push).
     */
    public function derive(Request $request, HeartRateZoneDeriver $deriver): JsonResponse
    {
        $validated = $request->validate([
            'date_of_birth' => ['nullable', 'date', 'before:today', 'after:1900-01-01'],
            'resting_heart_rate' => ['nullable', 'integer', 'min:30', 'max:120'],
        ]);

        $user = $request->user();

        if (! empty($validated['date_of_birth'])) {
            $user->update(['date_of_birth' => $validated['date_of_birth']]);
        }

        // Compute age from whichever DOB we now have on file. Carbon's
        // `age` accessor handles month/day rollover correctly (turns 35
        // → 34 if the runner hasn't had this year's birthday yet).
        $age = $user->date_of_birth !== null
            ? CarbonImmutable::parse($user->date_of_birth)->age
            : null;

        $result = $deriver->derive(
            $user,
            $age,
            $validated['resting_heart_rate'] ?? null,
        );

        // Skip persistence for the Default fallback — leaves the column
        // null so HeartRateZones::forUser keeps falling through to the
        // static table at read time.
        if ($result->source !== HeartRateZonesSource::Default) {
            $user->update([
                'heart_rate_zones' => $result->zones,
                'heart_rate_zones_source' => $result->source,
            ]);
        }

        return response()->json($result->toArray());
    }
}
