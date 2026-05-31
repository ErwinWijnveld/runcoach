# Geplande plan-evaluaties — implementation plan

**Date**: 2026-05-22
**Status**: ready to start
**Vervangt**: pace-adjustment notificaties (`PaceAdjustmentEvaluator` + `pace_adjustment` UserNotification flow)

## Overview

Vervang de huidige per-run `pace_adjustment` notificatie door **2-wekelijkse evaluatiemomenten** die deterministisch worden ingepland bij plan-generatie en zichtbaar staan in het weekschema. Op de geplande dag draait een cron-job die een AI-rapport opbouwt over de afgelopen 2 weken (runs, gemiste sessies, pace-/HR-trends), en — als er aanpassingen nodig zijn — direct een `EditActivePlan`-proposal aanmaakt via de bestaande `AdjustPlan`-flow. De gebruiker krijgt één push per evaluatie (niet per run), tapt door naar een card die het rapport + voorgestelde aanpassing toont, en accepteert of dismisst in één tap.

Opgesplitst in 6 commits zodat elke commit los testbaar + reviewable is. Backend doet het meeste werk; Flutter krijgt 1 nieuw scherm + nieuwe card-case + één deep-link route.

**Belangrijke ontwerpkeuzes:**
- **Cadans**: einde van elke 2e week (`week_number = 2, 4, 6, ...`). Vast, voorspelbaar.
- **Boundary**: GEEN evaluaties in de taper-window (laatste `TrainingPlanBuilder::TAPER_WEEKS = 3` weken). Dus alleen `week_number ≤ totalWeeks − TAPER_WEEKS`. Voorkomt "gekke evaluaties" vlak voor race-dag waar plan-mutaties juist risicovol zijn.
- **Datum**: zondag-avond van die week (`training_weeks.starts_at + 6 days`).
- **Cron**: dagelijks 19:00 Europe/Amsterdam — runner heeft hun zondag-run gedaan, evaluatie verschijnt 's avonds als "kijk terug" moment.
- **Tabel**: nieuw `plan_evaluations`. NIET de `TrainingType` enum uitbreiden — een evaluatie heeft geen km/pace/HR en zou compliance/optimizer/WorkoutKit-export vervuilen.
- **Proposal-hergebruik**: de evaluatie-agent gebruikt het bestaande `AdjustPlan` tool. Dat produceert al een `CoachProposal` van type `EditActivePlan` met een `diff[]` voor de "PLAN REVISION" UI. Geen tweede accept-pad.

---

## Commit plan

### Commit 1 — Schema + model + plan-builder hook

**Doel**: `plan_evaluations` tabel + model + automatische insert tijdens plan-generatie. Nog geen agent, geen cron, geen UI.

**Files:**
- `api/database/migrations/2026_05_22_XXXXXX_create_plan_evaluations_table.php` (nieuw)
- `api/app/Models/PlanEvaluation.php` (nieuw)
- `api/app/Enums/PlanEvaluationStatus.php` (nieuw) — `Pending`, `Processing`, `Ready`, `Accepted`, `Dismissed`, `NoChangeNeeded`
- `api/app/Services/Onboarding/TrainingPlanBuilder.php` — voeg `scheduleEvaluations()` toe aan het eind van `build()` (zie hieronder)
- `api/database/factories/PlanEvaluationFactory.php` (nieuw)

**Migratie shape:**

```php
Schema::create('plan_evaluations', function (Blueprint $table) {
    $table->id();
    $table->foreignId('user_id')->constrained()->cascadeOnDelete();
    $table->foreignId('goal_id')->constrained()->cascadeOnDelete();
    $table->foreignId('training_week_id')->nullable()->constrained()->nullOnDelete();
    $table->date('scheduled_for'); // zondag van de evaluatie-week
    $table->string('status')->default('pending'); // PlanEvaluationStatus
    $table->text('report_markdown')->nullable();
    $table->foreignId('proposal_id')->nullable()->constrained('coach_proposals')->nullOnDelete();
    $table->foreignId('notification_id')->nullable()->constrained('user_notifications')->nullOnDelete();
    $table->timestamp('triggered_at')->nullable();
    $table->timestamp('completed_at')->nullable();
    $table->timestamps();

    $table->index(['user_id', 'status', 'scheduled_for']);
    $table->index(['scheduled_for', 'status']); // voor de cron-query
});
```

**Plan-builder hook** — in `TrainingPlanBuilder::build()` ná `assembleWeeks()` en vóór de `return`:

