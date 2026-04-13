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
            ]
        );

        $user->stravaToken()->updateOrCreate(
            ['user_id' => $user->id],
            [
                'access_token' => $stravaData['access_token'],
                'refresh_token' => $stravaData['refresh_token'],
                'expires_at' => Carbon::createFromTimestamp($stravaData['expires_at']),
                'athlete_scope' => 'read,activity:read_all',
            ]
        );

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
}
