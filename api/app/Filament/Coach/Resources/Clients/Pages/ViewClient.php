<?php

namespace App\Filament\Coach\Resources\Clients\Pages;

use App\Enums\GoalStatus;
use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\ClientResource;
use App\Models\OrganizationMembership;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;
use Filament\Schemas\Components\Grid;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Utilities\Set;
use Illuminate\Validation\ValidationException;

class ViewClient extends ViewRecord
{
    protected static string $resource = ClientResource::class;

    public function getTitle(): string
    {
        /** @var User $record */
        $record = $this->getRecord();

        return $record->name ?? $record->email ?? 'Client';
    }

    protected function getHeaderActions(): array
    {
        /** @var User $record */
        $record = $this->getRecord();
        /** @var User|null $authUser */
        $authUser = auth()->user();

        $activeGoal = $record->goals()
            ->where('status', GoalStatus::Active)
            ->latest('target_date')
            ->first();

        $clientMembership = $this->resolveClientMembership($record, $authUser);
        $canReassign = $authUser !== null
            && $clientMembership !== null
            && ($authUser->isSuperadmin() || $authUser->isOrgAdmin());

        return [
            Action::make('openSchedule')
                ->label('Schedule')
                ->icon('heroicon-o-calendar-days')
                ->color('primary')
                ->visible(fn () => $activeGoal !== null)
                ->url(fn () => route('filament.coach.pages.goal-schedule', ['goal' => $activeGoal?->id])),
            $this->editHrZonesAction($record),
            Action::make('reassignCoach')
                ->label('Reassign coach')
                ->icon('heroicon-o-academic-cap')
                ->color('gray')
                ->visible(fn () => $canReassign)
                ->schema([
                    Select::make('coach_user_id')
                        ->label('Coach')
                        ->placeholder('Unassigned')
                        ->options(fn () => OrganizationMembership::query()
                            ->where('role', OrganizationRole::Coach)
                            ->where('status', MembershipStatus::Active)
                            ->where('organization_id', $clientMembership?->organization_id)
                            ->with('user')
                            ->get()
                            ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                            ->all())
                        ->default($clientMembership?->coach_user_id),
                ])
                ->action(function (array $data) use ($clientMembership): void {
                    if ($clientMembership === null) {
                        return;
                    }

                    $clientMembership->update([
                        'coach_user_id' => $data['coach_user_id'] ?: null,
                    ]);

                    Notification::make()->title('Coach updated')->success()->send();
                }),
        ];
    }

    private function editHrZonesAction(User $record): Action
    {
        return Action::make('editHrZones')
            ->label('HR zones')
            ->icon('heroicon-o-heart')
            ->color('gray')
            ->modalHeading('Edit HR zones')
            ->modalDescription('Adjust Max HR to recompute every zone, or edit a single boundary. Z1 starts at 0 bpm and Z5 has no upper limit.')
            ->modalSubmitActionLabel('Save')
            ->fillForm(fn (): array => $this->hrZoneFormState($record))
            ->schema([
                Section::make('Max HR shortcut')
                    ->description('Editing this recomputes all 5 boundaries via 60/70/80/90 % of Max HR.')
                    ->schema([
                        TextInput::make('max_hr')
                            ->label('Max HR')
                            ->numeric()
                            ->suffix('bpm')
                            ->minValue(100)
                            ->maxValue(250)
                            ->live(onBlur: true)
                            ->afterStateUpdated(function ($state, Set $set): void {
                                if (! is_numeric($state)) {
                                    return;
                                }
                                $max = (int) $state;
                                $set('z1_max', (int) round($max * 0.60));
                                $set('z2_max', (int) round($max * 0.70));
                                $set('z3_max', (int) round($max * 0.80));
                                $set('z4_max', (int) round($max * 0.90));
                            }),
                    ]),
                Section::make('Zone boundaries')
                    ->description('Each value is the upper bpm of that zone (and the lower bpm of the next).')
                    ->schema([
                        Grid::make(2)->schema([
                            TextInput::make('z1_max')
                                ->label('Z1 (Endurance) max')
                                ->numeric()
                                ->required()
                                ->suffix('bpm')
                                ->minValue(40)
                                ->maxValue(249),
                            TextInput::make('z2_max')
                                ->label('Z2 (Moderate) max')
                                ->numeric()
                                ->required()
                                ->suffix('bpm')
                                ->minValue(40)
                                ->maxValue(249),
                            TextInput::make('z3_max')
                                ->label('Z3 (Tempo) max')
                                ->numeric()
                                ->required()
                                ->suffix('bpm')
                                ->minValue(40)
                                ->maxValue(249),
                            TextInput::make('z4_max')
                                ->label('Z4 (Threshold) max')
                                ->numeric()
                                ->required()
                                ->suffix('bpm')
                                ->minValue(40)
                                ->maxValue(249),
                        ]),
                    ]),
            ])
            ->action(function (array $data) use ($record): void {
                $boundaries = [
                    (int) ($data['z1_max'] ?? 0),
                    (int) ($data['z2_max'] ?? 0),
                    (int) ($data['z3_max'] ?? 0),
                    (int) ($data['z4_max'] ?? 0),
                ];

                for ($i = 1; $i < 4; $i++) {
                    if ($boundaries[$i] <= $boundaries[$i - 1]) {
                        throw ValidationException::withMessages([
                            'z'.($i + 1).'_max' => 'Each zone max must be greater than the previous one.',
                        ]);
                    }
                }

                $record->forceFill([
                    'heart_rate_zones' => [
                        ['min' => 0, 'max' => $boundaries[0]],
                        ['min' => $boundaries[0], 'max' => $boundaries[1]],
                        ['min' => $boundaries[1], 'max' => $boundaries[2]],
                        ['min' => $boundaries[2], 'max' => $boundaries[3]],
                        ['min' => $boundaries[3], 'max' => -1],
                    ],
                ])->save();

                Notification::make()->title('HR zones updated')->success()->send();
            });
    }

    /**
     * @return array<string, int|null>
     */
    private function hrZoneFormState(User $record): array
    {
        $zones = $record->heart_rate_zones;

        if (is_array($zones) && count($zones) === 5) {
            $boundaries = [
                (int) ($zones[0]['max'] ?? 0),
                (int) ($zones[1]['max'] ?? 0),
                (int) ($zones[2]['max'] ?? 0),
                (int) ($zones[3]['max'] ?? 0),
            ];
        } else {
            // Fall back to the standard 60/70/80/90 % derivation off a
            // typical Max HR so the form opens with sensible defaults.
            $maxHr = 190;
            $boundaries = [
                (int) round($maxHr * 0.60),
                (int) round($maxHr * 0.70),
                (int) round($maxHr * 0.80),
                (int) round($maxHr * 0.90),
            ];
        }

        return [
            // Z4↔Z5 boundary sits at ~90 % of Max HR by convention.
            'max_hr' => (int) round($boundaries[3] / 0.9),
            'z1_max' => $boundaries[0],
            'z2_max' => $boundaries[1],
            'z3_max' => $boundaries[2],
            'z4_max' => $boundaries[3],
        ];
    }

    private function resolveClientMembership(User $record, ?User $authUser): ?OrganizationMembership
    {
        $query = $record->memberships()
            ->where('role', OrganizationRole::Client)
            ->where('status', MembershipStatus::Active);

        if ($authUser !== null && ! $authUser->isSuperadmin()) {
            $query->where('organization_id', $authUser->organizationId());
        }

        return $query->latest('id')->first();
    }
}
