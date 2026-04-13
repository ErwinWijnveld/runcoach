<?php

namespace App\Models;

use Database\Factories\TrainingResultFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['training_day_id', 'strava_activity_id', 'compliance_score', 'actual_km', 'actual_pace_seconds_per_km', 'actual_avg_heart_rate', 'pace_score', 'distance_score', 'heart_rate_score', 'ai_feedback', 'matched_at'])]
class TrainingResult extends Model
{
    /** @use HasFactory<TrainingResultFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'compliance_score' => 'decimal:1',
            'actual_km' => 'decimal:1',
            'actual_avg_heart_rate' => 'decimal:1',
            'pace_score' => 'decimal:1',
            'distance_score' => 'decimal:1',
            'heart_rate_score' => 'decimal:1',
            'matched_at' => 'datetime',
        ];
    }

    public function trainingDay(): BelongsTo
    {
        return $this->belongsTo(TrainingDay::class);
    }

    public function stravaActivity(): BelongsTo
    {
        return $this->belongsTo(StravaActivity::class);
    }
}
