<?php

namespace App\Console\Commands;

use App\Enums\GoalStatus;
use App\Enums\PlanEvaluationStatus;
use App\Jobs\GeneratePlanEvaluation;
use App\Models\PlanEvaluation;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Support\Carbon;

#[Signature('plan:run-evaluations {--date= : Override "today" (YYYY-MM-DD) for backfill / dry runs}')]
#[Description('Dispatch GeneratePlanEvaluation for every pending evaluation whose scheduled date has arrived and whose goal is still active.')]
class RunPlanEvaluations extends Command
{
    public function handle(): int
    {
        $tz = config('app.reminder_timezone', 'Europe/Amsterdam');
        $today = $this->option('date')
            ? Carbon::parse($this->option('date'))
            : now($tz);

        $evaluations = PlanEvaluation::query()
            ->where('status', PlanEvaluationStatus::Pending)
            ->whereDate('scheduled_for', '<=', $today->toDateString())
            ->whereHas('goal', fn ($q) => $q->where('status', GoalStatus::Active))
            ->get();

        foreach ($evaluations as $evaluation) {
            GeneratePlanEvaluation::dispatch($evaluation->id);
        }

        $this->info("Plan evaluations dispatched for {$today->toDateString()}: count={$evaluations->count()}");

        return self::SUCCESS;
    }
}
