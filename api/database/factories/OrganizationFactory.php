<?php

namespace Database\Factories;

use App\Enums\OrganizationStatus;
use App\Models\Organization;
use Illuminate\Database\Eloquent\Factories\Factory;
use Illuminate\Support\Str;

/**
 * @extends Factory<Organization>
 */
class OrganizationFactory extends Factory
{
    public function definition(): array
    {
        $name = fake()->unique()->company().' Running Club';

        return [
            'name' => $name,
            'slug' => Str::slug($name).'-'.Str::lower(Str::random(4)),
            'description' => fake()->sentence(),
            'website' => fake()->boolean(50) ? fake()->url() : null,
            'logo_path' => null,
            'status' => OrganizationStatus::Active,
            'coaches_own_plans' => true,
        ];
    }

    public function suspended(): static
    {
        return $this->state(fn () => ['status' => OrganizationStatus::Suspended]);
    }
}
