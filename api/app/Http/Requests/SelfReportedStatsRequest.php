<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class SelfReportedStatsRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user() !== null;
    }

    /**
     * @return array<string, list<string>>
     */
    public function rules(): array
    {
        return [
            'weekly_km' => ['nullable', 'numeric', 'min:1', 'max:300'],
            'easy_pace_seconds_per_km' => ['nullable', 'integer', 'min:180', 'max:720'],
        ];
    }
}
