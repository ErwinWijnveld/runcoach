<?php

namespace App\Notifications;

use App\Models\OrganizationMembership;
use Illuminate\Bus\Queueable;
use Illuminate\Notifications\Messages\MailMessage;
use Illuminate\Notifications\Notification;

class OrganizationInvitation extends Notification
{
    use Queueable;

    public function __construct(public OrganizationMembership $membership) {}

    /**
     * @return array<int, string>
     */
    public function via(object $notifiable): array
    {
        return ['mail'];
    }

    public function toMail(object $notifiable): MailMessage
    {
        $organization = $this->membership->organization;
        $roleLabel = $this->membership->role->label();
        $url = url('/invites/'.$this->membership->invite_token);

        return (new MailMessage)
            ->subject("You're invited to join {$organization->name} on RunCoach")
            ->greeting('Hi there!')
            ->line("{$organization->name} has invited you to join as a {$roleLabel}.")
            ->action('Accept invitation', $url)
            ->line('This invitation expires in 14 days.')
            ->line('If you weren\'t expecting this, you can safely ignore this email.');
    }

    /**
     * @return array<string, mixed>
     */
    public function toArray(object $notifiable): array
    {
        return [
            'membership_id' => $this->membership->id,
            'organization_id' => $this->membership->organization_id,
            'role' => $this->membership->role->value,
        ];
    }
}
