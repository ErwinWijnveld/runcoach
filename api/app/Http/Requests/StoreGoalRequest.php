<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreGoalRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'type' => 'required|in:race,general_fitness,pr_attempt',
            'name' => 'required|string|max:255',
            'distance' => 'nullable|in:5k,10k,half_marathon,marathon,custom',
            'custom_distance_meters' => 'nullable|integer|min:100',
            'goal_time_seconds' => 'nullable|integer|min:60',
            'target_date' => 'nullable|date',
            'status' => 'in:planning,completed,cancelled',
        ];
    }
}
