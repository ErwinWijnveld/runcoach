<?php

namespace App\Filament\Coach\Pages;

use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\WearableActivity;
use App\Support\Intervals\IntervalBlueprint;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Actions\Concerns\InteractsWithActions;
use Filament\Actions\Contracts\HasActions;
use Filament\Forms\Components\Checkbox;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Placeholder;
use Filament\Forms\Components\Repeater;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Panel;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Utilities\Get;
use Filament\Schemas\Components\View;
use Filament\Support\Enums\Width;
use Filament\Support\Icons\Heroicon;
use Illuminate\Support\Collection;
use Illuminate\Support\HtmlString;
use Illuminate\Support\Str;

class GoalSchedule extends Page implements HasActions
{
    use InteractsWithActions;

    protected string $view = 'filament.coach.pages.goal-schedule';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static bool $shouldRegisterNavigation = false;

    /**
     * Mirrors `PlanOptimizerService::normalizeIntervals` constraints — keep
     * these in sync with that service when the canonical rules change.
     */
    private const WARMUP_MAX_SECONDS = 120;

    private const COOLDOWN_MIN_SECONDS = 60;

    private const COOLDOWN_MAX_SECONDS = 600;

    private const REPS_MIN = 1;

    private const REPS_MAX = 30;

    /**
     * Validation rule for any pace text input — accepts m:ss with one or
     * two minute digits, two-digit seconds (e.g. "4:30", "5:00", "12:45"),
     * or empty (= no target pace, valid for non-interval days that haven't
     * been pace-set yet).
     */
    private const PACE_RULE = ['nullable', 'regex:/^\d{1,2}:[0-5]\d$/'];

    public static function getRoutePath(Panel $panel): string
    {
        return '/goal-schedule/{goal}';
    }

    public ?int $goalId = null;

    public function mount(Goal $goal): void
    {
        /** @var User $user */
        $user = auth()->user();

        if (! $user->isSuperadmin()) {
            abort_unless($this->coachCanEdit($user, $goal->user), 403);
        }

        $this->goalId = $goal->id;
    }

    public function getGoalProperty(): ?Goal
    {
        if ($this->goalId === null) {
            return null;
        }

        return Goal::with(['trainingWeeks.trainingDays.result.wearableActivity', 'user'])->find($this->goalId);
    }

    /**
     * Visual state shown on each day row — mirrors Flutter's
     * `TrainingDayStatus` (see app/lib/.../training_day_status.dart).
     *
     * - completed: has a `TrainingResult`
     * - today: today's date, no result yet
     * - missed: past date, no result
     * - upcoming: future date
     */
    public function dayStatus(TrainingDay $day): string
    {
        if ($day->result) {
            return 'completed';
        }

        $date = $day->date;
        if ($date === null) {
            return 'upcoming';
        }

        $today = now()->startOfDay();
        if ($date->isSameDay($today)) {
            return 'today';
        }

        return $date->lt($today) ? 'missed' : 'upcoming';
    }

    /**
     * Color band for a 0-10 compliance score — thresholds mirror Flutter's
     * `ComplianceColors` (good ≥ 8.0, ok ≥ 5.0) so coach and runner see the
     * same verdict for the same run.
     */
    public function complianceBand(float $score): string
    {
        if ($score >= 8.0) {
            return 'good';
        }

        return $score >= 5.0 ? 'ok' : 'bad';
    }

    /**
     * One-decimal grade out of 10, matching the runner-facing app ("8.7"
     * in the compliance ring). Null renders as an em dash.
     */
    public function formatScore(float|string|null $score): string
    {
        if ($score === null) {
            return '—';
        }

        return number_format((float) $score, 1);
    }

    /**
     * Inline actuals line for a completed day row, e.g.
     * "Ran 8.2 km @ 4:46/km · avg HR 162". HR is omitted when absent.
     */
    public function resultSummaryLine(TrainingResult $result): string
    {
        $parts = [];

        $km = $this->kmText($result->actual_km);
        $pace = $this->paceToText((int) $result->actual_pace_seconds_per_km);
        if ($km !== null) {
            $parts[] = $pace !== null ? "Ran {$km} km @ {$pace}/km" : "Ran {$km} km";
        }

        if ($result->actual_avg_heart_rate !== null) {
            $parts[] = 'avg HR '.round((float) $result->actual_avg_heart_rate);
        }

        return implode(' · ', $parts);
    }

