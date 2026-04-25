# Plan: Organizations, Coaches & Client Management

**Date:** 2026-04-25
**Status:** Draft — needs product review on open questions before implementation

## Summary

Introduce a multi-tier organizational structure on top of the existing single-user RunCoach app:

```
Superadmin
  └── Organization (gym / coaching business)
        └── Org Admin (manages org)
              └── Coach (manages clients)
                    └── Client (the existing User / runner)
```

Coaches log into a dedicated Filament panel at `/coach`, see all their assigned clients in a table, and drill into a client to view and edit their goal, training plan, and review their Strava activity compliance. Users (clients) can accept org invites or request to join an org from their account screen in the Flutter app.

## Goals

- Coaches manage multiple clients from one place with minimal friction
- Org admins onboard coaches without manual DB work
- Superadmins create new orgs (paid customer onboarding)
- Existing solo users keep working unchanged (no org required)
- Permission boundaries are enforced at the API and Filament layers
- Mobile UX for invites/requests is native and clear

## Non-goals (v1)

- Cross-org coach (a coach in two gyms simultaneously) — defer
- Client with multiple coaches — defer
- Coach-to-client messaging — defer (use the AI coach chat or external)
- Billing / subscriptions per org — defer
- Audit log of coach edits to a client's plan — defer (mention as v1.5)

## Q: Is Filament auth good for this?

**Yes — with one structural change.** Filament uses standard Laravel session auth on the `web` guard. The existing `/admin` panel only enforces an email allowlist (`ADMIN_EMAILS` env var). For coaches we need real role-based access, not an env-var allowlist. Two options:

| Option | Pros | Cons |
|---|---|---|
| **A. One `/admin` panel, role-aware** | Simplest infra, one login URL | UI for superadmin and coaches collide; bigger nav with conditional hiding; harder to brand for coaches |
| **B. Two panels: `/admin` + `/coach`** ✅ | Clean separation, separate branding, coaches never see system internals | Two `Panel` providers, two login routes, slight duplication |

**Recommendation: B.** Filament 4 supports multiple panels natively (`AdminPanelProvider` + new `CoachPanelProvider`). They share auth (`web` guard, `users` table) but expose different resources and apply different access checks via `User::canAccessPanel(Panel $panel)`.

The existing `canAccessPanel` becomes:

```php
public function canAccessPanel(Panel $panel): bool
{
    return match ($panel->getId()) {
        'admin' => $this->isSuperadmin(),
        'coach' => $this->hasActiveOrgRole(['org_admin', 'coach']),
        default => false,
    };
}
```

Sanctum API tokens for the Flutter app are unaffected — the panels are session-only.

## Domain model

### New tables

#### `organizations`
| column | type | notes |
|---|---|---|
| id | bigint pk | |
| name | string | "Amsterdam Running Club" |
| slug | string unique | url-safe identifier, used in invite links |
| description | text nullable | |
| website | string nullable | |
| logo_path | string nullable | optional org logo |
| status | enum(`active`, `suspended`) | superadmin can suspend |
| created_at / updated_at | | |

#### `organization_memberships`
The single source of truth for who-belongs-to-what-org-as-what.

| column | type | notes |
|---|---|---|
| id | bigint pk | |
| organization_id | fk → organizations | cascadeOnDelete |
| user_id | fk → users | cascadeOnDelete |
| role | enum(`org_admin`, `coach`, `client`) | |
| status | enum(`invited`, `requested`, `active`, `removed`) | lifecycle state |
| coach_user_id | fk → users nullable | for `role=client` rows: which coach in this org |
| invited_by_user_id | fk → users nullable | who sent the invite |
| invite_token | string nullable unique | for email-link invites where user not yet exists |
| invite_email | string nullable | when invitee has no account yet |
| invited_at / requested_at / joined_at / removed_at | timestamp nullable | |
| created_at / updated_at | | |

