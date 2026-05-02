<?php

namespace App\Filament\Coach\Resources\Clients\Tables;

use App\Enums\GoalStatus;
use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\OrganizationMembership;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ClientsTable
{
    public static function configure(Table $table): Table
    {
        /** @var User|null $authUser */
        $authUser = auth()->user();
        $showCoach = $authUser?->isOrgAdmin() === true || $authUser?->isSuperadmin() === true;

        return $table
            ->defaultSort('name')
            ->columns([
                TextColumn::make('name')
                    ->label('Name')
                    ->placeholder('—')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('email')
                    ->label('Email')
                    ->searchable()
                    ->copyable(),
                TextColumn::make('activeGoal.name')
                    ->label('Goal')
                    ->placeholder('—')
                    ->limit(40),
                TextColumn::make('activeGoal.target_date')
                    ->label('Race day')
                    ->date('M j, Y')
                    ->placeholder('—')
                    ->sortable(),
                TextColumn::make('activeMembership.coach.name')
                    ->label('Coach')
                    ->placeholder('—')
                    ->visible($showCoach)
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters(self::filtersFor($authUser))
            ->recordActions([
                Action::make('schedule')
                    ->label('Schedule')
                    ->icon('heroicon-o-calendar-days')
                    ->color('primary')
                    ->visible(fn (User $record) => $record->goals()
                        ->where('status', GoalStatus::Active)
                        ->exists())
                    ->url(function (User $record) {
                        $goal = $record->goals()
                            ->where('status', GoalStatus::Active)
                            ->latest('target_date')
                            ->first();

                        return $goal
                            ? route('filament.coach.pages.goal-schedule', ['goal' => $goal->id])
                            : null;
                    }),
                ViewAction::make()->label('Profile'),
            ]);
    }

    /**
     * @return array<int, mixed>
     */
    private static function filtersFor(?User $authUser): array
    {
        if ($authUser === null || $authUser->isSuperadmin()) {
            return [];
        }

        return [
            SelectFilter::make('coach_user_id')
                ->label('Assigned coach')
                ->options(fn () => OrganizationMembership::query()
                    ->where('role', OrganizationRole::Coach)
                    ->where('status', MembershipStatus::Active)
                    ->where('organization_id', $authUser->organizationId())
                    ->with('user')
                    ->get()
                    ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                    ->all())
                ->query(function ($query, array $data) use ($authUser) {
                    if (empty($data['value'])) {
                        return;
                    }

                    $query->whereHas('memberships', fn ($q) => $q
                        ->where('organization_id', $authUser->organizationId())
                        ->where('role', OrganizationRole::Client)
                        ->where('coach_user_id', $data['value']));
                }),
        ];
    }
}
