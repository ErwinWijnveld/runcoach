<?php

namespace App\Support\Onboarding;

use App\Enums\CoachStyle;
use App\Enums\GoalType;
use App\Enums\IntensityBias;
use App\Enums\RunnerLevel;
use App\Enums\TrainingType;
use Carbon\CarbonImmutable;
use InvalidArgumentException;

/**
 * Typed wrapper around the `plan_generations.payload` (which mirrors
 * the request body of `POST /onboarding/generate-plan`). Lets the
 * builder + tool depend on a predictable shape instead of open-ended
 * `array<string, mixed>`.
 *
 * `fromArray` is the single ingestion point: it normalises the historical
 * goal-type aliases (`pr` → `pr_attempt`, `fitness` / `weight_loss` →
 * `general_fitness`), parses the date string, and validates ranges.
 */
final readonly class OnboardingFormInput
{
    /**
     * @param  list<int>|null  $preferredWeekdays  ISO 1=Mon..7=Sun, distinct.
     * @param  list<TrainingType>|null  $runTypePreferences  Ordered runner
     *                                                       preference (gold → silver → bronze → last) over training-day
     *                                                       types. Distinct, max 4 (easy, tempo, interval, long_run). Null
     *                                                       means "no preference, use builder defaults". Index 0 = most
     *                                                       preferred. The builder reads this to (a) choose tempo vs
     *                                                       interval for quality slots, (b) optionally upgrade an easy slot
     *                                                       to a second quality session, (c) shift the long-run length cap.
     */
    public function __construct(
        public GoalType $goalType,
        public ?string $goalName,
        public ?int $distanceMeters,
        public ?CarbonImmutable $targetDate,
        public ?int $goalTimeSeconds,
        public ?int $prCurrentSeconds,
        public int $daysPerWeek,
        public ?array $preferredWeekdays,
        public CoachStyle $coachStyle,
        public ?string $additionalNotes,
        public ?array $runTypePreferences = null,
        public IntensityBias $intensityBias = IntensityBias::Standard,
        public RunnerLevel $runnerLevel = RunnerLevel::Intermediate,
    ) {}

    /**
     * Position of a TrainingType in the runner's ranking, or null when no
     * preferences are set OR the type isn't in the ranking. Lower index =
     * more preferred. Used by the builder for several biasing decisions.
     */
    public function rankOf(TrainingType $type): ?int
    {
        if ($this->runTypePreferences === null) {
            return null;
        }
        foreach ($this->runTypePreferences as $i => $entry) {
            if ($entry === $type) {
                return $i;
            }
        }

        return null;
    }

    /**
     * Compare two types by rank. Returns -1 if $a is preferred, 1 if $b is
     * preferred, 0 if equal (or if neither is ranked). Treats "not in
     * ranking" as worse than "in ranking" so a runner who ranked only
     * `intervals` still gets it preferred over `tempo`.
     */
    public function rankCompare(TrainingType $a, TrainingType $b): int
    {
        $rankA = $this->rankOf($a);
        $rankB = $this->rankOf($b);

        if ($rankA === null && $rankB === null) {
            return 0;
        }
        if ($rankA === null) {
            return 1;
        }
        if ($rankB === null) {
            return -1;
        }

        return $rankA <=> $rankB;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    public static function fromArray(array $data): self
    {
        $goalType = self::resolveGoalType($data['goal_type'] ?? null);
        $coachStyle = self::resolveCoachStyle($data['coach_style'] ?? null);

        $days = (int) ($data['days_per_week'] ?? 0);
        if ($days < 1 || $days > 7) {
            throw new InvalidArgumentException("days_per_week must be 1-7, got {$days}");
        }

        $weekdays = self::resolvePreferredWeekdays($data['preferred_weekdays'] ?? null);

        $targetDate = self::resolveTargetDate($data['target_date'] ?? null);

        $distanceMeters = self::resolveDistanceMeters($data['distance_meters'] ?? null);

        return new self(
            goalType: $goalType,
            goalName: self::resolveGoalName($data, $goalType),
            distanceMeters: $distanceMeters,
            targetDate: $targetDate,
            goalTimeSeconds: self::resolvePositiveInt($data['goal_time_seconds'] ?? null),
            prCurrentSeconds: self::resolvePositiveInt($data['pr_current_seconds'] ?? null),
            daysPerWeek: $days,
            preferredWeekdays: $weekdays,
            coachStyle: $coachStyle,
            additionalNotes: self::resolveNotes($data),
            runTypePreferences: self::resolveRunTypePreferences($data['run_type_preferences'] ?? null),
            intensityBias: self::resolveIntensityBias($data['intensity_bias'] ?? null),
            runnerLevel: self::resolveRunnerLevel($data['runner_level'] ?? null),
        );
    }

    private static function resolveIntensityBias(mixed $raw): IntensityBias
    {
        if ($raw instanceof IntensityBias) {
            return $raw;
        }
        if (! is_string($raw)) {
            return IntensityBias::Standard;
        }

        return IntensityBias::tryFrom($raw) ?? IntensityBias::Standard;
    }

    private static function resolveRunnerLevel(mixed $raw): RunnerLevel
    {
        if ($raw instanceof RunnerLevel) {
            return $raw;
        }
        if (! is_string($raw)) {
            return RunnerLevel::Intermediate;
        }

        return RunnerLevel::tryFrom($raw) ?? RunnerLevel::Intermediate;
    }

    /**
     * @return list<TrainingType>|null
     */
    private static function resolveRunTypePreferences(mixed $raw): ?array
    {
        if (! is_array($raw) || $raw === []) {
            return null;
        }

        $allowed = [
            TrainingType::Easy,
            TrainingType::Tempo,
            TrainingType::Interval,
            TrainingType::LongRun,
        ];
        $allowedValues = array_map(fn (TrainingType $t) => $t->value, $allowed);

        $cleaned = [];
        $seen = [];
        foreach ($raw as $entry) {
            $value = $entry instanceof TrainingType ? $entry->value : (string) $entry;
            if (! in_array($value, $allowedValues, true)) {
                continue;
            }
            if (in_array($value, $seen, true)) {
                continue;
            }
            $seen[] = $value;
            $cleaned[] = TrainingType::from($value);
        }

        return $cleaned === [] ? null : $cleaned;
    }

    /**
     * Map historical / shorthand goal-type aliases to the canonical
     * `GoalType` enum. The form has shipped `'pr'`, `'fitness'`, and
     * `'weight_loss'` historically; the proposal payload always speaks
     * the canonical enum string.
     */
    private static function resolveGoalType(mixed $raw): GoalType
    {
        if ($raw instanceof GoalType) {
            return $raw;
        }

        if (! is_string($raw) || $raw === '') {
            throw new InvalidArgumentException('goal_type is required');
        }

        return match ($raw) {
            'race' => GoalType::Race,
            'pr' => GoalType::PrAttempt,
            'pr_attempt' => GoalType::PrAttempt,
            'fitness', 'weight_loss', 'general_fitness' => GoalType::GeneralFitness,
            default => throw new InvalidArgumentException("Unknown goal_type: {$raw}"),
        };
    }

    private static function resolveCoachStyle(mixed $raw): CoachStyle
    {
        if ($raw instanceof CoachStyle) {
            return $raw;
        }
        if (! is_string($raw)) {
            return CoachStyle::Balanced;
        }

        return match ($raw) {
            'motivational', 'strict' => CoachStyle::Motivational,
            'analytical' => CoachStyle::Analytical,
            'flexible', 'balanced' => CoachStyle::Balanced,
            default => CoachStyle::Balanced,
        };
    }

    /**
     * @return list<int>|null
     */
    private static function resolvePreferredWeekdays(mixed $raw): ?array
    {
        if (! is_array($raw)) {
            return null;
        }

        $cleaned = [];
        foreach ($raw as $value) {
            $int = (int) $value;
            if ($int >= 1 && $int <= 7 && ! in_array($int, $cleaned, true)) {
                $cleaned[] = $int;
            }
        }

        if ($cleaned === []) {
            return null;
        }

        sort($cleaned);

        return $cleaned;
    }

    private static function resolveTargetDate(mixed $raw): ?CarbonImmutable
    {
        if (! is_string($raw) || trim($raw) === '') {
            return null;
        }

        try {
            return CarbonImmutable::parse(trim($raw))->startOfDay();
        } catch (\Throwable) {
            return null;
        }
    }

    private static function resolveDistanceMeters(mixed $raw): ?int
    {
        if (! is_numeric($raw)) {
            return null;
        }
        $int = (int) $raw;

        return $int > 0 ? $int : null;
    }

    private static function resolvePositiveInt(mixed $raw): ?int
    {
        if (! is_numeric($raw)) {
            return null;
        }
        $int = (int) $raw;

        return $int > 0 ? $int : null;
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private static function resolveGoalName(array $data, GoalType $goalType): ?string
    {
        $explicit = $data['goal_name'] ?? null;
        if (is_string($explicit) && trim($explicit) !== '') {
            return trim($explicit);
        }

        return match ($goalType) {
            GoalType::Race => 'Race',
            GoalType::PrAttempt => 'Personal record attempt',
            GoalType::GeneralFitness => 'General fitness',
        };
    }

    /**
     * @param  array<string, mixed>  $data
     */
    private static function resolveNotes(array $data): ?string
    {
        $notes = $data['additional_notes'] ?? $data['notes'] ?? null;
        if (! is_string($notes)) {
            return null;
        }
        $trimmed = trim($notes);

        return $trimmed === '' ? null : $trimmed;
    }
}
