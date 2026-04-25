<?php

namespace App\Support;

use App\Models\Goal;

/**
 * Pure read helpers over the CreateSchedule / EditSchedule payload shape:
 *
 *   { goal_type, goal_name, distance, target_date, goal_time_seconds, ...,
 *     schedule: { weeks: [{ week_number, focus, total_km,
 *                           days: [{ day_of_week, type, target_km, ... }] }] } }
 *
 * The tools (CreateSchedule, EditSchedule, VerifyPlan) and the optimizer
 * all operate on this shape. Previously each tool carried its own copy of
 * `weekStructure()` and `buildPayloadFromGoal()`; consolidated here so
 * there is ONE source of truth for payload construction and summary.
 *
 * All methods are pure (no IO, no state) so calling them is cheap and
 * safe from any layer.
 */
class PlanPayload
{
    /**
     * Compact map of the plan: which `day_of_week` slots exist in each
     * `week_number`. Surfaced on CreateSchedule / EditSchedule /
     * VerifyPlan responses so the agent has ground truth for composing
     * valid follow-up ops without having to call `get_current_proposal`.
     *
     *   [{ week_number: 1, days: [2, 4, 6] }, ...]
     *
     * @param  array<string, mixed>  $payload
     * @return list<array{week_number: int, days: list<int>}>
     */
    public static function weekStructure(array $payload): array
    {
        $out = [];
        foreach (($payload['schedule']['weeks'] ?? []) as $week) {
            $dows = [];
            foreach (($week['days'] ?? []) as $day) {
                if (isset($day['day_of_week'])) {
                    $dows[] = (int) $day['day_of_week'];
                }
            }
            sort($dows);
            $out[] = [
                'week_number' => (int) ($week['week_number'] ?? 0),
                'days' => $dows,
            ];
        }

        return $out;
    }

    /**
     * Reconstruct a CreateSchedule-shaped payload from a Goal's persisted
     * training weeks/days. Used when a tool needs to audit or edit an
     * active plan (rather than a pending proposal).
     *
     * Trims null fields from each day so the downstream shape matches
     * what CreateSchedule emits — optimizer passes and verifier prompts
     * don't have to special-case active-plan rows.
     *
     * @return array<string, mixed>
     */
    public static function fromGoal(Goal $goal): array
    {
        $weeks = [];
        foreach ($goal->trainingWeeks()->orderBy('week_number')->get() as $week) {
            $days = [];
            foreach ($week->trainingDays()->orderBy('order')->get() as $day) {
                $days[] = array_filter([
                    'day_of_week' => (int) $day->order,
                    'type' => $day->type?->value,
                    'title' => $day->title,
                    'description' => $day->description,
                    'target_km' => $day->target_km === null ? null : (float) $day->target_km,
                    'target_pace_seconds_per_km' => $day->target_pace_seconds_per_km,
                    'target_heart_rate_zone' => $day->target_heart_rate_zone,
                    'intervals' => $day->intervals_json,
                ], fn ($v) => $v !== null);
            }
            $weeks[] = [
                'week_number' => $week->week_number,
                'focus' => $week->focus,
                'total_km' => (float) $week->total_km,
                'days' => $days,
            ];
        }

        return [
            'goal_id' => $goal->id,
            'goal_type' => $goal->type->value,
            'goal_name' => $goal->name,
            'distance' => $goal->distance?->value,
            'custom_distance_meters' => $goal->custom_distance_meters,
            'goal_time_seconds' => $goal->goal_time_seconds,
            'target_date' => $goal->target_date?->toDateString(),
            'schedule' => ['weeks' => $weeks],
        ];
    }

    /**
     * Resolve the goal's race distance in kilometres from the payload.
     * Handles the standard enum values plus the `custom` case (which uses
     * `custom_distance_meters`). Returns null when no distance is set.
     *
     * @param  array<string, mixed>  $payload
     */
    public static function goalKm(array $payload): ?float
    {
        $distance = $payload['distance'] ?? null;
        $custom = $payload['custom_distance_meters'] ?? null;

        if ($distance === 'custom') {
            if (is_numeric($custom) && (int) $custom > 0) {
                return round((int) $custom / 1000, 2);
            }

            return null;
        }

        if ($distance === null || $distance === '') {
            return null;
        }

        if (is_numeric($distance)) {
            $meters = (float) $distance;

            return $meters > 0 ? round($meters / 1000, 2) : null;
        }

        return match ($distance) {
            '5k' => 5.0,
            '10k' => 10.0,
            'half_marathon' => 21.1,
            'marathon' => 42.2,
            default => null,
        };
    }
}