    /**
     * Completed/total + average compliance for one week, or null when the
     * week has no results yet (header renders unchanged in that case).
     *
     * @return array{done: int, total: int, avg: float|null}|null
     */
    public function weekResultStats(TrainingWeek $week): ?array
    {
        $stats = $this->resultStats($week->trainingDays);

        return $stats['done'] > 0 ? $stats : null;
    }

    /**
     * Plan-wide completed/total + average compliance for the hero summary.
     *
     * @return array{done: int, total: int, avg: float|null}
     */
    public function planResultStats(Goal $goal): array
    {
        return $this->resultStats($goal->trainingWeeks->flatMap->trainingDays);
    }

    /**
     * @param  Collection<int, TrainingDay>  $days
     * @return array{done: int, total: int, avg: float|null}
     */
    private function resultStats(Collection $days): array
    {
        $scores = $days
            ->map(fn (TrainingDay $day): ?float => $day->result?->compliance_score !== null
                ? (float) $day->result->compliance_score
                : null)
            ->filter(fn (?float $score): bool => $score !== null);

        return [
            'done' => $scores->count(),
            'total' => $days->count(),
            'avg' => $scores->isEmpty() ? null : round($scores->avg(), 1),
        ];
    }

    private function kmText(float|string|null $km): ?string
    {
        if ($km === null) {
            return null;
        }

        return rtrim(rtrim(number_format((float) $km, 1), '0'), '.');
    }

    /**
     * Seconds as "m:ss" or "h:mm:ss" for activity durations.
     */
    private function durationToText(?int $seconds): ?string
    {
        if ($seconds === null || $seconds <= 0) {
            return null;
        }

        $h = intdiv($seconds, 3600);
        $m = intdiv($seconds % 3600, 60);
        $s = $seconds % 60;

        return $h > 0 ? sprintf('%d:%02d:%02d', $h, $m, $s) : sprintf('%d:%02d', $m, $s);
    }

    public function getTitle(): string
    {
        return $this->goal?->user?->name ?? 'Schedule';
    }

    public function getHeading(): string
    {
        return $this->goal?->user?->name ?? 'Schedule';
    }

    public function getSubheading(): ?string
    {
        $goal = $this->goal;
        if ($goal === null) {
            return null;
        }

        $parts = [$goal->name];
        if ($goal->target_date) {
            $parts[] = $goal->target_date->format('D, M j');
        }

        return implode(' · ', $parts);
    }

    /**
     * Programmatic entry from the schedule grid — opens the Filament-managed
     * modal pre-filled with the day's current state.
     */
    public function openEditDay(int $dayId): void
    {
        $this->mountAction('editDay', ['dayId' => $dayId]);
    }

    public function editDayAction(): Action
    {
        return Action::make('editDay')
            ->modalHeading('Edit session')
            ->modalDescription('Changes go live immediately for the runner.')
            ->modalWidth(Width::Large)
            ->modalSubmitActionLabel('Save')
            ->fillForm(fn (array $arguments) => $this->dayFormState((int) $arguments['dayId']))
            ->schema(fn (array $arguments) => $this->dayFormSchema((int) ($arguments['dayId'] ?? 0)))
            ->action(fn (array $data, array $arguments) => $this->persistDay((int) $arguments['dayId'], $data))
            ->extraModalFooterActions(fn (Action $action): array => [
                Action::make('deleteDayInline')
                    ->label('Delete session')
                    ->color('danger')
                    ->link()
                    ->requiresConfirmation()
                    ->modalHeading('Remove session')
                    ->modalDescription('This permanently removes the session from the plan.')
                    ->action(function () use ($action) {
                        $dayId = (int) ($action->getArguments()['dayId'] ?? 0);
                        $day = TrainingDay::find($dayId);
                        if ($day) {
                            $day->delete();
                            Notification::make()->title('Session removed')->success()->send();
                        }
                        $action->cancel();
                    }),
            ]);
    }

