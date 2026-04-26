<?php

namespace App\Filament\Coach\Resources\Clients\Pages;

use App\Enums\GoalStatus;
use App\Filament\Coach\Resources\Clients\ClientResource;
use Filament\Actions\Action;
use Filament\Actions\EditAction;
use Filament\Resources\Pages\ViewRecord;

class ViewClient extends ViewRecord
{
    protected static string $resource = ClientResource::class;

    public function getTitle(): string
    {
        $record = $this->getRecord();

        return $record->user?->name ?? $record->invite_email ?? 'Client';
    }

    protected function getHeaderActions(): array
    {
        $record = $this->getRecord();
        $activeGoal = $record->user?->goals()
            ->where('status', GoalStatus::Active)
            ->latest('target_date')
            ->first();

        return [
            Action::make('openSchedule')
                ->label('View schedule')
                ->icon('heroicon-o-calendar-days')
                ->color('primary')
                ->visible(fn () => $activeGoal !== null)
                ->url(fn () => route('filament.coach.pages.goal-schedule', ['goal' => $activeGoal?->id])),
            EditAction::make()->label('Reassign coach'),
        ];
    }
}
