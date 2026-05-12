# i18n Foundation Implementation Plan (Phase 1 + 2)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lay the i18n plumbing in Flutter and Laravel so the app is locale-aware end-to-end, with `users.locale` persisted, `Accept-Language` flowing both directions, and all server-side templated user-facing strings going through `__()`. No string extraction yet, no agent localization yet — the app continues to ship in English only with no user-visible change.

**Architecture:** Flutter uses the official `flutter_localizations` (SDK) + `intl` + ARB + `flutter gen-l10n` workflow. Laravel uses built-in localization (`lang/{en,nl}/*.php`) driven by a custom `SetLocale` middleware that resolves locale as `users.locale → Accept-Language → fallback`. The User model implements `HasLocalePreference` so queue-dispatched notifications auto-respect the runner's stored locale without any per-class `withLocale()` glue. Spec: `docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md`.

**Tech Stack:**
- Flutter: `flutter_localizations` (SDK), `intl ^0.20.2` (already a dep), `shared_preferences` (already a dep), Riverpod with codegen
- Laravel 13: built-in `__()` / `App::setLocale()` / `Carbon::setLocale()`, `Illuminate\Contracts\Translation\HasLocalePreference`
- Tests: `php artisan test --compact` (LazilyRefreshDatabase per `api/CLAUDE.md`), `flutter test`

**Scope (what is and isn't in this plan):**
- ✅ Locale resolution end-to-end (device → `Accept-Language` header → `App::setLocale()` → `__()`)
- ✅ `users.locale` column + storage + `PUT /profile` write
- ✅ Notifications routed through `__()` so queue workers respect `$user->locale`
- ✅ `TrainingType::label()` and other enum labels go through `__()`
- ✅ Flutter ARB seed file (handful of test keys), `AppLocalizations` wired into `CupertinoApp`
- ✅ `localeProvider` (Riverpod) with auto-detect + persist
- ✅ `Accept-Language` header on every Dio request
- ❌ Migrating 700 hardcoded `Text('…')` calls (Phase 3 — separate plan)
- ❌ Settings → Language picker UI (Phase 3 — needs extracted strings)
- ❌ Translating agent system prompts / appending language directive (Phase 4 — separate plan)
- ❌ Dutch translations for the bulk of UI strings (Phase 3)

After this plan ships, the app continues to look 100% English to the user; flipping `users.locale` to `'nl'` in the database makes the few migrated touchpoints (validation errors, 4 push notifications, `TrainingType` labels) come back in Dutch, with everything else still English. That's the intended foundation state.

---

## File Structure

### Backend (Laravel, Phase 2)

**Create:**
- `api/database/migrations/2026_05_12_HHMMSS_add_locale_to_users.php` — adds `locale VARCHAR(8) NULL` column
- `api/app/Http/Middleware/SetLocale.php` — resolves locale per request
- `api/lang/en/validation.php` — Laravel's published default English validation messages
- `api/lang/nl/validation.php` — Dutch translations
- `api/lang/en/notifications.php` — push-notification copy keys
- `api/lang/nl/notifications.php` — Dutch
- `api/lang/en/enums.php` — `TrainingType` labels (and any other enums we touch)
- `api/lang/nl/enums.php` — Dutch
- `api/tests/Feature/Middleware/SetLocaleTest.php`
- `api/tests/Feature/Notifications/PlanGenerationCompletedLocalizationTest.php` (one representative test; the others mirror it)
- `api/tests/Feature/Enums/TrainingTypeLabelTest.php`
- `api/tests/Feature/Auth/AppleSignInBackfillsLocaleTest.php`
- `api/tests/Feature/Profile/UpdateLocaleTest.php`

**Modify:**
- `api/app/Models/User.php` — add `locale` to `$fillable`, implement `HasLocalePreference::preferredLocale()`
- `api/bootstrap/app.php` — register `SetLocale` middleware on the `api` route group
- `api/app/Notifications/PlanGenerationCompleted.php` — route title/body through `__()`
- `api/app/Notifications/PlanGenerationFailed.php` — same
- `api/app/Notifications/TrainingDayReminder.php` — same
- `api/app/Notifications/BirthdayZoneCheckReminder.php` — same
- `api/app/Enums/TrainingType.php` — `label()` returns `__('enums.training_type.{value}')`
- `api/app/Http/Controllers/AuthController.php` — backfill `locale` from `Accept-Language` on first Apple sign-in
- `api/app/Http/Controllers/ProfileController.php` — accept `locale` field in `update()`

### Frontend (Flutter, Phase 1)

**Create:**
- `app/l10n.yaml` — gen-l10n config
- `app/lib/l10n/app_en.arb` — template ARB (seed keys only; bulk extraction is Phase 3)
- `app/lib/l10n/app_nl.arb` — Dutch ARB (same seed keys)
- `app/lib/l10n/app_localizations.dart` — **generated** by `flutter gen-l10n`; committed to git per `synthetic-package: false`. Don't hand-edit.
- `app/lib/core/i18n/build_context_l10n.dart` — `context.l10n` extension
- `app/lib/core/i18n/app_localizations_provider.dart` — Riverpod provider exposing `AppLocalizations` for non-widget contexts
- `app/lib/core/i18n/locale_provider.dart` — Riverpod notifier for current `Locale` (auto-detect + override)
- `app/lib/core/i18n/current_locale.dart` — top-level mutable `currentAppLocaleTag` (BCP-47 string) used by the Dio interceptor; mirrors the pattern of `appDateLocale` in `core/utils/date_formatter.dart`
- `app/lib/core/api/locale_interceptor.dart` — adds `Accept-Language` header to every Dio request
- `app/test/core/i18n/locale_provider_test.dart`
- `app/test/core/i18n/locale_interceptor_test.dart`

**Modify:**
- `app/pubspec.yaml` — add `flutter_localizations: { sdk: flutter }`, set `flutter: generate: true`
- `app/lib/app.dart:71-86` — replace the three `Default*Localizations.delegate` entries with `AppLocalizations.localizationsDelegates`, add `supportedLocales: AppLocalizations.supportedLocales`, pass `locale` from `localeProvider`
- `app/lib/main.dart` — read locale from `localeProvider` (or the underlying detector) before `initializeDateFormatting`
- `app/lib/core/api/dio_client.dart:29` — register `LocaleInterceptor` alongside `AuthInterceptor`
- `app/lib/core/utils/date_formatter.dart:9` — `appDateLocale` becomes mutable + synced from `localeProvider`

---

## Task Order

Backend first (Tasks 1–7): the foundation is fully self-contained and shippable without any Flutter changes — middleware works off `Accept-Language` if no Flutter client is sending the header yet, falling back to `app.fallback_locale`. Then Flutter (Tasks 8–12).

---

## Backend Tasks

### Task 1: Add `users.locale` column + `HasLocalePreference`

**Files:**
- Create: `api/database/migrations/2026_05_12_HHMMSS_add_locale_to_users.php` (replace `HHMMSS` with `date +%H%M%S` at creation time)
- Modify: `api/app/Models/User.php`
- Test: `api/tests/Feature/Models/UserLocaleTest.php`

- [ ] **Step 1: Generate migration file**

Run: `cd api && php artisan make:migration add_locale_to_users --table=users`
Expected: Creates `api/database/migrations/2026_05_12_<timestamp>_add_locale_to_users.php`

- [ ] **Step 2: Write the migration body**

Open the new file and replace its contents with:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->string('locale', 8)->nullable()->after('runner_level');
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn('locale');
        });
    }
};
```

- [ ] **Step 3: Write the failing test**

Create `api/tests/Feature/Models/UserLocaleTest.php`:

```php
<?php

namespace Tests\Feature\Models;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_locale_column_persists_and_round_trips(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->assertSame('nl', $user->fresh()->locale);
    }

    public function test_locale_defaults_to_null(): void
    {
        $user = User::factory()->create();

        $this->assertNull($user->fresh()->locale);
    }

    public function test_preferred_locale_returns_stored_locale_when_set(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->assertSame('nl', $user->preferredLocale());
    }

    public function test_preferred_locale_falls_back_to_app_fallback_when_null(): void
    {
        config(['app.fallback_locale' => 'en']);
        $user = User::factory()->create(['locale' => null]);

        $this->assertSame('en', $user->preferredLocale());
    }
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `cd api && php artisan test --filter=UserLocaleTest --compact`
Expected: FAIL — `locale` is not yet fillable on the User model and `preferredLocale()` is not defined.

- [ ] **Step 5: Update `app/Models/User.php`**

Add `'locale'` to the `$fillable` array (existing array — add at the end after `'self_reported_stats_at'` and `'runner_level'`).

Add the `HasLocalePreference` interface import and implementation:

```php
// at the top of the file, with other imports
use Illuminate\Contracts\Translation\HasLocalePreference;
```

Change the class declaration to add the interface:

```php
class User extends Authenticatable implements FilamentUser, HasLocalePreference
```

