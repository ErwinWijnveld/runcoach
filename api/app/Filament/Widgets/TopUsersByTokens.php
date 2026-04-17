<?php

namespace App\Filament\Widgets;

use App\Models\User;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Table;
use Filament\Widgets\TableWidget;

class TopUsersByTokens extends TableWidget
{
    protected int|string|array $columnSpan = ['md' => 1];

    public function table(Table $table): Table
    {
        return $table
            ->heading('Top users (last 7 days)')
            ->query(
                User::query()
                    ->leftJoin('token_usages', function ($join) {
                        $join->on('users.id', '=', 'token_usages.user_id')
                            ->where('token_usages.created_at', '>=', now()->subDays(7));
                    })
                    ->selectRaw('users.id, users.email')
                    ->selectRaw('COALESCE(SUM(token_usages.total_tokens), 0) as tokens')
                    ->selectRaw('COUNT(token_usages.id) as calls')
                    ->groupBy('users.id', 'users.email')
                    ->havingRaw('tokens > 0')
                    ->orderByDesc('tokens')
                    ->limit(10)
            )
            ->defaultKeySort(false)
            ->columns([
                TextColumn::make('email')->searchable(),
                TextColumn::make('calls')->numeric(),
                TextColumn::make('tokens')->numeric()->weight('bold'),
            ])
            ->paginated(false);
    }
}