    public function addDay(int $weekId): void
    {
        $week = TrainingWeek::findOrFail($weekId);
        $latestDay = $week->trainingDays()->orderByDesc('order')->first();
        $nextOrder = ($latestDay?->order ?? 0) + 1;

        $newDay = TrainingDay::create([
            'training_week_id' => $week->id,
            'date' => $week->starts_at->copy()->addDays(min($nextOrder - 1, 6)),
            'type' => TrainingType::Easy,
            'title' => 'Easy run',
            'description' => null,
            'target_km' => 5,
            'target_pace_seconds_per_km' => 360,
            'order' => $nextOrder,
        ]);

        $this->openEditDay($newDay->id);
    }

    /**
     * @return array<string, mixed>
     */
    private function dayFormState(int $dayId): array
    {
        $day = TrainingDay::findOrFail($dayId);
        $intervals = $this->parseIntervals($day->intervals_json);

        return [
            'type' => $day->type?->value,
            'title' => $day->title,
            'date' => $day->date?->toDateString(),
            'target_km' => $day->target_km,
            'target_pace_text' => $this->paceToText($day->target_pace_seconds_per_km),
            'description' => $day->description,
            'has_warmup' => $intervals['has_warmup'],
            'warmup_seconds' => $intervals['warmup_seconds'],
            'steps' => $intervals['steps'],
            'cooldown_seconds' => $intervals['cooldown_seconds'],
        ];
    }

    private function persistDay(int $dayId, array $data): void
    {
        $day = TrainingDay::findOrFail($dayId);

        $isInterval = ($data['type'] ?? null) === TrainingType::Interval->value;

        $day->update([
            'type' => $data['type'] ?? null,
            'title' => $data['title'] ?? null,
            'date' => $data['date'] ?? null,
            'target_km' => $data['target_km'] ?? null,
            // Interval days never store a day-level pace — the per-rep
            // pace inside `intervals_json` is the source of truth, surfaced
            // at read time via `TrainingDay::workSetAveragePaceSecondsPerKm`.
            'target_pace_seconds_per_km' => $isInterval
                ? null
                : $this->paceFromText($data['target_pace_text'] ?? null),
            'description' => $data['description'] ?? null,
            'intervals_json' => $isInterval ? $this->serializeIntervals($data) : null,
        ]);

        Notification::make()->title('Saved')->success()->send();
    }

    /**
     * Read-only result block shown at the top of the edit modal when the day
     * has a matched run — rendered by the app-style result panel partial
     * (compliance ring + sub-score bars + target-vs-actual table).
     */
    private function resultSection(?TrainingDay $day): ?Section
    {
        $panel = $this->resultPanelData($day);
        if ($panel === null) {
            return null;
        }

        return Section::make('Result')
            ->description('What the runner actually did — read-only.')
            ->schema([
                View::make('filament.coach.components.day-result-panel')
                    ->viewData(['panel' => $panel]),
            ]);
    }