```php
$payload['evaluations'] = $this->scheduleEvaluations($payload['schedule']['weeks']);
```

```php
/**
 * Plaats evaluatiemomenten elke 2e week, maar nooit in de taper/race-window.
 *
 * @param  array<int, array<string, mixed>>  $weeks
 * @return array<int, array{week_number: int, scheduled_for: string}>
 */
private function scheduleEvaluations(array $weeks): array
{
    $total = count($weeks);
    $taper = $this->taperLengthForRamp($total); // bestaande helper, 1-3 weken
    $lastEvalWeek = $total - $taper; // exclusief taper

    $evaluations = [];
    foreach ($weeks as $week) {
        $n = $week['week_number'];
        if ($n % 2 !== 0) {
            continue;
        }
        if ($n > $lastEvalWeek) {
            continue; // skip taper + race-week
        }
        // Zondag van die week = starts_at + 6 dagen
        $sunday = CarbonImmutable::parse($week['starts_at'])->addDays(6)->toDateString();
        $evaluations[] = [
            'week_number' => $n,
            'scheduled_for' => $sunday,
        ];
    }

    return $evaluations;
}
```

**Persistentie** — in `ProposalService::applyCreateSchedule()` ná het maken van weken/dagen, loop over `$payload['evaluations']` en maak `PlanEvaluation` rows met `status = pending`, `goal_id = $goal->id`, `training_week_id` opgezocht via `week_number`.

**Edge cases:**
- Plan ≤ 4 weken: `taper = 1`, `lastEvalWeek = 3` of 4. Mogelijk 1 evaluatie (week 2). Mogelijk geen — dat is OK.
- `EditActivePlan` proposal: NIET opnieuw evaluaties inplannen. De bestaande rows blijven, hun `scheduled_for` blijft staan. Alleen `applyCreateSchedule` plant.
- Plan-cancel / goal-cancel: cascade-delete via FK (`onDelete('cascade')` op `goal_id`).

**Tests:** `tests/Feature/Services/Onboarding/TrainingPlanBuilderTest.php`:
- `test_evaluations_are_scheduled_every_other_week`
- `test_evaluations_skip_taper_weeks`
- `test_short_plan_may_have_zero_evaluations`
- `test_evaluations_persist_through_proposal_acceptance` (integratie via `ProposalService`)

---

### Commit 2 — PlanEvaluationAgent + GeneratePlanEvaluation job

**Doel**: kun een evaluatie handmatig draaien (`PlanEvaluation $eval` → `GeneratePlanEvaluation::dispatch($eval)`) en het levert een rapport + (optioneel) proposal op. Nog geen cron, geen notificatie.

**Files:**
- `api/app/Ai/Agents/PlanEvaluationAgent.php` (nieuw)
- `api/app/Jobs/GeneratePlanEvaluation.php` (nieuw)

**Agent shape** — Sonnet, met memory uit (one-shot zoals `WeeklyInsightAgent`) maar mét tools:

```php
class PlanEvaluationAgent
{
    use Promptable;
    use HasTools;

    public function __construct(public User $user) {}

    public function tools(): array
    {
        return [
            new GetRecentRuns($this->user),       // bestaand
            new GetComplianceReport($this->user), // bestaand
            new GetCurrentSchedule($this->user),  // bestaand
            new AdjustPlan($this->user),          // bestaand — produceert EditActivePlan proposal
        ];
    }

    public function instructions(): string
    {
        return <<<PROMPT
        You are evaluating the runner's last 2 weeks of training, mid-plan.

        Step 1. Read context via `get_recent_runs(14)` + `get_compliance_report` + `get_current_schedule`.
        Step 2. Write a SHORT (≤200 words) markdown report covering:
            - Wat ging goed (completed sessions, compliance highlights).
            - Wat ging niet (missed sessions, low compliance, HR/pace drift).
            - Trend (volume up/down vs target, easy pace getting faster/slower).
        Step 3. Decide: aanpassing nodig?
            - JA → roep `adjust_plan` ÉÉN keer aan met gerichte ops (max 5).
              Voorbeelden: bump easy pace omlaag als HR consistent te hoog, add easy day als runner vaak short loopt, replace tempo met threshold als runner herhaald slow tempos doet.
              NIET aanpassen: race-day, dagen in de afgelopen tijd, dagen met een result.
            - NEE → roep `adjust_plan` NIET aan. Return alleen het rapport.

        Output: leg uit wat je hebt aangepast (of niet) in dezelfde markdown, daaronder.
        Schrijf in {$this->locale()}.
        PROMPT . LanguageDirective::current();
    }
}
```