**Indexes:** `(organization_id, role, status)`, `(user_id, status)`, `(invite_token)`, `(coach_user_id)`.

**Constraint:** A user can have at most ONE row with `status=active` across all orgs. Enforced in the application layer (not as a unique index because invited/requested rows are allowed in parallel).

### Changes to existing tables

#### `users` — add columns (per project memory: edit migration in place since pre-launch)
| column | type | notes |
|---|---|---|
| is_superadmin | boolean default false | replaces ADMIN_EMAILS allowlist |

That's it on `users`. Org membership lives in the bridge table — querying `$user->activeMembership()` is one join. No `organization_id` column on `users`.

### Models / relationships

```php
// User
public function memberships(): HasMany;                              // all rows
public function activeMembership(): HasOne;                          // status=active
public function pendingInvites(): HasMany;                           // status=invited
public function pendingRequests(): HasMany;                          // status=requested
public function coachedClients(): HasMany;                           // memberships where coach_user_id=$this->id, status=active
public function organization(): ?Organization;                       // accessor → activeMembership.organization
public function role(): ?string;                                     // accessor → activeMembership.role
public function isSuperadmin(): bool;
public function isOrgAdmin(): bool;
public function isCoach(): bool;
public function isClientOf(User $coach): bool;

// Organization
public function memberships(): HasMany;
public function admins(): HasMany;       // role=org_admin, status=active
public function coaches(): HasMany;      // role=coach, status=active
public function clients(): HasMany;      // role=client, status=active
public function pending(): HasMany;      // status in (invited, requested)
```

### Enums

`api/app/Enums/`:
- `OrganizationRole` — `OrgAdmin`, `Coach`, `Client`
- `MembershipStatus` — `Invited`, `Requested`, `Active`, `Removed`
- `OrganizationStatus` — `Active`, `Suspended`

## Roles & permissions matrix

| Action | Superadmin | Org Admin | Coach | Client |
|---|:-:|:-:|:-:|:-:|
| Create / suspend orgs | ✅ | — | — | — |
| Edit own org details | ✅ | ✅ | — | — |
| Invite org admin | ✅ | ✅ (own org) | — | — |
| Invite coach | ✅ | ✅ (own org) | — | — |
| Invite client | ✅ | ✅ (own org) | ✅ (own org) | — |
| Approve / reject join request | ✅ | ✅ (own org) | — | — |
| Assign coach to client | ✅ | ✅ (own org) | — | — |
| View any client | ✅ | ✅ (own org clients) | ✅ (own org clients, read-only for unassigned) | — |
| Edit client's goal & schedule | ✅ | ✅ (own org clients) | ✅ (assigned only) | — |
| View client's Strava data | ✅ | ✅ (own org) | ✅ (own org clients) | — |
| Remove member from org | ✅ | ✅ (own org, except themselves) | — | — |
| Leave org | — | ✅ | ✅ | ✅ |
| Request to join org | — | — | — | ✅ |
| Accept org invite | ✅ | ✅ | ✅ | ✅ |

Single source of truth: `app/Policies/` + `app/Models/User.php` helper methods. Filament resource classes call `authorize` against these policies.

## Auth & panel architecture

### Filament panels

```
api/app/Providers/Filament/
├── AdminPanelProvider.php       (existing — superadmin only)
└── CoachPanelProvider.php       (new — org_admin + coach)
```

#### `AdminPanelProvider` (existing, updated)
- Path: `/admin`
- Resources: existing `TokenUsageResource` + new `OrganizationResource`, `UserResource` (read-only system view)
- Access gate: `$user->is_superadmin === true`

#### `CoachPanelProvider` (new)
- Path: `/coach`
- Login route: `/coach/login`
- Brand: simple "RunCoach for Coaches" wordmark
- Discovers resources in `app/Filament/Coach/Resources`
- Access gate: user has active membership with `role in (org_admin, coach)`
- Tenancy: scoped to user's org via Filament's `tenant` feature OR a global query scope on every coach resource. Recommend a single `OrganizationScope` global scope applied to relevant models when accessed via the coach panel, since we don't want full Filament multi-tenancy yet (only one org per user in v1).