    /**
     * Display payload for the result panel — mirrors the Flutter training
     * result screen: a compliance ring, per-sub-score bars, and a
     * Target vs Actual comparison table whose "actual" cells are colored by
     * the matching sub-score band. Row inclusion rules match the app's
     * `_TargetVsActualSection` (no pace row on interval days, HR row shown
     * when either side has data).
     *
     * @return array{score: float, grade: string, band: string, rows: list<array{label: string, target: string, actual: string, band: string|null}>, bars: list<array{label: string, grade: string, band: string}>, activity: string|null, feedback: HtmlString|null}|null
     */
    public function resultPanelData(?TrainingDay $day): ?array
    {
        $result = $day?->result;
        if ($result === null) {
            return null;
        }

        $score = (float) $result->compliance_score;

        $rows = [];
        if ($day->target_km !== null) {
            $rows[] = [
                'label' => 'Distance',
                'target' => $this->kmText($day->target_km).' km',
                'actual' => $this->kmText($result->actual_km).' km',
                'band' => $result->distance_score !== null ? $this->complianceBand((float) $result->distance_score) : null,
            ];
        }
        if ($day->target_pace_seconds_per_km !== null) {
            $rows[] = [
                'label' => 'Pace',
                'target' => $this->paceToText($day->target_pace_seconds_per_km).'/km',
                'actual' => $this->paceToText((int) $result->actual_pace_seconds_per_km).'/km',
                'band' => $result->pace_score !== null ? $this->complianceBand((float) $result->pace_score) : null,
            ];
        }
        if ($day->target_heart_rate_zone !== null || $result->actual_avg_heart_rate !== null) {
            $rows[] = [
                'label' => 'Heart rate',
                'target' => $day->target_heart_rate_zone !== null ? 'Zone '.$day->target_heart_rate_zone : '—',
                'actual' => $result->actual_avg_heart_rate !== null ? round((float) $result->actual_avg_heart_rate).' bpm' : '—',
                'band' => $result->heart_rate_score !== null ? $this->complianceBand((float) $result->heart_rate_score) : null,
            ];
        }

        $bars = [];
        foreach (['Distance' => $result->distance_score, 'Pace' => $result->pace_score, 'HR' => $result->heart_rate_score] as $label => $subScore) {
            if ($subScore === null) {
                continue;
            }
            $bars[] = [
                'label' => $label,
                'grade' => $this->formatScore($subScore),
                'band' => $this->complianceBand((float) $subScore),
            ];
        }

        $feedback = null;
        if ($result->ai_feedback !== null && trim($result->ai_feedback) !== '') {
            $feedback = new HtmlString(Str::markdown($result->ai_feedback, [
                'html_input' => 'strip',
                'allow_unsafe_links' => false,
            ]));
        }

        return [
            'score' => $score,
            'grade' => $this->formatScore($score),
            'band' => $this->complianceBand($score),
            'rows' => $rows,
            'bars' => $bars,
            'activity' => $this->activitySummaryLine($result->wearableActivity),
            'feedback' => $feedback,
        ];
    }

    /**
     * Off-plan ("buiten schema") runs grouped per training week — run-type
     * activities inside a week's [starts_at, starts_at + 7d) range that never
     * matched a planned session. Same semantics as
     * `TrainingScheduleController::attachUnplannedRuns`, so the coach sees
     * exactly the blue tiles the runner sees. Weeks without off-plan runs
     * are omitted from the result.
     *
     * @return array<int, Collection<int, WearableActivity>>
     */
    public function offPlanRunsByWeek(Goal $goal): array
    {
        $weeks = $goal->trainingWeeks
            ->filter(fn (TrainingWeek $week): bool => $week->starts_at !== null)
            ->sortBy('starts_at')
            ->values();

        if ($weeks->isEmpty()) {
            return [];
        }

        $rangeStart = $weeks->first()->starts_at->copy()->startOfDay();
        $rangeEnd = $weeks->last()->starts_at->copy()->startOfDay()->addDays(7);

        $runs = WearableActivity::query()
            ->where('user_id', $goal->user_id)
            ->whereIn('type', WearableActivity::RUN_TYPES)
            ->whereBetween('start_date', [$rangeStart, $rangeEnd])
            ->whereDoesntHave('trainingResults')
            ->orderBy('start_date')
            ->get();

        $byWeek = [];
        foreach ($weeks as $week) {
            $weekStart = $week->starts_at->copy()->startOfDay();
            $weekEnd = $weekStart->copy()->addDays(7);

            $weekRuns = $runs
                ->filter(fn (WearableActivity $run): bool => $run->start_date >= $weekStart && $run->start_date < $weekEnd)
                ->values();

            if ($weekRuns->isNotEmpty()) {
                $byWeek[$week->id] = $weekRuns;
            }
        }

        return $byWeek;
    }

