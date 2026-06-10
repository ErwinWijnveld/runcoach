<?php

namespace App\Console\Commands;

use App\Enums\TrainingType;
use App\Models\TrainingResult;
use App\Services\ComplianceScoringService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Facades\DB;
use Throwable;

#[Signature('compliance:rescore-intervals {--dry-run : Print the old → new scores without persisting}')]
#[Description('Re-run compliance scoring for every interval-day training result. One-off backfill after the 2026-06-10 interval-scoring change (max-HR touch + pace band + asymmetric distance); idempotent, safe to re-run.')]
class RescoreIntervalCompliance extends Command
{
    public function handle(ComplianceScoringService $service): int
    {
        $results = TrainingResult::query()
            ->whereNotNull('wearable_activity_id')
            ->whereHas('trainingDay', fn ($query) => $query->where('type', TrainingType::Interval->value))
            ->with(['trainingDay.trainingWeek.goal', 'wearableActivity'])
            ->get();

        if ($results->isEmpty()) {
            $this->info('No interval-day training results to rescore.');

            return self::SUCCESS;
        }

        $dryRun = (bool) $this->option('dry-run');
        $rescored = 0;

        DB::beginTransaction();

        try {
            foreach ($results as $result) {
                if (! $result->trainingDay || ! $result->wearableActivity) {
                    continue;
                }

                $oldScore = (float) $result->compliance_score;
                $fresh = $service->scoreDay($result->trainingDay, $result->wearableActivity);

                $this->line(sprintf(
                    'result #%d (day #%d): %.1f → %.1f',
                    $result->id,
                    $result->training_day_id,
                    $oldScore,
                    (float) $fresh->compliance_score,
                ));
                $rescored++;
            }

            $dryRun ? DB::rollBack() : DB::commit();
        } catch (Throwable $e) {
            DB::rollBack();

            throw $e;
        }

        $this->info($dryRun
            ? "Dry run — {$rescored} interval result(s) would be rescored (rolled back)."
            : "Rescored {$rescored} interval result(s).");

        return self::SUCCESS;
    }
}