### Login flow

- Coaches & org admins: `/coach/login` → email/password → Filament dashboard
- They originally arrived via an emailed invite link → set password → land on `/coach`
- Superadmins: `/admin/login` (unchanged)
- Clients (athletes): mobile app only; never log into Filament

### Migrate ADMIN_EMAILS → is_superadmin

- One-time migration: any email in current `ADMIN_EMAILS` env → `users.is_superadmin = true`
- Update `User::canAccessPanel()` to use `is_superadmin` for `/admin` panel
- Keep `ADMIN_EMAILS` as a legacy fallback for one release, then drop

## Database migrations

Per project convention (pre-launch, memory: edit in place):

1. **Edit `0001_01_01_000000_create_users_table.php`** — add `is_superadmin` boolean
2. **New migration `2026_04_26_000001_create_organizations_table.php`**
3. **New migration `2026_04_26_000002_create_organization_memberships_table.php`**
4. **`migrate:fresh --seed`** in dev

Foreign keys via `constrained()->cascadeOnDelete()`. Indexes declared in the migration, not as an afterthought.

## Filament resources (coach panel)

`app/Filament/Coach/Resources/`:

### `ClientResource`
The headline screen. Lists clients the current user has access to (org admins see all; coaches see assigned + read-only on others).

- **Table columns:** Avatar, Name, Email, Assigned Coach (if org admin), Active Goal (badge: "Half Marathon — Sept 14"), Last activity (relative time), Compliance (last 4 weeks, %), Status
- **Filters:** by coach (org admin only), by goal status, by activity recency
- **Actions per row:** View, Reassign coach (org admin), Remove from org
- **Header actions:** Invite client (opens modal: email + role + assign-to-coach)
- **Detail page:** Tabbed view
  - Tab 1: Overview — profile, current goal, recent activities
  - Tab 2: Schedule — full plan tree (weeks → days), inline edit
  - Tab 3: Activities — last 50 Strava activities, with compliance scoring
  - Tab 4: Coach Notes (free text per-client, new column on memberships or separate table — decide later)

### `ScheduleResource` (relation manager under Client)
Not a top-level resource. Surfaces as a `RelationManager` on the Client detail page:
- `GoalRelationManager` — list goals, create/edit
- `TrainingWeekRelationManager` — under selected goal
- `TrainingDayRelationManager` — under selected week, inline edit (type, distance, pace, description)

Coach edits apply directly (no proposal flow — coach is authorized, unlike the AI which needs user approval).

### `CoachResource` (org admin only)
Manage coaches in the org: list, invite, deactivate.

### `OrganizationSettingsPage`
Single page (not a resource) for org admins: edit org name, logo, description.

### `MembershipRequestsResource` (org admin only)
Inbox of pending join requests + invites. Approve / reject / resend.

## Filament resources (admin panel additions)

`app/Filament/Resources/`:

### `OrganizationResource`
Superadmin CRUD for orgs.
- Create org → form: name, slug (auto from name), website, initial admin email
- On create: send invite email to initial admin → they set password and become `org_admin`
- Suspend / reactivate org

### `UserResource` (read-only)
System-wide user search/view for support. No edit, just inspection.

## API endpoints (Flutter app — clients/runners)

All authenticated with Sanctum.

```
GET    /api/v1/organizations/search?q=...           Search orgs by name (paginated, public-ish)
GET    /api/v1/me/memberships                       List own memberships (active, invited, requested)
POST   /api/v1/me/memberships/invites/{token}/accept    Accept an emailed invite (token)
POST   /api/v1/me/memberships/invites/{id}/accept       Accept an in-app invite (existing user)
POST   /api/v1/me/memberships/invites/{id}/reject
POST   /api/v1/me/memberships/requests                  Request to join { organization_id, message }
DELETE /api/v1/me/memberships/requests/{id}             Cancel pending request
POST   /api/v1/me/memberships/leave                     Leave current org
```