    /**
     * "8.2 km · 4:46/km" subtitle for an off-plan run tile — mirrors the
     * Flutter `_UnplannedRunTile` subtitle.
     */
    public function offPlanRunLine(WearableActivity $run): string
    {
        $km = $this->kmText(($run->distance_meters ?? 0) / 1000) ?? '0';
        $line = "{$km} km";

        $pace = $this->paceToText((int) ($run->average_pace_seconds_per_km ?? 0));
        if ($pace !== null) {
            $line .= " · {$pace}/km";
        }

        return $line;
    }

    /**
     * "39:12 · max HR 174 · 124 m elev · 512 kcal" — each fragment omitted
     * when the activity lacks it; null when there's nothing to show (or the
     * activity row was deleted).
     */
    private function activitySummaryLine(?WearableActivity $activity): ?string
    {
        if ($activity === null) {
            return null;
        }

        $parts = [];
        if (($duration = $this->durationToText($activity->duration_seconds)) !== null) {
            $parts[] = $duration;
        }
        if ($activity->max_heartrate !== null) {
            $parts[] = 'max HR '.round((float) $activity->max_heartrate);
        }
        if ($activity->elevation_gain_meters !== null) {
            $parts[] = round((float) $activity->elevation_gain_meters).' m elev';
        }
        if ($activity->calories_kcal !== null) {
            $parts[] = round((float) $activity->calories_kcal).' kcal';
        }

        return $parts === [] ? null : implode(' · ', $parts);
    }

