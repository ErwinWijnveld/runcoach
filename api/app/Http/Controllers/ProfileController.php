<?php

namespace App\Http\Controllers;

use App\Enums\MembershipStatus;
use App\Http\Requests\UpdateProfileRequest;
use App\Http\Resources\OrganizationMembershipResource;
use App\Models\User;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ProfileController extends Controller
{
    public function show(Request $request): JsonResponse
    {
        return response()->json([
            'user' => $this->serialize($request->user()),
        ]);
    }

    public function update(UpdateProfileRequest $request): JsonResponse
    {
        $request->user()->update($request->validated());

        return response()->json([
            'user' => $this->serialize($request->user()->fresh()),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(User $user): array
    {
        $pending = $user->pendingPlanGeneration();

        $active = $user->activeMembership;
        if ($active) {
            $active->load(['organization', 'coach']);
        }

        $invites = $user->memberships()
            ->with('organization')
            ->where('status', MembershipStatus::Invited)
            ->get();

        $requests = $user->memberships()
            ->with('organization')
            ->where('status', MembershipStatus::Requested)
            ->get();

        return [
            ...$user->only([
                'id', 'name', 'email',
                'coach_style', 'has_completed_onboarding',
            ]),
            'pending_plan_generation' => $pending !== null
                ? OnboardingController::serialize($pending)
                : null,
            'current_membership' => $active
                ? OrganizationMembershipResource::make($active)
                : null,
            'pending_invites' => OrganizationMembershipResource::collection($invites),
            'pending_requests' => OrganizationMembershipResource::collection($requests),
        ];
    }

    public function destroy(Request $request): Response
    {
        /** @var User $user */
        $user = $request->user();

        DB::transaction(function () use ($user) {
            // Sanctum tokens: polymorphic, no FK cascade from users.
            $user->tokens()->delete();

            // Laravel AI SDK tables: `user_id` is a nullable bigint with no FK
            // constraint, so user deletion does not cascade. Delete explicitly.
            $conversationIds = DB::table('agent_conversations')
                ->where('user_id', $user->id)
                ->pluck('id');

            if ($conversationIds->isNotEmpty()) {
                DB::table('agent_conversation_messages')
                    ->whereIn('conversation_id', $conversationIds)
                    ->delete();

                DB::table('agent_conversations')
                    ->whereIn('id', $conversationIds)
                    ->delete();
            }

            $user->delete();
        });

        return response()->noContent();
    }
}
