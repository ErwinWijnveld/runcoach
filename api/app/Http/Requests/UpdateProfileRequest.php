<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Validator;

class UpdateProfileRequest extends FormRequest
{
    public function rules(): array
    {
        return [
            'name' => ['sometimes', 'string', 'max:255'],
            'coach_style' => ['sometimes', Rule::enum(CoachStyle::class)],
            'has_completed_onboarding' => ['sometimes', 'boolean'],
            'heart_rate_zones' => ['sometimes', 'array', 'size:5'],
            'heart_rate_zones.*.min' => ['required_with:heart_rate_zones', 'integer', 'min:0', 'max:250'],
            // Z5 max is open-ended by convention (-1). Earlier zones are
            // bounded; allow -1 too and let withValidator enforce the rest.
            'heart_rate_zones.*.max' => ['required_with:heart_rate_zones', 'integer', 'min:-1', 'max:250'],
        ];
    }

    public function withValidator(Validator $validator): void
    {
        $validator->after(function ($v) {
            $zones = $this->input('heart_rate_zones');
            if (! is_array($zones) || count($zones) !== 5) {
                return;
            }

            foreach ($zones as $i => $zone) {
                $min = (int) ($zone['min'] ?? 0);
                $max = (int) ($zone['max'] ?? 0);

                if ($i === 4) {
                    if ($max !== -1) {
                        $v->errors()->add('heart_rate_zones.4.max', 'Zone 5 must be open-ended (-1).');
                    }
                } elseif ($max <= $min) {
                    $v->errors()->add("heart_rate_zones.$i.max", 'Each zone max must be greater than its min.');
                }

                if ($i > 0) {
                    $prevMax = (int) ($zones[$i - 1]['max'] ?? 0);
                    if ($prevMax !== $min) {
                        $v->errors()->add("heart_rate_zones.$i.min", 'Zones must be contiguous.');
                    }
                }
            }
        });
    }
}
