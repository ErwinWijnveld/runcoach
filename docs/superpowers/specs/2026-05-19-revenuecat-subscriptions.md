# RevenueCat subscriptions (iOS, monthly + yearly, post-plan-generation paywall)

**Status:** design proposed, awaiting approval
**Author:** Erwin + Claude
**Date:** 2026-05-19
**Last revised:** 2026-05-19 (re-evaluation pass)

## Problem

We need to gate the expensive parts of RunCoach (Anthropic-calls in `RunCoachAgent`, plan generation, activity feedback, weekly insight) behind a paid subscription. Today everything is free, which is unsustainable at any scale — per-user Anthropic costs run into single-digit euros per month for an active runner.

## Goal

- Sell `runcoach_pro_monthly` and `runcoach_pro_yearly` via StoreKit.
- Show the paywall **after** plan generation: the user sees their generated plan as a 4-week sneak peek (weeks 1–4 visible in detail, weeks 5+ blurred with a lock overlay) and the RevenueCat paywall sits on top.
- 7-day free trial on the yearly SKU for new subscribers.
- Hard paywall: until the user purchases, they can't use the rest of the app — only the plan preview is visible. No "skip for now" option.
- Backend knows entitlement state per user (`pro_active_until`) and gates AI-spending endpoints + AI-spending background jobs on it.
- Webhook from RevenueCat → Laravel → updates `pro_active_until`. Built **in-house, no 3rd-party Laravel package**.
- Graceful degradation against RC webhook delays via a server-driven sync endpoint that re-fetches truth from RC's REST API.

## Non-goals (v1)

- Android (deferred with the rest of the Android port; the same `purchases_flutter` cross-platform SDK will cover it later).
- Web/Stripe checkout (RC Web Billing is a separate spec for desktop).
- Family sharing, in-app gift codes, custom referral codes. Apple's redemption-code flow works out of the box (RC reflects it).
- Refund clawback of AI replies already sent — once we've spent Anthropic budget, we don't unsend.
- A/B-testing different paywall designs via RC Experiments. Capability is included for free with the Paywall Builder; v1 ships one design. Revisit after the first ~100 conversions.
- Granular feature-flagging (no "yearly unlocks X, monthly unlocks Y"). One entitlement: **pro**.
- Free/freemium tier on the app itself. After onboarding-paywall, it's all-or-nothing.

## Why RevenueCat (briefly)

Researched in the prior turn. Short version:

- **RevenueCat**: best Flutter SDK, robust webhook spec, free under $2.5k MTR then 1% gross. Pure broker — receipts stay with Apple. Low lock-in. **Chosen.**
- **Adapty**: $10k free tier but A/B + webhooks behind $99/mo Pro. Overkill for solo pre-revenue.
- **Superwall**: paywall-only, no subscription backend. Could be bolted on later via observer mode if we ever need serious paywall A/B testing.
- **Qonversion / Apphud**: smaller ecosystem, vendor risk (Glassfy shut down Dec 2024).
- **Pure StoreKit + own Laravel**: 3–6 weeks of work for receipt validation, refund handling, sandbox plumbing. Wrong tradeoff for a solo dev shipping AI features.

## Why we write the webhook handler ourselves (not a package)

The community Laravel/RevenueCat packages on Packagist are all very low-star, single-maintainer, and irregularly updated. This is the revenue layer; depending on a 1-star unmaintained package would be a single point of failure we can't accept.

The actual scope is small: one controller action, one shared-secret header check, one `switch` on `event.type`, one Eloquent model write + one idempotency-key write. ~150 lines + tests. Cheaper to own.

## Design

### User flow (paywall placement)

```
[Onboarding form] → [Generating screen, ~60–110s] → [Plan preview + paywall] → [Coach welcome chat]
                                                          │
                                                          ├─ Plan preview screen (Flutter):
                                                          │    • Renders the full generated plan
                                                          │    • Weeks 1–4: visible in detail (sneak peek)
                                                          │    • Weeks 5+: rendered but blurred + locked icon overlay
                                                          │  Tapping anywhere on the locked area, the
                                                          │  bottom CTA, or trying to navigate elsewhere
                                                          │  opens the RevenueCat PaywallView.
                                                          │
                                                          └─ Hard paywall: user cannot leave this screen
                                                             without purchasing or quitting the app.
                                                             No "skip" button. No bottom-nav.
```

