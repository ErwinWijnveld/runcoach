<?php

namespace App\Models;

use App\Enums\RaceDistance;
use App\Enums\RaceStatus;
use Database\Factories\RaceFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['user_id', 'name', 'distance', 'custom_distance_meters', 'goal_time_seconds', 'race_date', 'status'])]
class Race extends Model
{
    /** @use HasFactory<RaceFactory> */
    use HasFactory;

    protected function casts(): array
    {
        return [
            'distance' => RaceDistance::class,
            'race_date' => 'date',
            'status' => RaceStatus::class,
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

    public function coachConversations(): HasMany
    {
        return $this->hasMany(CoachConversation::class);
    }

    public function weeksUntilRace(): int
    {
        return (int) now()->diffInWeeks($this->race_date, false);
    }
}
