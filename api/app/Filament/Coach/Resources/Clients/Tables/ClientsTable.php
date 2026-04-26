<?php

namespace App\Filament\Coach\Resources\Clients\Tables;

use App\Enums\GoalStatus;
use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Models\OrganizationMembership;
use Filament\Actions\Action;
use Filament\Actions\ViewAction;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class ClientsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('joined_at', 'desc')
            ->columns([
                TextColumn::make('user.name')
                    ->label('Name')
                    ->placeholder('— pending —')
                    ->searchable(['users.name'])
                    ->weight('bold'),
                TextColumn::make('display_email')
                    ->label('Email')
                    ->state(fn ($record) => $record->user?->email ?? $record->invite_email)
                    ->searchable(query: function ($query, string $search) {
                        $query->whereHas('user', fn ($q) => $q->where('email', 'like', "%{$search}%"))
                            ->orWhere('invite_email', 'like', "%{$search}%");
                    }),
                TextColumn::make('coach.name')
                    ->label('Coach')
                    ->placeholder('— unassigned —')
                    ->toggleable(),
                TextColumn::make('user.activeGoal.name')
                    ->label('Goal')
                    ->placeholder('— no active goal —')
                    ->limit(40)
                    ->toggleable(),
                TextColumn::make('user.activeGoal.target_date')
                    ->label('Target')
                    ->date('Y-m-d')
                    ->toggleable(),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (MembershipStatus $state) => match ($state) {
                        MembershipStatus::Active => 'success',
                        MembershipStatus::Invited => 'warning',
                        default => 'gray',
                    }),
                TextColumn::make('joined_at')
                    ->label('Joined')
                    ->date('Y-m-d')
                    ->placeholder('—')
                    ->sortable(),
            ])
            ->filters([
                SelectFilter::make('coach_user_id')
                    ->label('Assigned coach')
                    ->options(fn () => OrganizationMembership::query()
                        ->where('role', OrganizationRole::Coach)
                        ->where('status', MembershipStatus::Active)
                        ->where('organization_id', auth()->user()?->organizationId())
                        ->with('user')
                        ->get()
                        ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                        ->all()),
                SelectFilter::make('status')->options(MembershipStatus::class),
            ])
            ->recordActions([
                Action::make('schedule')
                    ->label('Schedule')
                    ->icon('heroicon-o-calendar-days')
                    ->color('primary')
                    ->visible(function ($record) {
                        return $record->user?->goals()
                            ->where('status', GoalStatus::Active)
                            ->exists() ?? false;
                    })
                    ->url(function ($record) {
                        $goal = $record->user?->goals()
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
}
