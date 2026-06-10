<?php

use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

/**
 * Backfill the interval-distance invariant: every interval-type training day's
 * `target_km` must equal `IntervalBlueprint::estimateTotalKm(intervals_json)`.
 * Existing rows were written by the old builder (`max(estimate, allocated)`
 * inflation) or went stale when a later edit changed the blueprint without
 * touching the distance. Affected weeks get their `total_km` re-summed.
 *
 * Data-only migration (no schema change). Idempotent: the estimator is a pure
 * function of the blueprint, so a re-run is a no-op.
 * Spec: docs/superpowers/specs/2026-06-10-interval-target-km-recompute.md.
 */
return new class extends Migration
{
    public function up(): void
    {
        $touchedWeekIds = [];

        DB::table('training_days')
            ->where('type', 'interval')
            ->whereNotNull('intervals_json')
            ->orderBy('id')
            ->chunkById(200, function ($rows) use (&$touchedWeekIds) {
                foreach ($rows as $row) {
                    $estimated = IntervalBlueprint::estimateTotalKm(
                        json_decode((string) $row->intervals_json, true),
                    );
                    if ($estimated === null || abs($estimated - (float) $row->target_km) < 0.05) {
                        continue;
                    }

                    DB::table('training_days')
                        ->where('id', $row->id)
                        ->update(['target_km' => $estimated]);
                    $touchedWeekIds[$row->training_week_id] = true;
                }
            });

        foreach (array_keys($touchedWeekIds) as $weekId) {
            $total = (float) DB::table('training_days')
                ->where('training_week_id', $weekId)
                ->sum('target_km');

            DB::table('training_weeks')
                ->where('id', $weekId)
                ->update(['total_km' => round($total, 1)]);
        }
    }

    public function down(): void
    {
        // Intentionally irreversible: the pre-backfill values were stale
        // artifacts with no independent meaning. Forward-fix if needed.
    }
};
