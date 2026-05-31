<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;

return new class extends Migration
{
    public function up(): void
    {
        // The pace_adjustment notification type was retired in favour of the
        // 2-week PlanEvaluation flow. Any rows still hanging around are
        // unactionable post-deploy (the controller no longer routes the type)
        // so dismiss them to keep the inbox clean.
        // All pace_adjustment producers were removed in this release; any
        // row still pending in prod is unactionable post-deploy (the
        // controller no longer routes the type). Backfill acted_at when
        // missing so the inbox-clean invariant ("dismissed row has acted_at")
        // stays intact for analytics.
        DB::table('user_notifications')
            ->where('type', 'pace_adjustment')
            ->where('status', 'pending')
            ->update([
                'status' => 'dismissed',
                'acted_at' => DB::raw('COALESCE(acted_at, '.$this->nowExpression().')'),
            ]);
    }

    /**
     * SQLite (used in tests) doesn't have NOW(); MySQL (prod) does. Pick
     * the right expression so the UPDATE works in both.
     */
    private function nowExpression(): string
    {
        return DB::connection()->getDriverName() === 'sqlite'
            ? "datetime('now')"
            : 'NOW()';
    }

    public function down(): void
    {
        // Forward-only — restoring dismissed-status would require tracking
        // which rows we flipped and the type itself is gone.
    }
};
