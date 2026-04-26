<?php

namespace App\Models;

use Database\Factories\WearableActivityFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'user_id',
    'source',
    'source_activity_id',
    'source_user_id',
    'type',
    'name',
    'distance_meters',
    'duration_seconds',
    'elapsed_seconds',
    'average_pace_seconds_per_km',
    'average_heartrate',
    'max_heartrate',
    'elevation_gain_meters',
    'calories_kcal',
    'start_date',
    'end_date',
    'raw_data',
    'synced_at',
])]
// Raw provider JSON blob is ~5-10KB per row and the client never needs it
// over the wire — it's kept in the DB for future field access without refetching.
#[Hidden(['raw_data'])]
class WearableActivity extends Model
{
    /** @use HasFactory<WearableActivityFactory> */
    use HasFactory;

    /**
     * Activity types we treat as a runner's "run" for matching to a training
     * day. Covers road, trail, and treadmill / virtual runs across providers.
     */
    public const RUN_TYPES = ['Run', 'TrailRun', 'VirtualRun'];

    protected function casts(): array
    {
        return [
            'start_date' => 'datetime',
            'end_date' => 'datetime',
            'raw_data' => 'array',
            'synced_at' => 'datetime',
            'average_heartrate' => 'decimal:1',
            'max_heartrate' => 'decimal:1',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function trainingResults(): HasMany
    {
        return $this->hasMany(TrainingResult::class);
    }

    public function distanceInKm(): float
    {
        return round($this->distance_meters / 1000, 1);
    }

    public function paceSecondsPerKm(): int
    {
        return $this->average_pace_seconds_per_km;
    }
}
