<?php

namespace App\Filament\Coach\Resources\Clients\Schemas;

use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ClientInfolist
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                Section::make('Profile')
                    ->columns(2)
                    ->schema([
                        TextEntry::make('name')
                            ->label('Name')
                            ->placeholder('—'),
                        TextEntry::make('email')
                            ->label('Email')
                            ->placeholder('—'),
                        TextEntry::make('activeMembership.organization.name')
                            ->label('Organization')
                            ->placeholder('— none —'),
                        TextEntry::make('activeMembership.coach.name')
                            ->label('Assigned coach')
                            ->placeholder('— unassigned —'),
                    ]),
                Section::make('Active goal')
                    ->columns(3)
                    ->schema([
                        TextEntry::make('activeGoal.name')
                            ->label('Goal')
                            ->placeholder('— no active goal —'),
                        TextEntry::make('activeGoal.distance')
                            ->label('Distance')
                            ->placeholder('—'),
                        TextEntry::make('activeGoal.target_date')
                            ->label('Race day')
                            ->date('M j, Y')
                            ->placeholder('—'),
                    ]),
            ]);
    }
}
