<?php

namespace App\Http\Controllers\Api;

use App\Enums\OrganizationStatus;
use App\Http\Controllers\Controller;
use App\Http\Resources\OrganizationResource;
use App\Models\Organization;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OrganizationController extends Controller
{
    public function search(Request $request): JsonResponse
    {
        $request->validate([
            'q' => ['nullable', 'string', 'max:100'],
        ]);

        $query = Organization::query()->where('status', OrganizationStatus::Active);

        if ($search = $request->string('q')->toString()) {
            $query->where('name', 'like', "%{$search}%");
        }

        $organizations = $query->orderBy('name')->limit(25)->get();

        return response()->json([
            'data' => OrganizationResource::collection($organizations),
        ]);
    }
}