Rationale: industry data (Runna, MyFitnessPal pattern) shows higher conversion when the user sees what they're getting first. Cost of `/onboarding/generate-plan` for an unconverted user is ~$0.20–0.50 Anthropic spend — at any reasonable conversion rate this is dwarfed by the conversion uplift.

### Pre-launch grandfathering

The app is in TestFlight only, no public users. Migrations are now **additive only** (no `migrate:fresh`) — see updated project memory. Existing TestFlight installs will hit the paywall on next launch because their `pro_active_until` is `null`. Erwin's own TestFlight account gets a permanent comp entitlement via the Filament admin action (see below) so dev/testing isn't blocked.

### Apple Developer / App Store Connect setup

Manual steps, listed for completeness.

1. App Store Connect → Apps → RunCoach → Monetization → **Subscriptions**.
2. Create subscription group `RunCoach Pro`.
3. Subscriptions in the group:
   - `runcoach_pro_monthly`, duration 1 month, base price €9.99 (Apple auto-tiers other storefronts).
   - `runcoach_pro_yearly`, duration 1 year, base price €59.99. ~50% off vs 12× monthly (€119.88).
4. On `runcoach_pro_yearly`: add Introductory Offer → "New Subscribers" → 7 days free.
5. Localized descriptions + display names in `en-US` and `nl-NL` per SKU. Marketing screenshot per SKU.
6. Agreements / Tax / Banking must be `Active`.
7. **App Review test-account**: in App Store Connect → Users and Access → create reviewer credentials (`apple-review@erwinwijnveld.nl` or similar). After backend deploy, grant that account a permanent comp entitlement via Filament so reviewers can use the app without making a real purchase. Put the credentials in the review notes for every submission.

### RevenueCat dashboard setup

1. RC project `RunCoach`, iOS app with bundle ID `com.erwinwijnveld.runcoach`.
2. Connect App Store Connect API (same key already used by `upload-ios.sh`).
3. Entitlement: `pro`.
4. Products: import `runcoach_pro_monthly` + `runcoach_pro_yearly`. Attach both to `pro`.
5. Offering `default` with packages `$rc_monthly` + `$rc_annual`, mark as current.
6. **Paywall** on offering `default`: start from a built-in template, override colors to the RunCoach palette (cream `#FAF8F4` background, gold CTA), yearly package above monthly, "Bespaar 50%" badge on yearly, localize copy in `en-US` + `nl-NL`. Save & publish — re-publishes are live in the app on next `PaywallView` mount, no app build needed.
7. **Webhook**: Integrations → Webhooks. URL: `https://runcoach.free.laravel.cloud/api/webhooks/revenuecat`. Authorization header: long random secret stored in Laravel as `REVENUECAT_WEBHOOK_SECRET`. Enable all event types — we filter server-side.
8. Enable "Send sandbox events to webhook" for TestFlight + sandbox testing.

### Backend

#### New tables

```
subscriptions
  id                       bigint pk
  user_id                  bigint fk → users (cascade on delete)
  rc_app_user_id           string                — RC's app_user_id, equal to (string) users.id
  rc_original_app_user_id  string nullable       — set if user transferred between RC profiles
  product_id               string                — 'runcoach_pro_monthly' | 'runcoach_pro_yearly' | 'comp'
  store                    string                — 'app_store' | 'comp' (future: 'play_store', 'stripe')
  status                   string                — 'active' | 'in_grace_period' | 'in_billing_retry' | 'expired' | 'cancelled' | 'paused'
  period_type              string                — 'normal' | 'trial' | 'intro' | 'comp'
  purchased_at             timestamp
  expires_at               timestamp nullable
  cancelled_at             timestamp nullable
  environment              string                — 'sandbox' | 'production' | 'comp'
  raw_attributes           json                  — last full RC subscriber.entitlements.pro payload, for debugging
  created_at, updated_at

  unique(user_id)                                — one row per user, updated in place; full history lives in revenuecat_webhook_events
  index(expires_at)
```

