<?php

namespace App\Models;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'strava_athlete_id', 'level', 'coach_style', 'weekly_km_capacity'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'level' => RunnerLevel::class,
            'coach_style' => CoachStyle::class,
            'weekly_km_capacity' => 'decimal:1',
        ];
    }

    public function stravaToken(): HasOne
    {
        return $this->hasOne(StravaToken::class);
    }

    public function races(): HasMany
    {
        return $this->hasMany(Race::class);
    }

    public function stravaActivities(): HasMany
    {
        return $this->hasMany(StravaActivity::class);
    }
}
