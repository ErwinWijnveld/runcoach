<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'coach_style' => ['sometimes', Rule::enum(CoachStyle::class)],
            'has_completed_onboarding' => ['sometimes', 'boolean'],
        ];
    }
}