The `/profile` and auth responses gain a `current_membership` field (null for solo users) so the app knows on cold start whether to show org branding.

### Coach-side API (used by Flutter coach app — out of scope v1)
Coaches use Filament for v1. A native iOS coach app comes later. The data model is API-ready for it.

## Invite & join flow

### Org-initiated: invite a user

1. **Org admin** clicks "Invite client" → enters email + (optional) assigned coach
2. Backend creates `organization_memberships` row with `status=invited`, `invite_token=Str::random(40)`, `invite_email=...`, `invited_by_user_id=...`
3. Email sent to that address with link `https://runcoach.free.laravel.cloud/invites/{token}`
4. Two cases:
   - **Email matches existing user** → opens deep link `runcoach://invites/{token}` → app shows "Coach Sarah at Amsterdam Running Club has invited you" → Accept / Reject
   - **No account yet** → opens web page → "Create account to accept invite" → after Strava OAuth signup, the membership row is automatically linked by email and activated
5. Accept → `status=active`, `joined_at=now()`. Reject → `status=removed`, `removed_at=now()`.

### User-initiated: request to join an org

1. **Client** opens app → Profile menu → "Connections" → "Find a coach / gym"
2. Search by name → tap an org → "Request to join" → optional message
3. Backend creates `organization_memberships` row `status=requested`, `requested_at=now()`
4. Org admin sees it in Filament `MembershipRequestsResource` → approve (assigns coach) or reject
5. Push notification to user when status changes (v1.5 — for v1 they see it on next app open)

### Idempotency rules

- A user with an `active` membership cannot request another (prompt: "Leave current org first")
- An org cannot have two `invited` rows for the same email (prompt: "Already invited")
- A user cannot have two `requested` rows for the same org

## Authorization

`app/Policies/`:
- `OrganizationPolicy` — view, update, suspend, invite
- `OrganizationMembershipPolicy` — view, update, remove, assign-coach
- `ClientSchedulePolicy` (or extend existing `GoalPolicy` / new) — viewClient, editClient

Enforced both in Filament resources (`canViewAny`, `canEdit`, etc.) AND in any API controllers that touch this data. Use Form Request authorize() methods for org-related API endpoints.

## Coach view of a client's schedule

This is the centerpiece UX. Tab on the Client detail page, fully editable for assigned coach / org admin.

```
┌─ Client: Erwin Wijnveld ─────────────────────────────────────┐
│ Goal: Half Marathon — Berlin — Sept 14, 2026                │
│ Week 8 of 16 · 67% compliance · Last run: 2 days ago         │
├──────────────────────────────────────────────────────────────┤
│  Week 8 (May 3 – May 9)  · 42 km  · "Build phase 2"          │
│  ├ Mon  Easy 8k @ 5:30/km                                    │
│  ├ Tue  Tempo 6k @ 4:30/km   ← edit                          │
│  ├ Wed  Rest                                                  │
│  ...                                                          │
│  [+ Add day]  [Generate week with AI]  [Save changes]        │
└──────────────────────────────────────────────────────────────┘
```

- Inline edit on `TrainingDay`: type, target_km, target_pace_seconds_per_km, description
- "Generate week with AI" calls a new `CoachToolsAgent` (out of scope v1, mention as v1.5)
- Bulk operations: shift all remaining weeks by N days, mark week as taper, etc. (v1.5)

For v1: just make the existing `Goal` / `TrainingWeek` / `TrainingDay` resources editable in the coach panel via Filament forms. No new agent tools.

## Strava data access by coach

The coach needs to see the client's Strava activities to evaluate compliance.
- `StravaActivity` model already has `user_id` — coach access is purely a policy concern
- New `ActivityResource` in coach panel shows the client's last N runs
- No token sharing — the coach only sees data already synced by the user
- For privacy: `Goal`, `TrainingWeek`, `TrainingDay`, `StravaActivity`, `TrainingResult` all gain a policy that says "viewable by self OR by an active coach in same org"

