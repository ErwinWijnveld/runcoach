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

    /**
     * Average target pace across the working segments of an interval session.
     *
     * On interval days the day-level `target_pace_seconds_per_km` is null
     * by design — pace lives in `intervals_json` per work segment. This
     * accessor surfaces a single representative number (the unweighted
     * mean of every `kind=work` segment's `target_pace_seconds_per_km`)
     * so UI/feedback callsites can show "work avg X:YY/km" without
     * digging through the JSON.
     *
     * Returns null when:
     *  - the day isn't an interval session
     *  - `intervals_json` is missing/empty
     *  - no work segment carries a target pace
     */
    public function workSetAveragePaceSecondsPerKm(): ?int
    {
        if ($this->type !== TrainingType::Interval) {
            return null;
        }

        $segments = $this->intervals_json;
        if (! is_array($segments) || $segments === []) {
            return null;
        }

        $paces = [];
        foreach ($segments as $segment) {
            if (! is_array($segment)) {
                continue;
            }
            if (($segment['kind'] ?? null) !== 'work') {
                continue;
            }
            $pace = $segment['target_pace_seconds_per_km'] ?? null;
            if (is_int($pace) && $pace > 0) {
                $paces[] = $pace;
            }
        }

        if ($paces === []) {
            return null;
        }

        return (int) round(array_sum($paces) / count($paces));
    }
}
