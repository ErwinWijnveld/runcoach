<?php

namespace App\Filament\Coach\Resources\Coaches\Tables;

use App\Enums\MembershipStatus;
use App\Notifications\OrganizationInvitation;
use Filament\Actions\Action;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class CoachesTable
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
                SelectFilter::make('status')->options(MembershipStatus::class),
            ])
            ->recordActions([
                Action::make('resendInvite')
                    ->label('Resend invite')
                    ->icon('heroicon-o-envelope')
                    ->visible(fn ($record) => $record->isInvited())
                    ->action(function ($record) {
                        if ($record->user) {
                            $record->user->notify(new OrganizationInvitation($record));
                        } else {
                            \Illuminate\Support\Facades\Notification::route('mail', $record->invite_email)
                                ->notify(new OrganizationInvitation($record));
                        }

                        Notification::make()
                            ->title('Invite resent')
                            ->success()
                            ->send();
                    }),
                Action::make('revoke')
                    ->label('Revoke')
                    ->icon('heroicon-o-x-mark')
                    ->color('danger')
                    ->requiresConfirmation()
                    ->action(fn ($record) => $record->update([
                        'status' => MembershipStatus::Removed,
                        'removed_at' => now(),
                        'invite_token' => null,
                    ])),
            ]);
    }
}
