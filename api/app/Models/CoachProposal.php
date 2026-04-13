<?php

namespace App\Models;

use App\Enums\ProposalStatus;
use App\Enums\ProposalType;
use Database\Factories\CoachProposalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['agent_message_id', 'user_id', 'type', 'payload', 'status', 'applied_at'])]
class CoachProposal extends Model
{
    /** @use HasFactory<CoachProposalFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'type' => ProposalType::class,
            'payload' => 'array',
            'status' => ProposalStatus::class,
            'applied_at' => 'datetime',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
