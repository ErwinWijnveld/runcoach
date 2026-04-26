<?php

namespace App\Http\Controllers;

use App\Enums\MembershipStatus;
use App\Models\OrganizationMembership;
use Illuminate\Contracts\View\View;

class InviteController extends Controller
{
    /**
     * Public landing page for an emailed invite. Renders a simple HTML page
     * with a deep link to the mobile app + a fallback CTA.
     */
    public function landing(string $token): View
    {
        $membership = OrganizationMembership::where('invite_token', $token)
            ->where('status', MembershipStatus::Invited)
            ->with('organization')
            ->first();

        return view('invites.landing', [
            'membership' => $membership,
            'token' => $token,
        ]);
    }
}
