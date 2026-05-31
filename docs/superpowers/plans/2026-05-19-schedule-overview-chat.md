# Schedule Overview pop-up chat (week-scoped, RunCoachAgent)

**Date**: 2026-05-19
**Spec basis**: dit document (geen aparte spec — feature is klein genoeg)
**Author**: discussie met user

## Goal

Voeg een pop-up chat toe aan de Schedule Overview (`/schedule`), gemodelleerd op de bestaande `WorkoutChatSheet`. Verschil met workout chat:

- Gebruikt de **bestaande** `RunCoachAgent` (geen aparte agent zoals `WorkoutAgent`)
- Krijgt als context de week die de gebruiker op dat moment in de slider bekijkt
- De conversatie wordt opgeslagen en verschijnt in de normale chatlijst, en is daarna gewoon te openen op `/coach/chat/{id}` met de week-context nog steeds intact

## Scope

### In scope
- Nieuwe `ScheduleWeekChatSheet` (Flutter) die opent vanaf de bestaande floating `CoachPromptBar` op `/schedule`
- Pill bovenaan input ("Bekijkt week 3 · 12 – 18 mei" / "Viewing week 3 · May 12 – May 18"), altijd zichtbaar, geen ✕
- Week wordt vastgesteld op het moment dat de sheet opent (de zichtbare week uit `_WeekPages`)
- Backend: lichte uitbreiding van `RunCoachAgent` zodat het subject-binding `training_week` herkent en de week-context in de system prompt bakt
- Conversatie verschijnt in `GET /coach/conversations` (de normale chats-lijst) en is heropenbaar
- i18n strings voor pill, chat-titel, en de empty-state suggestion(s) van de sheet

### Out of scope
- Andere "context-bronnen" (bv. een day-scoped chat vanaf calendar, een goal-scoped chat). Architectuur staat het toe (zelfde subject-binding pattern) maar implementatie is alleen voor `training_week`
- Wijziging van `WorkoutChatSheet` of `WorkoutAgent`
- Wijziging van de chat-lijst UI zelf (alleen dat de nieuwe conversaties er in landen)
- Tools / proposals — `RunCoachAgent` houdt z'n volledige toolset; de week-context is puur prompt-injectie

## Architecturele keuze

We hebben drie opties overwogen:

| Optie | Mechanisme | Verdict |
|---|---|---|
| A | Seed-message via bestaande `startNewCoachChat(seedMessage:)` als zichtbare eerste user-message | Voelt vies — gebruiker ziet een bericht dat ze niet getypt hebben in hun chat-historie |
| B | Subject-binding `agent_conversations.subject_type='training_week'` + `RunCoachAgent::instructions()` bakt context in system prompt | **Gekozen** — schoon, identiek pattern als `WorkoutAgent`, context persistent over heropenen, geen vervuilde berichten-historie |
| C | Een `week_context` JSON-kolom op `agent_conversations` | Te specifiek, schaalt niet naar andere context-types |

**Conclusie: optie B.** We hergebruiken het exact pattern van `WorkoutAgent::resolveDay()` + `buildDayContext()`, maar dan voor `TrainingWeek` in `RunCoachAgent`.

### Voordelen
- Conversatie verschijnt in normale chats-lijst zonder filtering-aanpassingen aan de backend (de lijst-query filtert vermoedelijk al op user-id, niet op subject-type — zie open vraag 1)
- Bij heropenen via `/coach/chat/{id}` heeft de agent de week-context nog steeds (system prompt wordt elke turn gegenereerd)
- Conversatie is óók continueerbaar met andere tools (`CreateSchedule`, `EditSchedule`, etc.) — het is een gewone RunCoachAgent-chat met extra prompt-context

### Risico's
- Anthropic prompt-cache wordt per-conversatie minder gedeeld (elke week-context-conversatie heeft een unieke system prompt). Acceptabel: cache wordt nog steeds binnen één conversatie hergebruikt voor turn 2+.

## UX

### Trigger
- Op `/schedule` blijft de floating `CoachPromptBar.navigateAnimated` zichtbaar
- Tap op de prompt-bar opent niet langer een nieuwe chat-screen, maar `ScheduleWeekChatSheet.show(context, currentWeek)`
- De huidige `_WeekPages._currentPage` wordt omhoog gelift naar `WeeklyPlanScreen` zodat de tap-handler weet welke week zichtbaar is