**Job shape:**

```php
class GeneratePlanEvaluation implements ShouldQueue
{
    public function __construct(public PlanEvaluation $evaluation) {}

    public function handle(): void
    {
        $user = $this->evaluation->user;

        if (! $user->isPro()) {
            Log::info('Skipping plan evaluation for non-pro user', ['user_id' => $user->id]);
            return;
        }

        App::setLocale($user->preferredLocale());

        $this->evaluation->update([
            'status' => PlanEvaluationStatus::Processing,
            'triggered_at' => now(),
        ]);

        $response = PlanEvaluationAgent::make($user)->prompt(
            'Evalueer de afgelopen 2 weken en stel zo nodig een aanpassing voor.'
        );

        // Detect proposal die AdjustPlan heeft achtergelaten in dit run-scope
        $proposalId = $this->detectProposalFromToolResults($response);

        $this->evaluation->update([
            'status' => $proposalId
                ? PlanEvaluationStatus::Ready
                : PlanEvaluationStatus::NoChangeNeeded,
            'report_markdown' => $response->text,
            'proposal_id' => $proposalId,
            'completed_at' => now(),
        ]);
    }

    public function failed(Throwable $e): void
    {
        $this->evaluation->update(['status' => PlanEvaluationStatus::Pending]);
        report($e);
    }
}
```

**Belangrijk detail — `detectProposalFromToolResults`:** lijkt op `ProposalService::detectProposalFromConversation` maar voor een single-shot `prompt()`. Lees `$response->toolResults` (Laravel AI SDK heeft deze) en grijp de `proposal_id` uit het laatste `AdjustPlan` resultaat. Helper kan in `ProposalService` worden geplaatst voor herbruik.

**Tests:** `tests/Feature/Jobs/GeneratePlanEvaluationTest.php`:
- `test_no_change_path_records_report_without_proposal`
- `test_change_path_records_report_and_proposal`
- `test_pro_gate_skips_non_pro_users`
- `test_failure_resets_status_to_pending_for_retry`

Test met `PlanEvaluationAgent::fake([...])` — bestaande SDK-mock infrastructuur.

---

### Commit 3 — Scheduled command `plan:run-evaluations` (cron)

**Doel**: automatisch om 19:00 alle pending evaluations triggeren waarvan `scheduled_for ≤ today`.

**Files:**
- `api/app/Console/Commands/RunPlanEvaluations.php` (nieuw)
- `api/routes/console.php` (+5 regels)

**Command:**

```php
class RunPlanEvaluations extends Command
{
    protected $signature = 'plan:run-evaluations {--date= : ISO date to use as "today" for backfill}';

    protected $description = 'Trigger pending plan evaluations whose scheduled date has passed.';

    public function handle(): int
    {
        $today = $this->option('date')
            ? CarbonImmutable::parse($this->option('date'))->toDateString()
            : CarbonImmutable::now(config('app.reminder_timezone'))->toDateString();

        $count = PlanEvaluation::query()
            ->where('status', PlanEvaluationStatus::Pending)
            ->where('scheduled_for', '<=', $today)
            ->whereHas('goal', fn ($q) => $q->where('status', GoalStatus::Active))
            ->get()
            ->each(fn ($eval) => GeneratePlanEvaluation::dispatch($eval))
            ->count();

        $this->info("Dispatched {$count} plan evaluations.");
        return self::SUCCESS;
    }
}
```

**Schedule** in `routes/console.php`:

```php
Schedule::command('plan:run-evaluations')
    ->dailyAt('19:00')
    ->timezone(config('app.reminder_timezone', 'Europe/Amsterdam'))
    ->withoutOverlapping()
    ->onOneServer();
```

**Edge cases:**
- Goal is inactief / completed / cancelled → skip (filter via `whereHas('goal', active)`).
- Job al een keer mislukt → status staat op `Pending` na `failed()` (zie commit 2), cron pikt 'm de volgende dag weer op. Gewenst gedrag.
- Backfill: `php artisan plan:run-evaluations --date=2026-05-15` triggert evaluaties die toen pending waren.

**Tests:** `tests/Feature/Console/RunPlanEvaluationsTest.php`:
- `test_dispatches_jobs_for_due_pending_evaluations`
- `test_skips_evaluations_for_inactive_goals`
- `test_skips_evaluations_already_processed`
- `test_date_option_overrides_today`

