<?php

namespace App\Services;

use App\Enums\GoalStatus;
use App\Models\Goal;
use Illuminate\Support\Facades\DB;

class GoalService
{
    /**
     * Make the given goal the runner's single active goal.
     *
     * Demotes every other active goal for the same user to `paused`, so the
     * "one active goal per user" invariant holds. Safe to call on a goal
     * that's already active (it just ensures no others are).
     */
    public function activate(Goal $goal): Goal
    {
        DB::transaction(function () use ($goal) {
            Goal::query()
                ->where('user_id', $goal->user_id)
                ->where('id', '!=', $goal->id)
                ->where('status', GoalStatus::Active)
                ->update(['status' => GoalStatus::Paused]);

            if ($goal->status !== GoalStatus::Active) {
                $goal->status = GoalStatus::Active;
                $goal->save();
            }
        });

        return $goal->fresh();
    }
}