### De sheet zelf (parallel aan `WorkoutChatSheet`)
- `BackdropFilter` blur + slide-up modal (85% screen height, border radius 28, collapse op keyboard zoals workout sheet)
- Bovenin: handle bar + sluit-knop (X rechtsboven, zelfde positie als workout sheet)
- Onder de handle bar: de **week-pill**
  - Tekst: `context.l10n.scheduleChatViewingWeek(weekNumber: 3, dateRange: "12 – 18 mei")`
  - Style: pill (border-radius 999), `AppColors.secondary`-tinted (lichtgouden achtergrond, donkere tekst) of `AppColors.surfaceVariant` — afhankelijk van wat past bij de chat sheet (controleren bij implementatie)
  - Altijd zichtbaar, geen sluit-knop
  - Niet-tappable (puur informatief)
- Daaronder: `CoachChatView` (zelfde widget als in workout sheet en in `/coach/chat/{id}`)

### Eerste opening van de sheet (lege conversatie)
- De conversatie wordt **niet** direct aangemaakt — wachten tot de gebruiker het eerste bericht stuurt (zoals workout chat)
- Sheet toont een empty state met 1–3 voorgestelde vragen (geïntern-aliseerd, vergelijkbaar met `scheduleCoachSuggestions(context.l10n)` maar week-specifiek)

### Bij eerste send
- Flutter doet `POST /coach/conversations` met body `{ title: <i18n>, subject_type: 'training_week', subject_id: <week.id> }`
- Conversation-id (UUID) terug, daarna `POST /coach/conversations/{id}/messages` (SSE-stream zoals normaal)
- De sheet blijft open, bericht streamt in

### Heropenen
Gebruiker tapt prompt-bar nog eens met dezelfde week → **bestaande conversatie heropenen** (zelfde pattern als `WorkoutChatSheet` per `training_day_id`). De sheet doet bij open eerst `GET /coach/conversations?subject_type=training_week&subject_id={week.id}` (of dedicated endpoint, zie backend-sectie); als er één is, laad bestaande messages; als er geen is, lazy-create bij eerste send.

Bijgevolg: één conversatie per `(user, training_week_id)`-paar. Wisselt de gebruiker van zichtbare week en opent dan de sheet, dan is dat een andere week → andere conversatie.

## Backend changes

### 0. Lookup endpoint — find existing week-chat

Naast `POST /coach/conversations` willen we een lookup voor "bestaat er al een chat voor deze week?":

- **Optie A**: `GET /coach/conversations?subject_type=training_week&subject_id={id}` — generieke query-filter op de bestaande list-endpoint, returnt array (max 1 verwacht). Vereist controller-aanpassing om filter-params te accepteren.
- **Optie B**: `GET /schedule/weeks/{week}/chat` — dedicated endpoint, returnt `{ id }` of `null`, parallel aan workout-chat's `GET /workout-chat/{dayId}`.

**Keuze: Optie B** (consistent met workout-chat pattern, geen filter-logica in de generieke list-endpoint). Endpoint controleert ownership van de week, returnt UUID of `null`.

### 1. `api/app/Ai/Agents/RunCoachAgent.php`

Voeg een `resolveTrainingWeekContext()` toe (analoog aan `WorkoutAgent::resolveDay()`) en injecteer de output in `coachInstructions()`.

**Wijzigingen:**

```php
// pseudo — niet finale code
public function instructions(): string
{
    $base = $this->coachInstructions();
    $weekContext = $this->resolveTrainingWeekContext();

    return $weekContext
        ? $base . "\n\n## Current view context\n" . $weekContext
        : $base;
}

private function resolveTrainingWeekContext(): ?string
{
    $conversation = $this->currentConversation(); // via RemembersConversations
    if ($conversation?->subject_type !== 'training_week') return null;

    $week = TrainingWeek::with(['goal', 'trainingDays.result'])
        ->find($conversation->subject_id);

    if (!$week) return null;

    return $this->buildWeekContext($week);
}

private function buildWeekContext(TrainingWeek $week): string
{
    // - Week number + date range
    // - Goal title + race date
    // - Total km voor de week + focus + coach_notes
    // - Per dag: date, day-of-week, type, target km/pace/HR zone, status, completed compliance scores indien aanwezig
    // - Ingestie status: hoeveel dagen voltooid / gemist
}
```

**Reden voor `## Current view context` als sectie-titel:** geeft de agent een impliciet handvat ("user is asking in the context of week 3") zonder dat de agent de andere weken vergeet — de tools (`GetCurrentSchedule`) blijven gewoon werken voor cross-week vragen.

### 2. `api/app/Http/Controllers/Api/CoachController.php` (of de conversation-create endpoint)

