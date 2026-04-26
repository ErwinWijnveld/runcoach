<?php

namespace App\Filament\Coach\Pages;

use App\Models\Organization;
use App\Models\User;
use BackedEnum;
use Filament\Actions\Action;
use Filament\Forms\Components\Textarea;
use Filament\Forms\Components\TextInput;
use Filament\Forms\Components\Toggle;
use Filament\Notifications\Notification;
use Filament\Pages\Page;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;

/**
 * @property-read array $data
 */
class OrganizationSettings extends Page
{
    protected string $view = 'filament.coach.pages.organization-settings';

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedCog6Tooth;

    protected static ?string $navigationLabel = 'Organization';

    protected static ?int $navigationSort = 90;

    public ?array $data = [];

    public ?Organization $organization = null;

    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = auth()->user();

        return $user?->isOrgAdmin() === true || $user?->isSuperadmin() === true;
    }

    public function mount(): void
    {
        /** @var User $user */
        $user = auth()->user();
        $this->organization = $user->organization();

        if ($this->organization === null) {
            return;
        }

        $this->data = [
            'name' => $this->organization->name,
            'description' => $this->organization->description,
            'website' => $this->organization->website,
            'coaches_own_plans' => $this->organization->coaches_own_plans,
        ];
    }

    public function form(Schema $schema): Schema
    {
        return $schema
            ->components([
                TextInput::make('name')->required(),
                Textarea::make('description')->rows(3),
                TextInput::make('website')->url()->prefix('https://'),
                Toggle::make('coaches_own_plans')
                    ->label('Coaches own plans')
                    ->helperText('When on, the AI coach will not generate or edit training plans for this org\'s clients.'),
            ])
            ->statePath('data')
            ->model($this->organization);
    }

    protected function getHeaderActions(): array
    {
        return [
            Action::make('save')
                ->label('Save changes')
                ->color('primary')
                ->action('save'),
        ];
    }

    public function save(): void
    {
        if ($this->organization === null) {
            return;
        }

        $this->organization->update($this->data);

        Notification::make()
            ->title('Organization updated')
            ->success()
            ->send();
    }
}
