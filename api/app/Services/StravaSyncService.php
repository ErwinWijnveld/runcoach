<?php

namespace App\Services;

use App\Models\StravaToken;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Support\Facades\Http;

class StravaSyncService
{
    public function getAuthorizeUrl(): string
    {
        $params = http_build_query([
            'client_id' => config('services.strava.client_id'),
            'redirect_uri' => config('services.strava.redirect_uri'),
            'response_type' => 'code',
            'scope' => 'read,activity:read_all',
        ]);

        return "https://www.strava.com/oauth/authorize?$params";
    }

    public function exchangeCode(string $code): array
    {
        $response = Http::post('https://www.strava.com/oauth/token', [
            'client_id' => config('services.strava.client_id'),
            'client_secret' => config('services.strava.client_secret'),
            'code' => $code,
            'grant_type' => 'authorization_code',
        ]);

        $response->throw();

        return $response->json();
    }

    public function createOrUpdateUser(array $stravaData): User
    {
        $athlete = $stravaData['athlete'];

        $user = User::updateOrCreate(
            ['strava_athlete_id' => $athlete['id']],
            [
                'name' => trim($athlete['firstname'].' '.$athlete['lastname']),
                'email' => $athlete['email'] ?? $athlete['id'].'@strava.runcoach',
                'strava_profile_url' => $this->extractProfileUrl($athlete),
            ]
        );

        $token = $user->stravaToken()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'access_token' => $stravaData['access_token'],
                'refresh_token' => $stravaData['refresh_token'],
                'expires_at' => Carbon::createFromTimestamp($stravaData['expires_at']),
                'athlete_scope' => 'read,activity:read_all',
            ]
        );

        // Best-effort zone fetch. Null on failure — compliance scoring falls
        // back to the standard default zones.
        $zones = $this->fetchAthleteZones($token);
        if ($zones !== null) {
            $user->forceFill(['heart_rate_zones' => $zones])->save();
        }

        return $user;
    }

    public function refreshTokenIfNeeded(StravaToken $token): StravaToken
    {
        if (! $token->isExpired()) {
            return $token;
        }

        $response = Http::post('https://www.strava.com/oauth/token', [
            'client_id' => config('services.strava.client_id'),
            'client_secret' => config('services.strava.client_secret'),
            'refresh_token' => $token->refresh_token,
            'grant_type' => 'refresh_token',
        ]);

        $response->throw();
        $data = $response->json();

        $token->update([
            'access_token' => $data['access_token'],
            'refresh_token' => $data['refresh_token'],
            'expires_at' => Carbon::createFromTimestamp($data['expires_at']),
        ]);

        return $token->refresh();
    }

    public function fetchActivities(StravaToken $token, int $page = 1, int $perPage = 30, ?int $after = null, ?int $before = null): array
    {
        $token = $this->refreshTokenIfNeeded($token);

        $query = ['page' => $page, 'per_page' => $perPage];
        if ($after) {
            $query['after'] = $after;
        }
        if ($before) {
            $query['before'] = $before;
        }

        $response = Http::withToken($token->access_token)
            ->get('https://www.strava.com/api/v3/athlete/activities', $query);

        $response->throw();

        return $response->json();
    }

    public function fetchActivity(StravaToken $token, int $stravaActivityId): array
    {
        $token = $this->refreshTokenIfNeeded($token);

        $response = Http::withToken($token->access_token)
            ->get("https://www.strava.com/api/v3/activities/{$stravaActivityId}");

        $response->throw();

        return $response->json();
    }

    /**
     * Fetch per-sample streams (time, distance, heartrate, …) for an activity.
     * Returns `{type: {data: [...]}, ...}` keyed by type. Empty array on failure.
     *
     * @param  array<int, string>  $keys
     * @return array<string, array{data: array<int, int|float>}>
     */
    public function fetchStreams(StravaToken $token, int $stravaActivityId, array $keys = ['time', 'distance', 'heartrate']): array
    {
        $token = $this->refreshTokenIfNeeded($token);

        $response = Http::withToken($token->access_token)
            ->get("https://www.strava.com/api/v3/activities/{$stravaActivityId}/streams", [
                'keys' => implode(',', $keys),
                'key_by_type' => 'true',
            ]);

        $response->throw();

        return $response->json();
    }

    /**
     * Fetch the athlete's heart-rate zones. Returns the raw zone array
     * (5 entries, ordered Z1..Z5, each `{min, max}`; Z5 max is -1) or
     * null on failure / missing profile data. Strava's endpoint requires
     * the `profile:read_all` scope — returns empty otherwise.
     *
     * @return array<int, array{min:int, max:int}>|null
     */
    public function fetchAthleteZones(StravaToken $token): ?array
    {
        try {
            $token = $this->refreshTokenIfNeeded($token);

            $response = Http::withToken($token->access_token)
                ->get('https://www.strava.com/api/v3/athlete/zones');

            if (! $response->successful()) {
                return null;
            }

            $zones = $response->json('heart_rate.zones');
            if (! is_array($zones) || count($zones) < 5) {
                return null;
            }

            // Normalise to plain {min, max} shape, ignoring any extra fields.
            return array_values(array_map(fn ($z) => [
                'min' => (int) ($z['min'] ?? 0),
                'max' => (int) ($z['max'] ?? -1),
            ], $zones));
        } catch (\Throwable $e) {
            report($e);

            return null;
        }
    }

    /**
     * Extract a usable profile picture URL from Strava's athlete payload.
     * Prefers `profile_medium`, falls back to `profile`. Strava returns the
     * literal path "avatar/athlete/..." when the user has no picture set —
     * we treat that as null.
     */
    private function extractProfileUrl(array $athlete): ?string
    {
        $url = $athlete['profile_medium'] ?? $athlete['profile'] ?? null;

        if (! is_string($url) || $url === '') {
            return null;
        }

        if (! str_starts_with($url, 'http')) {
            return null;
        }

        return $url;
    }
}