`POST /coach/conversations` body uitbreiden met optionele `subject_type` + `subject_id` (validatie: alleen `'training_week'` toegestaan voor nu, en `subject_id` moet bestaan + tot de auth-user behoren).

```php
// Form request rule sketch
'subject_type' => ['sometimes', 'string', Rule::in(['training_week'])],
'subject_id'   => ['required_with:subject_type', 'integer'],
// + custom: training_week.id moet bij user horen via goal.user_id
```

Bij create: doorzetten naar de Laravel AI SDK conversation-creator (die `subject_type`/`subject_id` nativief opslaat op `agent_conversations`).

### 3. `api/app/Http/Controllers/Api/CoachController.php` — list endpoint

`GET /coach/conversations` moet:
- ✅ Tonen: conversaties zonder `subject_type` (gewone coach-chats vanuit `/coach`-tab)
- ✅ Tonen: `subject_type='training_week'` (schedule-overview chats)
- ❌ NIET tonen: `subject_type='training_day'` (workout-chats blijven in hun eigen sheet)

Concreet: scope wordt `whereNull('subject_type')->orWhere('subject_type', 'training_week')` (of equivalent). Tests dekken alle drie de gevallen.

### 4. Tests

- `api/tests/Feature/Ai/RunCoachAgentWeekContextTest.php` (nieuw)
  - Maak een goal + training_week voor user → start conversatie met `subject_type='training_week'` → assert dat de system prompt de week-info bevat
  - Assert dat zonder subject de coachInstructions ongewijzigd blijven (geen lege `## Current view context` sectie)
- `api/tests/Feature/Api/CoachConversationsControllerTest.php` (bestaand uitbreiden)
  - Conversation create met geldige `training_week` subject → 201 + binding gepersisteerd
  - Conversation create met andermans training_week → 403/422
  - List bevat de week-bound conversation

## Flutter changes

### 1. `app/lib/features/coach/widgets/coach_chat_view.dart` (bestaand)

Mogelijk een optionele `header` prop toevoegen voor de pill (te bevestigen — wellicht zit het beter in de sheet wrapper). **Beslissing tijdens implementatie**: als de huidige `CoachChatView` flexibel genoeg is via `Column { pill, CoachChatView }` in de sheet zelf, niets aanpassen.

### 2. `app/lib/features/schedule/widgets/schedule_week_chat_sheet.dart` (**nieuw**)

Parallel aan `workout_chat_sheet.dart`. Receives een `TrainingWeek` instance, rendert:
- Backdrop + modal (kopiëren van `WorkoutChatSheet`)
- Header bar (handle + sluit-knop)
- Week-pill widget
- `CoachChatView` met `conversationId` (UUID die de sheet ophaalt of aanmaakt)

Public API: `ScheduleWeekChatSheet.show(BuildContext context, TrainingWeek week)`.

**Open-flow:**
1. Bij open: `GET /schedule/weeks/{week.id}/chat` → `{ id }` of `null`
2. Indien `id` → laad bestaande messages via `GET /coach/conversations/{id}/messages` (bestaande endpoint), toon in `CoachChatView`
3. Indien `null` → toon empty state met week-specifieke suggestions; pas op eerste send wordt `POST /coach/conversations { title, subject_type: 'training_week', subject_id: week.id }` aangeroepen, daarna meteen `POST /coach/conversations/{id}/messages` met de user-tekst

### 3. `app/lib/features/schedule/widgets/schedule_week_context_pill.dart` (**nieuw**)

Kleine stateless widget:
- Props: `int weekNumber`, `String startsAtIso`
- Berekent `endsAt = startsAt + 6 days` (TrainingWeek heeft alleen `startsAt`)
- Formatteert met `intl.DateFormat`, locale = `Localizations.localeOf(context)`
  - NL: `"12 – 18 mei"` (zelfde maand) of `"30 apr – 6 mei"` (cross-month)
  - EN: `"May 12 – 18"` / `"Apr 30 – May 6"`
- Tekst: `context.l10n.scheduleChatViewingWeek(weekNumber, dateRange)`
- Style: **neutraal** — `Container` met `BorderRadius.circular(999)`, padding 6/12, achtergrond `AppColors.surfaceVariant` (of de neutrale equivalent in het design-system — controleren bij implementatie), tekst `AppColors.textSecondary`, font 12-13 medium. Geen goud, geen accent

### 4. `app/lib/features/schedule/screens/weekly_plan_screen.dart`

