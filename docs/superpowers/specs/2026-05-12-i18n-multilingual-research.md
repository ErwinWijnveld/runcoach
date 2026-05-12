# Multi-language Support — Research & Recommendations

**Goal:** Introduce Dutch as a second language alongside English. iOS users whose device language is Dutch get the Dutch app automatically; everyone else stays in English. Architect for additional languages later without re-doing the foundation.

This document is the research + recommendation phase. It does not yet specify exact file diffs — that lives in a follow-up implementation plan once the decisions below are confirmed.

---

## 1. TL;DR — proposed stack

| Layer | Recommendation | Reason |
|---|---|---|
| **Flutter UI strings** | Official `flutter_localizations` (SDK) + `intl` + ARB + `flutter gen-l10n` | Bus factor ∞ (Google maintains as part of the Flutter SDK); ARB is an open spec with first-class support on every translation tool; type-safe codegen via `nullable-getter: false` + `context.l10n` extension; preserves option value (slang can natively read ARB if we ever want to switch) |
| **Flutter locale detection** | `PlatformDispatcher.instance.locales` → match `languageCode == 'nl'`, fall back to `en` | Aligns with iOS Settings → Language & Region; ignores country code intentionally (more accurate than country-based — see §4) |
| **Flutter persistence + override** | Riverpod `localeProvider` backed by `shared_preferences`; Settings → Language picker (EN / NL / Use system) | Override is needed for user agency and QA; `shared_preferences` is fine (not a secret) |
| **Laravel locale resolution** | Custom `SetLocale` middleware on `api` group: `users.locale` → `Accept-Language` → `app.fallback_locale` | Trivial (~20 lines), avoids `mcamara/laravel-localization` (URL-prefix model, doesn't fit an API) |
| **Laravel translation files** | `lang/en/*.php` and `lang/nl/*.php` per topic (`validation`, `notifications`, `enums`) | Conventional, plays with `__()`, fits the small server-side text surface |
| **`users.locale` column** | New nullable VARCHAR(8), default `null` (resolved per-request when null) | Required so queue workers (push notifications, plan-generation, weekly-insight) know the language outside an HTTP request |
| **LLM agent output (Anthropic)** | Keep system prompts & tool descriptions in English. Append a single language directive: *"Respond to the user in Dutch (Nederlands), idiomatic, native-coach voice. Keep HR/km/VO2max/proper nouns as-is."* | Preserves prompt-cache hits, single source of truth for behavior, Anthropic benchmarks Dutch ~97% of English on Sonnet-class models |
| **Agent tool outputs that surface to UI** | Emit stable enum keys (`workout_type: "easy_run"`); translate client-side via `AppLocalizations` | LLM output isn't string-stable ("Easy Run" vs "Easy run"); enum keys + client translation is robust |
| **Date / number / distance formatting** | `DateFormat`/`NumberFormat` from `intl` with `'nl_NL'` and `'nl_BE'` locales; Carbon `setLocale()` server-side | Already partly wired (`appDateLocale` exists in `core/utils/date_formatter.dart`); only thing that meaningfully changes for NL is `,` vs `.` decimal separator |
| **Push notifications** | Server-rendered bodies via `__()`, locale read from `users.locale` | LLM-flavored copy + bursty schedule changes make `loc-key` not worth it for two locales |

---

## 2. Current state — what's there to translate

**Findings from two parallel codebase inspections; full details in the appendix.**

### Flutter (`app/`)

- **Zero localization infrastructure** today. `pubspec.yaml` already has `intl: ^0.20.2` (for `DateFormat`/`NumberFormat`) but no `flutter_localizations`, no `l10n.yaml`, no delegates beyond the three `Default…Localizations.delegate` in `lib/app.dart:71-86`.
- **~550–750 hardcoded English strings** spread across **18 screens** in 7 feature folders. Onboarding alone is ~150–200 strings (form is 1,800+ lines, 12 steps). Coach + dashboard + schedule together are another ~200.
- **No string extraction**. Every literal is inline: `Text('Easy runs')`. The only structured copy lives in `_dayNames` const arrays (`weekly_plan_screen.dart:598`) and `switch` statements for enum labels (`onboarding_form_screen.dart:1650-1671`).
- **Date scaffolding is half-built**: `appDateLocale` global in `core/utils/date_formatter.dart:9` is hardcoded to `'en'` with a comment noting it's the hook for future locale switching. `initializeDateFormatting(appDateLocale)` is already called in `main.dart:12`. Switching it to `'nl'` is a one-line change.
- **Backend-provided text** lives in: `CoachMessage.content`, `CoachProposal.payload`, `TrainingDay.title/description`, `TrainingResult.aiFeedback`, `UserNotification.title/body`. These cannot be translated client-side — they must be generated in the user's language by the backend.

### Laravel (`api/`)

- **Zero localization infrastructure**. `config/app.php` has `'locale' => env('APP_LOCALE', 'en')`, but there's no `lang/` directory, no middleware setting locale, no `Carbon::setLocale` anywhere, and no package like `mcamara/laravel-localization`.
- **User model** (`app/Models/User.php`) has no `locale`/`language` column. Recent migrations added `coach_style`, `intensity_bias`, `date_of_birth`, `heart_rate_zones_source`, `self_reported_*` — locale was never added.
- **Server-side user-facing text surfaces**, ordered by size:
  - `RunCoachAgent::coachInstructions()` — **~400 lines** of English system prompt (`app/Ai/Agents/RunCoachAgent.php:40-150ish`).
  - `OnboardingAgent::instructions()` — ~80 lines.
  - 17 agent tools under `app/Ai/Tools/` with English `description()` + `schema()` parameter docs (~50 lines each = ~850 lines total).
  - `ActivityFeedbackAgent::instructions()` — ~20 lines.
  - `WeeklyInsightAgent::instructions()` — 1 line.
  - 5 notification classes (`PlanGenerationCompleted`, `PlanGenerationFailed`, `TrainingDayReminder`, `BirthdayZoneCheckReminder`, `WorkoutAnalyzed`/`OrganizationInvitation`) — ~100 lines of hard-coded titles/bodies in `toApn()`.
  - `TrainingType::label()` enum — 5 string labels (Easy, Tempo, Intervals, Long run, Threshold).
  - Default Laravel validation messages (currently English from `vendor/laravel/framework`).
- **Filament admin** is isolated and doesn't leak into mobile API responses — out of scope for now.

---

## 3. Recommended approach — detail

### 3.1 Flutter UI strings: official `flutter_localizations` + `intl` + ARB + `flutter gen-l10n`

This is the Flutter team's blessed workflow, built into the SDK. `intl: ^0.20.2` is already in your `pubspec.yaml`. Strings live in `.arb` files (a Google-maintained [open spec](https://github.com/google/app-resource-bundle/wiki/ApplicationResourceBundleSpecification) — JSON + sibling `@key` metadata) and `flutter gen-l10n` auto-generates a typed `AppLocalizations` class on `flutter pub get` / `flutter run`.

```jsonc
// lib/l10n/app_en.arb (template)
{
  "welcomeTitle": "Train smarter, not harder",
  "@welcomeTitle": { "description": "Welcome screen headline" },
  "signInWithApple": "Sign in with Apple",
  "kmRemaining": "{km} km remaining",
  "@kmRemaining": {
    "placeholders": { "km": { "type": "num", "format": "decimalPattern" } }
  }
}
```

```yaml
# l10n.yaml at project root
arb-dir: lib/l10n
template-arb-file: app_en.arb
output-localization-file: app_localizations.dart
nullable-getter: false
synthetic-package: false  # generated code lives in lib/l10n/, version-controlled
```

Usage in widgets with a one-time 5-line `BuildContext` extension (the well-trodden [codewithandrea pattern](https://codewithandrea.com/articles/flutter-localization-build-context-extension/)):

```dart
extension BuildContextL10n on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

// in widget code
Text(context.l10n.welcomeTitle)
Text(context.l10n.kmRemaining(5.2))
```

For non-widget contexts (Riverpod providers, services that build agent prompts or compose notification strings), expose `AppLocalizations` via a Riverpod provider — Andrea Bizzotto's pattern, [documented here](https://codewithandrea.com/articles/app-localizations-outside-widgets-riverpod/). ~20 lines, well-trodden.

**Why this is the right call** (changed from the first draft after follow-up research):

| Robustness criterion | Official | `slang` | `easy_localization` |
|---|---|---|---|
| Bus factor | Google / Dart team | **1 person** (Tien Do Nam) | Sole community maintainer |
| 2026 monthly downloads | **6.18M** (`intl`) | 221k | 211k |
| Last release | continuous via Flutter SDK | 4.14.0 (Mar 2026) | 3.0.8 (Jul 2025) |
| File format | **ARB** — Google's open spec, decade-stable | Bespoke nested JSON | JSON/YAML, package-defined |
| TMS first-class support | Crowdin, Lokalise, Phrase, POEditor, Localizely | Custom mappings | Yes |
| Compile-time key check | Yes | Yes | **No** (runtime only) |
| Compile-time placeholder check | Yes (`context.l10n.foo(x: 1)`) | Yes (`t.foo(x: 1)`) | **No** (`Map<String, String>`) |
| IDE rename refactor | Yes | Yes | No (string literals) |
| Open issues | Triaged in `flutter/flutter`, dozens active | ~35 | **196 open** |
| Migration cost if abandoned | n/a | low-to-moderate (slang reads ARB) | low (JSON, but call-site sweep) |
| **Migration cost FROM official TO slang later** | n/a | **trivial — `dart run slang migrate arb`** | n/a |

The 2023-era ergonomics gap that drove people to `slang` has substantially closed: `nullable-getter: false` drops the `!`, the `BuildContext` extension drops `AppLocalizations.of(context)` to `context.l10n`, and codegen auto-fires on `flutter run`. What's left is ~20% more typing on accessors (`context.l10n.foo` vs `t.foo`) — not a 5-year trade.

The killer argument: **starting with ARB preserves your option value.** Slang reads ARB natively (`dart run slang migrate arb`), so you can adopt slang later if ergonomics ever start mattering. The reverse migration — slang's nested JSON back to flat ARB — requires manually flattening keys and is painful. Choose the format with the most exits.

**Why not `slang`:** Solid package, real production usage (LocalSend, Saber, ReVanced Manager). The single-maintainer bus factor + bespoke file format are the material downsides for a 5-year horizon. If gen-l10n verbosity ever bites, the one-command escape hatch exists.

**Why not `easy_localization`:** No compile-time key checking. `'welcome.hello'.tr()` is a string literal — typos silently fail at runtime, and IDE rename refactors don't touch call sites. With ~700 strings, the regression risk dwarfs the setup savings. 196 open issues and a 9-month release gap aren't helping either.

**File layout.** ARB requires flat per-locale files (one ARB per language), but key naming conventions cover the namespacing need:

```
lib/l10n/
├── app_en.arb              # template
├── app_nl.arb
└── app_localizations.dart  # generated, version-controlled
```

Keys use a `feature_screen_element` convention (`coach_proposalCard_acceptButton`). Long names are fine — the IDE autocompletes them and the generated `AppLocalizations` class makes them discoverable.

**ICU plural support** (`{count, plural, =0{no runs} =1{1 run} other{{count} runs}}`) is built in. The one limitation — nested plurals/selects in a single message — is rare in practice and not blocking for our string set.

**Tooling that earns its keep:**
- [Flutter Intl VS Code extension](https://marketplace.visualstudio.com/items?itemName=localizely.flutter-intl) (Localizely) — syntax highlighting, missing-key detection, side-by-side editing
- [ARB Editor](https://marketplace.visualstudio.com/items?itemName=Google.arb-editor) (official, Google) — validation
- IntelliJ/Android Studio plugin from Localizely

### 3.2 Locale detection — auto + override

**Detection rule (recommend):**

```dart
// pseudocode in localeProvider
final saved = prefs.getString('locale'); // user override
if (saved != null) return Locale(saved);

final preferred = PlatformDispatcher.instance.locales; // ordered, most-preferred first
for (final loc in preferred) {
  if (loc.languageCode.toLowerCase() == 'nl') return const Locale('nl');
}
return const Locale('en');
```

**Why language-code only, not country-code:**

- The user's framing was "Dutch in NL and BE". Country-code matching (`countryCode in {NL, BE}`) sounds right but is actually less accurate:
  - **French-speaking Belgians** (50% of Belgium) set their phone to French. `fr_BE` should give them English, not Dutch. Language-only matching gets this right; country matching gets it wrong.
  - **Dutch-speaking expat in Berlin** with phone set to Dutch (`nl_DE` or `nl` with countryCode missing) should get Dutch. Language-only matching gets this right.
  - **English-speaking Dutch native in Amsterdam** with phone set to English (`en_NL`) should get English (the user explicitly set their language). Language-only matching gets this right.
- Conclusion: the iPhone's *language* signal already encodes user intent. Country code is a regional/formatting signal — useful for `NumberFormat('nl_BE')` vs `NumberFormat('nl_NL')`, but not for choosing between EN and NL UI.

**Override UX:** Settings → Language → [English | Nederlands | Use system]. No first-launch banner ("We've set you to Dutch — change?") — that's noise for the 99% case where detection is correct. The toggle in Settings is discoverable for the 1% who care.

### 3.3 Laravel — middleware + lang files

Custom middleware on the `api` route group:

```php
class SetLocale
{
    private const SUPPORTED = ['en', 'nl'];

    public function handle(Request $request, Closure $next): Response
    {
        $locale = auth()->user()?->locale
            ?? $request->getPreferredLanguage(self::SUPPORTED)
            ?? config('app.fallback_locale');

        App::setLocale($locale);
        Carbon::setLocale($locale);

        return $next($request);
    }
}
```

Resolution order: stored user preference → `Accept-Language` header (Symfony's parser handles `q=` quality factors per BCP-47) → fallback.

**Translation files** follow Laravel convention:

```
api/lang/
├── en/
│   ├── validation.php          # (override the framework defaults)
│   ├── notifications.php       # push titles/bodies
│   ├── enums.php               # TrainingType labels, etc.
│   └── agent.php               # the single Dutch directive snippet
└── nl/
    └── (same files)
```

Access via `__('notifications.training_day.title', ['km' => 5])`. Validation messages auto-localize once `App::setLocale()` runs.

**Skip `mcamara/laravel-localization`** — its model is `/{locale}/url-prefix`, which is wrong for an API and breaks `route:cache`.

### 3.4 LLM agent strategy — the most interesting decision

The four agents (`RunCoachAgent`, `OnboardingAgent`, `ActivityFeedbackAgent`, `WeeklyInsightAgent`) generate the bulk of user-facing copy. They use Anthropic `claude-sonnet-4-6` via `laravel/ai`. We have three options:

1. **English system prompt + trailing language directive (recommended).** The 400-line system prompt and all 17 tool descriptions stay English. At the very end of the prompt we append: *"Respond to the user in Dutch (Nederlands), idiomatic, native-coach voice. Keep proper nouns and acronyms (HR, VO2max, km, 5k, PR) in their original form."* This is composed per-request from `users.locale`.

2. **Full Dutch translation of system prompt + tools.** Doubles the surface area: any prompt edit (and we edit these often — onboarding rules, plan-edit guards, persona tweaks) must be applied in both languages and re-verified. Real risk of cross-language drift.

3. **English prompts, no directive, rely on Claude auto-detecting from user message.** Works when the user types in Dutch, but breaks for proactive assistant turns (onboarding intros, push-triggered messages, plan explanations) where the assistant speaks first. Not robust.

**Why option 1 wins:**

- Anthropic's [multilingual support guidance](https://platform.claude.com/docs/en/build-with-claude/multilingual-support) explicitly recommends "explicitly stating the desired input/output language improves reliability". The directive is the documented pattern.
- Anthropic benchmarks Dutch at ~97% of English MMLU on Sonnet-class models (German is the listed sibling). Quality is not the bottleneck; consistency is.
- The **prompt-cache hit** (`AnthropicPromptCaching` middleware in `api/app/Ai/Support/`) covers system + tools. Keeping those English means one cache lineage per agent, regardless of user locale — important because we already see ~10× input-cost reduction from turn 2 onward.
- Single source of truth for behavior. We tune *what the coach does* in one prompt and *what language it speaks* in one switchable line.

**Tool descriptions stay English.** They're internal API for the LLM's routing decision, not user-facing. Translating them adds noise and may degrade tool-call reliability.

**Tool *return values* that the UI renders** — like `workout_type: "easy_run"` from `BuildPlan` — should be emitted as stable enum keys (already mostly the case: wire format is `easy`, `tempo`, etc.). Translate on the Flutter side via `AppLocalizations` (the same ARB infrastructure that handles UI strings). Asking the LLM to localize these is brittle (output drift between turns).

**Plan day titles** are the tricky middle case. Today the LLM can set `title` on a training day (e.g., "Tempo intervals", "Recovery 5k"), or fall through to `TrainingType::label()`. Options:
- **Option A:** Keep the LLM setting titles in the user's language (the directive ensures Dutch). Acceptable but means the same plan generated twice has different titles each time.
- **Option B:** LLM emits a structured `title_key` (e.g., `tempo_intervals`) + we maintain a translation table client-side. More work, more deterministic.
- **Recommendation:** Start with Option A. Watch for problems. Most users won't switch language mid-plan; if they do, the existing titles just stay in the original language until plan is rebuilt. Defer Option B.

### 3.5 `users.locale` column

```
ALTER TABLE users ADD COLUMN locale VARCHAR(8) NULL AFTER intensity_bias;
```

`NULL` means "resolve from Accept-Language each request". `'nl'` or `'en'` means user has explicitly chosen.

**Why required:** queue workers don't have a request, hence no `Accept-Language` header. `PlanGenerationCompleted::toApn()`, the `WeeklyInsightAgent` daily run, `BirthdayZoneCheckReminder` — all read `$user->locale` to decide which language to use.

**Auto-backfill on first sign-in:** the `AuthController::appleSignIn()` endpoint already runs in an HTTP context. After upserting the user, set `$user->locale = $request->getPreferredLanguage(['en', 'nl'])` if `locale` is null. Future logins respect the existing value (or the user's manual override).

**API endpoint to update:** `PATCH /profile` already exists for other preferences (`coach_style`, `intensity_bias`). Add `locale` to its allowed fields. Flutter's Settings → Language picker calls this.

### 3.6 Distance, dates, numbers

- **Distance:** `NumberFormat.decimalPattern('nl_NL').format(5.2)` → `"5,2"` (vs `"5.2"` in English). Unit `"km"` stays the same. Wrap into a helper `formatKm(double km, Locale locale)`.
- **Dates:** `DateFormat.yMMMMd('nl_NL').format(date)` → `"12 mei 2026"`. The `appDateLocale` global already exists; switch it to read from `localeProvider`.
- **Pace:** `4:30/km` format is the same in both languages — no change.
- **Belgian Dutch:** can use `'nl_BE'` for formatting; output is effectively identical to `nl_NL` for our use cases (decimals, dates). Not worth distinguishing.

### 3.7 Push notifications — server-side localized bodies

Today's 5 notification classes (`app/Notifications/`) hardcode English titles + bodies in `toApn()`. Wrap them in `__()`:

```php
->title(__('notifications.plan_generated.title'))
->body(__('notifications.plan_generated.body'))
```

The dispatching context (queue worker) calls `App::setLocale($user->locale ?? 'en')` before dispatching so `__()` resolves correctly. Spec already notes this is the natural pattern.

**Skip APNs `loc-key`** — requires shipping translations in the iOS bundle's `Localizable.strings`, and a translation hot-fix becomes an App Store release. For 2 locales and ~5 notification types, server-side rendering is simpler.

---

## 4. Scope — what gets localized

| Surface | EN | NL | Owner |
|---|---|---|---|
| Flutter UI strings (~700) | ✅ | ✅ | ARB files (`lib/l10n/app_{en,nl}.arb`) |
| Flutter date/number formatters | ✅ | ✅ | `intl` with locale |
| Laravel validation messages | ✅ | ✅ | `lang/{locale}/validation.php` (publish Laravel defaults + add Dutch) |
| Push notification copy | ✅ | ✅ | `lang/{locale}/notifications.php` |
| `TrainingType::label()` + other enum labels | ✅ | ✅ | `lang/{locale}/enums.php` |
| Coach agent responses (Anthropic) | ✅ | ✅ | Single directive at end of system prompt |
| Onboarding agent responses | ✅ | ✅ | Same directive pattern |
| Activity feedback (LLM-generated) | ✅ | ✅ | Same |
| Weekly insight (LLM-generated) | ✅ | ✅ | Same |
| Plan explanation modal (LLM-generated) | ✅ | ✅ | Same |
| Auto-generated conversation titles | ✅ | ✅ | Same (LLM produces them in user's language) |
| Agent system prompts | EN only | EN only | One source, language directive switches output |
| Agent tool descriptions / schemas | EN only | EN only | Internal LLM-facing, not user-facing |
| Filament admin | EN only | EN only | Out of scope; admin is for us |
| Workout titles set by LLM (`TrainingDay.title`) | written in user's language at generation time | (deferred — see §3.4) |
| Apple Sign-In native dialog | OS-controlled | OS-controlled | iOS handles via device locale |

---

## 5. Phased rollout

I'd suggest 4 phases. Each is independently shippable.

**Phase 1 — Foundation (UI plumbing, no Dutch strings yet)**
- Add `flutter_localizations: { sdk: flutter }` to `pubspec.yaml` (`intl: ^0.20.2` already there)
- Set `flutter: generate: true` in `pubspec.yaml`; create `l10n.yaml` with `nullable-getter: false`, `synthetic-package: false`
- Create `lib/l10n/app_en.arb` + `app_nl.arb` with a handful of seed keys
- Wire `CupertinoApp.router` with `AppLocalizations.localizationsDelegates` + `AppLocalizations.supportedLocales`
- Add `appLocalizationsProvider` (Riverpod) for non-widget access; add `BuildContext` extension `context.l10n`
- Add Riverpod `localeProvider` (auto-detect via `PlatformDispatcher.instance.locales` matching `languageCode == 'nl'`; `shared_preferences` persistence for override)
- Add lint (`hardcoded_strings_lint` at warning level)
- **No user-visible change.** Ship to confirm the plumbing is sound.

**Phase 2 — Backend foundation**
- Add `users.locale` column (migration, default NULL, backfill from Accept-Language on next request)
- Add `SetLocale` middleware on `api` route group
- Publish Laravel's `lang/en/validation.php` so we own it; create `lang/nl/validation.php` (start with key mirror)
- Add `lang/{en,nl}/notifications.php` + refactor 5 notification classes to use `__()`
- Add `lang/{en,nl}/enums.php` + refactor `TrainingType::label()` to use it
- Add `Carbon::setLocale()` in middleware
- Add Dio interceptor in Flutter to send `Accept-Language` header
- Add `PATCH /profile` support for `locale`
- **No user-visible change** because lang files only have English keys; system is locale-aware but always serves English.

**Phase 3 — Flutter string extraction (the bulk of the work)**
- Migrate hardcoded `Text('…')` to `context.l10n.…` feature-by-feature: `auth` → `onboarding` → `dashboard` → `schedule` → `coach` → `goals` → `organization`
- Each feature: add new keys to `app_en.arb` + Dutch translation in `app_nl.arb`; escalate that directory's lint to `error` once 100% migrated
- Order by frequency: onboarding first (highest impact), then dashboard/schedule (daily use), then coach (LLM-heavy so less static UI text), then auxiliary
- Each feature is ~1-2 days of careful work; ~10-14 days total

**Phase 4 — Agent localization**
- Add a `languageDirective(string $locale)` helper that returns the trailing Dutch instruction
- Inject into `RunCoachAgent::instructions()`, `OnboardingAgent::instructions()`, `ActivityFeedbackAgent`, `WeeklyInsightAgent`, `PlanExplanationAgent`
- For queue workers, ensure `App::setLocale($user->locale)` runs before agent dispatch
- Test with `users.locale='nl'`: verify agent replies in Dutch, tool calls still route correctly, plan titles localize, prompt-cache still hits

**Settings UI** can ship any time after Phase 2.

---

## 6. Risks / tradeoffs / edge cases

1. **String count is a fixed cost.** ~700 strings × ~2 minutes per string (extract, translate, verify) = roughly 23 dev-hours for the extraction phase, plus translation time. Native Dutch translation: ideally use a fluent Dutch speaker (Erwin, presumably?). DeepL is a reasonable first pass.

2. **LLM cache fragmentation.** The current `AnthropicPromptCaching` middleware caches based on the system+tools content. Appending the language directive at the *end* of the system prompt means each locale gets its own cache lineage. With 2 languages this is fine (2 cache lineages instead of 1). With 5+ languages we'd want to revisit cache strategy.

3. **Plan-generated titles ("Easy 5k") will mix languages.** A plan created when `locale='en'` then viewed when `locale='nl'` shows English titles. Acceptable for v1; the user can regenerate the plan.

4. **Old conversations.** Existing `agent_conversations` rows have English messages. Switching to NL won't retro-translate them. The agent will continue in Dutch from the next message; visible history stays English. Acceptable.

5. **Apple Sign-In native dialog** is fully controlled by iOS and follows device language — no work needed.

6. **TestFlight users with Dutch language** will get Dutch immediately after the rollout. Worth a note in the release notes.

7. **Belgian users with French phones** will get English. This is by design (§3.2). If we want to support French later, add as a third locale.

8. **`intl` package locale data** is bundled — initialization (`initializeDateFormatting('nl')`) is the only runtime cost.

9. **String length differences.** Dutch is ~20% longer than English on average. Some buttons/labels may overflow. We'll catch these in QA.

10. **HealthKit + WorkoutKit native bridges** don't surface user-visible strings — they only pass data structures. Out of scope.

---

## 7. Decisions I'd like to confirm before writing the implementation plan

1. ~~Confirm Flutter package choice — `slang`?~~ → **Resolved after follow-up research:** official `flutter_localizations` + `intl` + ARB + `flutter gen-l10n`. The 2023-era ergonomics gap that drove people to `slang` has substantially closed (`nullable-getter: false` + `context.l10n` extension). Robustness, TMS compatibility, and option value all favor the official path; `slang` reads ARB natively as an escape hatch if we ever change our minds.

2. **Confirm locale detection rule.** Language-code-only (`nl` → Dutch) as I argued in §3.2, or stricter country-code matching (`nl_NL` or `nl_BE` → Dutch)? My recommendation is language-code-only — it handles Belgian francophones and Dutch expats correctly.

3. **Confirm user override UX.** Settings → Language picker with [English | Nederlands | Use system]? Or auto-detect only, no override? I recommend a picker (lets you QA and gives users agency).

4. **Confirm LLM strategy.** English system prompt + Dutch directive at the end, as in §3.4 option 1? Or do you want a full Dutch translation of the system prompts (option 2)? I strongly recommend option 1.

5. **Confirm phased rollout shape.** Foundation → Backend foundation → Flutter extraction (feature-by-feature) → Agent localization? Or is there a different ordering you'd prefer (e.g., translate one whole feature end-to-end at a time, starting with onboarding)?

6. **Translation source.** Will you provide Dutch translations yourself (native speaker), or want me to draft them with DeepL/manual + you review? The latter is faster but needs your editing pass.

7. **Future languages.** Anything else on the horizon (German? French?) — affects whether to invest in centralized translation tooling (Crowdin, Lokalise) now or stay on raw JSON files for a while. My default is raw files until 3+ languages.

---

## Appendix A — Flutter codebase findings (summary)

- 18 screens, ~700 hardcoded strings. Largest single file: `onboarding_form_screen.dart` (1800+ lines, ~150-200 strings).
- `intl` already a dependency; date formatter has a `appDateLocale = 'en'` hook ready.
- Riverpod state management with code generation; routes via `GoRouter`; theme via `app_theme.dart`.
- API models flowing user-facing text: `CoachMessage`, `CoachProposal`, `TrainingDay`, `TrainingResult`, `UserNotification`, `Conversation`.
- No existing `Locale` / `Platform.localeName` references in the app code (besides the date formatter scaffolding).

## Appendix B — Laravel codebase findings (summary)

- Zero localization in place: no `lang/` directory, no middleware, no Carbon locale, no `users.locale`.
- Server-side user-facing text totals ~700 lines:
  - Agent system prompts (`RunCoachAgent` 400, `OnboardingAgent` 80, `ActivityFeedbackAgent` 20, `WeeklyInsightAgent` 1)
  - 17 tool descriptions + schemas in `app/Ai/Tools/`
  - 5 notification classes
  - `TrainingType::label()` enum (5 labels)
  - Default Laravel validation messages
- `RunCoachAgent` already composes the prompt at runtime (embeds `$today`, `$style`), so adding a language directive is just one more interpolation.
- `AnthropicPromptCaching` middleware (`api/app/Ai/Support/`) caches system+tools — design must preserve cache hits.

## Appendix C — Sources

Flutter / i18n:
- [docs.flutter.dev — Internationalizing Flutter apps](https://docs.flutter.dev/ui/accessibility-and-internationalization/internationalization)
- [pub.dev/packages/slang](https://pub.dev/packages/slang)
- [pub.dev/packages/easy_localization](https://pub.dev/packages/easy_localization)
- [api.flutter.dev — PlatformDispatcher.locale](https://api.flutter.dev/flutter/dart-ui/PlatformDispatcher/locale.html)
- [codewithandrea.com — App Localizations outside widgets with Riverpod](https://codewithandrea.com/articles/app-localizations-outside-widgets-riverpod/)
- [smart-interface-design-patterns.com — Language Selector UX](https://smart-interface-design-patterns.com/articles/language-selector/)

Laravel:
- [laravel.com/docs/13.x/localization](https://laravel.com/docs/13.x/localization)
- [github.com/mcamara/laravel-localization](https://github.com/mcamara/laravel-localization)
- [hamdaouiacademy.com — Multilingual APIs in Laravel](https://hamdaouiacademy.com/blog/handling-multilingual-apis-in-laravel-best-practices-and-use-case)

Anthropic / Claude:
- [platform.claude.com — Multilingual support](https://platform.claude.com/docs/en/build-with-claude/multilingual-support)
- [docs.anthropic.com — Keep Claude in character](https://docs.anthropic.com/en/docs/test-and-evaluate/strengthen-guardrails/keep-claude-in-character)

iOS / APNs:
- [developer.apple.com — Remote Notification Payload](https://developer.apple.com/library/archive/documentation/NetworkingInternet/Conceptual/RemoteNotificationsPG/CreatingtheNotificationPayload.html)
- [MDN — Accept-Language header](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Accept-Language)
