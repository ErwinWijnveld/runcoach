<?php

namespace App\Models;

use Database\Factories\StravaActivityFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'strava_id', 'type', 'name', 'distance_meters', 'moving_time_seconds', 'elapsed_time_seconds', 'average_heartrate', 'average_speed', 'start_date', 'summary_polyline', 'raw_data', 'synced_at'])]
// Raw Strava JSON blob is ~5-10KB per row and the client never needs it over
// the wire — it's kept in the DB for future field access without refetching.
#[Hidden(['raw_data'])]
class StravaActivity extends Model
{
    /** @use HasFactory<StravaActivityFactory> */
    use HasFactory;

    /**
     * Strava activity types we treat as a runner's "run" for matching to a
     * training day. Covers road, trail, and treadmill / virtual runs.
     */
    public const RUN_TYPES = ['Run', 'TrailRun', 'VirtualRun'];

    protected function casts(): array
    {
        return [
            'start_date' => 'datetime',
            'raw_data' => 'array',
            'synced_at' => 'datetime',
            'average_heartrate' => 'decimal:1',
            'average_speed' => 'decimal:2',
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
        $km = $this->distance_meters / 1000;
        if ($km <= 0) {
            return 0;
        }

        return (int) round($this->moving_time_seconds / $km);
    }
}
