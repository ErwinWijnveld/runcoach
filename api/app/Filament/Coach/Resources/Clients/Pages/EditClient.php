<?php

namespace App\Filament\Coach\Resources\Clients\Pages;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\ClientResource;
use App\Models\OrganizationMembership;
use App\Models\User;
use Filament\Actions\Action;
use Filament\Forms\Components\Select;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\EditRecord;
use Filament\Schemas\Schema;

class EditClient extends EditRecord
{
    protected static string $resource = ClientResource::class;

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                Select::make('coach_user_id')
                    ->label('Assigned coach')
                    ->placeholder('Unassigned')
                    ->options(function () {
                        /** @var User $user */
                        $user = auth()->user();

                        return OrganizationMembership::query()
                            ->where('role', OrganizationRole::Coach)
                            ->where('status', MembershipStatus::Active)
                            ->where('organization_id', $user->organizationId())
                            ->with('user')
                            ->get()
                            ->mapWithKeys(fn ($m) => [$m->user_id => $m->user?->name ?? $m->invite_email])
                            ->all();
                    }),
            ]);
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('remove')
                ->label('Remove from org')
                ->icon('heroicon-o-trash')
                ->color('danger')
                ->requiresConfirmation()
                ->action(function () {
                    $this->record->update([
                        'status' => MembershipStatus::Removed,
                        'removed_at' => now(),
                    ]);

                    Notification::make()->title('Member removed')->success()->send();

                    $this->redirect(ClientResource::getUrl('index'));
                }),
        ];
    }
}
