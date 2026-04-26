<?php

namespace App\Filament\Coach\Resources\Coaches\Pages;

use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Coaches\CoachResource;
use App\Models\Organization;
use App\Models\User;
use App\Services\OrganizationInviteService;
use Filament\Actions\Action;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use RuntimeException;

class ListCoaches extends ListRecords
{
    protected static string $resource = CoachResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('inviteCoach')
                ->label('Invite coach')
                ->icon('heroicon-o-plus')
                ->color('primary')
                ->schema([
                    TextInput::make('email')
                        ->label('Coach email')
                        ->email()
                        ->required(),
                    TextInput::make('name')
                        ->label('Display name (optional)')
                        ->helperText('Used in the invitation email.'),
                ])
                ->action(function (array $data): void {
                    /** @var User $user */
                    $user = auth()->user();
                    $org = Organization::find($user->organizationId());

                    if (! $org) {
                        Notification::make()->title('No organization context')->danger()->send();

                        return;
                    }

                    try {
                        app(OrganizationInviteService::class)->invite(
                            $org,
                            $data['email'],
                            OrganizationRole::Coach,
                            $user,
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
