<?php

namespace App\Filament\Coach\Resources\Clients;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Clients\Pages\ListClients;
use App\Filament\Coach\Resources\Clients\Pages\ViewClient;
use App\Filament\Coach\Resources\Clients\RelationManagers\GoalsRelationManager;
use App\Filament\Coach\Resources\Clients\Schemas\ClientInfolist;
use App\Filament\Coach\Resources\Clients\Tables\ClientsTable;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Schemas\Schema;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class ClientResource extends Resource
{
    protected static ?string $model = User::class;

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

        $query = User::query()
            ->with(['activeGoal', 'activeMembership.coach']);

        if ($user->isSuperadmin()) {
            return $query;
        }

        $orgId = $user->organizationId();

        return $query->whereHas('memberships', fn (Builder $q) => $q
            ->where('organization_id', $orgId)
            ->where('role', OrganizationRole::Client)
            ->whereIn('status', [MembershipStatus::Active, MembershipStatus::Invited]));
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
        ];
    }

    public static function canCreate(): bool
    {
        return false;
    }
}
