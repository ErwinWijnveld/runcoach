# RevenueCat subscriptions — implementation plan

Spec: `docs/superpowers/specs/2026-05-19-revenuecat-subscriptions.md`

Order matters: dashboard setup first (manual), then backend, then Flutter. Migrations are additive — no `migrate:fresh`.

## Phase 0 — Apple + RevenueCat dashboard (manual)

### Step 1 — App Store Connect: subscription group + SKUs
- [ ] App Store Connect → Apps → RunCoach → Monetization → **Subscriptions** → create group "RunCoach Pro".
- [ ] Add `runcoach_pro_monthly`: 1 month, €9.99 base price.
- [ ] Add `runcoach_pro_yearly`: 1 year, €59.99 base price. Order it above monthly in the group.
- [ ] Per SKU: localized description + display name in `en-US` + `nl-NL`. Upload one marketing screenshot (1024×1024).
- [ ] On `runcoach_pro_yearly` → Introductory Offers → New Subscribers → **7 days free**.
- [ ] Verify Agreements / Tax / Banking all `Active`.

### Step 2 — App Store Connect: reviewer account
- [ ] Users and Access → Add user `apple-review@erwinwijnveld.nl` (or similar) → role: Admin or Developer (whichever the app already uses).
- [ ] Save the password — you paste these credentials into App Review notes on every submission.
- [ ] After backend deploy (Step 13), grant this user a permanent comp entitlement via Filament admin.

### Step 3 — Sandbox tester (optional, for non-TestFlight dev)
- [ ] Users and Access → Sandbox → Testers → create `runcoach-sandbox-1@erwinwijnveld.nl` with a non-real password.
- [ ] On physical iPhone: Settings → App Store → Sandbox Account → sign in.
- [ ] Not needed for TestFlight — TestFlight automatically routes to sandbox with the real Apple ID.

### Step 4 — RevenueCat project setup
- [ ] Create RC project `RunCoach`. Add iOS app with bundle ID `com.erwinwijnveld.runcoach`.
- [ ] Project settings → App Store Connect API → paste same key ID/issuer that `upload-ios.sh` uses (already in `~/.zshrc`).
- [ ] Entitlements → create `pro`.
- [ ] Products → import `runcoach_pro_monthly` + `runcoach_pro_yearly` from ASC → attach both to entitlement `pro`.
- [ ] Offerings → create `default` with `$rc_monthly` + `$rc_annual`. Mark `default` as current.

### Step 5 — RevenueCat: paywall via builder
- [ ] Paywalls tab → New paywall on offering `default`. Start from "Bold" or "Sleek" template (whichever is closest to a two-card vertical layout).
- [ ] Branding: primary color = runcoach-gold (hex from `app/lib/core/theme/...`), background = cream `#FAF8F4`. Upload TTF/OTF font if not Inter/system.
- [ ] Reorder packages: annual on top, monthly below.
- [ ] Annual package → add badge "Bespaar 50%" / `Save 50%`.
- [ ] Localization → add `en-US` + `nl-NL`. Translate headline, sub, CTA, footer, badge. Verify no truncation in either locale.
- [ ] Footer: ToS link (e.g. `https://runcoach.app/terms`), Privacy link (`https://runcoach.app/privacy`), Restore Purchases button (built-in component).
- [ ] Preview on iPhone 16 Pro frame in both locales. Save & publish.

### Step 6 — RevenueCat: webhook + secrets
- [ ] `openssl rand -hex 32` → save as `REVENUECAT_WEBHOOK_SECRET`.
- [ ] Integrations → Webhooks → new endpoint:
  - URL: `https://runcoach.free.laravel.cloud/api/webhooks/revenuecat`
  - Authorization header: the secret you just generated
  - Enable **all** event types
  - Enable "Send sandbox events to webhook"
- [ ] Project settings → API keys → copy **public iOS SDK key** → save as `REVENUECAT_PUBLIC_SDK_KEY`.
- [ ] API keys → create a **secret v2 REST API key** → save as `REVENUECAT_REST_API_KEY`.
- [ ] Project settings → copy **project ID** → save as `REVENUECAT_PROJECT_ID`.

## Phase 1 — Backend

All migrations are **new files** (additive). No `migrate:fresh`.

