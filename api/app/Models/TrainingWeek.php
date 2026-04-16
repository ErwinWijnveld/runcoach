<?php

namespace App\Models;

use Database\Factories\TrainingWeekFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['goal_id', 'week_number', 'starts_at', 'total_km', 'focus', 'coach_notes'])]
class TrainingWeek extends Model
{
    /** @use HasFactory<TrainingWeekFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'starts_at' => 'date',
            'total_km' => 'decimal:1',
        ];
    }

    public function goal(): BelongsTo
    {
        return $this->belongsTo(Goal::class);
    }

    public function trainingDays(): HasMany
    {
        return $this->hasMany(TrainingDay::class);
    }
}