```
revenuecat_webhook_events
  id              bigint pk
  event_id        string                          — RC's event.id, idempotency key
  event_type      string
  app_user_id     string nullable
  payload         json
  processed_at    timestamp nullable
  error           text nullable
  received_at     timestamp

  unique(event_id)
  index(app_user_id)
  index(processed_at)
```

```
users  (additive migration, no migrate:fresh)
  + pro_active_until        timestamp nullable    — hot-path entitlement check; computed from subscriptions.expires_at + 24h grace
  + pro_product_id          string nullable       — denormalized for UI badge ('Pro · Yearly')
```

`users.pro_active_until` is the **only column the hot path reads** when gating AI calls. Denormalized on purpose so every AI request avoids a join.

#### Webhook endpoint

```
POST /api/webhooks/revenuecat
Headers:
  Authorization: <REVENUECAT_WEBHOOK_SECRET>
  Content-Type: application/json

200 OK on success (always — even for unknown event types, to stop RC retrying).
401 Unauthorized if the shared secret is wrong.
422 only for malformed JSON.
```

Routed outside `auth:sanctum` and outside `Route::prefix('v1')`. `throttle:300,1` on the route — permissive because the Authorization header is the real auth gate; this is just abuse-cap if someone tries to spam without the secret. No CSRF concerns (API routes don't have CSRF middleware).

Controller (`App\Http\Controllers\Webhooks\RevenueCatWebhookController`) flow:

1. Constant-time compare of `Authorization` header with `config('services.revenuecat.webhook_secret')`. Mismatch → `401`, log warning. Never log the actual secret value.
2. Validate body has `event.id` and `event.type`. Missing → `422`.
3. Try insert into `revenuecat_webhook_events` with unique `event_id`. Constraint violation → log "duplicate event_id, skipping", return `200`. RC retries on non-2xx; duplicates must no-op.
4. Dispatch `ProcessRevenueCatWebhookEvent` job onto the default `database` queue. Return `200`. The webhook endpoint never updates `subscriptions` or `users` synchronously — that's the job's responsibility.

The job (`App\Jobs\Subscription\ProcessRevenueCatWebhookEvent`):

1. Load event row, early-return if already `processed_at` (idempotency for job retries).
2. Resolve user: `User::find((int) $event['app_user_id'])` (explicit cast — RC sends `app_user_id` as a string).
3. `switch ($event['type'])`:
   - `INITIAL_PURCHASE`, `RENEWAL`, `PRODUCT_CHANGE`, `UNCANCELLATION`, `NON_RENEWING_PURCHASE` → upsert `subscriptions` row, recompute `users.pro_active_until = expires_at + 24h grace`.
   - `CANCELLATION` → switch on `cancel_reason`:
     - `REFUND` → set `subscriptions.status='cancelled'`, `users.pro_active_until=null`, `pro_product_id=null`. Apple has clawed back the money — access revokes immediately.
     - All other reasons (`UNSUBSCRIBE`, `BILLING_ERROR`, `CUSTOMER_SUPPORT`, `DEVELOPER_INITIATED`, `PRICE_INCREASE`) → set `cancelled_at = now()`, **do not touch `pro_active_until`**. User keeps access until `expires_at`.
   - `EXPIRATION` → status `expired`, `pro_active_until = null`, `pro_product_id = null`.
   - `BILLING_ISSUE` → status `in_billing_retry`. Leave `pro_active_until` as-is — Apple's grace covers it, and RC will extend `expires_date` if the retry succeeds.
   - `SUBSCRIPTION_PAUSED` → status `paused`.
   - `TRANSFER` → see Transfer handling below.
   - `TEST` → no-op, mark processed.
   - default → log warning, mark processed, ack.
4. Mark `processed_at = now()`.

On exception: leave `processed_at` null, set `error`. Job has `tries=5` with exponential backoff `[10, 30, 60, 300, 900]` seconds. After final failure: `Log::error(...)` + `report($exception)` so it shows up in Laravel Cloud logs (no Sentry installed yet).

**Transfer handling**: when an Apple ID changes hands, RC fires `TRANSFER` with `transferred_from` + `transferred_to` arrays of `app_user_id`s. Find the existing `Subscription` whose `rc_app_user_id` matches `transferred_from`, update its `user_id` + `rc_app_user_id` to the matching `transferred_to`. Rare event in practice (Sign in with Apple is stable), but worth handling cleanly.

Why a job and not synchronous: webhook timing SLAs are ~3s before RC retries. Async processing means transient DB issues never cause double-delivery. Idempotency on `event_id` makes legitimate retries safe.

#### Server-driven sync endpoint (defense-in-depth)

```
POST /api/v1/subscriptions/sync       (auth:sanctum)
body: { } (empty)
200 { active_until: ISO8601 | null, product_id: string | null }
```

Called by Flutter on cold-start and after every purchase/restore. The handler:

1. Calls `RevenueCatRestClient::getActiveEntitlements($user->id)` against `https://api.revenuecat.com/v2/projects/{project_id}/customers/{app_user_id}/active_entitlements` with the secret REST API key.
2. If the `pro` entitlement is present and `expires_date` is in the future → upsert `subscriptions` + recompute `pro_active_until`.
3. If absent or expired → null out `pro_active_until` if it's past.
4. Returns the resulting state.

Why server-side fetch instead of trusting client-posted `CustomerInfo`: simpler, no payload validation, no spoofing concerns. ~100ms extra latency per cold-start is fine. This is the safety net for [known RC webhook-delay incidents](https://status.revenuecat.com/history) — the webhook stays primary, this catches anything it missed.

#### AI feature gate

**Two layers**, because some AI work runs outside the HTTP request path.

**Layer 1 — HTTP middleware** `App\Http\Middleware\RequireProEntitlement`:
- Reads `$request->user()->isPro()` (helper: `$this->pro_active_until?->isFuture() ?? false`).
- Returns `response()->json(['error' => 'pro_required'], 402)` if not pro.
- Applied to:
  - `POST /api/v1/onboarding/generate-plan` — only via the post-paywall path. Pre-paywall, the generation has already run (see flow). But the route stays guarded because someone could call it directly with a Sanctum token to burn budget.
  - All coach chat endpoints.
  - Activity-analysis trigger endpoints. **NOT** the activity ingest endpoint (`POST /wearable/activities`) — sync stays free so expired users still build up history.

**Layer 2 — job-level guard** in every AI-spending background job:
```php
if (! $this->user->isPro()) {
    Log::info('Skipping AI work for non-pro user', [
        'user_id' => $this->user->id,
        'job'     => static::class,
    ]);
    return;
}
```
Applied to: `GenerateActivityFeedback`, `GenerateWeeklyInsight`, and any future AI job. The first job that doesn't have this guard becomes a budget leak — make it part of the AI-job checklist in `api/CLAUDE.md`.

`GeneratePlan` is the explicit exception — it runs **before** paywall in the new flow, so it does NOT have the guard. This is intentional: we eat the ~$0.20–0.50 Anthropic cost as an acquisition expense.

#### Comp/promo entitlements (Filament admin)

New action on `UserResource` in `/admin`: "Grant Pro until [date picker]". Writes a `Subscription` row with `store='comp'`, `product_id='comp'`, `environment='comp'`, `expires_at = picked_date`. Sets `users.pro_active_until` to the same. Used for:
- Reviewer accounts (permanent comp).
- Customer support ("my card failed, give me 2 weeks free").
- Friends/family/influencer comps.

Counterpart "Revoke Pro" action that null-outs the row + entitlement. Logged with admin user id for audit trail.

#### Daily reconcile command

`subscriptions:reconcile` scheduled at 04:00 Europe/Amsterdam:
- Flips `subscriptions` where `expires_at < now()->subDay()` and `status != 'expired'` (and `store != 'comp'`) → expired; nulls `users.pro_active_until` + `pro_product_id`.
- Logs warning to Laravel logs for any active subscription with no event in 7 days past expected renewal — human-investigate signal, no auto-fix.

#### Config

`api/config/services.php`:
```php
'revenuecat' => [
    'webhook_secret' => env('REVENUECAT_WEBHOOK_SECRET'),
    'rest_api_key'   => env('REVENUECAT_REST_API_KEY'),
    'project_id'     => env('REVENUECAT_PROJECT_ID'),
],
```

Env vars required: `REVENUECAT_WEBHOOK_SECRET`, `REVENUECAT_REST_API_KEY`, `REVENUECAT_PROJECT_ID` in both `.env` and Laravel Cloud.

### Flutter app

#### Packages

- `purchases_flutter: ^10.1.0` — core SDK.
- `purchases_ui_flutter: ^10.1.0` — Paywall Builder runtime. Officially maintained by RevenueCat, native rendering, MIT, last update May 2026, 90k+ weekly downloads.

#### Initialization

In `lib/main.dart`, after auth bootstrap once `user.id` is known:
```dart
await Purchases.setLogLevel(LogLevel.warn);
final config = PurchasesConfiguration(<rc-public-sdk-key>)
  ..appUserID = user.id.toString();
await Purchases.configure(config);
```

Public SDK key bundled in the binary (correct usage — that's what it's for). `appUserID` set explicitly so RC's identity matches `users.id`.

#### Entitlement provider

`app/lib/core/purchases/pro_entitlement_provider.dart` (Riverpod codegen):
- State: `{ activeUntil: DateTime?, productId: String? }`, `bool get isPro`.
- `Future<void> syncFromServer()` → POSTs empty body to `/subscriptions/sync`, gets server-of-truth back.
- Wired into `app.dart` cold-start (non-blocking; errors reported to Laravel via the API path is fine, Flutter just falls back to whatever previous state was cached).

#### Plan preview screen (the paywall moment)

`app/lib/features/onboarding/screens/plan_preview_screen.dart`:
- Renders the user's full generated plan (reuse `_WeeklyVolumeChart` + the existing day-card components).
- Weeks 1–4: rendered with full detail.
- Weeks 5+: rendered, then overlaid with a `BackdropFilter(blur: 8) + ColoredBox(white @ 50%) + center lock icon + tap target`. Tapping the locked area opens the paywall.
- Persistent CTA at the bottom: "Ontgrendel RunCoach Pro" → opens the paywall.
- The paywall itself is presented via `RevenueCatUI.presentPaywall()` (modal over the preview), not a separate route, so the user sees the plan behind it. After purchase: navigate to `/coach/chat/{conversation_id}`.
- No app shell (no bottom-nav, no profile menu) — the user is locked to this screen until they purchase.

Why preview-first and paywall-on-top: the plan is the value the user just made. Showing it as the backdrop while presenting the price is the highest-converting layout for plan-based fitness apps.

#### Paywall implementation

Using `purchases_ui_flutter`'s `RevenueCatUI.presentPaywall()`:
```dart
final result = await RevenueCatUI.presentPaywall(
  displayCloseButton: false,  // hard paywall, no skip
);
// result is one of: PURCHASED, RESTORED, CANCELLED, ERROR, NOT_PRESENTED
if (result == PaywallResult.purchased || result == PaywallResult.restored) {
  await ref.read(proEntitlementProvider.notifier).syncFromServer();
  if (ref.read(proEntitlementProvider).isPro && context.mounted) {
    context.go('/coach/chat/$conversationId');
  }
}
```
The paywall layout (cards, badges, copy, trial messaging) lives in the RC dashboard, not in Dart. Trial-eligible users automatically see "7 days free, then €59.99/year" because we configured the intro offer in App Store Connect.

#### Manage subscription + Pro badge

Profile menu (visible only post-onboarding once the user is Pro):
- Row: "Beheer abonnement" → `Purchases.showManageSubscriptions()` (deep-links to iOS Settings).
- Pro badge in menu header showing the active product (Monthly / Yearly / Comp).

#### Restore purchases

Built into the RC paywall (it's a required Apple component). Tapping it calls `Purchases.restorePurchases()` internally, fires the `RESTORED` result, we sync and navigate.

#### Pre-launch grandfathering (TestFlight users)

After deploy, existing TestFlight users land on the paywall on next launch. Erwin's own dev account gets a comp via Filament so testing isn't blocked. No code path for "auto-grant pro to existing users" — we deliberately want them to see the paywall to validate the flow.

## Testing

### Backend

- **Webhook auth**: wrong secret → 401, no DB write.
- **Idempotency**: same `event_id` twice → second insert hits unique constraint, no double-write, both return 200.
- **Each event type**: fixture per type in `api/tests/fixtures/revenuecat/` (captured from sandbox during smoke testing). Asserts state transitions.
- **REFUND-flavored CANCELLATION**: access revoked immediately, not just `cancelled_at` set.
- **Layer-1 middleware**: expired user → 402; active user → reachable; grace-window user → still reachable.
- **Layer-2 job guard**: `GenerateActivityFeedback` for an expired user no-ops with a log line, no Anthropic call made.
- **Sync endpoint**: mock `RevenueCatRestClient` → returns active → `pro_active_until` populated. Returns expired → null. REST call fails → 502 (or returns cached state, decide during implementation).
- **TRANSFER**: subscription's `rc_app_user_id` updated correctly.
- **Comp action**: Filament admin grant → user becomes pro; revoke → expired.
- **Reconcile command**: stale active → expired. Active-no-events-7-days → warning logged.

### Flutter

- **Sandbox tester** walks full flow: onboarding → plan preview → buy yearly with trial → land in coach chat.
- **Locked weeks**: tap on a blurred week → paywall opens.
- **Restore purchases**: after delete + reinstall, restore → returns to authenticated state.
- **Subscription expiry**: sandbox monthly expires (renews every 5 min, max 6 cycles) → coach chat returns 402 → app shows paywall again.
- **Webhook-loss simulation**: disable RC webhook in dashboard → buy in sandbox → confirm app blocked → cold-restart → `/subscriptions/sync` recovers state.

## Risks and mitigations

| Risk | Mitigation |
|---|---|
| Webhook delivery delay | Cold-start `/subscriptions/sync` pulls truth from RC REST; 24h grace in `pro_active_until`; daily reconcile job |
| Webhook secret leak | Rotate via RC dashboard + Laravel env; constant-time comparison; secret never logged |
| Background job leaks Anthropic budget post-expiry | Layer-2 `isPro()` guard in every AI-spending job; documented in `api/CLAUDE.md` as a job-checklist item |
| RC service outage during purchase | StoreKit succeeds independently. RC reflects shortly. Cold-start sync recovers state |
| App Review rejection | Reviewer account with permanent comp entitlement (granted via Filament); review notes include credentials; restore + ToS + privacy links all built into RC paywall |
| Refund chargebacks | `CANCELLATION` with `cancel_reason='REFUND'` → immediate `pro_active_until=null` |
| Webhook DDoS | `throttle:300,1` plus secret-header check; 401 path is cheap (no DB write) |
| User stuck on paywall forever | They can quit the app and re-open; entitlement is rechecked on every cold start. Manual support path = Filament comp grant |

## Migration path

- **Android**: `purchases_flutter` is cross-platform. Add Play Console app to RC project, add `play_store` to the `store` enum. Schema unchanged. `MainActivity` must extend `FlutterFragmentActivity` (a `PaywallView` requirement).
- **Web/Stripe**: RC Web Billing exposes same `entitlements.pro`. Add `store='stripe'` rows. Gate logic unchanged.
- **Promo codes**: Apple offer codes work out of the box. Custom referral/partner deals → Filament comp action covers it.
- **If we ever leave RC**: receipts owned by Apple. Re-validate via App Store Server API + Notifications V2, repopulate `subscriptions`. Nothing in our schema is RC-specific except `raw_attributes` (debug-only) and `rc_app_user_id` (just `users.id` stringified).

## Open product decisions (resolved 2026-05-19)

- ~~Paywall placement~~ → **After plan generation**, with 4-week preview + lock overlay on weeks 5+.
- ~~Free trial vs intro price~~ → **7-day free trial** on yearly SKU for new subscribers.
- ~~Hard paywall vs soft skip~~ → **Hard paywall**. No "skip for now" option. User can only quit the app.
- **Pricing** (working assumption, change in App Store Connect anytime): €9.99/mo, €59.99/yr.

## Post-launch follow-ups (not in this plan)

- Soft monthly Anthropic quota per user (toast at 80%, hard stop at 100%).
- A/B-test paywall designs via RC Experiments.
- Win-back offers for cancelled users.
- Family Sharing opt-in.
- Sentry integration (right now we use `Log::error` + `report()` → Laravel Cloud logs).
