<?php

namespace App\Filament\Resources\Organizations\Schemas;

use App\Enums\OrganizationStatus;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Schemas\Schema;
use Illuminate\Support\Str;

class OrganizationForm
{
    public static function configure(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')
                    ->required()
                    ->live(onBlur: true)
                    ->afterStateUpdated(function ($state, callable $set, callable $get, ?string $context) {
                        if ($context === 'create' && empty($get('slug'))) {
                            $set('slug', Str::slug((string) $state));
                        }
                    }),
                TextInput::make('slug')
                    ->required()
                    ->unique(ignoreRecord: true)
                    ->helperText('Used in invite links. Lowercase letters, numbers, hyphens only.'),
                Textarea::make('description')
                    ->columnSpanFull()
                    ->rows(3),
                TextInput::make('website')
                    ->url()
                    ->prefix('https://'),
                TextInput::make('logo_path')
                    ->helperText('Path to a stored logo image. Optional.'),
                Select::make('status')
                    ->options(OrganizationStatus::class)
                    ->default(OrganizationStatus::Active->value)
                    ->required(),
                Toggle::make('coaches_own_plans')
                    ->label('Coaches own plans')
                    ->helperText('When on, the AI coach will not create or modify training plans for clients in this org.')
                    ->default(true)
                    ->required(),
            ]);
    }
}
