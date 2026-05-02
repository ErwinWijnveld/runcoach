<?php

namespace App\Filament\Coach\Resources\Clients\Pages;

use App\Enums\GoalStatus;
use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\ClientResource;
use App\Models\OrganizationMembership;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ViewRecord;

class ViewClient extends ViewRecord
{
    protected static string $resource = ClientResource::class;

    public function getTitle(): string
    {
        /** @var User $record */
        $record = $this->getRecord();

        return $record->name ?? $record->email ?? 'Client';
    }

    protected function getHeaderActions(): array
    {
        /** @var User $record */
        $record = $this->getRecord();
        /** @var User|null $authUser */
        $authUser = auth()->user();

        $activeGoal = $record->goals()
            ->where('status', GoalStatus::Active)
            ->latest('target_date')
            ->first();

        $clientMembership = $this->resolveClientMembership($record, $authUser);
        $canReassign = $authUser !== null
            && $clientMembership !== null
            && ($authUser->isSuperadmin() || $authUser->isOrgAdmin());

        return [
            Action::make('openSchedule')
                ->label('Schedule')
                ->icon('heroicon-o-calendar-days')
                ->color('primary')
                ->visible(fn () => $activeGoal !== null)
                ->url(fn () => route('filament.coach.pages.goal-schedule', ['goal' => $activeGoal?->id])),
            Action::make('reassignCoach')
                ->label('Reassign coach')
                ->icon('heroicon-o-academic-cap')
                ->color('gray')
                ->visible(fn () => $canReassign)
                ->schema([
                    Select::make('coach_user_id')
                        ->label('Coach')
                        ->placeholder('Unassigned')
                        ->options(fn () => OrganizationMembership::query()
                            ->where('role', OrganizationRole::Coach)
                            ->where('status', MembershipStatus::Active)
                            ->where('organization_id', $clientMembership?->organization_id)
                            ->with('user')
                            ->get()
                            ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                            ->all())
                        ->default($clientMembership?->coach_user_id),
                ])
                ->action(function (array $data) use ($clientMembership): void {
                    if ($clientMembership === null) {
                        return;
                    }

                    $clientMembership->update([
                        'coach_user_id' => $data['coach_user_id'] ?: null,
                    ]);

                    Notification::make()->title('Coach updated')->success()->send();
                }),
        ];
    }

    private function resolveClientMembership(User $record, ?User $authUser): ?OrganizationMembership
    {
        $query = $record->memberships()
            ->where('role', OrganizationRole::Client)
            ->where('status', MembershipStatus::Active);

        if ($authUser !== null && ! $authUser->isSuperadmin()) {
            $query->where('organization_id', $authUser->organizationId());
        }

        return $query->latest('id')->first();
    }
}
