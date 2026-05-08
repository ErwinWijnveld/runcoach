<?php

namespace App\Support;

use App\Enums\HeartRateZonesSource;

/**
 * Outcome of HeartRateZoneDeriver::derive(). The five-zone array always
 * has the canonical Z1..Z5 shape (each `{min, max}`, Z5's max = -1 to
 * signal open-ended). When source = Default the zones are the static
 * fallback table — caller should typically NOT persist these.
 *
 * @phpstan-import-type Zone from HeartRateZones
 */
final readonly class DerivationResult
{
    /**
     * @param  list<array{min:int, max:int}>  $zones
     */
    public function __construct(
        public array $zones,
        public HeartRateZonesSource $source,
        public ?int $maxHeartRate,
        public int $sampleCount,
        public ?int $age,
        public ?int $restingHeartRate,
    ) {}

    /**
     * Wire shape used by the API endpoint and tests.
     *
     * @return array{zones: list<array{min:int, max:int}>, source: string, max_hr: int|null, sample_count: int, age: int|null, resting_heart_rate: int|null}
     */
    public function toArray(): array
    {
        return [
            'zones' => $this->zones,
            'source' => $this->source->value,
            'max_hr' => $this->maxHeartRate,
            'sample_count' => $this->sampleCount,
            'age' => $this->age,
            'resting_heart_rate' => $this->restingHeartRate,
        ];
    }
}