Add the `preferredLocale()` method to the class body (anywhere; convention is near the end after casts/relationships):

```php
public function preferredLocale(): string
{
    return $this->locale ?? config('app.fallback_locale', 'en');
}
```

- [ ] **Step 6: Run the migration**

Run: `cd api && php artisan migrate`
Expected: Migration runs successfully; `users.locale` column now exists.

- [ ] **Step 7: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=UserLocaleTest --compact`
Expected: PASS (4 tests).

- [ ] **Step 8: Commit**

```bash
cd api && git add database/migrations/*add_locale_to_users.php app/Models/User.php tests/Feature/Models/UserLocaleTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): add users.locale + HasLocalePreference

Adds the persisted locale column needed by queue workers (push
notifications, agent runs) that don't see an Accept-Language header.
preferredLocale() falls back to app.fallback_locale when null so the
column stays optional.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Create `SetLocale` middleware + tests + register

**Files:**
- Create: `api/app/Http/Middleware/SetLocale.php`
- Modify: `api/bootstrap/app.php`
- Test: `api/tests/Feature/Middleware/SetLocaleTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Middleware/SetLocaleTest.php`:

```php
<?php

namespace Tests\Feature\Middleware;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\App;
use Illuminate\Support\Facades\Route;
use Tests\TestCase;

class SetLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();
        Route::middleware([\App\Http\Middleware\SetLocale::class])
            ->get('/test-locale', fn () => [
                'app_locale' => App::getLocale(),
                'carbon_locale' => Carbon::getLocale(),
            ]);
    }

    public function test_resolves_dutch_from_accept_language_header(): void
    {
        $this->withHeader('Accept-Language', 'nl-NL,nl;q=0.9,en;q=0.8')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'nl', 'carbon_locale' => 'nl']);
    }

    public function test_falls_back_to_app_fallback_when_header_unsupported(): void
    {
        config(['app.fallback_locale' => 'en']);

        $this->withHeader('Accept-Language', 'de-DE,fr;q=0.8')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'en']);
    }

    public function test_authenticated_user_locale_overrides_header(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);

        $this->actingAs($user)
            ->withHeader('Accept-Language', 'en-US')
            ->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'nl']);
    }

    public function test_no_header_no_user_falls_back(): void
    {
        config(['app.fallback_locale' => 'en']);

        $this->getJson('/test-locale')
            ->assertOk()
            ->assertJson(['app_locale' => 'en']);
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd api && php artisan test --filter=SetLocaleTest --compact`
Expected: FAIL — `App\Http\Middleware\SetLocale` does not exist.

- [ ] **Step 3: Create the middleware**

Create `api/app/Http/Middleware/SetLocale.php`:

```php
<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\App;
use Symfony\Component\HttpFoundation\Response;

class SetLocale
{
    public const SUPPORTED = ['en', 'nl'];

    public function handle(Request $request, Closure $next): Response
    {
        $locale = $this->resolve($request);

        App::setLocale($locale);
        Carbon::setLocale($locale);

        return $next($request);
    }

    private function resolve(Request $request): string
    {
        $user = $request->user();
        if ($user?->locale && in_array($user->locale, self::SUPPORTED, true)) {
            return $user->locale;
        }

        return $request->getPreferredLanguage(self::SUPPORTED)
            ?? config('app.fallback_locale', 'en');
    }
}
```

Note: `Request::getPreferredLanguage(array $supported)` is Symfony's parser; it respects `q=` quality factors and returns the first supported match. When `Accept-Language` is absent it returns the first element of the supported list (which is `en`), but we explicitly fall back to `config('app.fallback_locale')` for clarity in case the supported list ever reorders.

- [ ] **Step 4: Register the middleware on the api route group**

Open `api/bootstrap/app.php` and find the `->withMiddleware(function (Middleware $middleware): void { ... })` block. Add inside that closure:

```php
$middleware->appendToGroup('api', \App\Http\Middleware\SetLocale::class);
```

Place this immediately after any existing `appendToGroup` / `prependToGroup` calls. If there are none, add it as the first line inside the closure.

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=SetLocaleTest --compact`
Expected: PASS (4 tests).

- [ ] **Step 6: Commit**

```bash
cd api && git add app/Http/Middleware/SetLocale.php bootstrap/app.php tests/Feature/Middleware/SetLocaleTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): SetLocale middleware on api group

Resolves locale per request from users.locale > Accept-Language >
fallback. Wires both App::setLocale() and Carbon::setLocale() so
translation lookups and date formatting both respect the runner's
language.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 3: Create `lang/{en,nl}/validation.php` (publish defaults + translate)

**Files:**
- Create: `api/lang/en/validation.php`
- Create: `api/lang/nl/validation.php`
- Test: `api/tests/Feature/Validation/LocalizedValidationTest.php`

- [ ] **Step 1: Publish Laravel's English validation file**

Run: `cd api && php artisan lang:publish`
Expected: Creates `api/lang/en/auth.php`, `api/lang/en/pagination.php`, `api/lang/en/passwords.php`, `api/lang/en/validation.php`.

We only care about `validation.php` for this task — the others can stay as-is (we're not exposing password-reset or paginator strings on the API surface yet).

- [ ] **Step 2: Create the Dutch validation file**

Create `api/lang/nl/validation.php` as a translation of `api/lang/en/validation.php`. Translate the *user-facing* messages (the `'required' => '...'` entries); keep keys, placeholders (`:attribute`, `:min`, `:max`), and structure identical. Below is the file in full — copy verbatim:

```php
<?php

return [

    'accepted' => 'Het veld :attribute moet geaccepteerd worden.',
    'accepted_if' => 'Het veld :attribute moet geaccepteerd worden als :other gelijk is aan :value.',
    'active_url' => 'Het veld :attribute moet een geldige URL bevatten.',
    'after' => 'Het veld :attribute moet een datum na :date bevatten.',
    'after_or_equal' => 'Het veld :attribute moet een datum na of gelijk aan :date bevatten.',
    'alpha' => 'Het veld :attribute mag alleen letters bevatten.',
    'alpha_dash' => 'Het veld :attribute mag alleen letters, nummers, underscores (_) en streepjes (-) bevatten.',
    'alpha_num' => 'Het veld :attribute mag alleen letters en nummers bevatten.',
    'array' => 'Het veld :attribute moet geselecteerde elementen bevatten.',
    'ascii' => 'Het veld :attribute mag alleen single-byte alfanumerieke tekens en symbolen bevatten.',
    'before' => 'Het veld :attribute moet een datum voor :date bevatten.',
    'before_or_equal' => 'Het veld :attribute moet een datum voor of gelijk aan :date bevatten.',
    'between' => [
        'array' => 'Het veld :attribute moet tussen :min en :max items bevatten.',
        'file' => 'Het veld :attribute moet tussen :min en :max kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet tussen :min en :max zijn.',
        'string' => 'Het veld :attribute moet tussen :min en :max karakters bevatten.',
    ],
    'boolean' => 'Het veld :attribute moet ja of nee zijn.',
    'confirmed' => 'De bevestiging van :attribute komt niet overeen.',
    'current_password' => 'Het wachtwoord is onjuist.',
    'date' => 'Het veld :attribute moet een geldige datum bevatten.',
    'date_equals' => 'Het veld :attribute moet een datum gelijk aan :date zijn.',
    'date_format' => 'Het veld :attribute moet overeenkomen met het formaat :format.',
    'decimal' => 'Het veld :attribute moet :decimal decimalen hebben.',
    'declined' => 'Het veld :attribute moet afgewezen worden.',
    'declined_if' => 'Het veld :attribute moet afgewezen worden als :other gelijk is aan :value.',
    'different' => 'De velden :attribute en :other moeten verschillend zijn.',
    'digits' => 'Het veld :attribute moet bestaan uit :digits cijfers.',
    'digits_between' => 'Het veld :attribute moet bestaan uit minimaal :min en maximaal :max cijfers.',
    'dimensions' => 'Het veld :attribute heeft geen geldige afmetingen voor afbeeldingen.',
    'distinct' => 'Het veld :attribute heeft een dubbele waarde.',
    'doesnt_end_with' => 'Het veld :attribute mag niet eindigen met een van de volgende: :values.',
    'doesnt_start_with' => 'Het veld :attribute mag niet beginnen met een van de volgende: :values.',
    'email' => 'Het veld :attribute moet een geldig e-mailadres bevatten.',
    'ends_with' => 'Het veld :attribute moet met een van de volgende waarden eindigen: :values.',
    'enum' => 'Het veld :attribute is ongeldig.',
    'exists' => 'Het veld :attribute bestaat niet.',
    'extensions' => 'Het veld :attribute moet een van de volgende extensies hebben: :values.',
    'file' => 'Het veld :attribute moet een bestand zijn.',
    'filled' => 'Het veld :attribute is verplicht.',
    'gt' => [
        'array' => 'Het veld :attribute moet meer dan :value items bevatten.',
        'file' => 'Het veld :attribute moet groter dan :value kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet groter dan :value zijn.',
        'string' => 'Het veld :attribute moet meer dan :value karakters bevatten.',
    ],
    'gte' => [
        'array' => 'Het veld :attribute moet :value items of meer bevatten.',
        'file' => 'Het veld :attribute moet groter of gelijk aan :value kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet groter of gelijk aan :value zijn.',
        'string' => 'Het veld :attribute moet :value karakters of meer bevatten.',
    ],
    'hex_color' => 'Het veld :attribute moet een geldige hexadecimale kleur zijn.',
    'image' => 'Het veld :attribute moet een afbeelding zijn.',
    'in' => 'Het veld :attribute is ongeldig.',
    'in_array' => 'Het veld :attribute moet in :other voorkomen.',
    'integer' => 'Het veld :attribute moet een getal zijn.',
    'ip' => 'Het veld :attribute moet een geldig IP-adres zijn.',
    'ipv4' => 'Het veld :attribute moet een geldig IPv4-adres zijn.',
    'ipv6' => 'Het veld :attribute moet een geldig IPv6-adres zijn.',
    'json' => 'Het veld :attribute moet een geldige JSON-string zijn.',
    'list' => 'Het veld :attribute moet een lijst zijn.',
    'lowercase' => 'Het veld :attribute moet in kleine letters zijn.',
    'lt' => [
        'array' => 'Het veld :attribute moet minder dan :value items bevatten.',
        'file' => 'Het veld :attribute moet kleiner dan :value kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet kleiner dan :value zijn.',
        'string' => 'Het veld :attribute moet minder dan :value karakters bevatten.',
    ],
    'lte' => [
        'array' => 'Het veld :attribute mag niet meer dan :value items bevatten.',
        'file' => 'Het veld :attribute moet kleiner of gelijk aan :value kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet kleiner of gelijk aan :value zijn.',
        'string' => 'Het veld :attribute moet :value karakters of minder bevatten.',
    ],
    'mac_address' => 'Het veld :attribute moet een geldig MAC-adres zijn.',
    'max' => [
        'array' => 'Het veld :attribute mag niet meer dan :max items bevatten.',
        'file' => 'Het veld :attribute mag niet groter dan :max kilobytes zijn.',
        'numeric' => 'Het veld :attribute mag niet groter dan :max zijn.',
        'string' => 'Het veld :attribute mag niet uit meer dan :max karakters bestaan.',
    ],
    'max_digits' => 'Het veld :attribute mag niet meer dan :max cijfers bevatten.',
    'mimes' => 'Het veld :attribute moet een bestand zijn van het bestandstype: :values.',
    'mimetypes' => 'Het veld :attribute moet een bestand zijn van het bestandstype: :values.',
    'min' => [
        'array' => 'Het veld :attribute moet ten minste :min items bevatten.',
        'file' => 'Het veld :attribute moet ten minste :min kilobytes zijn.',
        'numeric' => 'Het veld :attribute moet ten minste :min zijn.',
        'string' => 'Het veld :attribute moet ten minste :min karakters bevatten.',
    ],
    'min_digits' => 'Het veld :attribute moet ten minste :min cijfers bevatten.',
    'missing' => 'Het veld :attribute mag niet aanwezig zijn.',
    'missing_if' => 'Het veld :attribute mag niet aanwezig zijn als :other gelijk is aan :value.',
    'missing_unless' => 'Het veld :attribute mag niet aanwezig zijn tenzij :other gelijk is aan :value.',
    'missing_with' => 'Het veld :attribute mag niet aanwezig zijn als :values aanwezig is.',
    'missing_with_all' => 'Het veld :attribute mag niet aanwezig zijn als :values aanwezig zijn.',
    'multiple_of' => 'Het veld :attribute moet een veelvoud van :value zijn.',
    'not_in' => 'Het veld :attribute is ongeldig.',
    'not_regex' => 'Het veld :attribute heeft een ongeldige indeling.',
    'numeric' => 'Het veld :attribute moet een getal zijn.',
    'password' => [
        'letters' => 'Het veld :attribute moet ten minste één letter bevatten.',
        'mixed' => 'Het veld :attribute moet ten minste één hoofdletter en één kleine letter bevatten.',
        'numbers' => 'Het veld :attribute moet ten minste één cijfer bevatten.',
        'symbols' => 'Het veld :attribute moet ten minste één symbool bevatten.',
        'uncompromised' => 'De opgegeven :attribute is gelekt bij een datalek. Kies een andere :attribute.',
    ],
    'present' => 'Het veld :attribute moet aanwezig zijn.',
    'present_if' => 'Het veld :attribute moet aanwezig zijn als :other gelijk is aan :value.',
    'present_unless' => 'Het veld :attribute moet aanwezig zijn tenzij :other gelijk is aan :value.',
    'present_with' => 'Het veld :attribute moet aanwezig zijn als :values aanwezig is.',
    'present_with_all' => 'Het veld :attribute moet aanwezig zijn als :values aanwezig zijn.',
    'prohibited' => 'Het veld :attribute is verboden.',
    'prohibited_if' => 'Het veld :attribute is verboden als :other gelijk is aan :value.',
    'prohibited_unless' => 'Het veld :attribute is verboden tenzij :other voorkomt in :values.',
    'prohibits' => 'Het veld :attribute verbiedt aanwezigheid van :other.',
    'regex' => 'Het veld :attribute heeft een ongeldige indeling.',
    'required' => 'Het veld :attribute is verplicht.',
    'required_array_keys' => 'Het veld :attribute moet items bevatten voor: :values.',
    'required_if' => 'Het veld :attribute is verplicht als :other gelijk is aan :value.',
    'required_if_accepted' => 'Het veld :attribute is verplicht als :other geaccepteerd is.',
    'required_if_declined' => 'Het veld :attribute is verplicht als :other afgewezen is.',
    'required_unless' => 'Het veld :attribute is verplicht tenzij :other in :values voorkomt.',
    'required_with' => 'Het veld :attribute is verplicht in combinatie met :values.',
    'required_with_all' => 'Het veld :attribute is verplicht in combinatie met :values.',
    'required_without' => 'Het veld :attribute is verplicht als :values niet aanwezig is.',
    'required_without_all' => 'Het veld :attribute is verplicht als :values niet aanwezig zijn.',
    'same' => 'De velden :attribute en :other moeten overeenkomen.',
    'size' => [
        'array' => 'Het veld :attribute moet :size items bevatten.',
        'file' => 'Het veld :attribute moet :size kilobyte zijn.',
        'numeric' => 'Het veld :attribute moet :size zijn.',
        'string' => 'Het veld :attribute moet :size karakters lang zijn.',
    ],
    'starts_with' => 'Het veld :attribute moet beginnen met een van de volgende: :values.',
    'string' => 'Het veld :attribute moet een tekst zijn.',
    'timezone' => 'Het veld :attribute moet een geldige tijdzone zijn.',
    'unique' => 'De opgegeven :attribute is al in gebruik.',
    'uploaded' => 'Het uploaden van :attribute is mislukt.',
    'uppercase' => 'Het veld :attribute moet in hoofdletters zijn.',
    'url' => 'Het veld :attribute moet een geldige URL zijn.',
    'ulid' => 'Het veld :attribute moet een geldige ULID zijn.',
    'uuid' => 'Het veld :attribute moet een geldige UUID zijn.',

    'custom' => [
        'attribute-name' => [
            'rule-name' => 'custom-message',
        ],
    ],

    'attributes' => [],

];
```

- [ ] **Step 3: Write the failing test**

Create `api/tests/Feature/Validation/LocalizedValidationTest.php`:

```php
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
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=LocalizedValidationTest --compact`
Expected: PASS (2 tests). Laravel auto-discovers `lang/{en,nl}/validation.php`.

- [ ] **Step 5: Commit**

```bash
cd api && git add lang/ tests/Feature/Validation/LocalizedValidationTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): publish validation lang files + Dutch translation

Publishes Laravel's English validation messages so we own them, and
adds the Dutch counterpart. Laravel's __() auto-resolves once the
SetLocale middleware sets App::setLocale('nl').

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 4: Localize the 4 templated push notifications

The 4 notifications with fully templated copy (no admin-typed text) are: `PlanGenerationCompleted`, `PlanGenerationFailed`, `TrainingDayReminder`, `BirthdayZoneCheckReminder`. The other 3 (`AdhocPush`, `OrganizationInvitation`, `WorkoutAnalyzed`) are out of scope here — `AdhocPush` accepts admin-typed copy, and `OrganizationInvitation`/`WorkoutAnalyzed` need their own design review before localizing. Add a `// TODO(i18n)` note on those during this task.

**Files:**
- Create: `api/lang/en/notifications.php`
- Create: `api/lang/nl/notifications.php`
- Modify: `api/app/Notifications/PlanGenerationCompleted.php`
- Modify: `api/app/Notifications/PlanGenerationFailed.php`
- Modify: `api/app/Notifications/TrainingDayReminder.php`
- Modify: `api/app/Notifications/BirthdayZoneCheckReminder.php`
- Modify: `api/app/Notifications/AdhocPush.php` (just add TODO note)
- Modify: `api/app/Notifications/OrganizationInvitation.php` (just add TODO note)
- Modify: `api/app/Notifications/WorkoutAnalyzed.php` (just add TODO note)
- Test: `api/tests/Feature/Notifications/PlanGenerationCompletedLocalizationTest.php`

- [ ] **Step 1: Read the four notifications to capture every hardcoded string**

Read each in full:

```bash
cd api && for f in PlanGenerationCompleted PlanGenerationFailed TrainingDayReminder BirthdayZoneCheckReminder; do
  echo "==== $f.php ===="
  cat app/Notifications/$f.php
done
```

Note every literal title/body string and any inline expressions (e.g., `"Today: {$km}km {$label}"`). These become keys + `:placeholder` pairs in the lang files.

- [ ] **Step 2: Create `lang/en/notifications.php`**

```php
<?php

return [

    'plan_generation' => [
        'completed' => [
            'title' => 'Your training plan is ready',
            'body' => 'Tap to review and accept your plan.',
        ],
        'failed' => [
            'title' => 'Plan generation hit a snag',
            'body' => 'Tap to try again.',
        ],
    ],

    'training_day' => [
        // Used when the training day has no custom title and no km target —
        // the bare fallback.
        'fallback_title' => "Today's run",
        // Used when km + type label are available, e.g. "Today: 5km Easy".
        'title_with_km' => 'Today: :km km :type',
        // Body composed of optional pieces — see the notification class for
        // how they're joined.
        'target_pace' => 'Target pace :pace/km',
        'tap_for_details' => 'Tap for details.',
    ],

    'birthday_zone_check' => [
        'title' => 'Happy birthday! 🎂',
        'body' => "You're a year wiser — let's refresh your heart-rate zones to match.",
    ],

];
```

- [ ] **Step 3: Create `lang/nl/notifications.php`**

```php
<?php

return [

    'plan_generation' => [
        'completed' => [
            'title' => 'Je trainingsplan staat klaar',
            'body' => 'Tik om te bekijken en goed te keuren.',
        ],
        'failed' => [
            'title' => 'Plan-generatie liep vast',
            'body' => 'Tik om opnieuw te proberen.',
        ],
    ],

    'training_day' => [
        'fallback_title' => 'Loop van vandaag',
        'title_with_km' => 'Vandaag: :km km :type',
        'target_pace' => 'Richttempo :pace/km',
        'tap_for_details' => 'Tik voor details.',
    ],

    'birthday_zone_check' => [
        'title' => 'Gefeliciteerd! 🎂',
        'body' => 'Je bent een jaar wijzer — laten we je hartslagzones bijwerken.',
    ],

];
```

- [ ] **Step 4: Refactor `PlanGenerationCompleted.php`**

Modify `toApn()`:

```php
public function toApn(object $notifiable): ApnMessage
{
    return ApnMessage::create()
        ->title(__('notifications.plan_generation.completed.title'))
        ->body(__('notifications.plan_generation.completed.body'))
        ->sound('default')
        ->expiresAt(now()->addHours(4)->toDateTime())
        ->custom('type', 'plan_generation_completed')
        ->custom('conversation_id', $this->conversationId);
}
```

- [ ] **Step 5: Refactor `PlanGenerationFailed.php` the same way**

Replace its `->title(...)` and `->body(...)` calls with:

```php
->title(__('notifications.plan_generation.failed.title'))
->body(__('notifications.plan_generation.failed.body'))
```

- [ ] **Step 6: Refactor `TrainingDayReminder.php`**

This notification composes its title + body from `TrainingDay` fields. Inspect the current implementation; replace inline string literals with `__()` calls passing the same data through `:placeholder` substitution. The two helper methods become roughly:

```php
private function title(TrainingDay $day): string
{
    if ($day->target_km === null) {
        return __('notifications.training_day.fallback_title');
    }

    return __('notifications.training_day.title_with_km', [
        'km' => $day->target_km,
        'type' => $day->training_type->label(), // localized in Task 5
    ]);
}

private function body(TrainingDay $day): string
{
    $parts = [];

    if ($day->title !== null && $day->title !== $day->training_type->label()) {
        $parts[] = $day->title;
    }

    if ($day->target_pace_seconds_per_km !== null) {
        $parts[] = __('notifications.training_day.target_pace', [
            'pace' => $this->formatPace($day->target_pace_seconds_per_km),
        ]);
    }

    $parts[] = __('notifications.training_day.tap_for_details');

    return implode(' ', $parts);
}
```

Keep `formatPace()` unchanged — the `m:ss` format is the same in both locales.

- [ ] **Step 7: Refactor `BirthdayZoneCheckReminder.php`**

Replace its title/body with:

```php
->title(__('notifications.birthday_zone_check.title'))
->body(__('notifications.birthday_zone_check.body'))
```

- [ ] **Step 8: Add a TODO marker on the 3 non-localized notifications**

In `AdhocPush.php`, `OrganizationInvitation.php`, `WorkoutAnalyzed.php`, add at the top of each `toApn()` method:

```php
// TODO(i18n): localize when admin/inviter copy strategy is decided.
```

This avoids silent oversight in code review — anyone touching the file sees the deferred work.

- [ ] **Step 9: Write the failing test**

Create `api/tests/Feature/Notifications/PlanGenerationCompletedLocalizationTest.php`:

```php
<?php

namespace Tests\Feature\Notifications;

use App\Models\User;
use App\Notifications\PlanGenerationCompleted;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Tests\TestCase;

class PlanGenerationCompletedLocalizationTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_renders_dutch_when_user_locale_is_nl(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);
        $notification = new PlanGenerationCompleted(Str::uuid()->toString());

        $message = $notification->withLocale($user->preferredLocale())
            ->toApn($user);

        $this->assertSame('Je trainingsplan staat klaar', $message->title);
        $this->assertSame('Tik om te bekijken en goed te keuren.', $message->body);
    }

    public function test_renders_english_when_user_locale_is_null(): void
    {
        $user = User::factory()->create(['locale' => null]);
        $notification = new PlanGenerationCompleted(Str::uuid()->toString());

        $message = $notification->withLocale($user->preferredLocale())
            ->toApn($user);

        $this->assertSame('Your training plan is ready', $message->title);
        $this->assertSame('Tap to review and accept your plan.', $message->body);
    }
}
```

This test asserts the lang-file → `__()` → notification wiring works. Laravel's notification system calls `withLocale()` automatically via `HasLocalePreference` when dispatching through `$user->notify(...)`, so the test mirrors that behavior explicitly.

- [ ] **Step 10: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=PlanGenerationCompletedLocalizationTest --compact`
Expected: PASS (2 tests).

- [ ] **Step 11: Commit**

```bash
cd api && git add lang/en/notifications.php lang/nl/notifications.php app/Notifications/*.php tests/Feature/Notifications/PlanGenerationCompletedLocalizationTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): localize templated push notifications

PlanGenerationCompleted/Failed, TrainingDayReminder, and
BirthdayZoneCheckReminder now route through __(). The User model
already implements HasLocalePreference (Task 1) so queue-dispatched
notifications auto-respect $user->locale without explicit
withLocale() calls.

AdhocPush, OrganizationInvitation, and WorkoutAnalyzed carry
admin/inviter-typed copy or are pending design — marked with
TODO(i18n).

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 5: Localize `TrainingType::label()`

**Files:**
- Create: `api/lang/en/enums.php`
- Create: `api/lang/nl/enums.php`
- Modify: `api/app/Enums/TrainingType.php`
- Test: `api/tests/Feature/Enums/TrainingTypeLabelTest.php`

- [ ] **Step 1: Create `lang/en/enums.php`**

```php
<?php

return [

    'training_type' => [
        'easy' => 'Easy',
        'tempo' => 'Tempo',
        'interval' => 'Intervals',
        'long_run' => 'Long run',
        'threshold' => 'Threshold',
    ],

];
```

- [ ] **Step 2: Create `lang/nl/enums.php`**

```php
<?php

return [

    'training_type' => [
        'easy' => 'Rustig',
        'tempo' => 'Tempo',
        'interval' => 'Intervals',
        'long_run' => 'Lange duurloop',
        'threshold' => 'Drempel',
    ],

];
```

Note: "Tempo" and "Intervals" stay the same in Dutch running culture (loanwords). Adjust during native review if a different idiom is preferred.

- [ ] **Step 3: Write the failing test**

Create `api/tests/Feature/Enums/TrainingTypeLabelTest.php`:

```php
<?php

namespace Tests\Feature\Enums;

use App\Enums\TrainingType;
use Illuminate\Support\Facades\App;
use Tests\TestCase;

class TrainingTypeLabelTest extends TestCase
{
    public function test_english_labels(): void
    {
        App::setLocale('en');

        $this->assertSame('Easy', TrainingType::Easy->label());
        $this->assertSame('Tempo', TrainingType::Tempo->label());
        $this->assertSame('Intervals', TrainingType::Interval->label());
        $this->assertSame('Long run', TrainingType::LongRun->label());
        $this->assertSame('Threshold', TrainingType::Threshold->label());
    }

    public function test_dutch_labels(): void
    {
        App::setLocale('nl');

        $this->assertSame('Rustig', TrainingType::Easy->label());
        $this->assertSame('Lange duurloop', TrainingType::LongRun->label());
        $this->assertSame('Drempel', TrainingType::Threshold->label());
    }
}
```

- [ ] **Step 4: Run the test to verify it fails**

Run: `cd api && php artisan test --filter=TrainingTypeLabelTest --compact`
Expected: FAIL — `label()` still returns hardcoded English strings.

- [ ] **Step 5: Modify `app/Enums/TrainingType.php`**

Replace the `label()` method's `match` body with a single translation call:

```php
public function label(): string
{
    return __('enums.training_type.' . $this->value);
}
```

- [ ] **Step 6: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=TrainingTypeLabelTest --compact`
Expected: PASS (2 tests).

- [ ] **Step 7: Run the broader test suite to catch any regressions**

`TrainingType::label()` is consumed by `TrainingDayReminder`, `PaceAdjustmentEvaluator`, `PlanOptimizerService::generateTitles()`, and Filament resources. Catch any test that pinned an English label:

Run: `cd api && php artisan test --compact`
Expected: PASS overall. If a test fails because it asserted `"Easy"` against a label, update the test to either `App::setLocale('en')` first or use `__('enums.training_type.easy')` for the assertion.

- [ ] **Step 8: Commit**

```bash
cd api && git add lang/en/enums.php lang/nl/enums.php app/Enums/TrainingType.php tests/Feature/Enums/TrainingTypeLabelTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): localize TrainingType::label()

Routes label() through __() so Filament admin, push notifications,
and plan-generated session titles all respect the current locale.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 6: AuthController backfills `users.locale` on first Apple sign-in

When a user signs in with Apple and the server upserts the row, capture the `Accept-Language` header value (resolved to a supported locale) as the persisted preference if `locale` is currently NULL. Subsequent sign-ins respect the existing value (manual overrides win).

**Files:**
- Modify: `api/app/Http/Controllers/AuthController.php`
- Test: `api/tests/Feature/Auth/AppleSignInBackfillsLocaleTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Auth/AppleSignInBackfillsLocaleTest.php`:

```php
<?php

namespace Tests\Feature\Auth;

use App\Models\User;
use App\Services\Auth\AppleIdentityTokenVerifier;
use App\Services\Auth\VerifiedAppleIdentity;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class AppleSignInBackfillsLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        $verified = new VerifiedAppleIdentity(
            sub: 'apple-sub-test-1',
            email: 'runner@example.com',
        );

        $verifier = Mockery::mock(AppleIdentityTokenVerifier::class);
        $verifier->shouldReceive('verify')->andReturn($verified);
        $this->app->instance(AppleIdentityTokenVerifier::class, $verifier);
    }

    public function test_backfills_dutch_locale_on_first_sign_in_when_header_indicates_dutch(): void
    {
        $this->withHeader('Accept-Language', 'nl-NL,nl;q=0.9,en;q=0.8')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-test-1')->firstOrFail();
        $this->assertSame('nl', $user->locale);
    }

    public function test_backfills_english_when_header_indicates_unsupported_language(): void
    {
        $this->withHeader('Accept-Language', 'de-DE,fr;q=0.8')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-test-1')->firstOrFail();
        $this->assertSame('en', $user->locale);
    }

    public function test_does_not_overwrite_existing_locale_on_subsequent_sign_ins(): void
    {
        User::factory()->create(['apple_sub' => 'apple-sub-test-1', 'locale' => 'nl']);

        $this->withHeader('Accept-Language', 'en-US')
            ->postJson('/api/v1/auth/apple', ['identity_token' => 'fake'])
            ->assertOk();

        $user = User::where('apple_sub', 'apple-sub-test-1')->firstOrFail();
        $this->assertSame('nl', $user->locale, 'existing locale must not be overwritten');
    }
}
```

If the existing `AppleIdentityTokenVerifier` returns a different value object shape, adjust the mock to match. Read `api/app/Services/Auth/AppleIdentityTokenVerifier.php` to confirm.

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd api && php artisan test --filter=AppleSignInBackfillsLocaleTest --compact`
Expected: FAIL — `users.locale` is NULL after sign-in because the controller doesn't set it.

- [ ] **Step 3: Modify `AuthController::appleSignIn`**

Find the part of the method that upserts the user (something like `User::firstOrCreate(['apple_sub' => $verified->sub], [...])` or `User::updateOrCreate(...)`). After the upsert, **before** issuing the token, add:

```php
if ($user->locale === null) {
    $detected = $request->getPreferredLanguage(\App\Http\Middleware\SetLocale::SUPPORTED)
        ?? config('app.fallback_locale', 'en');
    $user->forceFill(['locale' => $detected])->save();
}
```

`forceFill` is used because we want this assignment regardless of `$fillable` rules at the controller level. (`locale` IS in fillable per Task 1, but `forceFill` makes the intent explicit and consistent with similar one-off backfills.)

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=AppleSignInBackfillsLocaleTest --compact`
Expected: PASS (3 tests).

- [ ] **Step 5: Commit**

```bash
cd api && git add app/Http/Controllers/AuthController.php tests/Feature/Auth/AppleSignInBackfillsLocaleTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): backfill users.locale from Accept-Language on Apple sign-in

First sign-in captures the device's preferred language so queue-
dispatched notifications work for the very first push (before the
runner has had a chance to override in Settings). Existing values
are preserved.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 7: `ProfileController::update` accepts `locale`

**Files:**
- Modify: `api/app/Http/Controllers/ProfileController.php`
- Test: `api/tests/Feature/Profile/UpdateLocaleTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Profile/UpdateLocaleTest.php`:

```php
<?php

namespace Tests\Feature\Profile;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class UpdateLocaleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_authenticated_user_can_set_locale_to_dutch(): void
    {
        $user = User::factory()->create(['locale' => null]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => 'nl'])
            ->assertOk();

        $this->assertSame('nl', $user->fresh()->locale);
    }

    public function test_locale_can_be_cleared_by_passing_null(): void
    {
        $user = User::factory()->create(['locale' => 'nl']);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => null])
            ->assertOk();

        $this->assertNull($user->fresh()->locale);
    }

    public function test_unsupported_locale_is_rejected(): void
    {
        $user = User::factory()->create(['locale' => null]);
        Sanctum::actingAs($user);

        $this->putJson('/api/v1/profile', ['locale' => 'fr'])
            ->assertStatus(422)
            ->assertJsonValidationErrors(['locale']);
    }
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd api && php artisan test --filter=UpdateLocaleTest --compact`
Expected: FAIL — `locale` is not in the validated input.

- [ ] **Step 3: Modify `ProfileController::update`**

Open `api/app/Http/Controllers/ProfileController.php` and find the `update()` method. Add `locale` to the validated rules:

```php
$validated = $request->validate([
    // ... existing rules
    'locale' => ['nullable', 'string', 'in:en,nl'],
]);
```

Then ensure the validated `locale` is applied to the user. If the controller currently does `$user->update($validated)` or `$user->fill($validated)->save()` and `locale` is already in `$fillable` (Task 1 added it), no extra step is needed. If it does field-by-field assignment, add:

```php
if (array_key_exists('locale', $validated)) {
    $user->locale = $validated['locale'];
}
```

before the save.

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd api && php artisan test --filter=UpdateLocaleTest --compact`
Expected: PASS (3 tests).

- [ ] **Step 5: Run the broader test suite to catch regressions**

Run: `cd api && php artisan test --compact`
Expected: All tests pass (~295 + the few new ones).

- [ ] **Step 6: Commit**

```bash
cd api && git add app/Http/Controllers/ProfileController.php tests/Feature/Profile/UpdateLocaleTest.php
git commit -m "$(cat <<'EOF'
feat(i18n): PUT /profile accepts locale field

Allows the Flutter app to push the runner's chosen language (or
null to revert to auto-detection on next request) to the backend.
Validates against en|nl.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Frontend Tasks

### Task 8: Add `flutter_localizations` + `l10n.yaml` + seed ARB files

**Files:**
- Modify: `app/pubspec.yaml`
- Create: `app/l10n.yaml`
- Create: `app/lib/l10n/app_en.arb`
- Create: `app/lib/l10n/app_nl.arb`
- Generated (do not hand-edit): `app/lib/l10n/app_localizations.dart`, `app_localizations_en.dart`, `app_localizations_nl.dart`

- [ ] **Step 1: Add `flutter_localizations` to `pubspec.yaml`**

Open `app/pubspec.yaml`. In the `dependencies:` block, immediately after `flutter: { sdk: flutter }`, add:

```yaml
  flutter_localizations:
    sdk: flutter
```

`intl: ^0.20.2` is already present further down — leave it.

Then in the `flutter:` section (near the bottom, where `uses-material-design: true` typically lives), add:

```yaml
flutter:
  uses-material-design: true
  generate: true   # <-- add this line
  # ... rest of the section
```

- [ ] **Step 2: Create `app/l10n.yaml`** at the project root (next to `pubspec.yaml`):

```yaml
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
output-class: AppLocalizations
nullable-getter: false
synthetic-package: false
```

`synthetic-package: false` means the generated `AppLocalizations` lives at `lib/l10n/app_localizations.dart` and is committed to git. This is the modern default (the synthetic-package approach was deprecated in Flutter 3.27+).

- [ ] **Step 3: Create `app/lib/l10n/app_en.arb`**

This seed file holds only a couple of keys to prove the pipeline. Phase 3 will balloon this file.

```jsonc
{
  "@@locale": "en",
  "appTitle": "RunCoach",
  "@appTitle": {
    "description": "The application title — used in window title, sharing intents, etc."
  },
  "languageEnglish": "English",
  "@languageEnglish": {
    "description": "Label for English in a language picker"
  },
  "languageDutch": "Nederlands",
  "@languageDutch": {
    "description": "Label for Dutch (Nederlands) in a language picker — always shown in Dutch regardless of UI locale"
  }
}
```

- [ ] **Step 4: Create `app/lib/l10n/app_nl.arb`**

```jsonc
{
  "@@locale": "nl",
  "appTitle": "RunCoach",
  "languageEnglish": "English",
  "languageDutch": "Nederlands"
}
```

The Dutch ARB only needs `@@locale` + the keys; sibling `@key` metadata is only required in the template (`app_en.arb`).

- [ ] **Step 5: Run `flutter pub get` to trigger gen-l10n**

Run: `cd app && flutter pub get`
Expected: Creates `lib/l10n/app_localizations.dart`, `lib/l10n/app_localizations_en.dart`, `lib/l10n/app_localizations_nl.dart`. No errors.

- [ ] **Step 6: Confirm the generated class compiles**

Run: `cd app && flutter analyze`
Expected: No analysis errors. `AppLocalizations.supportedLocales` and `AppLocalizations.localizationsDelegates` are now available for use.

- [ ] **Step 7: Commit**

```bash
cd app && git add pubspec.yaml pubspec.lock l10n.yaml lib/l10n/
git commit -m "$(cat <<'EOF'
feat(i18n): set up flutter_localizations + gen-l10n + ARB seed files

Adds the official Flutter i18n stack with synthetic-package: false
and nullable-getter: false (modern defaults). Seed app_en.arb +
app_nl.arb with three keys; bulk string extraction lands in Phase 3.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 9: `BuildContext.l10n` extension + `appLocalizationsProvider`

**Files:**
- Create: `app/lib/core/i18n/build_context_l10n.dart`
- Create: `app/lib/core/i18n/app_localizations_provider.dart`
- Create: `app/lib/core/i18n/app_localizations_provider.g.dart` (generated)

- [ ] **Step 1: Create the `BuildContext` extension**

`app/lib/core/i18n/build_context_l10n.dart`:

```dart
import 'package:flutter/widgets.dart';

import 'package:app/l10n/app_localizations.dart';

extension BuildContextL10n on BuildContext {
  /// Strongly-typed access to localized strings.
  ///
  /// Usage:
  /// ```dart
  /// Text(context.l10n.appTitle)
  /// ```
  ///
  /// Configured with `nullable-getter: false` in `l10n.yaml`, so
  /// this never returns null inside the app — `AppLocalizations` is
  /// always present once `CupertinoApp.router` registers the
  /// delegates (see `lib/app.dart`).
  AppLocalizations get l10n => AppLocalizations.of(this);
}
```

- [ ] **Step 2: Create the Riverpod provider for non-widget access**

`app/lib/core/i18n/app_localizations_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:app/l10n/app_localizations.dart';
import 'package:app/core/i18n/locale_provider.dart';

part 'app_localizations_provider.g.dart';

/// Exposes [AppLocalizations] outside of widget trees so services,
/// agents, and notifications-side state can read translated strings.
///
/// Implementation note: we instantiate `AppLocalizations.delegate.load(...)`
/// directly rather than going through `BuildContext` — services don't have
/// one. The result is cached per locale and rebuilt automatically when the
/// runner switches language via [appLocaleProvider].
@riverpod
Future<AppLocalizations> appLocalizations(Ref ref) async {
  final locale = await ref.watch(appLocaleProvider.future);
  return AppLocalizations.delegate.load(locale);
}
```

- [ ] **Step 3: Run codegen to produce `.g.dart`**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: Creates `app/lib/core/i18n/app_localizations_provider.g.dart`. (This task will likely fail until Task 10 lands `appLocaleProvider`, so add a placeholder for now — see next step.)

- [ ] **Step 4: If codegen fails because `appLocaleProvider` doesn't exist yet, defer the .g.dart generation**

Comment out the body of `app_localizations_provider.dart` temporarily, leaving only the file header + class skeleton, until Task 10 is complete. **Or** do Task 10 first — they're tightly coupled.

**Recommended:** combine Tasks 9 and 10 into one commit. The file split is purely for clarity in this plan; the actual work is one unit.

- [ ] **Step 5: Run analyzer**

Run: `cd app && flutter analyze`
Expected: No errors in `lib/core/i18n/`.

- [ ] **Step 6: Commit** (after Task 10 lands, in a combined commit — skip this step if combining)

---

### Task 10: `localeProvider` (Riverpod) — auto-detect + persist

**Files:**
- Create: `app/lib/core/i18n/current_locale.dart`
- Create: `app/lib/core/i18n/locale_provider.dart`
- Create: `app/lib/core/i18n/locale_provider.g.dart` (generated)
- Test: `app/test/core/i18n/locale_provider_test.dart`

- [ ] **Step 1: Create the top-level mutable BCP-47 string**

`app/lib/core/i18n/current_locale.dart`:

```dart
/// Mutable BCP-47 language tag for the app's currently active locale.
///
/// Read by the Dio `LocaleInterceptor` (which can't be made a Riverpod
/// consumer — Dio is constructed as a singleton). Written by
/// [AppLocaleNotifier] whenever the locale changes.
///
/// Mirrors the long-standing `appDateLocale` mutable global in
/// `core/utils/date_formatter.dart` for consistency.
String currentAppLocaleTag = 'en';
```

- [ ] **Step 2: Create the locale notifier**

`app/lib/core/i18n/locale_provider.dart`:

```dart
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/i18n/current_locale.dart';
import 'package:app/core/utils/date_formatter.dart';

part 'locale_provider.g.dart';

/// Single source of truth for the app's active locale.
///
/// On first launch, auto-detects from the device's preferred languages
/// (returns Dutch only when one of the device's preferred languages
/// is Dutch; everything else falls back to English).
///
/// Persists user override in `shared_preferences` under
/// [_overrideKey]. Passing null to [setOverride] clears the override
/// and reverts to auto-detection on next read.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  static const _overrideKey = 'app_locale_override';
  static const _supported = {'en', 'nl'};

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_overrideKey);
    final resolved = (override != null && _supported.contains(override))
        ? Locale(override)
        : detectDeviceLocale();

    _syncSideEffects(resolved);
    return resolved;
  }

  /// Picks the first device-preferred language that's Dutch; otherwise
  /// defaults to English.
  ///
  /// Visible for testing.
  static Locale detectDeviceLocale() {
    final preferred = PlatformDispatcher.instance.locales;
    for (final loc in preferred) {
      if (loc.languageCode.toLowerCase() == 'nl') {
        return const Locale('nl');
      }
    }
    return const Locale('en');
  }

  /// Sets an explicit user override (English / Dutch) or clears it
  /// (pass null → reverts to device auto-detection).
  Future<void> setOverride(Locale? locale) async {
    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_overrideKey);
      final resolved = detectDeviceLocale();
      _syncSideEffects(resolved);
      state = AsyncData(resolved);
      return;
    }

    if (!_supported.contains(locale.languageCode)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }

    await prefs.setString(_overrideKey, locale.languageCode);
    _syncSideEffects(locale);
    state = AsyncData(locale);
  }

  void _syncSideEffects(Locale locale) {
    currentAppLocaleTag = locale.languageCode;
    appDateLocale = locale.languageCode;
  }
}
```

- [ ] **Step 3: Run codegen**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: Creates `lib/core/i18n/locale_provider.g.dart`.

- [ ] **Step 4: Write the failing test**

Create `app/test/core/i18n/locale_provider_test.dart`:

```dart
import 'dart:ui';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/i18n/current_locale.dart';
import 'package:app/core/i18n/locale_provider.dart';

void main() {
  setUp(() async {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    currentAppLocaleTag = 'en';
  });

  group('AppLocale.detectDeviceLocale', () {
    // PlatformDispatcher.locales is hard to mock in pure Dart tests.
    // We instead unit-test the resolution branches via setOverride().
  });

  test('persists override across rebuilds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appLocaleProvider.notifier).setOverride(const Locale('nl'));
    expect(currentAppLocaleTag, 'nl');

    // New container = simulates app restart
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final resolved = await container2.read(appLocaleProvider.future);

    expect(resolved.languageCode, 'nl');
    expect(currentAppLocaleTag, 'nl');
  });

  test('clearing override falls back to detected device locale', () async {
    SharedPreferences.setMockInitialValues({
      'app_locale_override': 'nl',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final resolvedBefore = await container.read(appLocaleProvider.future);
    expect(resolvedBefore.languageCode, 'nl');

    await container.read(appLocaleProvider.notifier).setOverride(null);

    // Device locale in the test harness is en_US; detection returns 'en'.
    expect(container.read(appLocaleProvider).value?.languageCode, 'en');
    expect(currentAppLocaleTag, 'en');
  });

  test('throws on unsupported locale', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container.read(appLocaleProvider.notifier).setOverride(const Locale('fr')),
      throwsArgumentError,
    );
  });
}
```

- [ ] **Step 5: Run the test**

Run: `cd app && flutter test test/core/i18n/locale_provider_test.dart`
Expected: PASS (3 tests).

- [ ] **Step 6: Now also wire the `appLocalizationsProvider` from Task 9**

Create (or update if you already stubbed it in Task 9) `app/lib/core/i18n/app_localizations_provider.dart` with the implementation shown in Task 9, Step 2.

Re-run codegen:
```bash
cd app && dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Run analyzer**

Run: `cd app && flutter analyze`
Expected: No errors.

- [ ] **Step 8: Commit (Tasks 9 + 10 combined)**

```bash
cd app && git add lib/core/i18n/ test/core/i18n/
git commit -m "$(cat <<'EOF'
feat(i18n): localeProvider + appLocalizationsProvider + context.l10n

Single Riverpod source of truth for the app's active locale.
Auto-detects from PlatformDispatcher.instance.locales (matching
languageCode == 'nl' only — country code intentionally ignored,
see the design doc § 3.2 for why). Persists override in
shared_preferences.

Side-syncs to currentAppLocaleTag (read by Dio interceptor in
Task 12) and appDateLocale (used by date_formatter.dart) so both
network requests and date formatting follow the same source of
truth.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 11: Wire `CupertinoApp.router` with delegates + locale from provider

**Files:**
- Modify: `app/lib/app.dart:71-86`

- [ ] **Step 1: Update imports in `app/lib/app.dart`**

Add at the top of the file (next to the other imports):

```dart
import 'package:app/core/i18n/locale_provider.dart';
import 'package:app/l10n/app_localizations.dart';
```

- [ ] **Step 2: Read the locale provider inside `build()`**

Inside `_RunCoachAppState.build()`, after `final router = ref.watch(appRouterProvider);`, add:

```dart
final localeAsync = ref.watch(appLocaleProvider);
final locale = localeAsync.valueOrNull ?? const Locale('en');
```

Using `valueOrNull` + fallback guarantees the first frame has *some* locale even before the async provider resolves (it returns within a frame in practice because `shared_preferences` is fast, but defending against the AsyncValue.loading transient is cheap and correct).

- [ ] **Step 3: Replace the `localizationsDelegates` block**

Change the existing block in `CupertinoApp.router(...)`:

```dart
// BEFORE
localizationsDelegates: const [
  DefaultMaterialLocalizations.delegate,
  DefaultCupertinoLocalizations.delegate,
  DefaultWidgetsLocalizations.delegate,
],
```

to:

```dart
// AFTER
locale: locale,
localizationsDelegates: AppLocalizations.localizationsDelegates,
supportedLocales: AppLocalizations.supportedLocales,
```

`AppLocalizations.localizationsDelegates` already includes the three `GlobalCupertinoLocalizations.delegate`, `GlobalMaterialLocalizations.delegate`, and `GlobalWidgetsLocalizations.delegate` entries (the modern equivalents of `Default*Localizations.delegate`). Replacing the old `Default*` triplet with the new list is correct, not a regression.

- [ ] **Step 4: Run the app to confirm it boots**

Run: `cd app && flutter run` (against the simulator)
Expected: App boots; no console errors about missing locale delegates. The UI is still English (no strings extracted yet).

- [ ] **Step 5: Run analyzer + tests**

Run: `cd app && flutter analyze && flutter test`
Expected: Both pass.

- [ ] **Step 6: Commit**

```bash
cd app && git add lib/app.dart
git commit -m "$(cat <<'EOF'
feat(i18n): wire CupertinoApp with AppLocalizations + locale provider

Replaces the three Default*Localizations.delegate entries with
AppLocalizations.localizationsDelegates (which itself transitively
includes Material/Cupertino/Widgets globals). locale + supportedLocales
flow from appLocaleProvider.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

### Task 12: `LocaleInterceptor` for Dio + push locale changes to backend

**Files:**
- Create: `app/lib/core/api/locale_interceptor.dart`
- Modify: `app/lib/core/api/dio_client.dart:29` (register the interceptor)
- Modify: `app/lib/core/i18n/locale_provider.dart` (call backend on setOverride)
- Test: `app/test/core/api/locale_interceptor_test.dart`

- [ ] **Step 1: Write the interceptor**

Create `app/lib/core/api/locale_interceptor.dart`:

```dart
import 'package:dio/dio.dart';

import 'package:app/core/i18n/current_locale.dart';

/// Adds the `Accept-Language` header to every outgoing request, using
/// the BCP-47 tag held in [currentAppLocaleTag]. The interceptor reads
/// the global on each request, so locale changes propagate immediately
/// without needing to rebuild Dio.
class LocaleInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Accept-Language'] = currentAppLocaleTag;
    super.onRequest(options, handler);
  }
}
```

- [ ] **Step 2: Register the interceptor in `dio_client.dart`**

Open `app/lib/core/api/dio_client.dart`. Find the existing line `dio.interceptors.add(AuthInterceptor(tokenStorage));` (around line 29). Add immediately above it (so Accept-Language is set before Auth runs — the order doesn't actually matter for outgoing, but locale-first reads cleanly):

```dart
dio.interceptors.add(LocaleInterceptor());
```

Also add the import at the top of the file:

```dart
import 'package:app/core/api/locale_interceptor.dart';
```

- [ ] **Step 3: Write the failing test**

Create `app/test/core/api/locale_interceptor_test.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/core/api/locale_interceptor.dart';
import 'package:app/core/i18n/current_locale.dart';

void main() {
  setUp(() {
    currentAppLocaleTag = 'en';
  });

  test('adds Accept-Language header matching currentAppLocaleTag', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(LocaleInterceptor());

    // Capture the headers a real request would have sent without
    // making a network call.
    String? captured;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        captured = options.headers['Accept-Language'] as String?;
        handler.reject(
          DioException(requestOptions: options, message: 'abort'),
        );
      },
    ));

    currentAppLocaleTag = 'nl';
    await dio.get<dynamic>('/ping').catchError((_) => Response(
          requestOptions: RequestOptions(path: '/ping'),
        ));

    expect(captured, 'nl');
  });

  test('reads the latest tag value at request time, not at construct time', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
    dio.interceptors.add(LocaleInterceptor());

    String? captured;
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        captured = options.headers['Accept-Language'] as String?;
        handler.reject(
          DioException(requestOptions: options, message: 'abort'),
        );
      },
    ));

    currentAppLocaleTag = 'en';
    await dio.get<dynamic>('/first').catchError((_) => Response(
          requestOptions: RequestOptions(path: '/first'),
        ));
    expect(captured, 'en');

    currentAppLocaleTag = 'nl';
    await dio.get<dynamic>('/second').catchError((_) => Response(
          requestOptions: RequestOptions(path: '/second'),
        ));
    expect(captured, 'nl');
  });
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd app && flutter test test/core/api/locale_interceptor_test.dart`
Expected: PASS (2 tests).

- [ ] **Step 5: Update `locale_provider.dart` to push override to backend**

We want `setOverride()` to also call `PUT /profile` so the runner's choice survives sign-out + re-install. But provider-to-provider deps need care.

Locate the existing profile-update API service (likely `app/lib/features/profile/services/` or similar — check the codebase). Whatever the existing endpoint client looks like, the new call should match its pattern.

Open `app/lib/core/i18n/locale_provider.dart`. Add a call to push the value after persisting it locally. Modify the `setOverride` method:

```dart
Future<void> setOverride(Locale? locale) async {
  final prefs = await SharedPreferences.getInstance();
  if (locale == null) {
    await prefs.remove(_overrideKey);
    final resolved = detectDeviceLocale();
    _syncSideEffects(resolved);
    state = AsyncData(resolved);
    await _pushToBackend(null);
    return;
  }

  if (!_supported.contains(locale.languageCode)) {
    throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
  }

  await prefs.setString(_overrideKey, locale.languageCode);
  _syncSideEffects(locale);
  state = AsyncData(locale);
  await _pushToBackend(locale.languageCode);
}

Future<void> _pushToBackend(String? localeCode) async {
  try {
    // The exact call depends on the existing profile-update API client.
    // Replace this with the actual provider/service you find in the codebase:
    //
    //   final api = ref.read(profileApiProvider);
    //   await api.updateProfile(locale: localeCode);
    //
    // Make sure the call accepts null as a value (so the user can revert
    // to auto-detection). Match the existing pattern for partial updates.
  } catch (_) {
    // Backend push is best-effort — the local override has already been
    // persisted in shared_preferences and applied to the running app.
    // A failed push will heal on the next manual change or sign-in
    // (where the SetLocale middleware will re-resolve from
    // Accept-Language).
  }
}
```

**Search the codebase first** for the existing profile-update client. If `app/lib/features/auth/services/auth_service.dart` or similar exposes an `updateProfile()` method, use it. Otherwise, find where `PUT /profile` is called elsewhere in the app and copy the pattern. Don't introduce a new Dio call hand-rolled — reuse the existing Retrofit client.

- [ ] **Step 6: Run analyzer + tests**

Run: `cd app && flutter analyze && flutter test`
Expected: PASS.

- [ ] **Step 7: Commit**

```bash
cd app && git add lib/core/api/locale_interceptor.dart lib/core/api/dio_client.dart lib/core/i18n/locale_provider.dart test/core/api/locale_interceptor_test.dart
git commit -m "$(cat <<'EOF'
feat(i18n): Accept-Language Dio interceptor + backend sync

Every outgoing API request now includes Accept-Language matching the
runner's active locale, which the SetLocale middleware reads to set
App::setLocale() server-side. Locale overrides also PUT to /profile
so the runner's choice survives sign-out and re-install.

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Final verification

After all 12 tasks are committed:

- [ ] **Run the full backend test suite**

Run: `cd api && php artisan test --compact`
Expected: All ~295 + new tests pass. Look specifically for failures in tests that pinned English notification copy or `TrainingType` labels (we updated those in Tasks 4 and 5; any test that wasn't updated needs the same treatment).

- [ ] **Run the full Flutter test suite**

Run: `cd app && flutter analyze && flutter test`
Expected: PASS.

- [ ] **Manual smoke test 1 — English path (default)**

1. Reset simulator's language to English (Settings → General → Language & Region → Add Language → English (US), reorder to top, restart simulator).
2. Boot the app fresh (uninstall + reinstall to clear `shared_preferences`).
3. Sign in with Apple.
4. Check `api/storage/logs/laravel.log` for an inbound request with `Accept-Language: en-*` and confirm `users.locale` is `'en'` in the database (`SELECT id, locale FROM users ORDER BY id DESC LIMIT 1`).
5. Trigger a plan generation. The push notification body should be `"Tap to review and accept your plan."` (English).

- [ ] **Manual smoke test 2 — Dutch path**

1. Reset simulator language to Dutch (Settings → General → Language & Region → Add Language → Nederlands, reorder to top, restart).
2. Uninstall + reinstall the app to clear `shared_preferences`.
3. Sign in.
4. Confirm `users.locale = 'nl'` for the freshly-created user.
5. Trigger a plan generation. The push body should be `"Tik om te bekijken en goed te keuren."` (Dutch).
6. Validation error path: hit any endpoint with a missing required field and confirm the error message in the JSON body is Dutch (`"Het veld ... is verplicht."`).

- [ ] **Update `CLAUDE.md` with foundation bullet**

Append a one-line bullet to `CLAUDE.md` under "Current state":

```
- **i18n foundation** — Backend resolves locale per request via `SetLocale` middleware (api/app/Http/Middleware/SetLocale.php) → users.locale > Accept-Language > fallback. Push notifications, TrainingType labels, and validation errors auto-localize via `__()`. Flutter uses official `flutter_localizations` + ARB (lib/l10n/app_{en,nl}.arb), `appLocaleProvider` auto-detects device language (languageCode=='nl' → Dutch, else English), Dio sends Accept-Language header. **String extraction (~700 strings) is Phase 3 — not yet done.** Spec: `docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md`, plan: `docs/superpowers/plans/2026-05-12-i18n-foundation.md`.
```

Also append a one-line bullet to `api/CLAUDE.md` (under wherever the existing "Push notifications" or middleware section is):

```
- **i18n** — `SetLocale` middleware on the `api` group sets `App::setLocale()` + `Carbon::setLocale()` per request (users.locale > Accept-Language > fallback). User model implements `HasLocalePreference` so queue-dispatched notifications auto-respect `$user->locale`. Translation files: `lang/{en,nl}/{validation,notifications,enums}.php`.
```

And to `app/CLAUDE.md`:

```
- **i18n** — Official `flutter_localizations` + `intl` + ARB + `flutter gen-l10n`. Strings live in `lib/l10n/app_{en,nl}.arb`. Active locale held in `appLocaleProvider` (`lib/core/i18n/locale_provider.dart`) — auto-detects from `PlatformDispatcher.instance.locales` matching `languageCode == 'nl'` (intentionally not country-based; see design doc). Override persists in `shared_preferences`. `Accept-Language` is sent on every Dio request via `LocaleInterceptor`. Phase 3 (string extraction) and Phase 4 (agent localization) are separate plans.
```

- [ ] **Commit the CLAUDE.md updates**

```bash
cd /Users/erwin/personal/runcoach && git add CLAUDE.md api/CLAUDE.md app/CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: note i18n foundation in cross-cutting + per-app CLAUDE.md

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Self-review notes (for the executing engineer)

- **TDD discipline:** Each task starts with a failing test (or, for pure-config tasks like ARB setup, a "run and confirm gen-l10n outputs the expected file"). Don't skip the red step — it proves the test actually exercises the code path you think it does.
- **Pint:** After backend changes, `cd api && ./vendor/bin/pint --dirty` to format any modified PHP files.
- **Build runner:** After any change to `@riverpod` / `@freezed` / `@JsonSerializable` annotations, run `dart run build_runner build --delete-conflicting-outputs`.
- **No string extraction yet.** If you find yourself reaching for `context.l10n.someNewKey` to migrate an existing `Text('Hello')`, stop — that's Phase 3. This plan only adds the plumbing.
- **gen-l10n on PR review:** If `app/lib/l10n/app_localizations*.dart` shows diff that wasn't manually edited, that's expected — it's regenerated on every `flutter pub get`. Don't gitignore it; the `synthetic-package: false` directive means it lives in source.
- **Backend smoke test (no Flutter):** You can validate the SetLocale middleware end-to-end with `curl`:
  ```bash
  curl -H "Accept-Language: nl-NL" https://runcoach.test/api/v1/profile -H "Authorization: Bearer <token>"
  ```
  Validation errors should come back in Dutch.

---

## Out-of-scope / follow-up plans

- **Phase 3** — Migrate the ~700 hardcoded Flutter strings to ARB. Estimated 10-14 days. Will get its own plan: `docs/superpowers/plans/YYYY-MM-DD-i18n-flutter-string-extraction.md`. Suggested ordering: `auth` → `onboarding` → `dashboard` → `schedule` → `coach` → `goals` → `organization`. Each feature subdirectory gets its lint escalated from `warning` to `error` once 100% migrated.
- **Phase 4** — Agent localization. Append a single Dutch language directive at the end of each agent's `instructions()`: `RunCoachAgent`, `OnboardingAgent`, `ActivityFeedbackAgent`, `WeeklyInsightAgent`, `PlanExplanationAgent`. Workers that don't run inside an HTTP request need to explicitly `App::setLocale($user->locale)` before dispatching the agent.
- **Settings UI** — Language picker (`English | Nederlands | Use system`) on the menu/profile sheet. Calls `ref.read(appLocaleProvider.notifier).setOverride(...)`. Depends on extracted UI strings (so the picker itself can show in Dutch when active). Ship in Phase 3.
- **AdhocPush / OrganizationInvitation / WorkoutAnalyzed** — Localization deferred pending design review. The `TODO(i18n)` markers in those files are the breadcrumb.
- **Number/date formatting in widgets** — Phase 3 (or whenever those widgets are touched). The infrastructure is ready: `appDateLocale` is now synced from `appLocaleProvider`; widgets just need to switch from `'5.2 km'` to `NumberFormat.decimalPattern(appDateLocale).format(5.2) + ' km'`.

---

Plan complete and saved to `docs/superpowers/plans/2026-05-12-i18n-foundation.md`. Two execution options:

**1. Subagent-Driven (recommended)** — I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** — Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?
