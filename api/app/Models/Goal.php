<?php

namespace App\Models;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use Database\Factories\GoalFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'type', 'name', 'distance', 'custom_distance_meters', 'goal_time_seconds', 'target_date', 'status'])]
class Goal extends Model
{
    /** @use HasFactory<GoalFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'type' => GoalType::class,
            'distance' => GoalDistance::class,
            'target_date' => 'date',
            'goal_time_seconds' => 'integer',
            'custom_distance_meters' => 'integer',
            'status' => GoalStatus::class,
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function trainingWeeks(): HasMany
    {
        return $this->hasMany(TrainingWeek::class);
    }

    public function weeksUntilTargetDate(): ?int
    {
        if ($this->target_date === null) {
            return null;
        }

        return (int) now()->diffInWeeks($this->target_date, false);
    }
}
