<?php

namespace App\Console\Commands\Subscriptions;

use App\Models\User;
use App\Services\Subscription\EntitlementSyncService;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('subscriptions:revoke {user : User id or email}')]
#[Description('Revoke a user\'s Pro entitlement immediately (sets pro_active_until to null, marks subscription expired).')]
class RevokeSubscription extends Command
{
    public function handle(EntitlementSyncService $sync): int
    {
        $needle = (string) $this->argument('user');
        $user = filter_var($needle, FILTER_VALIDATE_EMAIL)
            ? User::where('email', $needle)->first()
            : User::find((int) $needle);

        if ($user === null) {
            $this->error("User not found: {$needle}");

            return self::FAILURE;
        }

        if (! $user->isPro() && $user->subscription === null) {
            $this->warn("User {$user->email} has no active entitlement; nothing to do.");

            return self::SUCCESS;
        }

        $sync->expire($user);

        $this->info("Revoked Pro for {$user->email} (id={$user->id})");

        return self::SUCCESS;
    }
}
