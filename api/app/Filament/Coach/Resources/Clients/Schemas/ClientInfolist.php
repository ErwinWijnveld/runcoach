<?php

namespace App\Filament\Coach\Resources\Clients\Schemas;

use App\Models\OrganizationMembership;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Components\Tabs;
use Filament\Schemas\Components\Tabs\Tab;
use Filament\Schemas\Schema;

class ClientInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Tabs::make('Client')
                    ->tabs([
                        Tab::make('Overview')
                            ->icon('heroicon-o-user')
                            ->schema([
                                Section::make('Profile')
                                    ->columns(2)
                                    ->schema([
                                        TextEntry::make('user.name')
                                            ->label('Name')
                                            ->placeholder('—'),
                                        TextEntry::make('user.email')
                                            ->label('Email')
                                            ->placeholder(fn (OrganizationMembership $r) => $r->invite_email),
                                        TextEntry::make('coach.name')
                                            ->label('Assigned coach')
                                            ->placeholder('Unassigned'),
                                        TextEntry::make('joined_at')
                                            ->label('Joined')
                                            ->date('Y-m-d')
                                            ->placeholder('—'),
                                    ]),
                                Section::make('Active goal')
                                    ->columns(3)
                                    ->schema([
                                        TextEntry::make('user.activeGoal.name')
                                            ->label('Goal')
                                            ->placeholder('— no active goal —'),
                                        TextEntry::make('user.activeGoal.distance')
                                            ->label('Distance')
                                            ->placeholder('—'),
                                        TextEntry::make('user.activeGoal.target_date')
                                            ->label('Target date')
                                            ->date('Y-m-d')
                                            ->placeholder('—'),
                                    ]),
                            ]),
                        Tab::make('Schedule')
                            ->icon('heroicon-o-calendar-days')
                            ->schema([
                                TextEntry::make('schedule_placeholder')
                                    ->label('')
                                    ->state('Inline schedule editor coming in Phase 5.'),
                            ]),
                        Tab::make('Activities')
                            ->icon('heroicon-o-bolt')
                            ->schema([
                                TextEntry::make('activities_placeholder')
                                    ->label('')
                                    ->state('Strava activities tab coming in Phase 5.'),
                            ]),
                    ])
                    ->columnSpanFull(),
            ]);
    }
}
