<?php

namespace Tests\Feature\Validation;

use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Validator;
use Tests\TestCase;

class LocalizedValidationTest extends TestCase
{
    public function test_dutch_required_message_resolves_when_locale_is_nl(): void
    {
        App::setLocale('nl');

        $validator = Validator::make([], ['email' => 'required']);
        $message = $validator->errors()->first('email');

        $this->assertStringContainsString('verplicht', $message);
    }

    public function test_english_required_message_resolves_when_locale_is_en(): void
    {
        App::setLocale('en');

        $validator = Validator::make([], ['email' => 'required']);
        $message = $validator->errors()->first('email');

        $this->assertStringContainsString('required', $message);
    }
}
