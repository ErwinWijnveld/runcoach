<?php

use App\Support\Intervals\IntervalBlueprint;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;

/**
 * Convert existing `training_days.intervals_json` from the legacy FLAT
 * segment list into the canonical GROUPED blueprint
 * ({warmup_seconds, steps:[{type:block,reps,…}], cooldown_seconds}).
 *
 * Data-only migration (no schema change — `intervals_json` is a JSON column).
 * Idempotent: rows already in grouped form are skipped, so a re-run or a
 * mid-cycle deploy is safe. Garbage / un-foldable rows are nulled.
 */
return new class extends Migration
{
    public function up(): void
    {
        DB::table('training_days')
            ->whereNotNull('intervals_json')
            ->orderBy('id')
            ->chunkById(200, function ($rows) {
                foreach ($rows as $row) {
                    $decoded = json_decode((string) $row->intervals_json, true);

                    // Already grouped → leave it (idempotent).
                    if (IntervalBlueprint::isGrouped($decoded)) {
                        continue;
                    }

                    // Flat list → fold to grouped. Anything else → null,
                    // logged with the raw value so the loss is auditable.
                    $grouped = is_array($decoded) ? IntervalBlueprint::collapse($decoded) : null;
                    $grouped = $grouped !== null ? IntervalBlueprint::normalize($grouped) : null;

                    if ($grouped === null) {
                        Log::warning('[migration] intervals_json could not be converted to grouped blueprint; clearing it.', [
                            'training_day_id' => $row->id,
                            'raw_intervals_json' => (string) $row->intervals_json,
                        ]);
                    }

                    DB::table('training_days')
                        ->where('id', $row->id)
                        ->update(['intervals_json' => $grouped !== null ? json_encode($grouped) : null]);
                }
            });
    }

    public function down(): void
    {
        // Best-effort rollback: expand grouped blueprints back to the flat
        // segment list for local rollbacks.
        DB::table('training_days')
            ->whereNotNull('intervals_json')
            ->orderBy('id')
            ->chunkById(200, function ($rows) {
                foreach ($rows as $row) {
                    $decoded = json_decode((string) $row->intervals_json, true);
                    if (! IntervalBlueprint::isGrouped($decoded)) {
                        continue;
                    }
                    $flat = IntervalBlueprint::expand($decoded);

                    DB::table('training_days')
                        ->where('id', $row->id)
                        ->update(['intervals_json' => $flat !== null ? json_encode($flat) : null]);
                }
            });
    }
};
