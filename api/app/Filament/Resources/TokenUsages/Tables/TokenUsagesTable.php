<?php

namespace App\Filament\Resources\TokenUsages\Tables;

use App\Models\TokenUsage;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class TokenUsagesTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('created_at')
                    ->label('When')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(),
                TextColumn::make('user.email')
                    ->label('User')
                    ->searchable()
                    ->placeholder('(system)')
                    ->toggleable(),
                TextColumn::make('context')
                    ->badge()
                    ->colors([
                        'primary' => 'coach',
                        'warning' => 'onboarding',
                        'success' => 'activity_feedback',
                        'info' => 'weekly_insight',
                        'gray' => 'plan_explanation',
                        'danger' => 'plan_verifier',
                    ])
                    ->sortable(),
                TextColumn::make('model')
                    ->sortable()
                    ->toggleable(),
                TextColumn::make('prompt_tokens')
                    ->label('In')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('completion_tokens')
                    ->label('Out')
                    ->numeric()
                    ->sortable(),
                TextColumn::make('cache_read_input_tokens')
                    ->label('Cache R')
                    ->numeric()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('cache_write_input_tokens')
                    ->label('Cache W')
                    ->numeric()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('total_tokens')
                    ->label('Total')
                    ->numeric()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('conversation_id')
                    ->label('Conv')
                    ->limit(8)
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('context')
                    ->options(fn () => TokenUsage::query()
                        ->select('context')
                        ->distinct()
                        ->orderBy('context')
                        ->pluck('context', 'context')
                        ->all()),
                SelectFilter::make('user_id')
                    ->label('User')
                    ->relationship('user', 'email')
                    ->searchable()
                    ->preload(),
                SelectFilter::make('model')
                    ->options(fn () => TokenUsage::query()
                        ->whereNotNull('model')
                        ->select('model')
                        ->distinct()
                        ->orderBy('model')
                        ->pluck('model', 'model')
                        ->all()),
                Filter::make('last_7_days')
                    ->label('Last 7 days')
                    ->query(fn (Builder $q) => $q->where('created_at', '>=', now()->subDays(7))),
            ])
            ->recordActions([])
            ->toolbarActions([]);
    }
}
