<?php

namespace App\Filament\Coach\Resources\Clients\RelationManagers;

use App\Enums\GoalDistance;
use App\Enums\GoalStatus;
use App\Enums\GoalType;
use App\Models\OrganizationMembership;
use Filament\Actions\Action;
use Filament\Actions\BulkActionGroup;
use Filament\Actions\CreateAction;
use Filament\Actions\DeleteAction;
use Filament\Actions\DeleteBulkAction;
use Filament\Actions\EditAction;
use Filament\Forms\Components\DatePicker;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Resources\RelationManagers\RelationManager;
use Filament\Schemas\Schema;
use Filament\Tables\Columns\TextColumn;
use Filament\Tables\Filters\SelectFilter;
use Filament\Tables\Table;

class GoalsRelationManager extends RelationManager
{
    protected static string $relationship = 'goals';

    protected static ?string $title = 'Goals';

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('type')
                    ->options(GoalType::class)
                    ->default(GoalType::Race->value)
                    ->required(),
                TextInput::make('name')
                    ->required()
                    ->maxLength(255),
                Select::make('distance')
                    ->options(GoalDistance::class)
                    ->reactive(),
                TextInput::make('custom_distance_meters')
                    ->numeric()
                    ->visible(fn (callable $get) => $get('distance') === GoalDistance::Custom->value)
                    ->helperText('Required when distance is "custom".'),
                TextInput::make('goal_time_seconds')
                    ->numeric()
                    ->label('Goal time (seconds)')
                    ->helperText('Optional target time in seconds.'),
                DatePicker::make('target_date'),
                Select::make('status')
                    ->options(GoalStatus::class)
                    ->default(GoalStatus::Planning->value)
                    ->required(),
            ]);
    }

    public function table(Table $table): Table
    {
        return $table
            ->recordTitleAttribute('name')
            ->defaultSort('target_date', 'desc')
            ->columns([
                TextColumn::make('name')
                    ->searchable()
                    ->weight('bold'),
                TextColumn::make('type')
                    ->badge(),
                TextColumn::make('distance')
                    ->badge()
                    ->placeholder('—'),
                TextColumn::make('target_date')
                    ->date('Y-m-d')
                    ->sortable()
                    ->placeholder('—'),
                TextColumn::make('status')
                    ->badge()
                    ->color(fn (GoalStatus $state) => match ($state) {
                        GoalStatus::Active => 'success',
                        GoalStatus::Completed => 'gray',
                        GoalStatus::Cancelled => 'danger',
                        default => 'warning',
                    }),
                TextColumn::make('trainingWeeks_count')
                    ->label('Weeks')
                    ->counts('trainingWeeks')
                    ->badge()
                    ->color('info'),
            ])
            ->filters([
                SelectFilter::make('status')->options(GoalStatus::class),
            ])
            ->headerActions([
                CreateAction::make()
                    ->mutateFormDataUsing(function (array $data): array {
                        /** @var OrganizationMembership $owner */
                        $owner = $this->getOwnerRecord();
                        $data['user_id'] = $owner->user_id;

                        return $data;
                    }),
            ])
            ->recordActions([
                Action::make('schedule')
                    ->label('Schedule')
                    ->icon('heroicon-o-calendar-days')
                    ->color('info')
                    ->url(fn ($record) => route('filament.coach.pages.goal-schedule', ['goal' => $record->id])),
                EditAction::make(),
                DeleteAction::make(),
            ])
            ->toolbarActions([
                BulkActionGroup::make([
                    DeleteBulkAction::make(),
                ]),
            ]);
    }
}