---

### Commit 4 — Notificatie + push

**Doel**: na succesvolle evaluatie krijgt de runner één APNs push en één row in de notifications inbox.

**Files:**
- `api/app/Models/UserNotification.php` — voeg `TYPE_PLAN_EVALUATION = 'plan_evaluation'` constant toe
- `api/app/Notifications/PlanEvaluationReady.php` (nieuw) — `ShouldQueue`, `via=[ApnChannel]`, custom payload `{type: 'plan_evaluation', evaluation_id}`
- `api/app/Jobs/GeneratePlanEvaluation.php` — aan het eind van `handle()`: maak `UserNotification` row + dispatch `PlanEvaluationReady`
- `api/app/Http/Controllers/Api/NotificationController.php` — voeg `match` arm voor `TYPE_PLAN_EVALUATION` toe die de geassocieerde `PlanEvaluation` markeert als `Accepted` en de gekoppelde `CoachProposal` accepteert via bestaande `ProposalService`
- `api/lang/{en,nl}/notifications.php` — `plan_evaluation.title` + `.body` keys

**Notification copy** (Dutch):
- Title: "Je 2-weken evaluatie staat klaar"
- Body: "Bekijk wat goed ging en wat we eventueel aanpassen."

**Notification copy** (English):
- Title: "Your 2-week check-in is ready"
- Body: "See what worked and what we'll tune."

**Producent in `GeneratePlanEvaluation::handle()`** — alleen pushen als `status === Ready` OF als we kiezen om ook `NoChangeNeeded` te pushen. **Voorstel: ook pushen bij `NoChangeNeeded`** (anders mist de runner positieve bevestiging dat het plan klopt). Body verschilt:
- `Ready`: "We hebben een aanpassing voorgesteld op basis van je laatste 2 weken."
- `NoChangeNeeded`: "Je plan klopt nog goed — geen aanpassingen nodig."

**Accept route** in `NotificationController::accept`:

```php
match ($notification->type) {
    UserNotification::TYPE_PLAN_EVALUATION => $this->acceptPlanEvaluation($user, $notification),
    default => abort(422, 'Unknown notification type'),
};
```

```php
private function acceptPlanEvaluation(User $user, UserNotification $n): void
{
    $eval = PlanEvaluation::findOrFail($n->action_data['evaluation_id']);
    abort_if($eval->user_id !== $user->id, 403);

    if ($eval->proposal_id) {
        // Hergebruik bestaande proposal-flow
        $proposal = CoachProposal::findOrFail($eval->proposal_id);
        app(ProposalService::class)->apply($proposal);
    }

    $eval->update(['status' => PlanEvaluationStatus::Accepted]);
}
```

Plus een `acceptPlanEvaluation` dismiss-pad: status → `Dismissed`, proposal blijft staan (geen apply). Bestaande `dismiss` endpoint doet dat automatisch via de generieke status-flip — niets extra nodig.

**Tests:** `tests/Feature/Http/NotificationControllerTest.php` (uitbreiden):
- `test_accept_plan_evaluation_applies_proposal_and_marks_accepted`
- `test_accept_plan_evaluation_without_proposal_just_marks_accepted` (NoChangeNeeded pad)
- `test_dismiss_plan_evaluation_does_not_apply_proposal`

---

### Commit 5 — Verwijder pace_adjustment

**Doel**: oude flow weg. Tests blijven groen.

**Backend verwijderen:**
- `api/app/Services/PaceAdjustmentEvaluator.php` (hele file)
- `api/app/Jobs/GenerateActivityFeedback.php:69-73` — de `try { PaceAdjustmentEvaluator::evaluate(...) }` block
- `api/app/Http/Controllers/Api/NotificationController.php:72-101` — `applyPaceAdjustment()` methode + de `TYPE_PACE_ADJUSTMENT` match-arm
- `api/app/Models/UserNotification.php` — constant `TYPE_PACE_ADJUSTMENT`
- `api/tests/Feature/Services/PaceAdjustmentEvaluatorTest.php` (hele file)
- `api/tests/Feature/Http/NotificationControllerTest.php` — pace-adjustment specifieke tests
- `api/tests/Feature/Jobs/GenerateActivityFeedbackTest.php::test_push_still_fires_when_pace_evaluator_throws` — niet meer relevant
- `api/CLAUDE.md` — sectie "Notifications inbox" → "Pace-adjustment producer rules" en "Pace-adjustment specifieke" referenties weg, vervang door verwijzing naar `plan_evaluation` type