### Step 7 — Migrations
- [ ] `php artisan make:migration create_subscriptions_table`:
  - `id`, `user_id` fk cascade, `rc_app_user_id` string, `rc_original_app_user_id` string nullable, `product_id` string, `store` string, `status` string, `period_type` string, `purchased_at`, `expires_at` nullable, `cancelled_at` nullable, `environment` string, `raw_attributes` json, timestamps.
  - `unique('user_id')`, `index('expires_at')`.
  - `down()`: `dropIfExists`.
- [ ] `php artisan make:migration create_revenuecat_webhook_events_table`:
  - `id`, `event_id` string, `event_type` string, `app_user_id` string nullable, `payload` json, `processed_at` timestamp nullable, `error` text nullable, `received_at` timestamp.
  - `unique('event_id')`, `index('app_user_id')`, `index('processed_at')`.
  - `down()`: `dropIfExists`.
- [ ] `php artisan make:migration add_pro_entitlement_to_users_table`:
  - `up()`: `Schema::table('users', fn ($t) => $t->timestamp('pro_active_until')->nullable()->index(); $t->string('pro_product_id')->nullable());`
  - `down()`: reverse.
- [ ] `php artisan migrate` (not `migrate:fresh`).

### Step 8 — Eloquent models
- [ ] `api/app/Models/Subscription.php`: fillable, `belongsTo(User::class)`, casts (`expires_at`/`cancelled_at`/`purchased_at` → datetime, `raw_attributes` → array).
- [ ] `api/app/Models/RevenueCatWebhookEvent.php`: fillable, casts (`payload` → array, `processed_at`/`received_at` → datetime).
- [ ] `api/app/Models/User.php`:
  - Add `subscription(): HasOne` to `Subscription`.
  - Add `pro_active_until` → `datetime` to `$casts`.
  - Add `pro_product_id` to fillable + cast list (string is default, just fillable).
  - Add `public function isPro(): bool { return $this->pro_active_until?->isFuture() ?? false; }`.

### Step 9 — Config + env
- [ ] `api/config/services.php` — append:
  ```php
  'revenuecat' => [
      'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
      'rest_api_key'   => env('REVENUECAT_REST_API_KEY'),
      'project_id'     => env('REVENUECAT_PROJECT_ID'),
  ],
  ```
- [ ] `api/.env.example`: add the three vars (empty).
- [ ] Laravel Cloud → Environment: set the three vars to production values from Step 6.
- [ ] Local `api/.env`: set the three vars.

### Step 10 — Webhook controller + job
- [ ] `api/app/Http/Controllers/Webhooks/RevenueCatWebhookController.php`:
  - `__invoke(Request)`:
    - `hash_equals(config('services.revenuecat.webhook_secret'), $request->header('Authorization') ?? '')` → false → `Log::warning('rc webhook bad auth')`, return `response('', 401)`.
    - Validate `event.id` + `event.type` present → missing → 422.
    - `try { RevenueCatWebhookEvent::create([...]) } catch (UniqueConstraintViolationException) { return response('', 200); }`.
    - `ProcessRevenueCatWebhookEvent::dispatch($row->id)`.
    - `response('', 200)`.
- [ ] Route in `api/routes/api.php` (top of file, outside `v1` and `auth:sanctum`):
  ```php
  Route::post('webhooks/revenuecat', RevenueCatWebhookController::class)
      ->middleware('throttle:300,1');
  ```
