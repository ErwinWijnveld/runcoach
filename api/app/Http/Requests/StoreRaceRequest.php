<?php

namespace App\Http\Requests;

use App\Enums\RaceDistance;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreRaceRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['required', 'string', 'max:255'],
            'distance' => ['required', Rule::enum(RaceDistance::class)],
            'custom_distance_meters' => ['nullable', 'integer', 'min:100', 'required_if:distance,custom'],
            'goal_time_seconds' => ['nullable', 'integer', 'min:300'],
            'race_date' => ['required', 'date', 'after:today'],
        ];
    }
}
