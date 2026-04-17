<?php

namespace App\Filament\Resources\TokenUsages\Pages;

use App\Filament\Resources\TokenUsages\TokenUsageResource;
use App\Filament\Widgets\TokenUsageByContext;
use App\Filament\Widgets\TokenUsageOverview;
use App\Filament\Widgets\TopUsersByTokens;
use Filament\Resources\Pages\ListRecords;

class ListTokenUsages extends ListRecords
{
    protected static string $resource = TokenUsageResource::class;

    protected function getHeaderWidgets(): array
    {
        return [
            TokenUsageOverview::class,
            TokenUsageByContext::class,
            TopUsersByTokens::class,
        ];
    }

    protected function getHeaderActions(): array
    {
        return [];
    }
}