- [ ] `api/app/Jobs/Subscription/ProcessRevenueCatWebhookEvent.php`:
  - `public int $tries = 5; public array $backoff = [10, 30, 60, 300, 900];`
  - Constructor: `public function __construct(public int $eventId) {}`.
  - `handle()`:
    - Load row; if `processed_at` set, return (idempotent for retries).
    - `$event = $row->payload['event']`; `$type = $event['type']`.
    - Resolve user: `User::find((int) $event['app_user_id'])`. If null and TRANSFER, try `original_app_user_id`. If still null + not TRANSFER → log warning, mark processed, return.
    - Switch on `$type`:
      - `INITIAL_PURCHASE | RENEWAL | PRODUCT_CHANGE | UNCANCELLATION | NON_RENEWING_PURCHASE` → `$this->upsertActive($user, $event)`.
      - `CANCELLATION` → switch `$event['cancel_reason']`:
        - `REFUND` → `$user->subscription()->update(['status' => 'cancelled'])`; `$user->update(['pro_active_until' => null, 'pro_product_id' => null])`.
        - default → `$user->subscription()->update(['cancelled_at' => now()])` only.
      - `EXPIRATION` → status `expired`; null out user's pro fields.
      - `BILLING_ISSUE` → status `in_billing_retry`; touch nothing else.
      - `SUBSCRIPTION_PAUSED` → status `paused`.
      - `TRANSFER` → `$this->handleTransfer($event)`.
      - `TEST` → no-op.
      - default → log warning "unknown RC event type", proceed.
    - `$row->update(['processed_at' => now()])`.
  - `upsertActive(User $user, array $event)`:
    - `$expiresAt = Carbon::createFromTimestampMs($event['expiration_at_ms'])`.
    - `Subscription::updateOrCreate(['user_id' => $user->id], [...all fields...])`.
    - `$user->update(['pro_active_until' => $expiresAt->copy()->addDay(), 'pro_product_id' => $event['product_id']])` — 24h grace baked in.
  - `handleTransfer(array $event)`: lookup by `rc_app_user_id IN transferred_from`, update to matching `transferred_to`.
  - `failed(Throwable $e)`: `$row->update(['error' => $e->getMessage()])`; `Log::error(...)`; `report($e)`.

### Step 11 — Entitlement middleware + job guard helper
- [ ] `api/app/Http/Middleware/RequireProEntitlement.php`:
  - `handle(Request, Closure $next)`: if `! $request->user()?->isPro()` → `response()->json(['error' => 'pro_required'], 402)`. Else `$next($request)`.
- [ ] Register alias `'require.pro' => RequireProEntitlement::class` in `bootstrap/app.php`.
- [ ] Apply in `api/routes/api.php`:
  - `Route::post('onboarding/generate-plan', ...)` → **NO** middleware (this runs pre-paywall in the new flow).
  - All coach chat routes → `->middleware('require.pro')`.
  - Activity-analysis trigger endpoint(s) → `->middleware('require.pro')`.
  - `POST wearable/activities` stays free.
- [ ] **Job-level guards** in:
  - `api/app/Jobs/GenerateActivityFeedback.php` — top of `handle()`:
    ```php
    if (! $this->user->isPro()) {
        Log::info('Skipping AI work for non-pro user', ['user_id' => $this->user->id, 'job' => static::class]);
        return;
    }
    ```
  - `api/app/Jobs/GenerateWeeklyInsight.php` — same.
- [ ] `api/CLAUDE.md` — append a one-line bullet under "AI agents" that every new AI-spending job MUST include the `isPro()` early-return guard. This is the budget-leak prevention rule.

### Step 12 — Sync endpoint + REST client
- [ ] `api/app/Services/RevenueCat/RevenueCatRestClient.php`:
  - `getActiveEntitlements(string $appUserId): array` — GET `https://api.revenuecat.com/v2/projects/{config('services.revenuecat.project_id')}/customers/{$appUserId}/active_entitlements`, `Authorization: Bearer {rest_api_key}`. Throw on non-2xx with the response body in the message. Return the decoded JSON.
