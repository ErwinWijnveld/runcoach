<?php

namespace App\Models;

use App\Enums\TrainingType;
use Database\Factories\TrainingDayFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasOne;

#[Fillable(['training_week_id', 'date', 'type', 'title', 'description', 'target_km', 'target_pace_seconds_per_km', 'target_heart_rate_zone', 'intervals_json', 'order'])]
class TrainingDay extends Model
{
    /** @use HasFactory<TrainingDayFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'date' => 'date',
            'type' => TrainingType::class,
            'target_km' => 'decimal:1',
            'intervals_json' => 'array',
        ];
    }

    public function trainingWeek(): BelongsTo
    {
        return $this->belongsTo(TrainingWeek::class);
    }

    public function result(): HasOne
    {
        return $this->hasOne(TrainingResult::class);
    }
}