## Plan generation & AI coach: how do they interact with org coaches?

**Open product question — needs decision before final implementation:**

| Option | Description | Pros | Cons |
|---|---|---|---|
| **AI-first** | AI keeps generating plans; human coach overrides if they want | No flow change for users | Coach work can be wiped by next AI proposal |
| **Coach-first** | If client has a coach, AI suggests but the coach must approve before applying | Coach is authority | More UX in app — proposals from AI now route through coach |
| **Hybrid** ✅ | If client has a coach: AI chat is advisory only (no `CreateSchedule` / `ModifySchedule` tools available). Coach edits directly. | Clean separation; coach is the planner | Disables a feature for coached users |

**Recommendation: Hybrid.** When generating the agent for a coached user, skip `CreateSchedule`/`ModifySchedule` tools. The AI remains useful for advice ("how was my week?"), just not for plan changes. Implement via a check in `RunCoachAgent::tools()`.

Document as a setting on the org: `org.coaches_own_plans` (boolean) so an org could opt out and let AI keep generating.

## Flutter app changes (client-side)

### New: `lib/features/organization/`
- `models/organization.dart` (Freezed)
- `models/membership.dart` (Freezed) — id, role, status, organization, coach (nullable User)
- `data/organization_api.dart` (Retrofit)
- `providers/membership_provider.dart` (Riverpod)
- `screens/connections_screen.dart` — list current memberships
- `screens/find_organization_screen.dart` — search + request to join
- `screens/invite_detail_screen.dart` — accept/reject invite (deep link target)
- `widgets/membership_card.dart`
- `widgets/pending_invite_banner.dart` — surfaces on dashboard when there's a pending invite

### Profile menu addition
Add a "Connections" item in the existing profile menu sheet → opens `ConnectionsScreen`.

### Deep link
`runcoach://invites/{token}` → `InviteDetailScreen`. Requires Universal Link configuration in iOS (associated domains entitlement) — same domain as API.

### `/profile` payload extension
Add nullable `current_membership` and `pending_invites` arrays to the existing `/profile` and `/auth/strava/callback` responses so the dashboard knows on first paint.

## Phased rollout

To avoid one giant PR. Each phase ships independently and is usable end-to-end.

### Phase 1 — Foundations (1–2 days)
- Migrations: `is_superadmin`, `organizations`, `organization_memberships`
- Models, enums, factories
- `User::canAccessPanel()` updated to use `is_superadmin`
- Backfill existing admins
- Tests for model relationships
- **Ship:** No user-visible change yet. Foundation for everything else.

