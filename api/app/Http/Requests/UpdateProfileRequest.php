<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use App\Enums\RunnerLevel;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateProfileRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'level' => ['sometimes', Rule::enum(RunnerLevel::class)],
            'coach_style' => ['sometimes', Rule::enum(CoachStyle::class)],
            'weekly_km_capacity' => ['sometimes', 'numeric', 'min:0', 'max:300'],
        ];
    }
}
