<?php

namespace App\Filament\Resources\Users\Tables;

use App\Models\User;
use App\Notifications\AdhocPush;
use App\Services\Subscription\EntitlementSyncService;
use Filament\Actions\Action;
use Filament\Actions\ActionGroup;
use Filament\Actions\BulkAction;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\Filter;
use Filament\Tables\Filters\TernaryFilter;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Collection;

class UsersTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                TextColumn::make('name')
                    ->searchable()
                    ->placeholder('—'),
                TextColumn::make('email')
                    ->searchable(),
                TextColumn::make('pro_status')
                    ->label('Pro')
                    ->badge()
                    ->getStateUsing(fn (User $record): string => $record->isPro() ? 'Pro' : 'Free')
                    ->color(fn (string $state): string => $state === 'Pro' ? 'success' : 'gray'),
                TextColumn::make('pro_active_until')
                    ->label('Pro until')
                    ->dateTime('Y-m-d H:i')
                    ->placeholder('—')
                    ->sortable(),
                TextColumn::make('pro_product_id')
                    ->label('Product')
                    ->placeholder('—')
                    ->toggleable(),
                IconColumn::make('has_completed_onboarding')
                    ->label('Onboarded')
                    ->boolean()
                    ->toggleable(),
                IconColumn::make('is_superadmin')
                    ->label('Admin')
                    ->boolean()
                    ->toggleable(isToggledHiddenByDefault: true),
                TextColumn::make('created_at')
                    ->label('Joined')
                    ->dateTime('Y-m-d')
                    ->sortable()
                    ->toggleable(),
            ])
            ->filters([
                Filter::make('pro_now')
                    ->label('Currently Pro')
                    ->query(fn (Builder $query): Builder => $query->where('pro_active_until', '>', now())),
                TernaryFilter::make('has_completed_onboarding')
                    ->label('Onboarding complete'),
            ])
            ->recordActions([
                ActionGroup::make([
                    Action::make('sendPush')
                        ->label('Send push notification')
                        ->icon('heroicon-o-paper-airplane')
                        ->color('info')
                        ->modalDescription('Sends a one-off APNs push — taps do not deep-link.')
                        ->schema(self::pushNotificationSchema())
                        ->action(function (User $record, array $data): void {
                            $deviceCount = count($record->routeNotificationForApn());

                            if ($deviceCount === 0) {
                                Notification::make()
                                    ->title("{$record->email} has no registered iOS devices — nothing sent")
                                    ->warning()
                                    ->send();

                                return;
                            }

                            $record->notify(new AdhocPush($data['title'], $data['body']));

                            Notification::make()
                                ->title("Push queued for {$record->email} ({$deviceCount} device(s))")
                                ->success()
                                ->send();
                        }),
                    Action::make('grantProMonth')
                        ->label('Grant Pro — 1 month')
                        ->icon('heroicon-o-star')
                        ->color('success')
                        ->requiresConfirmation()
                        ->action(function (User $record): void {
                            app(EntitlementSyncService::class)->grantComp(
                                $record,
                                now()->addMonth(),
                                'admin grant (1 month)',
                            );

                            Notification::make()
                                ->title("Granted Pro to {$record->email} for 1 month")
                                ->success()
                                ->send();
                        }),
                    Action::make('grantProYear')
                        ->label('Grant Pro — 1 year')
                        ->icon('heroicon-o-star')
                        ->color('success')
                        ->requiresConfirmation()
                        ->action(function (User $record): void {
                            app(EntitlementSyncService::class)->grantComp(
                                $record,
                                now()->addYear(),
                                'admin grant (1 year)',
                            );

                            Notification::make()
                                ->title("Granted Pro to {$record->email} for 1 year")
                                ->success()
                                ->send();
                        }),
                    Action::make('revokePro')
                        ->label('Revoke Pro')
                        ->icon('heroicon-o-x-circle')
                        ->color('danger')
                        ->requiresConfirmation()
                        ->visible(fn (User $record): bool => $record->isPro())
                        ->action(function (User $record): void {
                            app(EntitlementSyncService::class)->expire($record);

                            Notification::make()
                                ->title("Revoked Pro from {$record->email}")
                                ->success()
                                ->send();
                        }),
                ]),
            ])
            ->toolbarActions([
                BulkAction::make('sendPushBulk')
                    ->label('Send push notification')
                    ->icon('heroicon-o-paper-airplane')
                    ->color('info')
                    ->modalDescription('Sends the same one-off APNs push to every selected user — taps do not deep-link.')
                    ->schema(self::pushNotificationSchema())
                    ->deselectRecordsAfterCompletion()
                    ->action(function (Collection $records, array $data): void {
                        $queued = 0;
                        $skipped = 0;

                        foreach ($records as $user) {
                            if (count($user->routeNotificationForApn()) === 0) {
                                $skipped++;

                                continue;
                            }

                            $user->notify(new AdhocPush($data['title'], $data['body']));
                            $queued++;
                        }

                        $title = "Push queued for {$queued} user(s)"
                            .($skipped > 0 ? ", {$skipped} skipped (no iOS devices)" : '');

                        $notification = Notification::make()->title($title);
                        $queued > 0 ? $notification->success() : $notification->warning();
                        $notification->send();
                    }),
            ]);
    }

    /**
     * @return array<int, TextInput|Textarea>
     */
    private static function pushNotificationSchema(): array
    {
        return [
            TextInput::make('title')
                ->required()
                ->maxLength(120),
            Textarea::make('body')
                ->required()
                ->rows(3)
                ->maxLength(500),
        ];
    }
}