    /**
     * Filament form schema for the edit modal. The intervals section is only
     * rendered for `type === interval`; flipping the type live shows/hides
     * it without remounting the modal.
     *
     * @return array<int, mixed>
     */
    private function dayFormSchema(?int $dayId = null): array
    {
        $day = $dayId !== null && $dayId > 0
            ? TrainingDay::with('result.wearableActivity')->find($dayId)
            : null;

        return [
            ...array_filter([$this->resultSection($day)]),
            Grid::make(2)->schema([
                Select::make('type')
                    ->options(collect(TrainingType::cases())
                        ->mapWithKeys(fn (TrainingType $t) => [$t->value => $t->label()])
                        ->all())
                    ->required()
                    ->live(),
                DatePicker::make('date')
                    ->required()
                    ->native(false),
            ]),
            TextInput::make('title')
                ->placeholder('e.g. "Marathon-pace tempo"')
                ->maxLength(255),
            Grid::make(2)->schema([
                TextInput::make('target_km')
                    ->numeric()
                    ->step('0.1')
                    ->suffix('km')
                    ->label('Distance')
                    ->visible(fn (Get $get): bool => $get('type') !== TrainingType::Interval->value),
                // Interval distance is derived from the session structure
                // (TrainingDay saving hook enforces it on save) — read-only
                // here so the coach edits the steps, not the number.
                Placeholder::make('interval_km_summary')
                    ->label('Distance (auto)')
                    ->content(fn (Get $get): string => $this->intervalKmLabel($get))
                    ->visible(fn (Get $get): bool => $get('type') === TrainingType::Interval->value),
                TextInput::make('target_pace_text')
                    ->label('Pace')
                    ->placeholder('5:30')
                    ->suffix('/km')
                    ->helperText('Format: minutes:seconds')
                    ->rule(self::PACE_RULE)
                    ->visible(fn (Get $get): bool => $get('type') !== TrainingType::Interval->value),
                // For interval days the day-level pace IS the average across
                // work segments — read-only because the source of truth is
                // the work segments below, not a free-text field.
                Placeholder::make('interval_pace_summary')
                    ->label('Pace (work-set avg)')
                    ->content(fn (Get $get): string => $this->workAvgPaceLabel($get))
                    ->visible(fn (Get $get): bool => $get('type') === TrainingType::Interval->value),
            ]),
            Textarea::make('description')
                ->rows(3)
                ->placeholder('Notes for the runner: warmup, efforts, focus cues…')
                ->columnSpanFull(),

            Section::make('Intervals')
                ->description('Warmup, work loops + ad-hoc steps, cooldown. Drag to reorder.')
                ->visible(fn (Get $get): bool => $get('type') === TrainingType::Interval->value)
                ->schema([
                    Grid::make(2)->schema([
                        Checkbox::make('has_warmup')->label('Include warmup')->live(),
                        TextInput::make('warmup_seconds')
                            ->label('Warmup duration')
                            ->numeric()
                            ->minValue(1)
                            ->maxValue(self::WARMUP_MAX_SECONDS)
                            ->step(5)
                            ->suffix('s')
                            ->visible(fn (Get $get): bool => (bool) $get('has_warmup')),
                    ]),

                    Repeater::make('steps')
                        ->label('Steps')
                        ->reorderable()
                        ->collapsible()
                        ->collapsed()
                        ->defaultItems(0)
                        // A stepless interval session is meaningless and
                        // would null the derived target_km — only enforced
                        // while the section is visible (type = interval).
                        ->minItems(1)
                        ->addActionLabel('Add step')
                        ->itemLabel(fn (array $state): string => $this->stepLabel($state))
                        ->schema([
                            Select::make('step_type')
                                ->label('Type')
                                ->options([
                                    'block' => 'Loop (work + recovery × N)',
                                    'rep' => 'Single rep',
                                    'rest' => 'Rest',
                                ])
                                ->default('block')
                                ->required()
                                ->live(),

                            // BLOCK only: reps
                            TextInput::make('reps')
                                ->label('Reps')
                                ->numeric()
                                ->minValue(self::REPS_MIN)
                                ->maxValue(self::REPS_MAX)
                                ->default(6)
                                ->required()
                                ->visible(fn (Get $get): bool => $get('step_type') === 'block'),

                            // BLOCK + REP: work segment
                            Grid::make(2)
                                ->schema([
                                    Select::make('work_kind')
                                        ->label('Work measured by')
                                        ->options(['distance' => 'Distance', 'duration' => 'Time'])
                                        ->default('distance')
                                        ->required()
                                        ->live(),
                                    TextInput::make('work_distance_m')
                                        ->label('Distance')
                                        ->numeric()
                                        ->minValue(50)
                                        ->maxValue(5000)
                                        ->step(50)
                                        ->suffix('m')
                                        ->default(400)
                                        ->visible(fn (Get $get): bool => $get('work_kind') === 'distance'),
                                    TextInput::make('work_duration_seconds')
                                        ->label('Duration')
                                        ->numeric()
                                        ->minValue(10)
                                        ->maxValue(900)
                                        ->step(5)
                                        ->suffix('s')
                                        ->default(60)
                                        ->visible(fn (Get $get): bool => $get('work_kind') === 'duration'),
                                    TextInput::make('work_pace_text')
                                        ->label('Pace')
                                        ->placeholder('4:30')
                                        ->suffix('/km')
                                        ->rule(self::PACE_RULE),
                                ])
                                ->visible(fn (Get $get): bool => in_array($get('step_type'), ['block', 'rep'], true)),

                            // BLOCK only: recovery duration
                            TextInput::make('recovery_seconds')
                                ->label('Recovery between reps')
                                ->numeric()
                                ->minValue(15)
                                ->maxValue(600)
                                ->step(15)
                                ->suffix('s')
                                ->default(90)
                                ->required()
                                ->visible(fn (Get $get): bool => $get('step_type') === 'block'),

                            // REST only: duration
                            TextInput::make('duration_seconds')
                                ->label('Duration')
                                ->numeric()
                                ->minValue(15)
                                ->maxValue(600)
                                ->step(15)
                                ->suffix('s')
                                ->default(60)
                                ->required()
                                ->visible(fn (Get $get): bool => $get('step_type') === 'rest'),
                        ]),

                    TextInput::make('cooldown_seconds')
                        ->label('Cooldown duration')
                        ->numeric()
                        ->minValue(self::COOLDOWN_MIN_SECONDS)
                        ->maxValue(self::COOLDOWN_MAX_SECONDS)
                        ->step(30)
                        ->suffix('s')
                        ->default(300)
                        ->required(),
                ])
                ->collapsible(false),
        ];
    }

