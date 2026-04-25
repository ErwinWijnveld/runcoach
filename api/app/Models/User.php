<?php

namespace App\Models;

use App\Enums\CoachStyle;
use App\Enums\PlanGenerationStatus;
use App\Enums\ProposalStatus;
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

#[Fillable(['name', 'email', 'password', 'strava_athlete_id', 'strava_profile_url', 'coach_style', 'has_completed_onboarding', 'heart_rate_zones'])]
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
            'heart_rate_zones' => 'array',
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

    public function planGenerations(): HasMany
    {
        return $this->hasMany(PlanGeneration::class);
    }

    /**
     * Latest plan generation that requires the user's attention right now,
     * or null. Includes a read-time watchdog: any row stuck in queued/
     * processing for >10 minutes is auto-marked failed (covers worker
     * death where the job's own failed() callback never fires).
     */
    public function pendingPlanGeneration(): ?PlanGeneration
    {
        $latest = $this->planGenerations()
            ->with('proposal')
            ->orderByDesc('id')
            ->first();

        if ($latest === null) {
            return null;
        }

        if ($latest->isInFlight()) {
            $started = $latest->started_at ?? $latest->created_at;
            if ($started->lt(now()->subMinutes(10))) {
                $latest->update([
                    'status' => PlanGenerationStatus::Failed,
                    'error_message' => 'Generation timed out',
                    'completed_at' => now(),
                ]);
            }
        }

        if ($latest->status === PlanGenerationStatus::Completed) {
            $proposal = $latest->proposal;
            if ($proposal === null || $proposal->status !== ProposalStatus::Pending) {
                return null;
            }
        }

        return $latest;
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
