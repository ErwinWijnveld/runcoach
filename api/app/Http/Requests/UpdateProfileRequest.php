<?php

namespace App\Http\Requests;

use App\Enums\CoachStyle;
use App\Enums\HeartRateZonesSource;
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
            // Set internally by prepareForValidation when zones are present —
            // never trust the client to set this directly. The validator
            // only accepts the 'manual' value to keep the surface tight.
            'heart_rate_zones_source' => ['sometimes', Rule::in([HeartRateZonesSource::Manual->value])],
            // Locale override. `null` clears the override and reverts to
            // SetLocale middleware auto-detection on subsequent requests.
            'locale' => ['sometimes', 'nullable', 'string', 'in:en,nl'],
        ];
    }

    /**
     * When the runner edits zones via the menu sheet, flip the source to
     * 'manual' so future scheduled re-derivations skip them. The explicit
     * "Recompute from runs" button writes through a different endpoint
     * that overrides this.
     */
    protected function prepareForValidation(): void
    {
        if ($this->has('heart_rate_zones')) {
            $this->merge([
                'heart_rate_zones_source' => HeartRateZonesSource::Manual->value,
            ]);
        }
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
