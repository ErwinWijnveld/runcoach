<?php

namespace App\Http\Requests;

use Illuminate\Contracts\Validation\Validator;
use Illuminate\Foundation\Http\FormRequest;

class GeneratePlanRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, string>
     */
    public function rules(): array
    {
        return [
            'goal_type' => 'required|in:race,pr,fitness',
            'goal_name' => 'nullable|string|max:100',
            'distance_meters' => 'nullable|integer|min:1000|max:200000',
            'target_date' => 'nullable|date|after:today',
            'goal_time_seconds' => 'nullable|integer|min:600|max:86400',
            'pr_current_seconds' => 'nullable|integer|min:600|max:86400',
            'days_per_week' => 'required|integer|min:1|max:7',
            'coach_style' => 'required|in:balanced,strict,flexible,motivational,analytical',
            'notes' => 'nullable|string|max:500',
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function (Validator $v): void {
            if ($this->input('goal_type') === 'race') {
                foreach (['distance_meters', 'target_date'] as $field) {
                    if (! $this->filled($field)) {
                        $v->errors()->add($field, 'Required when goal_type=race');
                    }
                }
            }

            if ($this->input('goal_type') === 'pr' && ! $this->filled('distance_meters')) {
                $v->errors()->add('distance_meters', 'Required when goal_type=pr');
            }

            if ($this->input('goal_type') === 'pr' && ! $this->filled('goal_time_seconds')) {
                $v->errors()->add('goal_time_seconds', 'Required when goal_type=pr');
            }
        });
    }
}
