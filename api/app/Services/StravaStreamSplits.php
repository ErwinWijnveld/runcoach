<?php

namespace App\Services;

use App\Models\StravaToken;

/**
 * Bucket a Strava activity's raw streams (time/distance/heartrate) into
 * fine-grained splits — 50 m if total distance < 10 km, else 100 m.
 *
 * This is what lets the AI coach spot interval patterns and variable pace,
 * which Strava's built-in `splits_metric` (fixed 1 km) hides.
 */
class StravaStreamSplits
{
    public function __construct(private StravaSyncService $strava) {}

    /**
     * @return array<int, array{distance_m: int, pace_seconds_per_km: int, average_heart_rate: int|null}>
     */
    public function compute(StravaToken $token, int $stravaActivityId, int $totalDistanceMeters): array
    {
        $bucketSize = $totalDistanceMeters < 10000 ? 50 : 100;

        try {
            $streams = $this->strava->fetchStreams($token, $stravaActivityId);
        } catch (\Throwable) {
            return [];
        }

        $time = $streams['time']['data'] ?? [];
        $distance = $streams['distance']['data'] ?? [];
        $hr = $streams['heartrate']['data'] ?? [];
        $n = min(count($time), count($distance));

        if ($n < 2) {
            return [];
        }

        $buckets = [];
        for ($i = 0; $i < $n; $i++) {
            $idx = intdiv((int) $distance[$i], $bucketSize);
            if (! isset($buckets[$idx])) {
                $buckets[$idx] = [
                    't0' => $time[$i], 't1' => $time[$i],
                    'd0' => $distance[$i], 'd1' => $distance[$i],
                    'hrSum' => 0, 'hrCount' => 0,
                ];
            }
            $buckets[$idx]['t1'] = $time[$i];
            $buckets[$idx]['d1'] = $distance[$i];
            if (isset($hr[$i])) {
                $buckets[$idx]['hrSum'] += (int) $hr[$i];
                $buckets[$idx]['hrCount']++;
            }
        }

        ksort($buckets);

        $result = [];
        foreach ($buckets as $idx => $b) {
            $dd = $b['d1'] - $b['d0'];
            $dt = $b['t1'] - $b['t0'];
            if ($dd <= 0 || $dt <= 0) {
                continue;
            }
            $result[] = [
                'distance_m' => $idx * $bucketSize,
                'pace_seconds_per_km' => (int) round(($dt / $dd) * 1000),
                'average_heart_rate' => $b['hrCount'] > 0 ? (int) round($b['hrSum'] / $b['hrCount']) : null,
            ];
        }

        return $result;
    }
}