### Phase 2 — Superadmin org management (1 day)
- `OrganizationResource` in `/admin` panel
- Superadmin can create orgs and create initial org admins
- Email-based invite to org admin (re-uses Laravel's password reset flow for setting password)
- **Ship:** Superadmin can onboard their first paying gym manually.

### Phase 3 — Coach panel skeleton (1 day)
- `CoachPanelProvider` at `/coach`
- Empty dashboard, login, role-aware nav
- `OrganizationSettingsPage` for org admin
- `CoachResource` for inviting coaches
- **Ship:** Org admin logs in, configures org, invites coaches.

### Phase 4 — Client management (2–3 days)
- `ClientResource` table + detail tabs
- Invite client flow (email + Strava signup linking on accept)
- Assign coach
- Read-only client overview tab
- **Ship:** Coach can see their assigned clients in a list.

### Phase 5 — Schedule editing (2–3 days)
- Goal / TrainingWeek / TrainingDay relation managers under Client detail
- Inline edit on training days
- Activities tab (read-only Strava view)
- **Ship:** Coach can edit a client's plan.

### Phase 6 — Mobile invite/join UX (2 days)
- API endpoints for memberships
- Flutter `connections` feature
- Deep link for emailed invites
- Pending invite banner on dashboard
- **Ship:** Users can accept invites and request to join orgs from the app.

### Phase 7 — AI coach hybrid mode (1 day)
- Toggle `coaches_own_plans` on org
- Strip plan-mutation tools from `RunCoachAgent` for coached users
- Update onboarding flow to recognize "you have a coach — they'll build your plan"
- **Ship:** Clean handoff between coach-managed and AI-managed clients.

### Phase 8 — Polish & v1.5 candidates
- Audit log of coach edits
- Push notifications on invite/request status change
- Bulk schedule operations (shift week, taper)
- Coach notes per client
- "Generate week with AI" inside coach panel

**Total: roughly 10–14 days of focused work** to ship phases 1–7.

## Testing strategy

Follow existing project conventions (`LazilyRefreshDatabase`, `--compact` mode, factories with states):

- **Model tests:** relationship integrity, role accessors, "at most one active membership" rule
- **Policy tests:** every cell in the permissions matrix, including negative cases
- **Filament tests** (`api/tests/Feature/Filament/`):
  - Coach panel access requires active org_admin or coach role
  - Coach can edit assigned client, cannot edit unassigned client
  - Org admin can edit any client in own org, cannot edit other orgs' clients
- **API tests:** invite accept/reject, request flow, idempotency rules, deep-link token resolution
- **Flutter widget tests:** Connections screen states (no membership / pending invite / active membership / pending request)

Aim for parity with the existing 91-test suite — every new resource/policy/endpoint gets a feature test.

## Risks & considerations

| Risk | Mitigation |
|---|---|
| Coach edits silently overwrite an in-flight AI proposal | When opening `ClientResource`, deny pending proposals; or require coach to resolve them first |
| Email-based invite leaks across user accounts (different person owns the email later) | Token expires in 14 days; require Strava OAuth signup matching the invite email exactly |
| Coach sees data of clients who later leave the org | On `status=removed`, revoke access immediately; cached pages get policy re-checks on next request |
| Single membership constraint is enforced in app code, not DB | Add a covering test; consider partial unique index `WHERE status='active'` if MySQL version supports it (8.0.13+ for filtered indexes via generated columns) |
| Filament tenancy edge cases when a user logs out of one org and into another later | v1: forbid; show "leave current org first" UX. v2: support cleanly via Filament's tenant switcher |
| Deep link config takes 24h to propagate (apple-app-site-association) | Use the `/invites/{token}` web page as a fallback that always works |

## Open questions (need product input before implementation)

1. **AI plan ownership when coached:** confirm the Hybrid recommendation above (AI is advisory for coached users).
2. **Strava data privacy:** does a coach see ALL of a client's Strava activities, or only those matched to training days? My recommendation is all (they're a coach), but worth a explicit decision.
3. **Org switch:** if a user leaves one gym and joins another, do their old training plans / goals remain visible to the new coach? Recommendation: keep them but read-only (history); new coach starts fresh goals.
4. **Invite expiry:** 7 / 14 / 30 days? Recommend 14.
5. **Coach max clients:** unlimited in v1, or cap (e.g. 50 per coach) for performance? Probably uncapped — paginate properly.
6. **Org onboarding self-serve:** v1 is superadmin-creates-org. Should anyone be able to spin up an org from a public form? Defer to v2 (gates billing).

## Glossary

- **Org / Organization** — a gym, running club, or coaching business that pays for the platform
- **Org admin** — a user who manages an org (create coaches, edit org settings)
- **Coach** — a user in an org who manages a list of clients
- **Client** — a runner whose plan is managed by a coach (still uses the mobile app the same way)
- **Solo user** — a runner with no org; uses RunCoach exactly as it works today
- **Superadmin** — Anthropic-side / RunCoach team; manages all orgs

---

**Next step:** answer the open questions, then start Phase 1 in a new branch.