**Flutter verwijderen:**
- `app/lib/features/notifications/widgets/notifications_sheet.dart:~247` — switch-case voor `pace_adjustment` + "Edit HR Zones" tertiair
- Eventuele copy-strings in `app/lib/l10n/app_{en,nl}.arb`

**NIET verwijderen** (hergebruikt):
- `user_notifications` tabel en `UserNotification` model — wordt nu door `plan_evaluation` gebruikt
- `NotificationController::accept` / `dismiss` skeleton
- `_NotificationsSheet` en `notificationsProvider` — krijgen alleen een nieuwe card-case in commit 6
- Cold-start "Action required" popup in `app/lib/app.dart` — werkt generiek over alle pending notifications

**Database**: GEEN drop van bestaande `pace_adjustment` rows nodig. Forward-only migration regel staat dat toe — er kunnen prod rows staan. Ofwel:
(a) Eenmalige forward migration die ze als `dismissed` markeert (`UPDATE user_notifications SET status='dismissed' WHERE type='pace_adjustment' AND status='pending'`), OF
(b) Niets doen — ze zijn na deploy onbereikbaar omdat de controller geen `match`-arm meer heeft. Inbox-query filtert op `status=pending` dus ze blijven hangen in de inbox tot dismissed. **Kies (a)** — schoner voor de runner.

**Tests:**
- Run `php artisan test --compact` — alle ~295 tests moeten groen blijven (minus de verwijderde files).
- Run `cd app && flutter analyze && flutter test`.

---

### Commit 6 — Flutter: evaluation card in schedule + notification card + detail screen

**Doel**: evaluatie zichtbaar in week-view, push tap opent rapport+proposal, accept/dismiss werkt.

**Files** (nieuw + aangepast):

#### Schedule UI

- `app/lib/features/schedule/models/training_day.dart` — geen wijziging (evaluaties zijn een aparte entiteit, NIET een TrainingType)
- `app/lib/features/schedule/models/plan_evaluation.dart` (nieuw) — Freezed model
- `app/lib/features/schedule/data/schedule_api.dart` — `GET /schedule/weeks/{week}/evaluations` toevoegen, of beter: `GET /goals/{goal}/evaluations` voor de hele goal in één keer (cachebaar)
- `app/lib/features/schedule/providers/evaluations_provider.dart` (nieuw)
- `app/lib/features/schedule/screens/weekly_plan_screen.dart` — in de week-render, ná de TrainingDay-kaarten, interleave evaluatie-kaarten gesorteerd op `scheduled_for`
- `app/lib/features/schedule/widgets/evaluation_card.dart` (nieuw) — visueel onderscheidend, GEEN gebruik van `TrainingType.color()`:
  - Eyebrow pill "EVALUATIE" of "EVALUATION" in een coach-paars (uit design system)
  - Clipboard / check-list icoon (Cupertino `chart_bar_circle_fill` of vergelijkbaar)
  - Geen km/pace/HR tiles — alleen status:
    - `pending` toekomst: subtitel "Op {date}" grijs
    - `pending` vandaag/verleden: "Wordt opgesteld…" amber + subtle spinner
    - `ready` of `no_change_needed`: "Bekijk je evaluatie" gold CTA
    - `accepted`: "Aanpassing toegepast" met check-icoon, grijs
    - `dismissed`: "Genegeerd" grijs

#### Detail screen

- `app/lib/features/schedule/screens/evaluation_detail_screen.dart` (nieuw)
- Route in `app/lib/core/routing/app_router.dart`: `/schedule/evaluation/:id`
- Inhoud:
  1. Header met "Evaluatie {datum}" + status-pill
  2. Markdown-render van `report_markdown` (gebruik bestaande `flutter_markdown` als die er is, of een eenvoudige paragraaf-splitter)
  3. **Als `proposal_id` gevuld**: render `PlanRevisionContent` widget (bestaat al — `app/lib/features/coach/widgets/plan_revision_content.dart`) met de diff
  4. Bottom CTAs (zelfde white-card / gold-CTA patroon):
     - **Accept**: white card + gold "Toepassen" knop → `POST /notifications/{notification_id}/accept`
     - **Dismiss**: secondaire tekstknop → `POST /notifications/{notification_id}/dismiss`
  5. Als `status === no_change_needed` of `accepted`: alleen "Sluiten" knop

#### Notification card + push routing

