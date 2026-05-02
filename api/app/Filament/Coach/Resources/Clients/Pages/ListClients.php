<?php

namespace App\Filament\Coach\Resources\Clients\Pages;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\ClientResource;
use App\Models\Organization;
use App\Models\OrganizationMembership;
use App\Models\User;
use App\Services\OrganizationInviteService;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use RuntimeException;

class ListClients extends ListRecords
{
    protected static string $resource = ClientResource::class;

    protected function getHeaderActions(): array
    {
        /** @var User|null $authUser */
        $authUser = auth()->user();

        // Invite is org-scoped — superadmins without an org context don't see it.
        if ($authUser === null || $authUser->organizationId() === null) {
            return [];
        }

        return [
            Action::make('inviteClient')
                ->label('Invite client')
                ->icon('heroicon-o-plus')
                ->color('primary')
                ->schema([
                    TextInput::make('email')
                        ->label('Client email')
                        ->email()
                        ->required(),
                    Select::make('coach_user_id')
                        ->label('Assigned coach')
                        ->placeholder('Unassigned')
                        ->options(fn () => OrganizationMembership::query()
                            ->where('role', OrganizationRole::Coach)
                            ->where('status', MembershipStatus::Active)
                            ->where('organization_id', $authUser->organizationId())
                            ->with('user')
                            ->get()
                            ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                            ->all()),
                ])
                ->action(function (array $data) use ($authUser): void {
                    $org = Organization::find($authUser->organizationId());

                    if (! $org) {
                        Notification::make()->title('No organization context')->danger()->send();

                        return;
                    }

                    $coach = ! empty($data['coach_user_id']) ? User::find($data['coach_user_id']) : null;

                    try {
                        app(OrganizationInviteService::class)->invite(
                            $org,
                            $data['email'],
                            OrganizationRole::Client,
                            $authUser,
                            $coach,
                        );

                        Notification::make()
                            ->title("Invite sent to {$data['email']}")
                            ->success()
                            ->send();
                    } catch (RuntimeException $e) {
                        Notification::make()
                            ->title('Invite failed')
                            ->body($e->getMessage())
                            ->danger()
                            ->send();
                    }
                }),
        ];
    }
}
