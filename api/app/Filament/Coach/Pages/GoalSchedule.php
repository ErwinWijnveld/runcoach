<?php

namespace App\Filament\Coach\Pages;

use App\Enums\TrainingType;
use App\Models\Goal;
use App\Models\TrainingDay;
use App\Models\TrainingWeek;
use App\Models\User;
use BackedEnum;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Panel;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

/**
 * @property-read array $data
 */
class GoalSchedule extends Page
{
    protected string $view = 'filament.coach.pages.goal-schedule';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCalendarDays;

    protected static bool $shouldRegisterNavigation = false;

    public static function getRoutePath(Panel $panel): string
    {
        return '/goal-schedule/{goal}';
    }

    public ?int $goalId = null;

    public ?array $data = [];

    public ?int $editingDayId = null;

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

    public function getEditingDayProperty(): ?TrainingDay
    {
        return $this->editingDayId ? TrainingDay::find($this->editingDayId) : null;
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

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Grid::make(2)->schema([
                    Select::make('type')
                        ->options(collect(TrainingType::cases())
                            ->mapWithKeys(fn (TrainingType $t) => [$t->value => $t->label()])
                            ->all())
                        ->required(),
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
                        ->helperText('Format: minutes:seconds'),
                ]),
                Textarea::make('description')
                    ->rows(3)
                    ->placeholder('Notes for the runner: warmup, efforts, focus cues…')
                    ->columnSpanFull(),
            ])
            ->statePath('data')
            ->model(TrainingDay::class);
    }

    public function editDay(int $dayId): void
    {
        $day = TrainingDay::findOrFail($dayId);
        $this->editingDayId = $day->id;
        $this->data = [
            'type' => $day->type?->value,
            'title' => $day->title,
            'date' => $day->date?->toDateString(),
            'target_km' => $day->target_km,
            'target_pace_text' => $this->paceToText($day->target_pace_seconds_per_km),
            'description' => $day->description,
        ];
    }

    public function saveDay(): void
    {
        $day = $this->editingDay;
        if ($day === null) {
            return;
        }

        $payload = $this->data;
        $payload['target_pace_seconds_per_km'] = $this->paceFromText($payload['target_pace_text'] ?? null);
        unset($payload['target_pace_text']);

        $day->update($payload);

        Notification::make()->title('Saved')->success()->send();

        $this->cancelEdit();
    }

    public function cancelEdit(): void
    {
        $this->editingDayId = null;
        $this->data = [];
    }

    public function deleteEditingDay(): void
    {
        $day = $this->editingDay;
        if ($day === null) {
            return;
        }

        $day->delete();
        Notification::make()->title('Day removed')->success()->send();

        $this->cancelEdit();
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

        $this->editDay($newDay->id);
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
