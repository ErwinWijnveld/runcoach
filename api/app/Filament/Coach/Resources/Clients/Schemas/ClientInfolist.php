<?php

namespace App\Filament\Coach\Resources\Clients\Schemas;

use App\Models\User;
use Filament\Infolists\Components\TextEntry;
use Filament\Schemas\Components\Section;
use Filament\Schemas\Schema;

class ClientInfolist
{
    private const ZONE_NAMES = ['Endurance', 'Moderate', 'Tempo', 'Threshold', 'Anaerobic'];

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
                Section::make('HR zones')
                    ->description('Used for compliance scoring and the AI coach\'s zone targets. Edit via the "HR zones" action above.')
                    ->columns(5)
                    ->schema([
                        TextEntry::make('zone_1')
                            ->label('Z1 — '.self::ZONE_NAMES[0])
                            ->state(fn (User $record): string => self::formatZone($record, 0))
                            ->placeholder('—'),
                        TextEntry::make('zone_2')
                            ->label('Z2 — '.self::ZONE_NAMES[1])
                            ->state(fn (User $record): string => self::formatZone($record, 1))
                            ->placeholder('—'),
                        TextEntry::make('zone_3')
                            ->label('Z3 — '.self::ZONE_NAMES[2])
                            ->state(fn (User $record): string => self::formatZone($record, 2))
                            ->placeholder('—'),
                        TextEntry::make('zone_4')
                            ->label('Z4 — '.self::ZONE_NAMES[3])
                            ->state(fn (User $record): string => self::formatZone($record, 3))
                            ->placeholder('—'),
                        TextEntry::make('zone_5')
                            ->label('Z5 — '.self::ZONE_NAMES[4])
                            ->state(fn (User $record): string => self::formatZone($record, 4))
                            ->placeholder('—'),
                    ]),
            ]);
    }

    private static function formatZone(User $record, int $index): string
    {
        $zones = $record->heart_rate_zones;
        if (! is_array($zones) || ! isset($zones[$index])) {
            return '— not set —';
        }

        $min = (int) ($zones[$index]['min'] ?? 0);
        $max = (int) ($zones[$index]['max'] ?? 0);

        return $max < 0 ? "{$min}+ bpm" : "{$min}–{$max} bpm";
    }
}
