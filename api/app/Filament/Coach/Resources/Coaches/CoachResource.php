<?php

namespace App\Filament\Coach\Resources\Coaches;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Filament\Coach\Resources\Coaches\Pages\ListCoaches;
use App\Filament\Coach\Resources\Coaches\Tables\CoachesTable;
use App\Models\OrganizationMembership;
use App\Models\User;
use BackedEnum;
use Filament\Resources\Resource;
use Filament\Support\Icons\Heroicon;
use Filament\Tables\Table;
use Illuminate\Database\Eloquent\Builder;

class CoachResource extends Resource
{
    protected static ?string $model = OrganizationMembership::class;

    protected static string|BackedEnum|null $navigationIcon = Heroicon::OutlinedAcademicCap;

    protected static ?string $navigationLabel = 'Coaches';

    protected static ?string $modelLabel = 'Coach';

    protected static ?string $pluralModelLabel = 'Coaches';

    protected static ?int $navigationSort = 20;

    public static function canAccess(): bool
    {
        /** @var User|null $user */
        $user = auth()->user();

        return $user?->isOrgAdmin() === true || $user?->isSuperadmin() === true;
    }

    public static function getEloquentQuery(): Builder
    {
        /** @var User $user */
        $user = auth()->user();

        $query = OrganizationMembership::query()
            ->where('role', OrganizationRole::Coach)
            ->whereIn('status', [MembershipStatus::Active, MembershipStatus::Invited]);

        if (! $user->isSuperadmin()) {
            $query->where('organization_id', $user->organizationId());
        }

        return $query;
    }

    public static function table(Table $table): Table
    {
        return CoachesTable::configure($table);
    }

    public static function getPages(): array
    {
        return [
            'index' => ListCoaches::route('/'),
        ];
    }

    public static function canCreate(): bool
    {
        return false; // creation happens via header action (invite flow)
    }
}
