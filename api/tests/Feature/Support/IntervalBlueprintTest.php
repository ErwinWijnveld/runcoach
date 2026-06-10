<?php

namespace Tests\Feature\Support;

use App\Support\Intervals\IntervalBlueprint;
use Tests\TestCase;

class IntervalBlueprintTest extends TestCase
{
    /**
     * @param  array{kind:string, distance_m?:int|null, duration_seconds?:int|null, target_pace_seconds_per_km?:int|null}  ...$_
     * @return list<array<string,mixed>>
     */
    private function flat(array ...$segments): array
    {
        return array_map(fn ($s) => array_merge([
            'kind' => 'work',
            'label' => 'Segment',
            'distance_m' => null,
            'duration_seconds' => null,
            'target_pace_seconds_per_km' => null,
        ], $s), $segments);
    }

    private function work(int $distanceM, int $pace): array
    {
        return ['kind' => 'work', 'distance_m' => $distanceM, 'target_pace_seconds_per_km' => $pace];
    }

    private function recovery(int $seconds): array
    {
        return ['kind' => 'recovery', 'duration_seconds' => $seconds];
    }

    public function test_collapse_folds_a_uniform_block(): void
    {
        $flat = $this->flat(
            ['kind' => 'warmup', 'duration_seconds' => 60],
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            ['kind' => 'cooldown', 'duration_seconds' => 300],
        );

        $grouped = IntervalBlueprint::collapse($flat);

        $this->assertSame(60, $grouped['warmup_seconds']);
        $this->assertSame(300, $grouped['cooldown_seconds']);
        $this->assertCount(1, $grouped['steps']);
        $this->assertSame('block', $grouped['steps'][0]['type']);
        $this->assertSame(4, $grouped['steps'][0]['reps']);
        $this->assertSame(800, $grouped['steps'][0]['work_distance_m']);
        $this->assertSame(270, $grouped['steps'][0]['work_pace_seconds_per_km']);
        $this->assertSame(90, $grouped['steps'][0]['recovery_seconds']);
    }

    public function test_collapse_keeps_two_distinct_loops(): void
    {
        $flat = $this->flat(
            ['kind' => 'warmup', 'duration_seconds' => 60],
            $this->work(800, 270), $this->recovery(120),
            $this->work(800, 270), $this->recovery(120),
            $this->work(800, 270), $this->recovery(120),
            $this->work(800, 270), $this->recovery(120),
            $this->work(400, 255), $this->recovery(60),
            $this->work(400, 255), $this->recovery(60),
            $this->work(400, 255), $this->recovery(60),
            $this->work(400, 255), $this->recovery(60),
            ['kind' => 'cooldown', 'duration_seconds' => 300],
        );

        $grouped = IntervalBlueprint::collapse($flat);

        $this->assertCount(2, $grouped['steps']);
        $this->assertSame([4, 800, 120], [$grouped['steps'][0]['reps'], $grouped['steps'][0]['work_distance_m'], $grouped['steps'][0]['recovery_seconds']]);
        $this->assertSame([4, 400, 60], [$grouped['steps'][1]['reps'], $grouped['steps'][1]['work_distance_m'], $grouped['steps'][1]['recovery_seconds']]);
    }

    public function test_collapse_pyramid_stays_distinct_blocks(): void
    {
        $flat = $this->flat(
            ['kind' => 'warmup', 'duration_seconds' => 60],
            $this->work(400, 270), $this->recovery(90),
            $this->work(800, 280), $this->recovery(90),
            $this->work(400, 270), $this->recovery(90),
            ['kind' => 'cooldown', 'duration_seconds' => 300],
        );

        $grouped = IntervalBlueprint::collapse($flat);

        $this->assertCount(3, $grouped['steps']);
        $this->assertSame(400, $grouped['steps'][0]['work_distance_m']);
        $this->assertSame(800, $grouped['steps'][1]['work_distance_m']);
        $this->assertSame(400, $grouped['steps'][2]['work_distance_m']);
    }

