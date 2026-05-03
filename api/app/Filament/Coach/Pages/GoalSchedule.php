<?php

namespace App\Filament\Coach\Pages;

use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
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
use Filament\Support\Enums\Width;
use Filament\Support\Icons\Heroicon;

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

        return Goal::with(['trainingWeeks.trainingDays', 'user'])->find($this->goalId);
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
            ->schema(fn () => $this->dayFormSchema())
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
     * Filament form schema for the edit modal. The intervals section is only
     * rendered for `type === interval`; flipping the type live shows/hides
     * it without remounting the modal.
     *
     * @return array<int, mixed>
     */
    private function dayFormSchema(): array
    {
        return [
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
                    ->label('Distance'),
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

        if ($segments === null || count($segments) === 0) {
            return $defaults;
        }

        $warmup = null;
        $cooldown = null;
        $middle = [];

        foreach ($segments as $seg) {
            if (! is_array($seg)) {
                continue;
            }
            $kind = (string) ($seg['kind'] ?? 'work');
            if ($kind === 'warmup' && $warmup === null) {
                $warmup = $seg;
            } elseif ($kind === 'cooldown') {
                $cooldown = $seg;
            } else {
                $middle[] = $seg;
            }
        }

        $steps = [];
        $i = 0;
        while ($i < count($middle)) {
            $cur = $middle[$i];
            $kind = $cur['kind'] ?? 'work';

            if ($kind === 'recovery') {
                $steps[] = [
                    'step_type' => 'rest',
                    'duration_seconds' => (int) ($cur['duration_seconds'] ?? 60),
                ];
                $i++;

                continue;
            }

            // Work segment — try to grow a block by matching consecutive
            // (work, recovery) pairs against this work + the recovery that
            // follows. Falls back to a single-rep step when there's no
            // recovery after, or the next pair doesn't match.
            $next = $middle[$i + 1] ?? null;
            if ($next === null || ($next['kind'] ?? '') !== 'recovery') {
                $steps[] = $this->workToRepStep($cur);
                $i++;

                continue;
            }

            $reps = 1;
            $j = $i + 2;
            while ($j + 1 < count($middle)
                && ($middle[$j]['kind'] ?? '') === 'work'
                && ($middle[$j + 1]['kind'] ?? '') === 'recovery'
                && $this->workSegmentEquals($middle[$j], $cur)
                && $this->recoverySegmentEquals($middle[$j + 1], $next)
            ) {
                $reps++;
                $j += 2;
            }

            $steps[] = $this->workToBlockStep($cur, $next, $reps);
            $i = $j;
        }

        return [
            'has_warmup' => $warmup !== null,
            'warmup_seconds' => (int) ($warmup['duration_seconds'] ?? 60),
            'steps' => $steps,
            'cooldown_seconds' => (int) ($cooldown['duration_seconds'] ?? 300),
        ];
    }

    /**
     * @param  array<string, mixed>  $work
     * @return array<string, mixed>
     */
    private function workToRepStep(array $work): array
    {
        $kind = ($work['distance_m'] ?? null) !== null ? 'distance' : 'duration';

        return [
            'step_type' => 'rep',
            'work_kind' => $kind,
            'work_distance_m' => (int) ($work['distance_m'] ?? 400),
            'work_duration_seconds' => (int) ($work['duration_seconds'] ?? 60),
            'work_pace_text' => $this->paceToText($work['target_pace_seconds_per_km'] ?? null) ?? '',
        ];
    }

    /**
     * @param  array<string, mixed>  $work
     * @param  array<string, mixed>  $recovery
     * @return array<string, mixed>
     */
    private function workToBlockStep(array $work, array $recovery, int $reps): array
    {
        $kind = ($work['distance_m'] ?? null) !== null ? 'distance' : 'duration';

        return [
            'step_type' => 'block',
            'reps' => max(self::REPS_MIN, min(self::REPS_MAX, $reps)),
            'work_kind' => $kind,
            'work_distance_m' => (int) ($work['distance_m'] ?? 400),
            'work_duration_seconds' => (int) ($work['duration_seconds'] ?? 60),
            'work_pace_text' => $this->paceToText($work['target_pace_seconds_per_km'] ?? null) ?? '',
            'recovery_seconds' => (int) ($recovery['duration_seconds'] ?? 90),
        ];
    }

    /**
     * Pack the editor form data into a canonical `intervals_json` array.
     *
     * @param  array<string, mixed>  $data
     * @return list<array<string, mixed>>
     */
    private function serializeIntervals(array $data): array
    {
        $segments = [];

        if (! empty($data['has_warmup'])) {
            $sec = max(1, min(self::WARMUP_MAX_SECONDS, (int) ($data['warmup_seconds'] ?? 60)));
            $segments[] = [
                'kind' => 'warmup',
                'label' => 'Warm up',
                'distance_m' => null,
                'duration_seconds' => $sec,
                'target_pace_seconds_per_km' => null,
            ];
        }

        foreach (($data['steps'] ?? []) as $step) {
            if (! is_array($step)) {
                continue;
            }
            $type = $step['step_type'] ?? 'block';

            if ($type === 'rest') {
                $segments[] = [
                    'kind' => 'recovery',
                    'label' => 'Rest',
                    'distance_m' => null,
                    'duration_seconds' => max(15, (int) ($step['duration_seconds'] ?? 60)),
                    'target_pace_seconds_per_km' => null,
                ];

                continue;
            }

            $workKind = $step['work_kind'] ?? 'distance';
            $workDist = $workKind === 'distance' ? max(1, (int) ($step['work_distance_m'] ?? 400)) : null;
            $workDur = $workKind === 'duration' ? max(1, (int) ($step['work_duration_seconds'] ?? 60)) : null;
            $workPace = $this->paceFromText($step['work_pace_text'] ?? null);
            $workLabel = $workKind === 'distance' ? "{$workDist}m rep" : "{$workDur}s rep";

            $reps = $type === 'block'
                ? max(self::REPS_MIN, min(self::REPS_MAX, (int) ($step['reps'] ?? 1)))
                : 1;

            for ($r = 0; $r < $reps; $r++) {
                $segments[] = [
                    'kind' => 'work',
                    'label' => $workLabel,
                    'distance_m' => $workDist,
                    'duration_seconds' => $workDur,
                    'target_pace_seconds_per_km' => $workPace,
                ];
                if ($type === 'block') {
                    $segments[] = [
                        'kind' => 'recovery',
                        'label' => 'Recovery',
                        'distance_m' => null,
                        'duration_seconds' => max(15, (int) ($step['recovery_seconds'] ?? 90)),
                        'target_pace_seconds_per_km' => null,
                    ];
                }
            }
        }

        $cooldownSec = max(self::COOLDOWN_MIN_SECONDS, min(self::COOLDOWN_MAX_SECONDS, (int) ($data['cooldown_seconds'] ?? 300)));
        $segments[] = [
            'kind' => 'cooldown',
            'label' => 'Cool down',
            'distance_m' => null,
            'duration_seconds' => $cooldownSec,
            'target_pace_seconds_per_km' => null,
        ];

        return $segments;
    }

    /**
     * @param  array<string, mixed>  $a
     * @param  array<string, mixed>  $b
     */
    private function workSegmentEquals(array $a, array $b): bool
    {
        return ($a['distance_m'] ?? null) === ($b['distance_m'] ?? null)
            && ($a['duration_seconds'] ?? null) === ($b['duration_seconds'] ?? null)
            && ($a['target_pace_seconds_per_km'] ?? null) === ($b['target_pace_seconds_per_km'] ?? null);
    }

    /**
     * @param  array<string, mixed>  $a
     * @param  array<string, mixed>  $b
     */
    private function recoverySegmentEquals(array $a, array $b): bool
    {
        return ($a['duration_seconds'] ?? null) === ($b['duration_seconds'] ?? null);
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
