<?php

namespace App\Http\Controllers;

use App\Enums\HeartRateZonesSource;
use App\Support\HeartRateZoneDeriver;
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
     *   - The "Recompute from your runs" button on HeartRateZonesSheet,
     *     which deliberately overrides any prior 'manual' source —
     *     explicit user action, so trust the intent.
     *
     * Age resolution chain (first hit wins):
     *   1. `age` in request body — typically read from HealthKit
     *      `dateOfBirth` on the device, OR typed by the runner in the
     *      manual age dialog when HealthKit can't surface it.
     *   2. `user.birth_year` — persisted from a previous derive call.
     *      Spares the runner from typing their age every time.
     *   3. null → deriver returns Default, controller doesn't persist.
     *
     * Whenever a fresh `age` arrives, we derive birth_year from it and
     * persist it (idempotent — overwrites previous value if user got
     * older into a new bracket; rare but cheap).
     */
    public function derive(Request $request, HeartRateZoneDeriver $deriver): JsonResponse
    {
        $validated = $request->validate([
            'age' => ['nullable', 'integer', 'min:5', 'max:120'],
            'resting_heart_rate' => ['nullable', 'integer', 'min:30', 'max:120'],
        ]);

        $user = $request->user();

        $age = $validated['age'] ?? null;
        if ($age !== null) {
            // Persist birth_year so the runner doesn't have to type their
            // age again on next recompute. Derive from current year so
            // age stays accurate as time passes.
            $user->update(['birth_year' => now()->year - $age]);
        } elseif ($user->birth_year !== null) {
            $age = now()->year - $user->birth_year;
        }

        $result = $deriver->derive(
            $user,
            $age,
            $validated['resting_heart_rate'] ?? null,
        );

        // Skip persistence for the Default fallback — leaves the column
        // null so HeartRateZones::forUser keeps falling through to the
        // static table at read time. Avoids "user has zones, source =
        // default" rows that look half-set in admin.
        if ($result->source !== HeartRateZonesSource::Default) {
            $user->update([
                'heart_rate_zones' => $result->zones,
                'heart_rate_zones_source' => $result->source,
            ]);
        }

        return response()->json($result->toArray());
    }
}
