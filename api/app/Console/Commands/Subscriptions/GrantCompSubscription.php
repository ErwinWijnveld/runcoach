<?php

namespace App\Console\Commands\Subscriptions;

use App\Models\User;
use App\Services\Subscription\EntitlementSyncService;
use Carbon\Carbon;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('subscriptions:grant-comp {user : User id or email} {until : ISO8601 date or relative like "+10 years"} {--note= : Optional audit note}')]
#[Description('Grant a complimentary Pro entitlement to a user (reviewer accounts, support comps).')]
class GrantCompSubscription extends Command
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

        try {
            $until = Carbon::parse((string) $this->argument('until'));
        } catch (\Throwable $e) {
            $this->error("Invalid --until value: {$e->getMessage()}");

            return self::FAILURE;
        }

        if ($until->isPast()) {
            $this->error('until must be in the future');

            return self::FAILURE;
        }

        $sync->grantComp($user, $until, (string) $this->option('note') ?: null);

        $this->info(sprintf(
            'Granted comp to %s (id=%d) until %s',
            $user->email,
            $user->id,
            $until->toIso8601String(),
        ));

        return self::SUCCESS;
    }
}
