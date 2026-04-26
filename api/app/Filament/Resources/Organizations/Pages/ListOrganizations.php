<?php

namespace App\Filament\Resources\Organizations\Pages;

use App\Enums\OrganizationRole;
use App\Enums\OrganizationStatus;
use App\Filament\Resources\Organizations\OrganizationResource;
use App\Models\Organization;
use App\Services\OrganizationInviteService;
use Filament\Actions\Action;
use Filament\Actions\CreateAction;
use Filament\Forms\Components\TextInput;
use Filament\Notifications\Notification;
use Filament\Resources\Pages\ListRecords;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use RuntimeException;

class ListOrganizations extends ListRecords
{
    protected static string $resource = OrganizationResource::class;

    protected function getHeaderActions(): array
    {
        return [
            Action::make('createWithAdmin')
                ->label('New org with admin')
                ->icon('heroicon-o-plus')
                ->color('primary')
                ->schema([
                    TextInput::make('name')
                        ->label('Organization name')
                        ->required(),
                    TextInput::make('slug')
                        ->required()
                        ->unique('organizations', 'slug')
                        ->helperText('Lowercase letters, numbers, hyphens.'),
                    TextInput::make('admin_email')
                        ->label('Initial admin email')
                        ->email()
                        ->required()
                        ->helperText('They will receive an invitation to set up their account.'),
                ])
                ->fillForm(fn () => ['slug' => ''])
                ->action(function (array $data): void {
                    DB::transaction(function () use ($data) {
                        $org = Organization::create([
                            'name' => $data['name'],
                            'slug' => $data['slug'] ?: Str::slug($data['name']),
                            'status' => OrganizationStatus::Active,
                            'coaches_own_plans' => true,
                        ]);

                        try {
                            app(OrganizationInviteService::class)->invite(
                                $org,
                                $data['admin_email'],
                                OrganizationRole::OrgAdmin,
                                auth()->user(),
                            );
                        } catch (RuntimeException $e) {
                            Notification::make()
                                ->title('Org created, but invite failed')
                                ->body($e->getMessage())
                                ->warning()
                                ->send();

                            return;
                        }

                        Notification::make()
                            ->title("Org created and invite sent to {$data['admin_email']}")
                            ->success()
                            ->send();
                    });
                }),
            CreateAction::make()->label('New org (no admin)'),
        ];
    }
}