    /**
     * Live derived-distance label for the read-only Placeholder shown on
     * interval days — the same `IntervalBlueprint::estimateTotalKm` the
     * saving hook applies, so the preview matches what will be stored.
     */
    private function intervalKmLabel(Get $get): string
    {
        $km = IntervalBlueprint::estimateTotalKm($this->serializeIntervals([
            'has_warmup' => $get('has_warmup'),
            'warmup_seconds' => $get('warmup_seconds'),
            'steps' => (array) $get('steps'),
            'cooldown_seconds' => $get('cooldown_seconds'),
        ]));

        return $km === null ? '— (add a work step)' : $this->kmText($km).' km';
    }

    /**
     * Live work-set average pace label for the read-only Placeholder shown
     * on interval days. Reads the steps Repeater straight from form state
     * via Filament's `Get` helper so the label updates the moment a coach
     * tweaks any work segment.
     */
    private function workAvgPaceLabel(Get $get): string
    {
        $paces = [];
        foreach ((array) $get('steps') as $step) {
            if (! is_array($step)) {
                continue;
            }
            if (($step['step_type'] ?? null) === 'rest') {
                continue;
            }
            $pace = $this->paceFromText($step['work_pace_text'] ?? null);
            if ($pace !== null && $pace > 0) {
                $paces[] = $pace;
            }
        }

        if ($paces === []) {
            return '— (set pace on at least one work segment)';
        }

        $avg = (int) round(array_sum($paces) / count($paces));

        return $this->paceToText($avg).'/km';
    }

    /**
     * Compact one-line summary for a step row (shown when collapsed).
     *
     * @param  array<string, mixed>  $state
     */
    private function stepLabel(array $state): string
    {
        $type = $state['step_type'] ?? 'block';

        if ($type === 'rest') {
            $secs = (int) ($state['duration_seconds'] ?? 0);

            return "Rest · {$secs}s";
        }

        $work = $this->workLabel($state);
        if ($type === 'rep') {
            return "1× {$work}";
        }

        // block
        $reps = (int) ($state['reps'] ?? 1);
        $rec = (int) ($state['recovery_seconds'] ?? 0);

        return "{$reps}× {$work} → {$rec}s recovery";
    }

    /**
     * @param  array<string, mixed>  $state
     */
    private function workLabel(array $state): string
    {
        $kind = $state['work_kind'] ?? 'distance';
        $core = $kind === 'duration'
            ? ((int) ($state['work_duration_seconds'] ?? 0)).'s'
            : ((int) ($state['work_distance_m'] ?? 0)).'m';
        $pace = trim((string) ($state['work_pace_text'] ?? ''));

        return $pace !== '' ? "{$core} @ {$pace}/km" : $core;
    }

    /**
     * Decompose `intervals_json` into editor-state. Greedy block detection:
     * a run of identical `(work, recovery)` pairs becomes a single block step
     * with `reps`. Mixed/non-uniform sessions keep their structure as
     * single-rep + rest rows.
     *
     * @return array{has_warmup: bool, warmup_seconds: int, steps: list<array<string, mixed>>, cooldown_seconds: int}
     */
    private function parseIntervals(?array $segments): array
    {
        $defaults = [
            'has_warmup' => false,
            'warmup_seconds' => 60,
            'steps' => [],
            'cooldown_seconds' => 300,
        ];

        // `IntervalBlueprint` folds either the canonical grouped form or a
        // legacy flat segment list into grouped — the editor maps from there.
        $grouped = IntervalBlueprint::normalize($segments);
        if ($grouped === null) {
            return $defaults;
        }

        $steps = [];
        foreach ($grouped['steps'] as $step) {
            if (($step['type'] ?? null) === 'rest') {
                $steps[] = [
                    'step_type' => 'rest',
                    'duration_seconds' => (int) $step['duration_seconds'],
                ];

                continue;
            }

            $isDistance = ($step['work_distance_m'] ?? null) !== null;
            $base = [
                'work_kind' => $isDistance ? 'distance' : 'duration',
                'work_distance_m' => (int) ($step['work_distance_m'] ?? 400),
                'work_duration_seconds' => (int) ($step['work_duration_seconds'] ?? 60),
                'work_pace_text' => $this->paceToText($step['work_pace_seconds_per_km'] ?? null) ?? '',
            ];

            if (($step['type'] ?? 'block') === 'block') {
                $steps[] = array_merge([
                    'step_type' => 'block',
                    'reps' => max(self::REPS_MIN, min(self::REPS_MAX, (int) $step['reps'])),
                    'recovery_seconds' => (int) $step['recovery_seconds'],
                ], $base);
            } else {
                $steps[] = array_merge(['step_type' => 'rep'], $base);
            }
        }

        return [
            'has_warmup' => $grouped['warmup_seconds'] !== null,
            'warmup_seconds' => (int) ($grouped['warmup_seconds'] ?? 60),
            'steps' => $steps,
            'cooldown_seconds' => (int) $grouped['cooldown_seconds'],
        ];
    }

