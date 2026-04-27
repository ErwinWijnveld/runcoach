<?php

namespace App\Console\Commands;

use App\Models\User;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('users:list')]
#[Description('List all users with their id, email, and registered iOS device count.')]
class ListUsers extends Command
{
    public function handle(): int
    {
        $rows = User::query()
            ->withCount(['deviceTokens as ios_devices_count' => fn ($q) => $q->where('platform', 'ios')])
            ->orderBy('id')
            ->get(['id', 'email'])
            ->map(fn (User $u) => [$u->id, $u->email, $u->ios_devices_count])
            ->all();

        $this->table(['ID', 'Email', 'iOS devices'], $rows);
        $this->info(count($rows).' user(s)');

        return self::SUCCESS;
    }
}
