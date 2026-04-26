<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class OrganizationMembershipResource extends JsonResource
{
    /**
     * @return array<string, mixed>
     */
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'organization' => OrganizationResource::make($this->whenLoaded('organization')),
            'role' => $this->role->value,
            'status' => $this->status->value,
            'coach' => $this->whenLoaded('coach', fn () => $this->coach ? [
                'id' => $this->coach->id,
                'name' => $this->coach->name,
                'email' => $this->coach->email,
            ] : null),
            'invite_email' => $this->invite_email,
            'invited_at' => $this->invited_at?->toIso8601String(),
            'requested_at' => $this->requested_at?->toIso8601String(),
            'joined_at' => $this->joined_at?->toIso8601String(),
        ];
    }
}
