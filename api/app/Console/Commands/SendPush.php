<?php

namespace App\Console\Commands;

use App\Models\User;
use App\Notifications\AdhocPush;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;

#[Signature('push:send {user : User id} {title : Notification title} {body : Notification body}')]
#[Description('Send a one-off APNs push to a specific user. Useful for ops/admin smoke-testing — does not deep-link on tap.')]
class SendPush extends Command
{
    public function handle(): int
    {
        $userId = (int) $this->argument('user');
        $user = User::find($userId);

        if ($user === null) {
            $this->error("No user with id {$userId}.");

            return self::FAILURE;
        }

        $tokenCount = $user->routeNotificationForApn();

        if (count($tokenCount) === 0) {
            $this->warn("User {$userId} has no registered iOS device tokens — nothing will deliver.");

            return self::FAILURE;
        }

        $user->notify(new AdhocPush(
            (string) $this->argument('title'),
            (string) $this->argument('body'),
        ));

        $this->info("Queued for user {$userId} (".count($tokenCount).' device(s)).');

        return self::SUCCESS;
    }
}
