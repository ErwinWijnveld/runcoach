<?php

namespace App\Jobs;

use App\Enums\PlanGenerationStatus;
use App\Models\PlanGeneration;
use App\Services\OnboardingPlanGeneratorService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Throwable;

class GeneratePlan implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public int $timeout = 600;

    public int $tries = 1;

    public function __construct(public int $planGenerationId) {}

    public function handle(OnboardingPlanGeneratorService $generator): void
    {
        $row = PlanGeneration::with('user')->find($this->planGenerationId);

        if ($row === null || ! $row->isInFlight()) {
            return;
        }

        $row->update([
            'status' => PlanGenerationStatus::Processing,
            'started_at' => now(),
        ]);

        $result = $generator->generate($row->user, $row->payload);

        $row->update([
            'status' => PlanGenerationStatus::Completed,
            'conversation_id' => $result['conversation_id'],
            'proposal_id' => $result['proposal_id'],
            'completed_at' => now(),
        ]);
    }

    public function failed(Throwable $e): void
    {
        $row = PlanGeneration::find($this->planGenerationId);

        if ($row === null) {
            return;
        }

        $row->update([
            'status' => PlanGenerationStatus::Failed,
            'error_message' => $e->getMessage(),
            'completed_at' => now(),
        ]);
    }
}
