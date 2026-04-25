<?php

namespace App\Models;

use App\Enums\PlanGenerationStatus;
use Database\Factories\PlanGenerationFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'user_id',
    'status',
    'payload',
    'conversation_id',
    'proposal_id',
    'error_message',
    'started_at',
    'completed_at',
])]
class PlanGeneration extends Model
{
    /** @use HasFactory<PlanGenerationFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'status' => PlanGenerationStatus::class,
            'payload' => 'array',
            'started_at' => 'datetime',
            'completed_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function proposal(): BelongsTo
    {
        return $this->belongsTo(CoachProposal::class, 'proposal_id');
    }

    public function isInFlight(): bool
    {
        return in_array($this->status, [
            PlanGenerationStatus::Queued,
            PlanGenerationStatus::Processing,
        ], true);
    }
}