    public function test_expand_unrolls_reps(): void
    {
        $grouped = [
            'warmup_seconds' => 60,
            'steps' => [
                ['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
            ],
            'cooldown_seconds' => 300,
        ];

        $flat = IntervalBlueprint::expand($grouped);

        // 1 warmup + 4×(work+recovery) + 1 cooldown = 10
        $this->assertCount(10, $flat);
        $this->assertSame('warmup', $flat[0]['kind']);
        $this->assertSame('cooldown', $flat[9]['kind']);
        $this->assertSame(4, collect($flat)->where('kind', 'work')->count());
        $this->assertSame(4, collect($flat)->where('kind', 'recovery')->count());
        $this->assertSame(800, $flat[1]['distance_m']);
        $this->assertSame(270, $flat[1]['target_pace_seconds_per_km']);
    }

    public function test_round_trip_preserves_structure(): void
    {
        $flat = $this->flat(
            ['kind' => 'warmup', 'duration_seconds' => 90],
            $this->work(800, 270), $this->recovery(120),
            $this->work(800, 270), $this->recovery(120),
            $this->work(400, 255), $this->recovery(60),
            ['kind' => 'cooldown', 'duration_seconds' => 300],
        );

        $reExpanded = IntervalBlueprint::expand(IntervalBlueprint::collapse($flat));

        $this->assertCount(count($flat), $reExpanded);
        $this->assertSame(
            array_column($flat, 'kind'),
            array_column($reExpanded, 'kind'),
        );
    }

    public function test_normalize_accepts_grouped_and_is_idempotent(): void
    {
        $grouped = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 5, 'work_distance_m' => 400, 'work_pace_seconds_per_km' => 260, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];

        $once = IntervalBlueprint::normalize($grouped);
        $twice = IntervalBlueprint::normalize($once);

        $this->assertSame($once, $twice);
        $this->assertSame(5, $once['steps'][0]['reps']);
    }

    public function test_normalize_accepts_flat(): void
    {
        $flat = $this->flat(
            $this->work(400, 260), $this->recovery(60),
            $this->work(400, 260), $this->recovery(60),
        );

        $grouped = IntervalBlueprint::normalize($flat);

        $this->assertSame('block', $grouped['steps'][0]['type']);
        $this->assertSame(2, $grouped['steps'][0]['reps']);
        // Cooldown synthesized (required by the rules) even when absent.
        $this->assertSame(IntervalBlueprint::COOLDOWN_DEFAULT_SECONDS, $grouped['cooldown_seconds']);
    }

    public function test_normalize_clamps_sane_bounds(): void
    {
        $grouped = [
            'warmup_seconds' => 999,
            'steps' => [['type' => 'rest', 'duration_seconds' => 5]],
            'cooldown_seconds' => 9999,
        ];

        $out = IntervalBlueprint::normalize($grouped);

        $this->assertSame(IntervalBlueprint::WARMUP_MAX_SECONDS, $out['warmup_seconds']);
        $this->assertSame(IntervalBlueprint::COOLDOWN_MAX_SECONDS, $out['cooldown_seconds']);
        $this->assertSame(IntervalBlueprint::RECOVERY_MIN_SECONDS, $out['steps'][0]['duration_seconds']);
    }

    public function test_normalize_returns_null_for_empty_or_garbage(): void
    {
        $this->assertNull(IntervalBlueprint::normalize(null));
        $this->assertNull(IntervalBlueprint::normalize([]));
        $this->assertNull(IntervalBlueprint::normalize('nonsense'));
    }

