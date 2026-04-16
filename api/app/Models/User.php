<?php

namespace App\Models;

use App\Enums\CoachStyle;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'strava_athlete_id', 'coach_style', 'has_completed_onboarding'])]
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
            'coach_style' => CoachStyle::class,
            'has_completed_onboarding' => 'boolean',
        ];
    }

    public function stravaToken(): HasOne
    {
        return $this->hasOne(StravaToken::class);
    }

    public function goals(): HasMany
    {
        return $this->hasMany(Goal::class);
    }

    public function stravaActivities(): HasMany
    {
        return $this->hasMany(StravaActivity::class);
    }

    public function runningProfile(): HasOne
    {
        return $this->hasOne(UserRunningProfile::class);
    }
}
