<?php

namespace App\Models;

use App\Enums\PlanEvaluationStatus;
use Database\Factories\PlanEvaluationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'goal_id',
    'training_week_id',
    'scheduled_for',
    'status',
    'report_markdown',
    'proposal_id',
    'notification_id',
    'triggered_at',
    'completed_at',
])]
class PlanEvaluation extends Model
{
    /** @use HasFactory<PlanEvaluationFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'status' => PlanEvaluationStatus::class,
            'scheduled_for' => 'date',
            'triggered_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function goal(): BelongsTo
    {
        return $this->belongsTo(Goal::class);
    }

    public function trainingWeek(): BelongsTo
    {
        return $this->belongsTo(TrainingWeek::class);
    }

    public function proposal(): BelongsTo
    {
        return $this->belongsTo(CoachProposal::class, 'proposal_id');
    }

    public function notification(): BelongsTo
    {
        return $this->belongsTo(UserNotification::class, 'notification_id');
    }
}