    public function test_summary_renders_work_sets_only(): void
    {
        // Warm-up and cool-down are deliberately absent — runners (and the
        // diff card) only care about the work structure.
        $summary = IntervalBlueprint::summary([
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame('4×800m @4:30/km (rec 90s)', $summary);
    }

    public function test_summary_handles_rest_rep_and_duration_steps(): void
    {
        $summary = IntervalBlueprint::summary([
            'warmup_seconds' => null,
            'steps' => [
                ['type' => 'rest', 'duration_seconds' => 120],
                ['type' => 'rep', 'work_distance_m' => 400],
                ['type' => 'block', 'reps' => 6, 'work_duration_seconds' => 45, 'work_pace_seconds_per_km' => 250, 'recovery_seconds' => 60],
            ],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame('rest 120s + 1×400m + 6×45s @4:10/km (rec 60s)', $summary);
    }

    public function test_summary_returns_null_for_garbage(): void
    {
        $this->assertNull(IntervalBlueprint::summary(null));
        $this->assertNull(IntervalBlueprint::summary(['totally' => 'wrong']));
    }

    public function test_normalization_notes_flag_only_work_set_clamps(): void
    {
        // Warm-up / cool-down clamps are server bookkeeping the runner never
        // needs to see (they'd surface verbatim on the diff card) — only the
        // work-structure clamp (reps) is noted.
        $notes = IntervalBlueprint::normalizationNotes([
            'warmup_seconds' => 999,
            'steps' => [['type' => 'block', 'reps' => 100, 'work_distance_m' => 400, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 30,
        ]);

        $this->assertCount(1, $notes);
        $this->assertStringContainsString('you asked for 100', $notes[0]);
    }

    public function test_normalization_notes_empty_for_canonical_or_invalid_input(): void
    {
        $canonical = [
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 260, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ];

        $this->assertSame([], IntervalBlueprint::normalizationNotes($canonical));
        $this->assertSame([], IntervalBlueprint::normalizationNotes(null));
        $this->assertSame([], IntervalBlueprint::normalizationNotes('garbage'));
    }

    public function test_estimate_total_km_for_distance_block_with_warmup_and_cooldown(): void
    {
        // 4×800m @4:30/km (rec 90s), 60s warmup, 300s cooldown.
        // Jog pace = 270 + 100 = 370 s/km → work 3200m + time segments
        // (60+360+300)s / 370 ≈ 1946m → 5.1 km.
        $km = IntervalBlueprint::estimateTotalKm([
            'warmup_seconds' => 60,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(5.1, $km);
    }

    public function test_estimate_total_km_for_duration_based_work(): void
    {
        // 3×120s @5:00/km (rec 60s), no warmup, 300s cooldown.
        // Work 3×400m; jog = 400 s/km → (180+300)s / 400 = 1200m → 2.4 km.
        $km = IntervalBlueprint::estimateTotalKm([
            'warmup_seconds' => null,
            'steps' => [['type' => 'block', 'reps' => 3, 'work_distance_m' => null, 'work_duration_seconds' => 120, 'work_pace_seconds_per_km' => 300, 'recovery_seconds' => 60]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(2.4, $km);
    }

    public function test_estimate_total_km_falls_back_to_default_jog_pace_without_work_paces(): void
    {
        // 4×400m no pace anywhere → jog fallback 360 s/km.
        // Work 1600m + (360+300)s / 360 ≈ 1833m → 3.4 km.
        $km = IntervalBlueprint::estimateTotalKm([
            'warmup_seconds' => null,
            'steps' => [['type' => 'block', 'reps' => 4, 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => null, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(3.4, $km);
    }

    public function test_estimate_total_km_uses_avg_work_pace_for_paceless_duration_work(): void
    {
        // Duration work without its own pace converts at the blueprint-wide
        // work avg (240), not the jog pace: 2×180s @240 = 1500m + 400m rep
        // + (180s rec + 300s cd) / 340 jog ≈ 1412m → 3.3 km.
        $km = IntervalBlueprint::estimateTotalKm([
            'warmup_seconds' => null,
            'steps' => [
                ['type' => 'block', 'reps' => 2, 'work_distance_m' => null, 'work_duration_seconds' => 180, 'work_pace_seconds_per_km' => null, 'recovery_seconds' => 90],
                ['type' => 'rep', 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 240],
            ],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(3.3, $km);
    }

    public function test_estimate_total_km_counts_rest_steps_and_clamps_jog_pace(): void
    {
        // Work pace 700 → jog would be 800, clamped to 720.
        // 2×400m = 800m + (2×90 rec + 120 rest + 300 cd)s / 720 = 833m → 1.6 km.
        $km = IntervalBlueprint::estimateTotalKm([
            'warmup_seconds' => null,
            'steps' => [
                ['type' => 'block', 'reps' => 2, 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 700, 'recovery_seconds' => 90],
                ['type' => 'rest', 'duration_seconds' => 120],
            ],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(1.6, $km);
    }

    public function test_estimate_total_km_accepts_legacy_flat_input(): void
    {
        $flat = $this->flat(
            ['kind' => 'warmup', 'duration_seconds' => 60],
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            $this->work(800, 270), $this->recovery(90),
            ['kind' => 'cooldown', 'duration_seconds' => 300],
        );

        $this->assertSame(5.1, IntervalBlueprint::estimateTotalKm($flat));
    }

    public function test_estimate_total_km_returns_null_for_empty_or_garbage(): void
    {
        $this->assertNull(IntervalBlueprint::estimateTotalKm(null));
        $this->assertNull(IntervalBlueprint::estimateTotalKm([]));
        $this->assertNull(IntervalBlueprint::estimateTotalKm(['steps' => []]));
        $this->assertNull(IntervalBlueprint::estimateTotalKm('garbage'));
    }

    public function test_work_distance_km_sums_work_steps_only(): void
    {
        // Warmup, recoveries, rests and cooldown contribute nothing — this
        // is the compliance scorer's "reps demonstrably incomplete" floor.
        $km = IntervalBlueprint::workDistanceKm([
            'warmup_seconds' => 60,
            'steps' => [
                ['type' => 'block', 'reps' => 4, 'work_distance_m' => 800, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 270, 'recovery_seconds' => 90],
                ['type' => 'rest', 'duration_seconds' => 120],
                ['type' => 'rep', 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 240],
            ],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(3.6, $km);
    }

    public function test_work_distance_km_converts_duration_work_via_pace(): void
    {
        // 2×180s @5:00/km → 2 × 600m = 1.2 km.
        $km = IntervalBlueprint::workDistanceKm([
            'warmup_seconds' => null,
            'steps' => [['type' => 'block', 'reps' => 2, 'work_distance_m' => null, 'work_duration_seconds' => 180, 'work_pace_seconds_per_km' => 300, 'recovery_seconds' => 60]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(1.2, $km);
    }

    public function test_work_distance_km_uses_avg_pace_for_paceless_duration_work(): void
    {
        // Paceless 2×180s converts at the blueprint-wide work avg (240):
        // 2 × 750m = 1500m, plus the 400m rep → 1.9 km.
        $km = IntervalBlueprint::workDistanceKm([
            'warmup_seconds' => null,
            'steps' => [
                ['type' => 'block', 'reps' => 2, 'work_distance_m' => null, 'work_duration_seconds' => 180, 'work_pace_seconds_per_km' => null, 'recovery_seconds' => 90],
                ['type' => 'rep', 'work_distance_m' => 400, 'work_duration_seconds' => null, 'work_pace_seconds_per_km' => 240],
            ],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(1.9, $km);
    }

    public function test_work_distance_km_falls_back_to_default_jog_for_paceless_duration_work(): void
    {
        // No pace anywhere → fallback 360 s/km: 3 × (120/360) km = 1.0 km.
        $km = IntervalBlueprint::workDistanceKm([
            'warmup_seconds' => null,
            'steps' => [['type' => 'block', 'reps' => 3, 'work_distance_m' => null, 'work_duration_seconds' => 120, 'work_pace_seconds_per_km' => null, 'recovery_seconds' => 90]],
            'cooldown_seconds' => 300,
        ]);

        $this->assertSame(1.0, $km);
    }

    public function test_work_distance_km_returns_null_for_empty_or_garbage(): void
    {
        $this->assertNull(IntervalBlueprint::workDistanceKm(null));
        $this->assertNull(IntervalBlueprint::workDistanceKm([]));
        $this->assertNull(IntervalBlueprint::workDistanceKm(['steps' => []]));
        $this->assertNull(IntervalBlueprint::workDistanceKm('garbage'));
    }

    public function test_estimate_jog_pace_offsets_and_clamps(): void
    {
        $this->assertSame(360, IntervalBlueprint::estimateJogPace(null));
        $this->assertSame(370, IntervalBlueprint::estimateJogPace(270));
        $this->assertSame(720, IntervalBlueprint::estimateJogPace(700)); // clamped to max
        $this->assertSame(180, IntervalBlueprint::estimateJogPace(50)); // clamped to min
    }
}
