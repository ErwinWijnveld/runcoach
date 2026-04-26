<x-filament-panels::page>
    @if ($organization === null)
        <x-filament::section>
            <p class="text-gray-600 dark:text-gray-400">
                You're not a member of any organization yet.
            </p>
        </x-filament::section>
    @else
        <form wire:submit="save">
            {{ $this->form }}
        </form>
    @endif
</x-filament-panels::page>