- `_WeekPages` krijgt een `ValueChanged<int> onWeekChanged` callback
- `WeeklyPlanScreen` houdt zelf `int _currentWeekIndex` bij (lifted state), default = `_initialWeekIndex(weeks)`
- De floating `CoachPromptBar.navigateAnimated` `onTap` verandert van `() => startNewCoachChat(context, ref)` naar `() => ScheduleWeekChatSheet.show(context, weeks[_currentWeekIndex])`

Concreet diff-gebied (rond `weekly_plan_screen.dart:78-92` en `:178-230`).

### 5. `app/lib/features/coach/data/coach_api.dart`

`createConversation()` body uitbreiden zodat er optioneel `subject_type` + `subject_id` meegestuurd worden. Bestaande callers (Coach-tab nieuwe chat) blijven werken zonder.

### 6. `app/lib/l10n/app_en.arb` + `app/lib/l10n/app_nl.arb`

Toe te voegen strings:

```json
"scheduleChatViewingWeek": "Viewing week {weekNumber} · {dateRange}",
"@scheduleChatViewingWeek": {
  "placeholders": {
    "weekNumber": { "type": "int" },
    "dateRange": { "type": "String" }
  }
},
"scheduleChatTitle": "Week {weekNumber} ({dateRange})",
"@scheduleChatTitle": {
  "description": "Conversation title shown in the chats list",
  "placeholders": {
    "weekNumber": { "type": "int" },
    "dateRange": { "type": "String" }
  }
},
"scheduleChatEmptyHint": "Ask anything about this week — pace, intensity, swaps, recovery, …"
```

NL-tegenhangers:

```json
"scheduleChatViewingWeek": "Bekijkt week {weekNumber} · {dateRange}",
"scheduleChatTitle": "Week {weekNumber} ({dateRange})",
"scheduleChatEmptyHint": "Vraag wat je wilt over deze week — tempo, intensiteit, swaps, herstel, …"
```

**Suggestions zijn dynamisch, niet uit ARB.** Zie volgende sectie.

### 6b. Dynamische suggestions op basis van de huidige week

Suggesties worden op de client gegenereerd via een nieuwe helper `weekChatSuggestions(AppLocalizations l10n, TrainingWeek week)` (in bv. `app/lib/features/schedule/utils/week_chat_suggestions.dart`):

- Inspecteer `week.trainingDays` om context op te bouwen:
  - Bevat de week een **interval-sessie**? → suggestie "How should I pace the intervals on {dayname}?" / "Hoe moet ik de intervals op {dag} lopen?"
  - Bevat de week een **long run** (langste run-type)? → "How should I pace Sunday's long run?" / "Hoe loop ik de long run op {dag}?"
  - Is het een **deload-week** (`focus` bevat 'deload'/'recovery', of total_km < vorige week × 0.8)? → "Why is this week lighter?" / "Waarom is deze week rustiger?"
  - **Race-week** (bevat dag met `type='race'`)? → "What should I do the day before the race?" / "Wat doe ik de dag voor mijn race?"
  - Anders (default zware week): → "Is this week too hard for me?" / "Is deze week te zwaar voor mij?"
- Helper returnt max 3 suggesties, in de juiste taal via `l10n.weekChatSuggestion*` keys (die wél in ARB staan — alleen de selectie-logica is dynamisch)

ARB keys voor de suggesties:

```json
"weekChatSuggestionIntervalPace": "How should I pace the intervals on {dayName}?",
"weekChatSuggestionLongRunPace": "How should I pace the long run on {dayName}?",
"weekChatSuggestionDeloadWhy": "Why is this week lighter?",
"weekChatSuggestionRaceDayPrep": "What should I do the day before the race?",
"weekChatSuggestionTooHard": "Is this week too hard for me?",
"weekChatSuggestionSwapInterval": "Can we swap an interval for a long run?"
```

Idem NL. Placeholder `dayName` wordt voor-geformatteerd door de client via `intl.DateFormat.EEEE(locale)`.

Na toevoegen: `flutter gen-l10n` (of `flutter pub get`) regenereert `AppLocalizations`.

### 7. Tests (Flutter)

- `app/test/features/schedule/widgets/schedule_week_context_pill_test.dart` (nieuw) — render-test met NL + EN locale, assert datumformaat en cross-month edge case
- `app/test/features/schedule/screens/weekly_plan_screen_test.dart` (bestaand uitbreiden) — golden test op nieuwe tap-handler is niet nodig; minimaal: assert dat `_currentWeekIndex` mee verandert bij pageview swipe

(Flutter heeft beperkte provider-tests; geen integratietest voor de sheet zelf nodig — die wordt visueel getest op iPhone)

