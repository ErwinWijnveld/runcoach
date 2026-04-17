<?php

namespace App\Filament\Resources\TokenUsages;

use App\Filament\Resources\TokenUsages\Pages\ListTokenUsages;
use App\Filament\Resources\TokenUsages\Tables\TokenUsagesTable;
use App\Models\TokenUsage;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;

class TokenUsageResource extends Resource
{
    protected static ?string $model = TokenUsage::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedChartBar;

    protected static ?string $navigationLabel = 'Token Usage';

    protected static ?string $modelLabel = 'Token usage';

    protected static ?string $pluralModelLabel = 'Token usage';

    public static function table(Table $table): Table
    {
        return TokenUsagesTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListTokenUsages::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
