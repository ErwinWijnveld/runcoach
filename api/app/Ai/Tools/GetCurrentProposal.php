<?php

namespace App\Ai\Tools;

use App\Models\CoachProposal;
use App\Models\User;
use Illuminate\Contracts\JsonSchema\JsonSchema;
use Laravel\Ai\Contracts\Tool;
use Laravel\Ai\Tools\Request;

class GetCurrentProposal implements Tool
{
    public function __construct(private User $user) {}

    public function description(): string
    {
        return <<<'DESC'
        Fetch the runner's most recent plan proposal (any status: pending, rejected, or accepted). Returns the full payload so you can reference week numbers, day_of_week positions, distances, paces, and goal metadata before proposing an edit.

        USE THIS before `edit_schedule` when you need to see the current plan structure and the payload isn't already in your conversation history.

        Returns `{"none": true}` when the runner has no proposals yet.
        DESC;
    }

    public function schema(JsonSchema $schema): array
    {
        return [];
    }

    public function handle(Request $request): string
    {
        $proposal = CoachProposal::where('user_id', $this->user->id)
            ->latest('id')
            ->first();

        if (! $proposal) {
            return json_encode(['none' => true]);
        }

        return json_encode([
            'proposal_id' => $proposal->id,
            'status' => $proposal->status->value,
            'type' => $proposal->type->value,
            'created_at' => $proposal->created_at->toIso8601String(),
            'payload' => $proposal->payload,
        ]);
    }
}
