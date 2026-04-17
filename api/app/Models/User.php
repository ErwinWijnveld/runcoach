<?php

namespace App\Models;

use App\Enums\CoachStyle;
use Database\Factories\UserFactory;
use Filament\Models\Contracts\FilamentUser;
use Filament\Panel;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'password', 'strava_athlete_id', 'coach_style', 'has_completed_onboarding'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable implements FilamentUser
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

    public function tokenUsages(): HasMany
    {
        return $this->hasMany(TokenUsage::class);
    }

    public function canAccessPanel(Panel $panel): bool
    {
        $allowlist = array_filter(array_map(
            fn (string $email) => trim(Str::lower($email)),
            explode(',', (string) config('app.admin_emails', ''))
        ));

        if (empty($allowlist)) {
            return app()->environment('local');
        }

        return in_array(Str::lower((string) $this->email), $allowlist, true);
    }
}
