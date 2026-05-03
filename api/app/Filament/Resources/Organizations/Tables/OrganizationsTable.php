<?php

namespace App\Filament\Resources\Organizations\Tables;

use App\Enums\OrganizationStatus;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Tables\Columns\IconColumn;
use Filament\Tables\Columns\ImageColumn;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class OrganizationsTable
{
    public static function configure(Table $table): Table
    {
        return $table
            ->defaultSort('created_at', 'desc')
            ->columns([
                ImageColumn::make('logo_path')
                    ->label('Logo')
                    ->disk('public')
                    ->circular()
                    ->size(40),
                TextColumn::make('name')
                    ->searchable()
                    ->sortable()
                    ->weight('bold'),
                TextColumn::make('slug')
                    ->color('gray')
                    ->toggleable(),
                TextColumn::make('admins_count')
                    ->label('Admins')
                    ->counts('admins')
                    ->badge()
                    ->color('warning'),
                TextColumn::make('coaches_count')
                    ->label('Coaches')
                    ->counts('coaches')
                    ->badge()
                    ->color('info'),
                TextColumn::make('clients_count')
                    ->label('Clients')
                    ->counts('clients')
                    ->badge()
                    ->color('success'),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (OrganizationStatus $state) => match ($state) {
                        OrganizationStatus::Active => 'success',
                        OrganizationStatus::Suspended => 'danger',
                    }),
                IconColumn::make('coaches_own_plans')
                    ->label('Coach-managed')
                    ->boolean()
                    ->toggleable(),
                TextColumn::make('created_at')
                    ->label('Created')
                    ->dateTime('Y-m-d')
                    ->sortable()
                    ->toggleable(),
            ])
            ->filters([
                SelectFilter::make('status')->options(OrganizationStatus::class),
            ])
            ->recordActions([
                EditAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