## i18n / locale

- Pill, chat-titel, empty hint en suggestion-chips komen allemaal uit ARB
- Datumformaat via `intl.DateFormat.MMMd(locale)` — geen handmatig mapping
- Backend system prompt blijft Engels (de gewone `RunCoachAgent` doet dat ook); `LanguageDirective::current()` zorgt dat de agent ANTWOORDT in de juiste taal

## Resolved decisions

1. ✅ **Conversations-list filter** — toont alleen `subject_type IS NULL` + `subject_type='training_week'`. `training_day` (workout-chats) blijven exclusief in hun eigen sheet.
2. ✅ **Chat-titel format** — `"Week 3 (12-18 mei)"` / `"Week 3 (May 12 – 18)"`, dezelfde datum-range als in de pill.
3. ✅ **Hergebruik bestaande week-conversatie** — één conversatie per `(user, training_week_id)`. Bij heropening van de sheet voor dezelfde week wordt de bestaande conversatie geladen. Lookup via nieuwe `GET /schedule/weeks/{week}/chat` endpoint.
4. ✅ **Pill style** — neutraal (`surfaceVariant`-achtig), geen accent.
5. ✅ **Suggestions** — dynamisch op basis van de week (intervals/long run/deload/race-week). Selectie-logica client-side; tekst-templates in ARB.

## Test plan (manueel, op device)

1. Open app NL-locale, ga naar `/schedule`
2. Slidet naar week 3
3. Tap floating prompt-bar → sheet opent met neutrale pill "Bekijkt week 3 · 12 – 18 mei"
4. Sheet toont 1-3 dynamische suggesties op basis van week 3 (bv. long run/intervals)
5. Verstuur "Is deze week te zwaar?" → agent antwoordt met referentie naar specifieke dagen van week 3
6. Sluit sheet (X) → terug op `/schedule` zonder navigatie-stack-vervuiling
7. Tap dezelfde prompt-bar nog eens op week 3 → **bestaande** conversatie laadt opnieuw, vorige berichten zichtbaar
8. Slidet naar week 4 → tap prompt-bar → **nieuwe** lege conversatie (andere week-id)
9. Ga naar `/coach` → beide nieuwe conversaties staan in lijst met titels `"Week 3 (12-18 mei)"` en `"Week 4 (19-25 mei)"`
10. Open een training-day → tap WorkoutChatSheet → die conversatie verschijnt **niet** in `/coach` lijst (filter werkt)
11. Tap een week-chat-conversatie in `/coach` → opent `/coach/chat/{id}` → stuur "En week 5 dan?" → agent kan via `GetCurrentSchedule` tool ook andere weken inzien (cross-week werkt)
12. Switch app naar EN-locale → herhaal 1-5, controleer pill, titel en suggesties in EN
13. Cross-month edge case: open de week die 30 apr → 6 mei loopt, check pill datumformaat (`"30 apr – 6 mei"` / `"Apr 30 – May 6"`)
14. Race-week edge case: open de week met race-dag → suggestion "Wat doe ik de dag voor mijn race?" verschijnt
15. Deload-week edge case: open een week met `focus` "deload"/"recovery" → suggestion "Waarom is deze week rustiger?" verschijnt
16. Backend tests: `cd api && php artisan test --filter=RunCoachAgentWeekContextTest` + `--filter=WeekChatLookupTest`
17. Flutter analyze: `cd app && flutter analyze && flutter test`

## Deferred / niet nu

- Day-scoped chat vanaf de calendar-detail-screen (alternative entry point, niet nu)
- Multi-week selectie (gebruiker wil "kijken naar weken 3-5") — niet nu
- Pre-cached suggestions per week-type — polish
- Voice input in de sheet — out of scope, app-wide niet ondersteund

## Commit plan

1. Backend: subject-binding validatie op `POST /coach/conversations` + `GET /schedule/weeks/{week}/chat` lookup endpoint + list-filter (`subject_type IS NULL OR 'training_week'`) + tests → 1 commit
2. Backend: `RunCoachAgent` week-context injectie + tests → 1 commit
3. Flutter: i18n strings (pill, titel, suggesties) + pill widget + suggestions helper → 1 commit
4. Flutter: `ScheduleWeekChatSheet` + state-lift in `WeeklyPlanScreen` + coachApi uitbreiding → 1 commit
5. CLAUDE.md bullet aan `./CLAUDE.md` toevoegen onder "Current state" → samen met commit 4

Geen push, geen iOS build — wachten op expliciete instructie zoals altijd.