- [ ] `api/app/Http/Controllers/Api/SubscriptionsController.php` with `sync(Request)`:
  - `$entitlements = $client->getActiveEntitlements((string) $user->id);` — wrapped in try/catch; on REST failure return 503 + current local state (so client doesn't lose existing pro).
  - Find `pro` entitlement in response. If present + `expires_date > now()`:
    - Build a fake "event" payload mirroring `INITIAL_PURCHASE` shape from this entitlement's fields.
    - Call the same `upsertActive` logic the webhook job uses (extract that method to a service `EntitlementSyncService` so both can share).
  - If absent or expired:
    - If local `pro_active_until` is in the past → null it out.
    - Leave it alone if still in future (the webhook might be in flight).
  - Return `{ active_until: $user->fresh()->pro_active_until?->toIso8601String(), product_id: $user->pro_product_id }`.
- [ ] Refactor: extract the `upsertActive` logic from the job into `app/Services/Subscription/EntitlementSyncService.php` so both the job and the controller call the same code path.
- [ ] Route inside `auth:sanctum` v1 group: `Route::post('subscriptions/sync', [SubscriptionsController::class, 'sync']);`.

### Step 13 — Filament admin: subscription view + comp actions
- [ ] `api/app/Filament/Resources/SubscriptionResource.php` — read-only table: user (email), product_id, status, period_type, environment, purchased_at, expires_at, cancelled_at. Filters: status, environment, product_id, environment != 'comp'.
- [ ] On existing `UserResource`:
  - Add column `pro_active_until` (datetime) + `pro_product_id` (with comp badge if `store='comp'`).
  - Filter "Pro active" (boolean) on `pro_active_until > now()`.
  - **Header action / row action** "Grant Pro" with form: `expires_at` datetime picker + optional note → writes a `Subscription` row with `store='comp'`, `product_id='comp'`, `period_type='comp'`, `environment='comp'`, status `active`, no `rc_app_user_id`. Sets `users.pro_active_until = $expires_at`, `pro_product_id = 'comp'`. Logs admin id + timestamp via `Log::info`.
  - Row action "Revoke Pro" → nulls `pro_active_until`, sets sub to `cancelled`. Confirmation modal.
- [ ] After deploy: in Filament admin, grant the reviewer account (Step 2) a comp expiring in 10 years.

### Step 14 — Daily reconcile command
- [ ] `php artisan make:command ReconcileSubscriptions` → signature `subscriptions:reconcile`.
- [ ] `handle()`:
  - `Subscription::where('status', '!=', 'expired')->where('store', '!=', 'comp')->where('expires_at', '<', now()->subDay())->each(...)` → mark expired, null user's pro fields.
  - `Subscription::where('status', 'active')->where('store', '!=', 'comp')->where('expires_at', '<', now()->subDays(7))->each(fn ($s) => Log::warning('overdue subscription', ['user_id' => $s->user_id, 'expires_at' => $s->expires_at]));`
  - Output counts.
- [ ] `routes/console.php`: `Schedule::command('subscriptions:reconcile')->dailyAt('04:00')->timezone('Europe/Amsterdam');`.

### Step 15 — Backend tests
- [ ] `tests/Feature/Webhooks/RevenueCatWebhookTest.php`:
  - Wrong auth header → 401.
  - Valid `INITIAL_PURCHASE` → 200, event row created, job dispatched (`Queue::fake()`).
  - Duplicate `event_id` → 200, single row, no double-dispatch.
- [ ] `tests/Feature/Jobs/Subscription/ProcessRevenueCatWebhookEventTest.php`:
  - Fixtures in `tests/fixtures/revenuecat/`: `initial_purchase.json`, `renewal.json`, `cancellation_unsubscribe.json`, `cancellation_refund.json`, `expiration.json`, `billing_issue.json`, `product_change.json`, `transfer.json`, `test.json`. (Capture real payloads from sandbox in Step 19 + sanitize.)
  - One test per event type asserting state.
  - REFUND-flavored CANCELLATION revokes `pro_active_until` immediately.
  - Idempotency: running the job twice on same row is a no-op.
- [ ] `tests/Feature/Http/SubscriptionsControllerTest.php`:
  - Mock `RevenueCatRestClient`. Active entitlement → `pro_active_until` set. Expired → nulled. REST failure → 503, local state preserved.
- [ ] `tests/Feature/Middleware/RequireProEntitlementTest.php` (with a dummy route bound in test).
- [ ] `tests/Feature/Jobs/AiJobGuardTest.php`:
  - `GenerateActivityFeedback` for non-pro user → returns early without making an Anthropic call. (Mock the agent / HTTP client and assert no call.)
  - Same for `GenerateWeeklyInsight`.
- [ ] `tests/Feature/Console/ReconcileSubscriptionsTest.php`:
  - Stale active → flipped, user pro nulled.
  - 7-day overdue → Log warning emitted.
  - Comp subscriptions are skipped.
- [ ] `tests/Feature/Filament/GrantCompActionTest.php` — Filament action grants + revokes correctly.
- [ ] Run `php artisan test --compact && vendor/bin/pint --dirty`.

## Phase 2 — Flutter

### Step 16 — Packages + iOS plumbing
- [ ] `cd app && flutter pub add purchases_flutter purchases_ui_flutter` (both at `^10.1.0`).
- [ ] Verify `app/ios/Podfile` platform target ≥ `15.0` (current is fine).
- [ ] `cd app/ios && pod install`. Confirm `PurchasesHybridCommon` + `RevenueCatUI` resolve.
- [ ] Add Android note to `app/CLAUDE.md` (deferred to Android port): `MainActivity` must extend `FlutterFragmentActivity` for `PaywallView`.

### Step 17 — Build-script env
- [ ] Add to `~/.zshrc`: `export REVENUECAT_PUBLIC_SDK_KEY=appl_xxx`.
- [ ] `app/scripts/build-ios.sh` — add `--dart-define=REVENUECAT_PUBLIC_SDK_KEY=${REVENUECAT_PUBLIC_SDK_KEY}` next to `API_BASE_URL`.
- [ ] `app/scripts/run-dev.sh` — same `--dart-define`.

### Step 18 — Purchases service + entitlement provider
- [ ] `app/lib/core/purchases/purchases_service.dart`:
  - Static `configure(User user)` → `Purchases.setLogLevel(LogLevel.warn)` + `Purchases.configure(PurchasesConfiguration(_publicKey)..appUserID = user.id.toString())`. Idempotent via `_isConfigured` flag.
  - Wraps `getCustomerInfo`, `restorePurchases`, `showManageSubscriptions`.
- [ ] `app/lib/core/purchases/pro_entitlement_provider.dart` (Riverpod codegen):
  - State class with `{DateTime? activeUntil, String? productId}` + `bool get isPro`.
  - `syncFromServer()` → POSTs empty body to `/subscriptions/sync` via Dio, stores returned state.
- [ ] Wire `PurchasesService.configure` + `proEntitlementProvider.syncFromServer` into `app.dart` cold-start after auth bootstrap (non-blocking).
- [ ] Retrofit method in a new `app/lib/core/api/subscriptions_api.dart`:
  ```dart
  @POST('/subscriptions/sync')
  Future<SyncResponse> sync();
  ```
- [ ] Freezed `SyncResponse({DateTime? activeUntil, String? productId})`.
- [ ] `dart run build_runner build --delete-conflicting-outputs`.

### Step 19 — Plan preview screen (the paywall moment)
- [ ] `app/lib/features/onboarding/screens/plan_preview_screen.dart`:
  - `ConsumerStatefulWidget`. Reads the just-generated plan from `goalProvider` / schedule provider.
  - Body: `CustomScrollView` with the existing week cards reused.
  - Week index ≥ 4 (0-indexed weeks 5+): wrap each in a `Stack` with `BackdropFilter(filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8))` + translucent overlay + centered lock icon + tap GestureDetector → `_presentPaywall()`.
  - Persistent bottom CTA: "Ontgrendel RunCoach Pro" → `_presentPaywall()`.
  - `_presentPaywall()`:
    ```dart
    final result = await RevenueCatUI.presentPaywall(displayCloseButton: false);
    if (result == PaywallResult.purchased || result == PaywallResult.restored) {
      await ref.read(proEntitlementProvider.notifier).syncFromServer();
      if (!mounted) return;
      if (ref.read(proEntitlementProvider).isPro) {
        context.go('/coach/chat/$conversationId');
      }
    }
    ```
  - No `BottomNavigationBar`, no profile menu — `Scaffold` only with this content + CTA.
- [ ] Hard paywall: handle back-button on Android by intercepting `WillPopScope` to no-op. iOS: there's no system back from this route.
- [ ] Localize strings via `context.l10n.*` for CTA + screen-level text. Paywall internals are localized in the RC dashboard.

### Step 20 — Router + onboarding wiring
- [ ] `app/lib/core/router/app_router.dart`:
  - Add route `/onboarding/plan-preview` → `PlanPreviewScreen`. Takes `conversationId` as query param.
  - **Global redirect guard**: if the user is authenticated but not pro AND `pro_active_until` was ever null (i.e. they haven't purchased), redirect ANY route except `/onboarding/...` and `/coach/chat/{conversationId-from-onboarding}` to `/onboarding/plan-preview`. This enforces hard paywall: even if they kill the app and reopen at /dashboard, they end up back at the preview.
- [ ] `app/lib/features/onboarding/screens/onboarding_generating_screen.dart`:
  - On plan-generation complete, navigate to `/onboarding/plan-preview?conversationId=$convId` instead of `/coach/chat/$convId`.
- [ ] Cold-start resume: when `pending_plan_generation` is completed in `/profile` response but user is not pro → router takes them to `/onboarding/plan-preview`.

### Step 21 — Manage subscription in profile menu
- [ ] Add to `profile_menu_sheet.dart` (or wherever it lives) — visible only when `isPro`:
  - Row "Beheer abonnement" → `PurchasesService.showManageSubscriptions()`.
  - Small Pro badge in menu header showing `pro_product_id` ("Pro · Yearly" / "Pro · Monthly" / "Pro · Comp").

### Step 22 — Flutter tests
- [ ] `app/test/core/purchases/pro_entitlement_provider_test.dart` — mock Dio → assert state updates after `syncFromServer`.
- [ ] `app/test/features/onboarding/plan_preview_screen_test.dart`:
  - Renders weeks 1–4 unobstructed, weeks 5+ have a blur + lock overlay.
  - Tapping a locked week or the bottom CTA triggers `_presentPaywall`. (Mock `RevenueCatUI`.)
  - On `PaywallResult.purchased` → provider sync called → navigation to coach chat.
- [ ] `flutter analyze`, `flutter test`.

## Phase 3 — Verify end-to-end

### Step 23 — Sandbox smoke (physical iPhone, NOT TestFlight yet)
- [ ] Build via `bash app/scripts/run-dev.sh -d <iphone-id>` logged into sandbox tester from Step 3.
- [ ] Walk full onboarding → see generating → land on plan preview → confirm weeks 5+ are blurred → tap → paywall opens → buy yearly with 7-day trial → land in coach chat.
- [ ] Filament admin → Subscriptions: new row, `environment='sandbox'`, `period_type='trial'`.
- [ ] Filament admin → Webhook events: `INITIAL_PURCHASE` row with `processed_at` set.
- [ ] Cancel sub in iOS Settings → confirm `CANCELLATION` (non-refund) → user still has access (since `expires_at` is future).
- [ ] Wait for sandbox monthly cycles to expire (renews every 5 min × 6 = ~30 min) → confirm `EXPIRATION` event → `pro_active_until` nulled → coach chat returns 402 → app router redirects back to plan preview.
- [ ] In Filament, "Revoke Pro" while subscription is active → confirm middleware kicks in immediately on next request.

### Step 24 — REFUND simulation
- [ ] In RC sandbox, hand-craft a CANCELLATION event with `cancel_reason='REFUND'` via RC's webhook replay/test feature.
- [ ] Confirm `pro_active_until` is immediately nulled, not just `cancelled_at` set.

### Step 25 — Webhook-delay simulation
- [ ] RC dashboard → temporarily disable webhook → make a sandbox purchase → confirm AI features remain blocked.
- [ ] Cold-start the app → confirm `/subscriptions/sync` REST call pulls the entitlement → AI features unblock.
- [ ] Re-enable webhook.

### Step 26 — TestFlight smoke
- [ ] Bump `app/pubspec.yaml` build number.
- [ ] **Wait for explicit "build and upload" instruction** (per project rule) before running `bash app/scripts/build-ios.sh && bash app/scripts/upload-ios.sh`.
- [ ] After TestFlight processes: install on a clean device, log in with a real Apple ID, walk full flow. Sandbox banner appears on the purchase sheet — no real charge.
- [ ] Verify the reviewer comp account works: log in as reviewer → onboarding → plan preview → no paywall blocks (comp grants pro) → land in coach chat.

### Step 27 — Production checklist (pre go-live)
- [ ] App Store Connect → both SKUs status `Ready to Submit`, attached to next app version submission.
- [ ] Reviewer credentials pasted into App Review notes.
- [ ] Privacy policy updated to mention RevenueCat as a subprocessor (subscriber identifiers, transaction history, country, device type stored on RC servers).
- [ ] `REVENUECAT_WEBHOOK_SECRET` + `REVENUECAT_REST_API_KEY` + `REVENUECAT_PROJECT_ID` confirmed in Laravel Cloud production env.
- [ ] Manual log-check pass on Laravel Cloud: filter for "rc webhook" warnings, confirm clean.
- [ ] Submit app version for review.

## Post-launch follow-ups (out of scope)
- Soft monthly Anthropic quota with toast + hard stop.
- RC Experiments-based paywall A/B tests.
- Win-back offers (RC supports these natively).
- Sentry integration when we have one.
- Filament dashboard widget for subscription MRR / trial-conversion rate.
