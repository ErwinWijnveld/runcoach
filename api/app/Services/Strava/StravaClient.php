<?php

namespace App\Services\Strava;

use App\Models\User;
use App\Services\StravaSyncService;
use Carbon\Carbon;

class StravaClient
{
    private const MAX_PAGES = 10;

    private const PER_PAGE = 30;

    public function __construct(private readonly StravaSyncService $sync) {}

    /**
     * Fetch all activities for a user within the given date range.
     * Paginates up to MAX_PAGES (300 activities).
     *
     * @return array<int, array<string, mixed>>
     */
    public function fetchActivitiesInRange(User $user, Carbon $start, Carbon $end): array
    {
        $token = $user->stravaToken;

        if (! $token) {
            return [];
        }

        $all = [];

        for ($page = 1; $page <= self::MAX_PAGES; $page++) {
            $activities = $this->sync->fetchActivities(
                $token,
                $page,
                self::PER_PAGE,
                $start->timestamp,
                $end->timestamp,
            );

            if (empty($activities)) {
                break;
            }

            $all = array_merge($all, $activities);

            if (count($activities) < self::PER_PAGE) {
                break;
            }
        }

        return $all;
    }
}
