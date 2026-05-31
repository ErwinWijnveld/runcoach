<?php

namespace App\Filament\Resources\Subscriptions\Tables;

use App\Models\Subscription;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class SubscriptionsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('user.email')
                    ->label('User')
                    ->searchable(),
                TextColumn::make('product_id')
                    ->label('Product')
                    ->sortable(),
                TextColumn::make('status')
                    ->badge()
                    ->colors([
                        'success' => Subscription::STATUS_ACTIVE,
                        'warning' => Subscription::STATUS_IN_GRACE_PERIOD,
                        'warning' => Subscription::STATUS_IN_BILLING_RETRY,
                        'gray' => Subscription::STATUS_EXPIRED,
                        'danger' => Subscription::STATUS_CANCELLED,
                        'info' => Subscription::STATUS_PAUSED,
                    ])
                    ->sortable(),
                TextColumn::make('period_type')
                    ->label('Period')
                    ->sortable()
                    ->toggleable(),
                TextColumn::make('store')
                    ->badge()
                    ->colors([
                        'info' => Subscription::STORE_APP_STORE,
                        'info' => Subscription::STORE_PLAY_STORE,
                        'gray' => Subscription::STORE_COMP,
                    ])
                    ->sortable(),
                TextColumn::make('environment')
                    ->badge()
                    ->colors([
                        'success' => 'production',
                        'warning' => 'sandbox',
                        'gray' => 'comp',
                    ])
                    ->sortable(),
                TextColumn::make('purchased_at')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->toggleable(),
                TextColumn::make('expires_at')
                    ->dateTime('Y-m-d H:i')
                    ->sortable(),
                TextColumn::make('cancelled_at')
                    ->dateTime('Y-m-d H:i')
                    ->sortable()
                    ->placeholder('—')
                    ->toggleable(isToggledHiddenByDefault: true),
            ])
            ->filters([
                SelectFilter::make('status')
                    ->options([
                        Subscription::STATUS_ACTIVE => 'Active',
                        Subscription::STATUS_IN_GRACE_PERIOD => 'In grace period',
                        Subscription::STATUS_IN_BILLING_RETRY => 'Billing retry',
                        Subscription::STATUS_EXPIRED => 'Expired',
                        Subscription::STATUS_CANCELLED => 'Cancelled',
                        Subscription::STATUS_PAUSED => 'Paused',
                    ]),
                SelectFilter::make('environment')
                    ->options([
                        'production' => 'Production',
                        'sandbox' => 'Sandbox',
                        'comp' => 'Comp',
                    ]),
                SelectFilter::make('store')
                    ->options([
                        Subscription::STORE_APP_STORE => 'App Store',
                        Subscription::STORE_PLAY_STORE => 'Play Store',
                        Subscription::STORE_STRIPE => 'Stripe',
                        Subscription::STORE_COMP => 'Comp',
                    ]),
                Filter::make('active_now')
                    ->label('Currently active (pro_active_until > now)')
                    ->query(fn (Builder $q) => $q->whereHas(
                        'user',
                        fn (Builder $u) => $u->where('pro_active_until', '>', now()),
                    )),
            ])
            ->recordActions([])
            ->toolbarActions([]);
    }
}
