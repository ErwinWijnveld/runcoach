<?php

namespace App\Filament\Widgets;

use App\Models\TokenUsage;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class TokenUsageByContext extends TableWidget
{
    protected int|string|array $columnSpan = ['md' => 1];

    public function table(Table $table): Table
    {
        return $table
            ->heading('Tokens by context (last 7 days)')
            ->query(
                TokenUsage::query()
                    ->where('created_at', '>=', now()->subDays(7))
                    ->selectRaw('MIN(id) as id')
                    ->addSelect('context')
                    ->selectRaw('SUM(total_tokens) as total')
                    ->selectRaw('COUNT(*) as invocations')
                    ->groupBy('context')
                    ->orderByDesc('total')
            )
            ->defaultKeySort(false)
            ->columns([
                TextColumn::make('context')->badge(),
                TextColumn::make('invocations')->label('Calls')->numeric(),
                TextColumn::make('total')->label('Tokens')->numeric()->weight('bold'),
            ])
            ->paginated(false);
    }
}
