<?php

namespace App\Filament\Coach\Resources\Clients;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\Pages\EditClient;
use App\Filament\Coach\Resources\Clients\Pages\ListClients;
use App\Filament\Coach\Resources\Clients\Pages\ViewClient;
use App\Filament\Coach\Resources\Clients\RelationManagers\GoalsRelationManager;
use App\Filament\Coach\Resources\Clients\Schemas\ClientInfolist;
use App\Filament\Coach\Resources\Clients\Tables\ClientsTable;
use App\Models\OrganizationMembership;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ClientResource extends Resource
{
    protected static ?string $model = OrganizationMembership::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedUsers;

    protected static ?string $navigationLabel = 'Clients';

    protected static ?string $modelLabel = 'Client';

    protected static ?string $pluralModelLabel = 'Clients';

    protected static ?int $navigationSort = 10;

    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = auth()->user();

        return $user?->isOrgAdmin() === true || $user?->isCoach() === true || $user?->isSuperadmin() === true;
    }

    public static function getEloquentQuery(): Builder
    {
        /** @var User $user */
        $user = auth()->user();

        $query = OrganizationMembership::query()
            ->with(['user.activeGoal', 'coach'])
            ->where('role', OrganizationRole::Client)
            ->whereIn('status', [MembershipStatus::Active, MembershipStatus::Invited]);

        if (! $user->isSuperadmin()) {
            $query->where('organization_id', $user->organizationId());
        }

        return $query;
    }

    public static function table(Table $table): Table
    {
        return ClientsTable::configure($table);
    }

    public static function infolist(Schema $schema): Schema
    {
        return ClientInfolist::configure($schema);
    }

    public static function getRelations(): array
    {
        return [
            GoalsRelationManager::class,
        ];
    }

    public static function getPages(): array
    {
        return [
            'index' => ListClients::route('/'),
            'view' => ViewClient::route('/{record}'),
            'edit' => EditClient::route('/{record}/edit'),
        ];
    }

    public static function canCreate(): bool
    {
        return false; // creation via invite flow on the list page
    }
}