    /**
     * Pack the editor form data into the canonical grouped `intervals_json`.
     *
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function serializeIntervals(array $data): array
    {
        $steps = [];

        foreach (($data['steps'] ?? []) as $step) {
            if (! is_array($step)) {
                continue;
            }
            $type = $step['step_type'] ?? 'block';

            if ($type === 'rest') {
                $steps[] = [
                    'type' => 'rest',
                    'duration_seconds' => (int) ($step['duration_seconds'] ?? 60),
                ];

                continue;
            }

            $workKind = $step['work_kind'] ?? 'distance';
            $workDist = $workKind === 'distance' ? (int) ($step['work_distance_m'] ?? 400) : null;
            $workDur = $workKind === 'duration' ? (int) ($step['work_duration_seconds'] ?? 60) : null;
            $workPace = $this->paceFromText($step['work_pace_text'] ?? null);

            if ($type === 'block') {
                $steps[] = [
                    'type' => 'block',
                    'reps' => (int) ($step['reps'] ?? 1),
                    'work_distance_m' => $workDist,
                    'work_duration_seconds' => $workDur,
                    'work_pace_seconds_per_km' => $workPace,
                    'recovery_seconds' => (int) ($step['recovery_seconds'] ?? 90),
                ];
            } else {
                $steps[] = [
                    'type' => 'rep',
                    'work_distance_m' => $workDist,
                    'work_duration_seconds' => $workDur,
                    'work_pace_seconds_per_km' => $workPace,
                ];
            }
        }

        $grouped = [
            'warmup_seconds' => ! empty($data['has_warmup']) ? (int) ($data['warmup_seconds'] ?? 60) : null,
            'steps' => $steps,
            'cooldown_seconds' => (int) ($data['cooldown_seconds'] ?? 300),
        ];

        // IntervalBlueprint clamps everything (warmup cap, recovery/cooldown
        // bounds, reps) and is the single source of truth for the shape.
        return IntervalBlueprint::normalize($grouped) ?? $grouped;
    }

    /**
     * Render seconds-per-km as "m:ss". Empty input returns null.
     */
    public function paceToText(?int $seconds): ?string
    {
        if ($seconds === null || $seconds <= 0) {
            return null;
        }

        $m = intdiv($seconds, 60);
        $s = $seconds % 60;

        return sprintf('%d:%02d', $m, $s);
    }

    private function paceFromText(?string $text): ?int
    {
        if ($text === null || trim($text) === '') {
            return null;
        }

        $parts = explode(':', trim($text));
        if (count($parts) !== 2) {
            return null;
        }

        $m = (int) $parts[0];
        $s = (int) $parts[1];

        return $m * 60 + $s;
    }

    private function coachCanEdit(User $user, User $client): bool
    {
        $clientMembership = $client->activeMembership;
        if ($clientMembership === null) {
            return false;
        }

        if ($user->organizationId() !== $clientMembership->organization_id) {
            return false;
        }

        if ($user->isOrgAdmin()) {
            return true;
        }

        return $user->isCoach() && $clientMembership->coach_user_id === $user->id;
    }
}