- `app/lib/features/notifications/widgets/notifications_sheet.dart` — nieuwe case in `_NotificationCard` voor `type == 'plan_evaluation'`:
  - Eyebrow "Evaluatie"
  - Tap op CTA → push `/schedule/evaluation/{evaluation_id}` (uit `action_data`)
  - GEEN tertiaire "Edit HR Zones" knop — dat was pace-adjustment specifiek
- `app/lib/services/push_service.dart::routeFromPayload` — voeg `'plan_evaluation'` case toe → returnt `/schedule/evaluation/{evaluation_id}`

#### i18n strings

- `app/lib/l10n/app_en.arb` + `app/lib/l10n/app_nl.arb` — nieuwe keys:
  - `evaluationCardEyebrow`
  - `evaluationStatusPending`
  - `evaluationStatusReady`
  - `evaluationStatusNoChange`
  - `evaluationStatusAccepted`
  - `evaluationDetailTitle`
  - `evaluationApplyCta`
  - `evaluationDismissCta`

**Tests:**
- `app/test/features/schedule/widgets/evaluation_card_test.dart` — golden / widget-tests per status
- `app/test/features/schedule/screens/evaluation_detail_screen_test.dart` — markdown render, proposal-aanwezig vs afwezig, CTA-acties

---

## Acceptance criteria

- [ ] Bij een nieuw plan (16 weken, taper=3) worden evaluaties ingepland in week 2, 4, 6, 8, 10, 12 (week 14/15/16 = taper, geen evaluatie)
- [ ] Bij een 6-weken plan (taper=1, build=5) staat er een evaluatie in week 2 en 4 (niet week 6 = race week)
- [ ] Bij een 4-weken plan (taper=1, build=3) staat er max 1 evaluatie (week 2)
- [ ] `plan:run-evaluations` om 19:00 dispatcht jobs voor evaluaties waarvan `scheduled_for ≤ today` EN goal nog actief is
- [ ] Job draait `PlanEvaluationAgent`, schrijft `report_markdown`, koppelt `proposal_id` als de agent `adjust_plan` heeft aangeroepen, status wordt `ready` of `no_change_needed`
- [ ] Runner krijgt 1 push (`plan_evaluation` type) → tap → `/schedule/evaluation/{id}` → ziet rapport + (optioneel) diff + Accept/Dismiss
- [ ] Accept past de `EditActivePlan` proposal toe via bestaande `ProposalService::apply` flow; markeert evaluatie + notificatie
- [ ] Geen `pace_adjustment` notificaties meer worden geproduceerd; eventuele pending oude rows zijn opgeschoond
- [ ] `GenerateActivityFeedback` doet géén pace-evaluatie meer (alleen nog AI feedback opslag + push)
- [ ] Backend test suite groen (`php artisan test --compact`)
- [ ] Flutter `flutter analyze && flutter test` groen

---

## Beslissingen (v1)

1. **Frequentie hardcoded op 2 weken.** Geen `users.evaluation_cadence_weeks` kolom, geen UI toggle. Constante in `TrainingPlanBuilder::scheduleEvaluations()` (`const EVALUATION_EVERY_N_WEEKS = 2`). Als runners later vragen om 1× of 4× per maand → dán configureerbaar maken.

2. **Geen manuele "Evalueer nu" knop.** Coach-chat dekt ad-hoc evaluatievragen al (runner kan letterlijk vragen "kijk eens naar mijn laatste 2 weken"). Bespaart 1 extra endpoint + 1 UI-actie.

3. **Coach-managed clients: filter `AdjustPlan` uit de tools.** In `PlanEvaluationAgent::tools()`:

   ```php
   public function tools(): array
   {
       $tools = [
           new GetRecentRuns($this->user),
           new GetComplianceReport($this->user),
           new GetCurrentSchedule($this->user),
       ];

       if ($this->user->planMutationsAllowed()) {
           $tools[] = new AdjustPlan($this->user);
       }

       return $tools;
   }
   ```

   Voor coach-managed clients kan de agent dus geen proposal produceren → status wordt altijd `NoChangeNeeded`, push komt met "rapport klaar" body. De coach ziet ze later in het admin-panel (out of scope v1, kan gewoon via Filament resource later). Eén regel code, hergebruikt bestaande gate.

4. **Push-timing 19:00 lokale tijd.** Zoals gepland. Runners die ná 19:00 nog rennen krijgen die data pas mee bij de volgende cyclus — acceptabel; alternatief (per-user timezone scheduling) is veel meer code voor marginale winst.
