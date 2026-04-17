<?php

namespace App\Services;

use App\Models\StravaToken;

/**
 * Turn a Strava activity's time/distance/HR streams into natural pace
 * segments — run-length encoded runs of similar pace.
 *
 * We bucket by time (10 s for runs under 10 km, 30 s above) so the signal
 * is resilient to GPS jitter, then merge adjacent buckets whose pace is
 * within 30 s/km of each other. Output surfaces workout structure
 * (warmup / intervals / steady / cooldown) without hundreds of raw samples.
 */
class StravaStreamSplits
{
    /** Thresholds below which consecutive time-buckets merge into one segment. */
    private const PACE_MERGE_THRESHOLD_SECONDS = 30;

    private const HR_MERGE_THRESHOLD_BPM = 12;

    public function __construct(private StravaSyncService $strava) {}

    /**
     * @return array<int, array{duration_seconds: int, distance_m: int, pace_seconds_per_km: int, average_heart_rate: int|null}>
     */
    public function compute(StravaToken $token, int $stravaActivityId, int $totalDistanceMeters): array
    {
        $bucketSeconds = $totalDistanceMeters < 10000 ? 10 : 30;

        try {
            $streams = $this->strava->fetchStreams($token, $stravaActivityId);
        } catch (\Throwable) {
            return [];
        }

        $buckets = $this->buildTimeBuckets($streams, $bucketSeconds);
        if (count($buckets) < 2) {
            return $buckets;
        }

        return $this->mergeIntoSegments($buckets);
    }

    /**
     * @param  array<string, array{data: array<int, int|float>}>  $streams
     * @return array<int, array{duration_seconds: int, distance_m: int, pace_seconds_per_km: int, average_heart_rate: int|null}>
     */
    private function buildTimeBuckets(array $streams, int $bucketSeconds): array
    {
        $time = $streams['time']['data'] ?? [];
        $distance = $streams['distance']['data'] ?? [];
        $hr = $streams['heartrate']['data'] ?? [];
        $n = min(count($time), count($distance));

        if ($n < 2) {
            return [];
        }

        $buckets = [];
        for ($i = 0; $i < $n; $i++) {
            $idx = intdiv((int) $time[$i], $bucketSeconds);
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
        foreach ($buckets as $b) {
            $dt = $b['t1'] - $b['t0'];
            $dd = $b['d1'] - $b['d0'];
            if ($dt <= 0 || $dd <= 0) {
                continue;
            }
            $result[] = [
                'duration_seconds' => $dt,
                'distance_m' => (int) round($dd),
                'pace_seconds_per_km' => (int) round(($dt / $dd) * 1000),
                'average_heart_rate' => $b['hrCount'] > 0 ? (int) round($b['hrSum'] / $b['hrCount']) : null,
            ];
        }

        return $result;
    }

    /**
     * @param  array<int, array{duration_seconds: int, distance_m: int, pace_seconds_per_km: int, average_heart_rate: int|null}>  $buckets
     * @return array<int, array{duration_seconds: int, distance_m: int, pace_seconds_per_km: int, average_heart_rate: int|null}>
     */
    private function mergeIntoSegments(array $buckets): array
    {
        $segments = [];
        $current = null;

        foreach ($buckets as $b) {
            $paceDiff = $current === null ? 0 : abs($b['pace_seconds_per_km'] - $current['pace_seconds_per_km']);
            $hrDiff = $current === null || $b['average_heart_rate'] === null || $current['average_heart_rate'] === null
                ? 0
                : abs($b['average_heart_rate'] - $current['average_heart_rate']);

            if ($current === null
                || $paceDiff > self::PACE_MERGE_THRESHOLD_SECONDS
                || $hrDiff > self::HR_MERGE_THRESHOLD_BPM) {
                if ($current !== null) {
                    $segments[] = $current;
                }
                $current = $b;

                continue;
            }

            $dt1 = $current['duration_seconds'];
            $dt2 = $b['duration_seconds'];
            $total = $dt1 + $dt2;
            $current = [
                'duration_seconds' => $total,
                'distance_m' => $current['distance_m'] + $b['distance_m'],
                'pace_seconds_per_km' => (int) round(
                    ($current['pace_seconds_per_km'] * $dt1 + $b['pace_seconds_per_km'] * $dt2) / $total
                ),
                'average_heart_rate' => $this->mergeHr(
                    $current['average_heart_rate'], $b['average_heart_rate'], $dt1, $dt2
                ),
            ];
        }

        if ($current !== null) {
            $segments[] = $current;
        }

        return $segments;
    }

    private function mergeHr(?int $a, ?int $b, int $dt1, int $dt2): ?int
    {
        if ($a === null && $b === null) {
            return null;
        }
        if ($a === null) {
            return $b;
        }
        if ($b === null) {
            return $a;
        }

        return (int) round(($a * $dt1 + $b * $dt2) / ($dt1 + $dt2));
    }
}
