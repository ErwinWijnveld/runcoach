<?php

namespace App\Http\Controllers\Api;

use App\Enums\MembershipStatus;
use App\Enums\OrganizationRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\OrganizationMembershipResource;
use App\Models\OrganizationMembership;
use App\Models\User;
use App\Services\OrganizationInviteService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;
use RuntimeException;

class MembershipController extends Controller
{
    public function __construct(private readonly OrganizationInviteService $invites) {}

    public function index(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $memberships = $user->memberships()
            ->with(['organization', 'coach'])
            ->whereIn('status', [
                MembershipStatus::Active,
                MembershipStatus::Invited,
                MembershipStatus::Requested,
            ])
            ->orderByDesc('joined_at')
            ->orderByDesc('id')
            ->get();

        return response()->json([
            'data' => OrganizationMembershipResource::collection($memberships),
        ]);
    }

    public function acceptByToken(Request $request, string $token): JsonResponse
    {
        $membership = OrganizationMembership::where('invite_token', $token)
            ->where('status', MembershipStatus::Invited)
            ->firstOrFail();

        try {
            $membership = $this->invites->accept($membership, $request->user());
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $membership->load(['organization', 'coach']);

        return response()->json([
            'membership' => OrganizationMembershipResource::make($membership),
        ]);
    }

    public function accept(Request $request, OrganizationMembership $membership): JsonResponse
    {
        $this->ensureOwnedByUser($request->user(), $membership);

        try {
            $membership = $this->invites->accept($membership, $request->user());
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        $membership->load(['organization', 'coach']);

        return response()->json([
            'membership' => OrganizationMembershipResource::make($membership),
        ]);
    }

    public function reject(Request $request, OrganizationMembership $membership): JsonResponse
    {
        $this->ensureOwnedByUser($request->user(), $membership);

        try {
            $this->invites->reject($membership);
        } catch (RuntimeException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json(['ok' => true]);
    }

    public function requestJoin(Request $request): JsonResponse
    {
        $data = $request->validate([
            'organization_id' => ['required', Rule::exists('organizations', 'id')],
        ]);

        /** @var User $user */
        $user = $request->user();

        if ($user->memberships()->where('status', MembershipStatus::Active)->exists()) {
            return response()->json([
                'message' => 'Leave your current organization before requesting to join another.',
            ], 422);
        }

        $duplicate = $user->memberships()
            ->where('organization_id', $data['organization_id'])
            ->whereIn('status', [MembershipStatus::Requested, MembershipStatus::Invited])
            ->exists();

        if ($duplicate) {
            return response()->json([
                'message' => 'You already have a pending request or invite for this organization.',
            ], 422);
        }

        $membership = OrganizationMembership::create([
            'organization_id' => $data['organization_id'],
            'user_id' => $user->id,
            'role' => OrganizationRole::Client,
            'status' => MembershipStatus::Requested,
            'requested_at' => now(),
        ]);

        $membership->load(['organization']);

        return response()->json([
            'membership' => OrganizationMembershipResource::make($membership),
        ], 201);
    }

    public function cancelRequest(Request $request, OrganizationMembership $membership): JsonResponse
    {
        $this->ensureOwnedByUser($request->user(), $membership);

        if (! $membership->isRequested()) {
            return response()->json(['message' => 'Request is not pending.'], 422);
        }

        $membership->update([
            'status' => MembershipStatus::Removed,
            'removed_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }

    public function leave(Request $request): JsonResponse
    {
        /** @var User $user */
        $user = $request->user();

        $active = $user->activeMembership;
        if ($active === null) {
            return response()->json(['message' => 'You are not a member of any organization.'], 422);
        }

        $active->update([
            'status' => MembershipStatus::Removed,
            'removed_at' => now(),
        ]);

        return response()->json(['ok' => true]);
    }

    private function ensureOwnedByUser(User $user, OrganizationMembership $membership): void
    {
        if ($membership->user_id !== null && $membership->user_id !== $user->id) {
            abort(403, 'This invite belongs to another user.');
        }
    }
}
