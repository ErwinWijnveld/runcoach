# Onboarding + Race→Goal Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a chat-shaped first-time onboarding (12mo Strava analysis → branch → plan proposal) and rename `Race` → `Goal` end-to-end so goals can be races OR non-race goals (general fitness, get faster, not sure yet).

**Architecture:** Pre-launch rewrite: edit existing migrations in place + `migrate:fresh` rather than additive migrations. Onboarding is the existing `/coach/chat` screen with different scaffold chrome; pre-branch bot messages are scripted by a new `OnboardingController`; post-branch, the same `agent_conversation` flips into real agent mode to call `CreateSchedule`. New `RunningProfileService` computes + caches a 12-month running profile (the stats card data + LLM narrative).

**Tech Stack:** Laravel 13 + Laravel AI SDK + MySQL (backend); Flutter + Riverpod (@riverpod) + Freezed 3.x + GoRouter + Retrofit (mobile). Spec lives at `docs/superpowers/specs/2026-04-16-onboarding-and-goal-rename-design.md`. Figma: [51:453](https://www.figma.com/design/gokobgpFRmZph0Jyr1W4tE/RunCore?node-id=51-453).

---

## File Structure

### Backend (`api/`) — new files
| Path | Responsibility |
|---|---|
| `app/Models/UserRunningProfile.php` | Eloquent model for the cached running profile |
| `app/Services/RunningProfileService.php` | Fetch 12 months from Strava, compute metrics, generate narrative, upsert profile |
| `app/Jobs/AnalyzeRunningProfileJob.php` | Async runner for `RunningProfileService` + append post-analysis scripted messages |
| `app/Http/Controllers/OnboardingController.php` | `/v1/onboarding/*` endpoints + step machine |
| `app/Services/ChipClassifier.php` | Small LLM classifier: free text → chip value |
| `app/Ai/Tools/GetGoalInfo.php` | Renamed from `GetRaceInfo.php` |
| `app/Ai/Tools/GetRunningProfile.php` | New agent tool — read cached profile row |
| `database/migrations/..._create_user_running_profiles_table.php` | New profile table |

### Backend — modified
| Path | Why |
|---|---|
| `app/Models/Goal.php` | Renamed from `Race.php`; adds `type`, nullable `target_date`/`distance` |
| `app/Models/User.php` | Adds `has_completed_onboarding`; drops `level`/`weekly_km_capacity` |
| `app/Enums/GoalDistance.php` / `GoalStatus.php` | Renamed |
| `app/Http/Controllers/GoalController.php` | Renamed from `RaceController.php` |
| `app/Http/Requests/StoreGoalRequest.php` | Renamed from `StoreRaceRequest.php` |
| `app/Ai/Tools/CreateSchedule.php` | Param renames, add `goal_type`, nullable `target_date`/`distance` |
| `app/Ai/Agents/RunCoachAgent.php` | Updated `instructions()`; register new tools |
| `app/Http/Controllers/AuthController.php` | Return `has_completed_onboarding` in user payload |
| `app/Http/Controllers/ProfileController.php` | Delete `onboarding()` method |
| `routes/api.php` | Add `/v1/onboarding/*`; remove `/v1/profile/onboarding` |
| `database/migrations/..._create_goals_table.php` | Renamed from `create_races_table.php`; adds columns |
| `database/migrations/..._create_users_table.php` | Adds `has_completed_onboarding`; drops obsolete columns |
| `database/migrations/..._create_agent_conversations_table.php` | Adds `context` column |
| `database/migrations/..._create_training_weeks_table.php` | `race_id` → `goal_id` FK |

### Flutter (`app/lib/`) — new files
| Path | Responsibility |
|---|---|
| `features/onboarding/screens/onboarding_shell.dart` | Scaffold with centered logo; body = `CoachChatView(onboarding convo id)` |
| `features/onboarding/providers/onboarding_provider.dart` | Riverpod provider for the onboarding conversation id |
| `features/onboarding/data/onboarding_api.dart` | Retrofit client for `/v1/onboarding/*` |
| `features/coach/widgets/stats_card_bubble.dart` | 2×2 metric grid rendered inside a bot bubble |
| `features/coach/widgets/chip_suggestions_row.dart` | Right-aligned wrap of chip pills |
| `features/coach/widgets/coach_chat_view.dart` | Extracted core (message list + input) from `CoachChatScreen` |

### Flutter — modified
| Path | Why |
|---|---|
| `features/goals/...` | Renamed from `features/races/...`; all Race→Goal refs updated |
| `features/coach/models/coach_message.dart` | Adds `messageType` + `messagePayload` |
| `features/coach/widgets/message_bubble.dart` | Switch on `messageType` to pick renderer |
| `features/coach/widgets/proposal_card.dart` | Figma layout: Weekly km/runs summary + View Details + Accept/Adjust |
| `features/coach/screens/coach_chat_screen.dart` | Scaffold only — delegates to `CoachChatView` |
| `features/auth/providers/auth_provider.dart` | `needsOnboarding` → checks `hasCompletedOnboarding` |
| `features/auth/models/user.dart` | Add `hasCompletedOnboarding`; drop `level`/`weeklyKmCapacity` |
| `router/app_router.dart` | Route `/onboarding`; redirect on `!hasCompletedOnboarding`; remove `/auth/onboarding` |

### Flutter — deleted
| Path | Why |
|---|---|
| `features/auth/screens/onboarding_screen.dart` | Replaced by chat-shaped onboarding |
| Old Race freezed/g files (auto-regenerated after rename) | Generated artifacts |

---

# Phase 1 — Backend rename + schema

## Task 1: Backend — rename Race→Goal + add onboarding schema

**Files:**
- Rename: `api/app/Models/Race.php` → `api/app/Models/Goal.php`
- Rename: `api/app/Enums/RaceDistance.php` → `api/app/Enums/GoalDistance.php`
- Rename: `api/app/Enums/RaceStatus.php` → `api/app/Enums/GoalStatus.php`
- Rename: `api/app/Http/Controllers/RaceController.php` → `api/app/Http/Controllers/GoalController.php`
- Rename: `api/app/Http/Requests/StoreRaceRequest.php` → `api/app/Http/Requests/StoreGoalRequest.php`
- Rename: `api/app/Ai/Tools/GetRaceInfo.php` → `api/app/Ai/Tools/GetGoalInfo.php`
- Rename: `api/database/migrations/2026_04_13_160002_create_races_table.php` → `api/database/migrations/2026_04_13_160002_create_goals_table.php`
- Modify: `api/database/migrations/0001_01_01_000000_create_users_table.php` — add `has_completed_onboarding`, drop `level` and `weekly_km_capacity`
- Modify: `api/database/migrations/2026_04_13_193942_create_agent_conversations_table.php` — add `context` column
- Modify: `api/database/migrations/2026_04_13_160003_create_training_weeks_table.php` — `race_id` → `goal_id`
- Modify: `api/database/migrations/2026_04_13_160002_create_goals_table.php` — add `type`, make `distance` and `target_date` nullable, rename `race_date` → `target_date`
- Modify: everything else that references `Race`, `race`, `RaceDistance`, `RaceStatus`, `race_id`, `race_name`, `race_date`, `races`

- [ ] **Step 1: Rename migration files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
git mv database/migrations/2026_04_13_160002_create_races_table.php database/migrations/2026_04_13_160002_create_goals_table.php
```

- [ ] **Step 2: Edit `create_goals_table.php` migration in place**

Replace the entire file with:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('goals', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('type')->default('race'); // race | general_fitness | pr_attempt
            $table->string('name');
            $table->string('distance')->nullable(); // 5k | 10k | half_marathon | marathon | custom
            $table->unsignedInteger('custom_distance_meters')->nullable();
            $table->unsignedInteger('goal_time_seconds')->nullable();
            $table->date('target_date')->nullable();
            $table->string('status')->default('planning');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('goals');
    }
};
```

- [ ] **Step 3: Edit `create_users_table.php` migration**

Open `api/database/migrations/0001_01_01_000000_create_users_table.php`. In the `up()` method inside the `users` table blueprint, remove any `level` and `weekly_km_capacity` columns and add:

```php
$table->boolean('has_completed_onboarding')->default(false);
```

Keep `coach_style` (still used). The resulting users table columns are (roughly): `id, name, email, email_verified_at, password, remember_token, timestamps, coach_style, has_completed_onboarding`.

- [ ] **Step 4: Edit `create_training_weeks_table.php` migration**

Open `api/database/migrations/2026_04_13_160003_create_training_weeks_table.php`. Change the `race_id` FK column to `goal_id`:

```php
$table->foreignId('goal_id')->constrained('goals')->cascadeOnDelete();
```

- [ ] **Step 5: Edit `create_agent_conversations_table.php` migration**

Open `api/database/migrations/2026_04_13_193942_create_agent_conversations_table.php`. Inside the `agent_conversations` Blueprint, add:

```php
$table->string('context')->nullable()->index();
```

- [ ] **Step 6: Rename PHP files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
git mv app/Models/Race.php app/Models/Goal.php
git mv app/Enums/RaceDistance.php app/Enums/GoalDistance.php
git mv app/Enums/RaceStatus.php app/Enums/GoalStatus.php
git mv app/Http/Controllers/RaceController.php app/Http/Controllers/GoalController.php
git mv app/Http/Requests/StoreRaceRequest.php app/Http/Requests/StoreGoalRequest.php
git mv app/Ai/Tools/GetRaceInfo.php app/Ai/Tools/GetGoalInfo.php
```

- [ ] **Step 7: Global find-and-replace inside `api/` (code content)**

From `/Users/erwinwijnveld/projects/runcoach/api`, apply these replacements. Use sed for the exact-case ones and be careful with case sensitivity. Run each command separately and stop if any shows unexpected diff.

```bash
# Class names and type references
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bRaceDistance\b/GoalDistance/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bRaceStatus\b/GoalStatus/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bRaceController\b/GoalController/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bStoreRaceRequest\b/StoreGoalRequest/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bGetRaceInfo\b/GetGoalInfo/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bRace::class\b/Goal::class/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bApp\\\\Models\\\\Race\b/App\\Models\\Goal/g' {} +

# Bare "Race" model references (word-boundary aware)
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\bRace\b/Goal/g' {} +

# Property and parameter names
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\brace_id\b/goal_id/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\brace_name\b/goal_name/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\brace_date\b/target_date/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\braces\b/goals/g' {} +

# Relation/accessor names (camelCase)
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\braceId\b/goalId/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\braceName\b/goalName/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\braceDate\b/targetDate/g' {} +
find app tests database routes -type f -name "*.php" -exec sed -i '' 's/\braceDistance\b/goalDistance/g' {} +
```

- [ ] **Step 8: Review the diff and fix anything sed missed**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
git diff | head -400
```

Look for:
- Route paths in `routes/api.php`: `/races` → `/goals`.
- Agent instructions in `app/Ai/Agents/RunCoachAgent.php` that say "race" in prose — update to "goal" where they describe the data type (keep "race" when describing actual race events).
- Any docblocks/comments.

Apply manual edits with `Edit` tool where sed couldn't reach (prose inside strings where the meaning is goal-the-database-row vs. race-the-physical-event).

- [ ] **Step 9: Update `Goal` model for new schema**

Open `api/app/Models/Goal.php`. Ensure `$fillable` and `$casts` reflect the new columns:

```php
protected $fillable = [
    'user_id', 'type', 'name', 'distance',
    'custom_distance_meters', 'goal_time_seconds',
    'target_date', 'status',
];

protected $casts = [
    'target_date' => 'date',
    'goal_time_seconds' => 'integer',
    'custom_distance_meters' => 'integer',
];
```

Method `trainingWeeks()` stays as `HasMany(TrainingWeek::class)`. If there's a method `weeksUntilRace()`, rename to `weeksUntilTargetDate()` and make it gracefully return `null` when `target_date` is null.

- [ ] **Step 10: Update `User` model**

Open `api/app/Models/User.php`. In `$fillable`, drop `level` and `weekly_km_capacity`; add `has_completed_onboarding`. In `$casts`, add `'has_completed_onboarding' => 'boolean'`. Rename the relation method `races()` to `goals()` (the sed already renamed the string but double-check the method name).

- [ ] **Step 11: Update `CreateSchedule` tool**

Open `api/app/Ai/Tools/CreateSchedule.php`. Update the schema definition (`description` method) and the tool's handler:

- Rename param `race_name` → `goal_name` (required)
- Rename param `race_date` → `target_date`, change to `required()->nullable()`
- Change `distance` to `required()->nullable()`
- Add param `goal_type` as required enum: `race`, `general_fitness`, `pr_attempt`
- `goal_time_seconds` stays required+nullable

In the handler, when creating the Goal row, set `type` from `goal_type`, use `target_date` (which may be null), `distance` (may be null). Everything else stays.

- [ ] **Step 12: Update `GoalController` for new columns**

Open `api/app/Http/Controllers/GoalController.php`. Ensure any `race_date` reference became `target_date`; any listing/filtering by status/distance still works. No new endpoints needed yet — admin management stays as-is.

- [ ] **Step 13: Update `StoreGoalRequest` validation rules**

Open `api/app/Http/Requests/StoreGoalRequest.php`. Update rules:

```php
public function rules(): array
{
    return [
        'type' => 'required|in:race,general_fitness,pr_attempt',
        'name' => 'required|string|max:255',
        'distance' => 'nullable|in:5k,10k,half_marathon,marathon,custom',
        'custom_distance_meters' => 'nullable|integer|min:100',
        'goal_time_seconds' => 'nullable|integer|min:60',
        'target_date' => 'nullable|date',
        'status' => 'in:planning,completed,cancelled',
    ];
}
```

- [ ] **Step 14: Update routes**

Open `api/routes/api.php`. Replace `/races` route prefixes with `/goals`. Example:

```php
Route::apiResource('goals', GoalController::class);
```

Remove `Route::post('/profile/onboarding', ...)` if it exists — the old onboarding endpoint is deleted.

- [ ] **Step 15: Delete old `ProfileController::onboarding` method**

Open `api/app/Http/Controllers/ProfileController.php`. Remove the `onboarding()` method (any method that wrote `coach_style` / `level` / `weekly_km_capacity`). Keep other methods intact.

- [ ] **Step 16: Remove `OnboardingRequest`**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
git rm app/Http/Requests/OnboardingRequest.php
```

- [ ] **Step 17: Make `AuthController` return `has_completed_onboarding`**

Open `api/app/Http/Controllers/AuthController.php`. In the user serialization (callback / me endpoint), ensure the response includes `has_completed_onboarding`. If using `$user->toArray()`, append `'coach_style'` and `'has_completed_onboarding'` to `$visible`/`$appends` as needed, or explicitly shape the response array.

- [ ] **Step 18: Run migrate:fresh and confirm schema**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan migrate:fresh
php artisan tinker --execute="echo json_encode(\Schema::getColumnListing('goals'));"
```

Expected output includes: `id, user_id, type, name, distance, custom_distance_meters, goal_time_seconds, target_date, status, created_at, updated_at`.

- [ ] **Step 19: Run the backend test suite**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact
```

Expected: all 45 existing tests pass (the rename is mechanical; if any test references `race_id`/`Race`/etc. explicitly, sed already fixed them).

If tests reference the now-removed `level`/`weekly_km_capacity` attributes, update those tests to skip or remove those assertions.

- [ ] **Step 20: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
refactor(api): rename Race → Goal end-to-end; add onboarding schema

- Rename Race model, enums, controller, tool files
- goals.type enum, target_date+distance nullable, race_id → goal_id FK
- users: add has_completed_onboarding, drop level/weekly_km_capacity
- agent_conversations: add nullable context column
- CreateSchedule tool: goal_name/target_date/goal_type params
- Delete ProfileController::onboarding + OnboardingRequest

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 2: Flutter — rename races feature + update user model

**Files:**
- Rename: `app/lib/features/races/` → `app/lib/features/goals/`
- Rename: `race.dart` → `goal.dart`; `race_api.dart` → `goal_api.dart`; `race_provider.dart` → `goal_provider.dart`; `race_*_screen.dart` → `goal_*_screen.dart`
- Delete: generated files `race.freezed.dart`, `race.g.dart`, `race_api.g.dart`, `race_provider.g.dart` (regenerated)
- Modify: `app/lib/features/auth/models/user.dart` — add `hasCompletedOnboarding`; drop `level`/`weeklyKmCapacity`
- Modify: `app/lib/features/auth/providers/auth_provider.dart` — `needsOnboarding` checks the new flag
- Modify: `app/lib/router/app_router.dart` — redirect when `hasCompletedOnboarding == false`, add `/onboarding` route placeholder (will be completed in Phase 7)
- Modify: All dart files that reference `Race`, `race`, `races`

- [ ] **Step 1: Rename feature folder and files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
git mv lib/features/races lib/features/goals
cd lib/features/goals
git mv models/race.dart models/goal.dart
git mv data/race_api.dart data/goal_api.dart
git mv providers/race_provider.dart providers/goal_provider.dart
git mv screens/race_create_screen.dart screens/goal_create_screen.dart
git mv screens/race_detail_screen.dart screens/goal_detail_screen.dart
git mv screens/race_list_screen.dart screens/goal_list_screen.dart

# Delete generated files — build_runner will regenerate
rm -f models/race.freezed.dart models/race.g.dart data/race_api.g.dart providers/race_provider.g.dart
```

- [ ] **Step 2: Global find-and-replace in dart files**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app

# Type and filename references
find lib test -type f -name "*.dart" -exec sed -i '' 's|features/races/|features/goals/|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race\.dart|goal.dart|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race_api\.dart|goal_api.dart|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race_provider\.dart|goal_provider.dart|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race_create_screen\.dart|goal_create_screen.dart|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race_detail_screen\.dart|goal_detail_screen.dart|g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's|race_list_screen\.dart|goal_list_screen.dart|g' {} +

# Class names
find lib test -type f -name "*.dart" -exec sed -i '' 's/\bRace\b/Goal/g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's/\braceProvider\b/goalProvider/g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's/\braceApi\b/goalApi/g' {} +

# Field names (camelCase → match JSON via @JsonKey)
find lib test -type f -name "*.dart" -exec sed -i '' 's/\braceId\b/goalId/g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's/\braceName\b/goalName/g' {} +
find lib test -type f -name "*.dart" -exec sed -i '' 's/\braceDate\b/targetDate/g' {} +

# Route path
find lib test -type f -name "*.dart" -exec sed -i '' "s|'/races'|'/goals'|g" {} +
find lib test -type f -name "*.dart" -exec sed -i '' "s|'/races/|'/goals/|g" {} +

# JSON keys (@JsonKey(name: '...'))
find lib test -type f -name "*.dart" -exec sed -i '' "s|name: 'race_date'|name: 'target_date'|g" {} +
find lib test -type f -name "*.dart" -exec sed -i '' "s|name: 'race_id'|name: 'goal_id'|g" {} +
find lib test -type f -name "*.dart" -exec sed -i '' "s|name: 'race_name'|name: 'goal_name'|g" {} +
```

- [ ] **Step 3: Update `Goal` freezed model**

Open `app/lib/features/goals/models/goal.dart`. Ensure the class is named `Goal` (not `Race`) with sealed syntax, has these fields:

```dart
@freezed
sealed class Goal with _$Goal {
  const factory Goal({
    required int id,
    required String type,               // 'race' | 'general_fitness' | 'pr_attempt'
    required String name,
    String? distance,
    @JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,
    @JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,
    @JsonKey(name: 'target_date') String? targetDate,
    required String status,
  }) = _Goal;

  factory Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);
}
```

- [ ] **Step 4: Update `User` freezed model**

Open `app/lib/features/auth/models/user.dart`. Remove `level` and `weeklyKmCapacity` fields. Add:

```dart
@JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
```

Keep `coachStyle`.

- [ ] **Step 5: Update `AuthProvider::needsOnboarding`**

Open `app/lib/features/auth/providers/auth_provider.dart`. Replace the `needsOnboarding` getter:

```dart
bool get needsOnboarding => !(state.value?.hasCompletedOnboarding ?? false);
```

Remove any calls to the deleted `updateOnboarding(coachStyle, level, weeklyKmCapacity)` method. Leave the underlying API method call in place but comment out usages temporarily — it will be removed entirely in Task 27.

- [ ] **Step 6: Update router redirect**

Open `app/lib/router/app_router.dart`. In the redirect callback, replace the `coachStyle == null` check with:

```dart
if (loggedIn && user?.hasCompletedOnboarding == false && state.matchedLocation != '/onboarding') {
  return '/onboarding';
}
```

Do NOT delete the old `/auth/onboarding` route yet — that happens in Task 27 once the new screen exists. Leave the old route pointing to the old `OnboardingScreen` for now so the app compiles.

Add a placeholder route:

```dart
GoRoute(
  path: '/onboarding',
  builder: (_, __) => const Scaffold(body: Center(child: Text('Onboarding — WIP'))),
),
```

- [ ] **Step 7: Regenerate code**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: new `goal.freezed.dart`, `goal.g.dart`, `goal_api.g.dart`, `goal_provider.g.dart`, plus regenerated `user.freezed.dart`, `user.g.dart`.

- [ ] **Step 8: Run flutter analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues. Fix any remaining references (sed cannot handle all cases; likely leftovers in comments or docstrings).

- [ ] **Step 9: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
refactor(app): rename races feature → goals; user.hasCompletedOnboarding

- features/races → features/goals, all class/field renames
- User: hasCompletedOnboarding flag; drop level + weeklyKmCapacity
- Router: redirect to /onboarding when flag is false (placeholder screen)
- Regenerated Freezed + Retrofit

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 2 — Running profile service

## Task 3: Create `UserRunningProfile` model + migration

**Files:**
- Create: `api/database/migrations/2026_04_16_000001_create_user_running_profiles_table.php`
- Create: `api/app/Models/UserRunningProfile.php`
- Test: `api/tests/Feature/Models/UserRunningProfileTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Models/UserRunningProfileTest.php`:

```php
<?php

namespace Tests\Feature\Models;

use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class UserRunningProfileTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_belongs_to_user(): void
    {
        $user = User::factory()->create();
        $profile = UserRunningProfile::create([
            'user_id' => $user->id,
            'analyzed_at' => now(),
            'data_start_date' => now()->subYear(),
            'data_end_date' => now(),
            'metrics' => ['weekly_avg_km' => 25.0],
            'narrative_summary' => 'Consistent year.',
        ]);

        $this->assertEquals($user->id, $profile->user->id);
        $this->assertEquals(25.0, $profile->metrics['weekly_avg_km']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=UserRunningProfileTest
```

Expected: FAIL with "class UserRunningProfile not found" or similar.

- [ ] **Step 3: Create the migration**

Create `api/database/migrations/2026_04_16_000001_create_user_running_profiles_table.php`:

```php
<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('user_running_profiles', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->unique()->constrained()->cascadeOnDelete();
            $table->timestamp('analyzed_at')->nullable();
            $table->date('data_start_date')->nullable();
            $table->date('data_end_date')->nullable();
            $table->json('metrics')->nullable();
            $table->text('narrative_summary')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('user_running_profiles');
    }
};
```

- [ ] **Step 4: Create the model**

Create `api/app/Models/UserRunningProfile.php`:

```php
<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class UserRunningProfile extends Model
{
    protected $fillable = [
        'user_id', 'analyzed_at',
        'data_start_date', 'data_end_date',
        'metrics', 'narrative_summary',
    ];

    protected $casts = [
        'analyzed_at' => 'datetime',
        'data_start_date' => 'date',
        'data_end_date' => 'date',
        'metrics' => 'array',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
```

Also add a `runningProfile()` relation to `app/Models/User.php`:

```php
public function runningProfile(): \Illuminate\Database\Eloquent\Relations\HasOne
{
    return $this->hasOne(UserRunningProfile::class);
}
```

- [ ] **Step 5: Run migrate:fresh and the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan migrate:fresh
php artisan test --filter=UserRunningProfileTest
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): add user_running_profiles table + model

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: `RunningProfileService` — metrics computation

**Files:**
- Create: `api/app/Services/RunningProfileService.php`
- Test: `api/tests/Feature/Services/RunningProfileServiceTest.php`
- Reference: `api/app/Services/StravaSyncService.php` for the Strava client pattern, `api/app/Ai/Tools/SearchStravaActivities.php` for aggregation examples

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Services/RunningProfileServiceTest.php`:

```php
<?php

namespace Tests\Feature\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use App\Services\Strava\StravaClient;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Mockery;
use Tests\TestCase;

class RunningProfileServiceTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_analyze_computes_metrics_from_strava_activities(): void
    {
        $user = User::factory()->create();

        // Fake 52 weeks, 3 runs per week, 10km each at 5:00/km pace
        $activities = [];
        for ($week = 0; $week < 52; $week++) {
            for ($run = 0; $run < 3; $run++) {
                $activities[] = [
                    'type' => 'Run',
                    'distance' => 10_000, // meters
                    'moving_time' => 3000, // 50 min → 5:00/km
                    'start_date' => now()->subWeeks(52 - $week)->subDays($run)->toIso8601String(),
                    'elapsed_time' => 3000,
                ];
            }
        }

        $client = Mockery::mock(StravaClient::class);
        $client->shouldReceive('fetchActivitiesInRange')->once()->andReturn($activities);

        $service = new RunningProfileService($client, app(\OpenAI\Client::class));
        // Stub out narrative by overriding the method — see Task 5 for proper LLM test
        $profile = $service->computeMetrics($user, $activities);

        $this->assertInstanceOf(UserRunningProfile::class, $profile);
        $this->assertEquals(30.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(3, $profile->metrics['weekly_avg_runs']);
        $this->assertEquals(300, $profile->metrics['avg_pace_seconds_per_km']); // 5:00/km
        $this->assertEquals(3000, $profile->metrics['session_avg_duration_seconds']);
        $this->assertEquals(156, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(1560.0, $profile->metrics['total_distance_km_12mo']);
        $this->assertEquals(100, $profile->metrics['consistency_score']);
    }

    public function test_analyze_handles_zero_activities(): void
    {
        $user = User::factory()->create();

        $client = Mockery::mock(StravaClient::class);
        $client->shouldReceive('fetchActivitiesInRange')->once()->andReturn([]);

        $service = new RunningProfileService($client, app(\OpenAI\Client::class));
        $profile = $service->computeMetrics($user, []);

        $this->assertEquals(0, $profile->metrics['total_runs_12mo']);
        $this->assertEquals(0.0, $profile->metrics['weekly_avg_km']);
        $this->assertEquals(0, $profile->metrics['consistency_score']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=RunningProfileServiceTest
```

Expected: FAIL — class not found.

- [ ] **Step 3: Create the service**

Create `api/app/Services/RunningProfileService.php`:

```php
<?php

namespace App\Services;

use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\Strava\StravaClient;
use Carbon\Carbon;
use Illuminate\Support\Facades\Log;
use OpenAI\Client as OpenAIClient;

class RunningProfileService
{
    public function __construct(
        private readonly StravaClient $strava,
        private readonly OpenAIClient $openai,
    ) {}

    /**
     * Fetch 12 months, compute metrics, generate narrative, upsert profile.
     */
    public function analyze(User $user): UserRunningProfile
    {
        $end = now();
        $start = now()->subYear();

        $activities = $this->strava->fetchActivitiesInRange($user, $start, $end);
        $runs = array_filter($activities, fn ($a) => ($a['type'] ?? '') === 'Run');

        $profile = $this->computeMetrics($user, array_values($runs));
        $profile->narrative_summary = $this->generateNarrative($profile->metrics);
        $profile->analyzed_at = now();
        $profile->data_start_date = $start;
        $profile->data_end_date = $end;
        $profile->save();

        return $profile;
    }

    public function computeMetrics(User $user, array $runs): UserRunningProfile
    {
        $metrics = $this->aggregate($runs);

        return UserRunningProfile::updateOrCreate(
            ['user_id' => $user->id],
            ['metrics' => $metrics],
        );
    }

    private function aggregate(array $runs): array
    {
        $totalRuns = count($runs);
        $totalMeters = array_sum(array_column($runs, 'distance'));
        $totalSeconds = array_sum(array_column($runs, 'moving_time'));
        $totalKm = round($totalMeters / 1000, 1);

        $weeks = 52;
        $weeklyAvgKm = $totalRuns === 0 ? 0.0 : round($totalKm / $weeks, 1);
        $weeklyAvgRuns = $totalRuns === 0 ? 0 : (int) round($totalRuns / $weeks);

        $avgPace = $totalMeters === 0 ? 0 : (int) round($totalSeconds / ($totalMeters / 1000));
        $avgDuration = $totalRuns === 0 ? 0 : (int) round($totalSeconds / $totalRuns);

        $weeksWithRuns = [];
        foreach ($runs as $run) {
            $weeksWithRuns[Carbon::parse($run['start_date'])->format('o-W')] = true;
        }
        $consistency = (int) round(count($weeksWithRuns) / $weeks * 100);

        return [
            'weekly_avg_km' => $weeklyAvgKm,
            'weekly_avg_runs' => $weeklyAvgRuns,
            'avg_pace_seconds_per_km' => $avgPace,
            'session_avg_duration_seconds' => $avgDuration,
            'total_runs_12mo' => $totalRuns,
            'total_distance_km_12mo' => $totalKm,
            'consistency_score' => $consistency,
            'long_run_trend' => $this->trend($runs, fn ($r) => $r['distance']),
            'pace_trend' => $this->paceTrend($runs),
        ];
    }

    private function trend(array $runs, callable $metric): string
    {
        if (count($runs) < 10) return 'flat';
        $first = array_slice($runs, 0, (int) floor(count($runs) / 2));
        $last = array_slice($runs, (int) floor(count($runs) / 2));
        $avgFirst = array_sum(array_map($metric, $first)) / max(1, count($first));
        $avgLast = array_sum(array_map($metric, $last)) / max(1, count($last));
        if ($avgLast > $avgFirst * 1.05) return 'improving';
        if ($avgLast < $avgFirst * 0.95) return 'declining';
        return 'flat';
    }

    private function paceTrend(array $runs): string
    {
        if (count($runs) < 10) return 'flat';
        // Pace = seconds per meter; lower = faster
        return $this->trend($runs, fn ($r) => $r['distance'] > 0 ? $r['moving_time'] / $r['distance'] : 0);
    }

    private function generateNarrative(array $metrics): string
    {
        // Stub — real implementation in Task 5
        return "Here's your last 12 months.";
    }
}
```

- [ ] **Step 4: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=RunningProfileServiceTest
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): RunningProfileService — metrics aggregation (narrative stub)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `RunningProfileService` — LLM narrative generation

**Files:**
- Modify: `api/app/Services/RunningProfileService.php` — replace the narrative stub
- Test: `api/tests/Feature/Services/RunningProfileServiceTest.php` — add narrative test

- [ ] **Step 1: Write the failing test**

Add to `RunningProfileServiceTest.php`:

```php
public function test_generate_narrative_uses_openai_with_metrics_context(): void
{
    $metrics = [
        'weekly_avg_km' => 25.0,
        'weekly_avg_runs' => 3,
        'consistency_score' => 85,
        'long_run_trend' => 'improving',
        'pace_trend' => 'flat',
    ];

    $openai = Mockery::mock(\OpenAI\Client::class);
    $chat = Mockery::mock();
    $openai->shouldReceive('chat')->andReturn($chat);
    $chat->shouldReceive('create')->once()->withArgs(function ($args) use ($metrics) {
        $prompt = json_encode($args);
        return str_contains($prompt, (string) $metrics['weekly_avg_km'])
            && str_contains($prompt, 'improving');
    })->andReturn((object) [
        'choices' => [(object) [
            'message' => (object) ['content' => 'Strong consistent year.']
        ]]
    ]);

    $service = new RunningProfileService(app(\App\Services\Strava\StravaClient::class), $openai);
    $narrative = $service->generateNarrativePublic($metrics);

    $this->assertEquals('Strong consistent year.', $narrative);
}

public function test_generate_narrative_falls_back_on_openai_failure(): void
{
    $openai = Mockery::mock(\OpenAI\Client::class);
    $chat = Mockery::mock();
    $openai->shouldReceive('chat')->andReturn($chat);
    $chat->shouldReceive('create')->andThrow(new \Exception('API down'));

    $service = new RunningProfileService(app(\App\Services\Strava\StravaClient::class), $openai);
    $narrative = $service->generateNarrativePublic(['weekly_avg_km' => 10]);

    $this->assertEquals("Here's your last 12 months.", $narrative);
}
```

Temporarily make `generateNarrative` public via a proxy method `generateNarrativePublic` (simpler than reflection).

- [ ] **Step 2: Replace the narrative stub in `RunningProfileService`**

Update `api/app/Services/RunningProfileService.php`:

```php
private function generateNarrative(array $metrics): string
{
    try {
        $response = $this->openai->chat()->create([
            'model' => config('services.openai.narrative_model', 'gpt-4o-mini'),
            'temperature' => 0.4,
            'messages' => [
                [
                    'role' => 'system',
                    'content' => 'You are a running coach summarising 12 months of activity in ONE short paragraph (max 3 sentences). Mention consistency, pace feel, and progression. Do NOT invent numbers — only refer to what is in the metrics.',
                ],
                [
                    'role' => 'user',
                    'content' => 'Metrics: ' . json_encode($metrics),
                ],
            ],
        ]);

        $text = trim($response->choices[0]->message->content ?? '');
        return $text !== '' ? $text : "Here's your last 12 months.";
    } catch (\Throwable $e) {
        \Illuminate\Support\Facades\Log::warning('Narrative generation failed', ['error' => $e->getMessage()]);
        return "Here's your last 12 months.";
    }
}

/** @internal — exposed for testing only */
public function generateNarrativePublic(array $metrics): string
{
    return $this->generateNarrative($metrics);
}
```

- [ ] **Step 3: Run the tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=RunningProfileServiceTest
```

Expected: PASS (all three tests).

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): LLM narrative generation for running profile (with fallback)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `AnalyzeRunningProfileJob`

**Files:**
- Create: `api/app/Jobs/AnalyzeRunningProfileJob.php`
- Test: `api/tests/Feature/Jobs/AnalyzeRunningProfileJobTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Jobs/AnalyzeRunningProfileJobTest.php`:

```php
<?php

namespace Tests\Feature\Jobs;

use App\Jobs\AnalyzeRunningProfileJob;
use App\Models\User;
use App\Models\UserRunningProfile;
use App\Services\RunningProfileService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Mockery;
use Tests\TestCase;

class AnalyzeRunningProfileJobTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_job_creates_profile_and_appends_four_scripted_messages(): void
    {
        $user = User::factory()->create();
        $conversation = AgentConversation::create([
            'id' => (string) \Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'pending_analysis'],
        ]);

        $service = Mockery::mock(RunningProfileService::class);
        $profile = UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => [
                'weekly_avg_km' => 12.5,
                'weekly_avg_runs' => 3,
                'avg_pace_seconds_per_km' => 295,
                'session_avg_duration_seconds' => 2694,
            ],
            'narrative_summary' => 'Consistent year.',
        ]);
        $service->shouldReceive('analyze')->once()->with($user)->andReturn($profile);

        $this->app->instance(RunningProfileService::class, $service);

        (new AnalyzeRunningProfileJob($conversation->id, $user->id))->handle($service);

        $messages = AgentConversationMessage::where('conversation_id', $conversation->id)
            ->orderBy('created_at')
            ->get();

        $this->assertCount(4, $messages);
        $this->assertEquals('text', $messages[0]->meta['message_type']);
        $this->assertEquals('Consistent year.', $messages[0]->content);
        $this->assertEquals('stats_card', $messages[1]->meta['message_type']);
        $this->assertEquals(12.5, $messages[1]->meta['message_payload']['metrics']['weekly_avg_km']);
        $this->assertEquals('text', $messages[2]->meta['message_type']);
        $this->assertStringContainsString('training for', $messages[2]->content);
        $this->assertEquals('chip_suggestions', $messages[3]->meta['message_type']);
        $this->assertCount(4, $messages[3]->meta['message_payload']['chips']);

        $conversation->refresh();
        $this->assertEquals('awaiting_branch', $conversation->meta['onboarding_step']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=AnalyzeRunningProfileJobTest
```

Expected: FAIL — class not found.

- [ ] **Step 3: Create the job**

Create `api/app/Jobs/AnalyzeRunningProfileJob.php`:

```php
<?php

namespace App\Jobs;

use App\Services\RunningProfileService;
use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;

class AnalyzeRunningProfileJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public string $conversationId,
        public int $userId,
    ) {}

    public function handle(RunningProfileService $service): void
    {
        $conversation = AgentConversation::findOrFail($this->conversationId);
        $user = \App\Models\User::findOrFail($this->userId);

        $profile = $service->analyze($user);

        $this->appendMessage($conversation, 'text', $profile->narrative_summary);
        $this->appendMessage($conversation, 'stats_card', null, [
            'metrics' => [
                'weekly_avg_km' => $profile->metrics['weekly_avg_km'] ?? 0,
                'weekly_avg_runs' => $profile->metrics['weekly_avg_runs'] ?? 0,
                'avg_pace_seconds_per_km' => $profile->metrics['avg_pace_seconds_per_km'] ?? 0,
                'session_avg_duration_seconds' => $profile->metrics['session_avg_duration_seconds'] ?? 0,
            ],
        ]);
        $this->appendMessage($conversation, 'text', "Anything you're training for, or want to work toward?");
        $this->appendMessage($conversation, 'chip_suggestions', null, [
            'chips' => [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
                ['label' => 'Not sure yet', 'value' => 'skip'],
            ],
        ]);

        $meta = $conversation->meta ?? [];
        $meta['onboarding_step'] = 'awaiting_branch';
        $conversation->meta = $meta;
        $conversation->save();
    }

    public function failed(\Throwable $e): void
    {
        $conversation = AgentConversation::find($this->conversationId);
        if (!$conversation) return;

        $meta = $conversation->meta ?? [];
        $meta['onboarding_step'] = 'analysis_failed';
        $conversation->meta = $meta;
        $conversation->save();

        $this->appendMessage($conversation, 'loading_card_error', null, [
            'label' => "I couldn't reach Strava. Retry?",
            'retry' => true,
        ]);
    }

    private function appendMessage(AgentConversation $conversation, string $type, ?string $content = null, array $payload = []): void
    {
        AgentConversationMessage::create([
            'id' => (string) Str::uuid(),
            'conversation_id' => $conversation->id,
            'user_id' => $conversation->user_id,
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => $content ?? '',
            'meta' => [
                'message_type' => $type,
                'message_payload' => $payload,
            ],
        ]);
    }
}
```

- [ ] **Step 4: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=AnalyzeRunningProfileJobTest
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): AnalyzeRunningProfileJob appends 4 scripted onboarding messages

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 3 — Onboarding controller + step machine

## Task 7: `OnboardingController` scaffold + POST /start

**Files:**
- Create: `api/app/Http/Controllers/OnboardingController.php`
- Modify: `api/routes/api.php` — register onboarding routes
- Test: `api/tests/Feature/Http/OnboardingStartTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingStartTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Jobs\AnalyzeRunningProfileJob;
use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Queue;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingStartTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_start_creates_onboarding_conversation_and_dispatches_job(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $response = $this->postJson('/api/v1/onboarding/start');

        $response->assertOk()
            ->assertJsonStructure(['conversation_id', 'messages'])
            ->assertJsonCount(1, 'messages')
            ->assertJsonPath('messages.0.meta.message_type', 'loading_card');

        $conversation = AgentConversation::where('user_id', $user->id)
            ->where('context', 'onboarding')
            ->first();
        $this->assertNotNull($conversation);
        $this->assertEquals('pending_analysis', $conversation->meta['onboarding_step']);

        Queue::assertPushed(AnalyzeRunningProfileJob::class);
    }

    public function test_start_is_idempotent(): void
    {
        Queue::fake();
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $first = $this->postJson('/api/v1/onboarding/start')->assertOk();
        $second = $this->postJson('/api/v1/onboarding/start')->assertOk();

        $this->assertEquals(
            $first->json('conversation_id'),
            $second->json('conversation_id'),
        );
        $this->assertCount(1, AgentConversation::where('user_id', $user->id)->where('context', 'onboarding')->get());
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingStartTest
```

Expected: FAIL — route not defined (404).

- [ ] **Step 3: Create the controller**

Create `api/app/Http/Controllers/OnboardingController.php`:

```php
<?php

namespace App\Http\Controllers;

use App\Jobs\AnalyzeRunningProfileJob;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;

class OnboardingController extends Controller
{
    public function start(Request $request): JsonResponse
    {
        $user = $request->user();

        $conversation = AgentConversation::firstOrNew([
            'user_id' => $user->id,
            'context' => 'onboarding',
        ]);

        if (!$conversation->exists) {
            $conversation->id = (string) Str::uuid();
            $conversation->title = 'Onboarding';
            $conversation->meta = ['onboarding_step' => 'pending_analysis'];
            $conversation->save();

            AgentConversationMessage::create([
                'id' => (string) Str::uuid(),
                'conversation_id' => $conversation->id,
                'user_id' => $user->id,
                'agent' => 'RunCoachAgent',
                'role' => 'assistant',
                'content' => '',
                'meta' => [
                    'message_type' => 'loading_card',
                    'message_payload' => ['label' => 'Analysing Strava Data'],
                ],
            ]);

            AnalyzeRunningProfileJob::dispatch($conversation->id, $user->id);
        }

        $messages = AgentConversationMessage::where('conversation_id', $conversation->id)
            ->orderBy('created_at')
            ->get();

        return response()->json([
            'conversation_id' => $conversation->id,
            'messages' => $messages,
        ]);
    }
}
```

- [ ] **Step 4: Register the route**

Open `api/routes/api.php`. Inside the `Route::middleware('auth:sanctum')` group, add:

```php
Route::prefix('onboarding')->group(function () {
    Route::post('/start', [\App\Http\Controllers\OnboardingController::class, 'start']);
});
```

- [ ] **Step 5: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingStartTest
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): POST /v1/onboarding/start creates onboarding convo + dispatches analysis

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: POST /onboarding/conversations/{id}/messages — branch step

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — add `reply` action
- Modify: `api/routes/api.php`
- Test: `api/tests/Feature/Http/OnboardingBranchTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingBranchTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingBranchTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_race_branch_appends_user_message_and_race_prompt(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'awaiting_branch'],
        ]);

        $response = $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'Race coming up!',
            'chip_value' => 'race',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['messages']);

        $messages = AgentConversationMessage::where('conversation_id', $convo->id)
            ->orderBy('created_at')
            ->get();

        $this->assertCount(2, $messages);
        $this->assertEquals('user', $messages[0]->role);
        $this->assertEquals('Race coming up!', $messages[0]->content);
        $this->assertEquals('assistant', $messages[1]->role);
        $this->assertStringContainsString("let's get you going", $messages[1]->content);

        $convo->refresh();
        $this->assertEquals('awaiting_race_details', $convo->meta['onboarding_step']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingBranchTest
```

Expected: FAIL — route undefined.

- [ ] **Step 3: Add the `reply` action**

Open `api/app/Http/Controllers/OnboardingController.php`. Add method:

```php
public function reply(Request $request, string $conversationId): JsonResponse
{
    $validated = $request->validate([
        'text' => 'required|string',
        'chip_value' => 'nullable|string',
    ]);

    $conversation = AgentConversation::where('id', $conversationId)
        ->where('user_id', $request->user()->id)
        ->where('context', 'onboarding')
        ->firstOrFail();

    $chipValue = $validated['chip_value'];

    // Persist user message
    AgentConversationMessage::create([
        'id' => (string) Str::uuid(),
        'conversation_id' => $conversation->id,
        'user_id' => $request->user()->id,
        'agent' => 'RunCoachAgent',
        'role' => 'user',
        'content' => $validated['text'],
        'meta' => $chipValue ? ['chip_value' => $chipValue] : [],
    ]);

    $step = $conversation->meta['onboarding_step'] ?? 'awaiting_branch';
    $newMessages = $this->advance($conversation, $step, $validated['text'], $chipValue);

    return response()->json(['messages' => $newMessages]);
}

/**
 * Drive the state machine forward by one user reply.
 * Returns the newly appended assistant messages.
 */
private function advance(AgentConversation $conversation, string $step, string $text, ?string $chipValue): array
{
    $appended = [];

    if ($step === 'awaiting_branch') {
        $branch = $chipValue ?? $this->resolveChip($text, ['race', 'general_fitness', 'pr_attempt', 'skip']);

        if ($branch === 'race') {
            $appended[] = $this->appendAssistant($conversation, 'text', $this->racePromptCopy());
            $this->setStep($conversation, 'awaiting_race_details');
        }
        // Other branches handled in Tasks 10-11-13-14
    }

    return $appended;
}

private function racePromptCopy(): string
{
    return "Alright, let's get you going!\n\n"
        . "To create the plan, I need 3 things:\n"
        . "  1. Race name\n"
        . "  2. Race date\n"
        . "  3. Goal time, if you have one\n\n"
        . "Optional but helpful:\n"
        . "  • Race distance if it's not obvious from the name\n"
        . "  • How many days/week you want to run\n"
        . "  • Any injuries or days you can't train\n\n"
        . "Send me something like: \"City 10K, 12th of september 2025, goal 55:00, 4 days/week\"";
}

private function resolveChip(string $text, array $expected): ?string
{
    // Stub: strict lowercase match. Full LLM classifier in Task 13.
    $normalized = strtolower(trim($text));
    foreach ($expected as $value) {
        if (str_contains($normalized, $value)) return $value;
    }
    return null;
}

private function appendAssistant(AgentConversation $conversation, string $type, string $content = '', array $payload = []): AgentConversationMessage
{
    return AgentConversationMessage::create([
        'id' => (string) Str::uuid(),
        'conversation_id' => $conversation->id,
        'user_id' => $conversation->user_id,
        'agent' => 'RunCoachAgent',
        'role' => 'assistant',
        'content' => $content,
        'meta' => [
            'message_type' => $type,
            'message_payload' => $payload,
        ],
    ]);
}

private function setStep(AgentConversation $conversation, string $step): void
{
    $meta = $conversation->meta ?? [];
    $meta['onboarding_step'] = $step;
    $conversation->meta = $meta;
    $conversation->save();
}
```

- [ ] **Step 4: Register the route**

In `api/routes/api.php`, extend the onboarding group:

```php
Route::prefix('onboarding')->group(function () {
    Route::post('/start', [\App\Http\Controllers\OnboardingController::class, 'start']);
    Route::post('/conversations/{conversationId}/messages', [\App\Http\Controllers\OnboardingController::class, 'reply']);
});
```

- [ ] **Step 5: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingBranchTest
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): onboarding reply endpoint — handles race branch step

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 9: Race path → coach_style chip step

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — extend `advance()` for `awaiting_race_details` → `awaiting_coach_style`
- Test: `api/tests/Feature/Http/OnboardingRacePathTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingRacePathTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingRacePathTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_race_details_transitions_to_coach_style(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => [
                'onboarding_step' => 'awaiting_race_details',
                'path' => 'race',
            ],
        ]);

        $response = $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week',
        ]);

        $response->assertOk();

        $last = AgentConversationMessage::where('conversation_id', $convo->id)
            ->where('role', 'assistant')
            ->orderByDesc('created_at')
            ->first();

        $this->assertEquals('chip_suggestions', $last->meta['message_type']);
        $chipValues = array_column($last->meta['message_payload']['chips'], 'value');
        $this->assertEquals(['strict', 'balanced', 'flexible'], $chipValues);

        $convo->refresh();
        $this->assertEquals('awaiting_coach_style', $convo->meta['onboarding_step']);
        $this->assertEquals('Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week', $convo->meta['race_details_raw']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingRacePathTest
```

Expected: FAIL — step handler missing.

- [ ] **Step 3: Also set `path` on branch selection**

Update the `awaiting_branch` case in `advance()` so it stores the chosen path:

```php
if ($step === 'awaiting_branch') {
    $branch = $chipValue ?? $this->resolveChip($text, ['race', 'general_fitness', 'pr_attempt', 'skip']);

    $meta = $conversation->meta ?? [];
    $meta['path'] = $branch;
    $conversation->meta = $meta;
    $conversation->save();

    if ($branch === 'race') {
        $appended[] = $this->appendAssistant($conversation, 'text', $this->racePromptCopy());
        $this->setStep($conversation, 'awaiting_race_details');
    }
    // ... other branches
}
```

- [ ] **Step 4: Add the race-details handler**

In `advance()`, add a new branch:

```php
if ($step === 'awaiting_race_details') {
    $meta = $conversation->meta ?? [];
    $meta['race_details_raw'] = $text;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'text', "One last thing — how do you want me to coach you?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => 'Strict — hold me to it', 'value' => 'strict'],
            ['label' => 'Balanced', 'value' => 'balanced'],
            ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_coach_style');
}
```

- [ ] **Step 5: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingRacePathTest
```

Expected: PASS.

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): onboarding race path → coach_style chip step

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: General fitness + Get faster paths

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — add handlers for general_fitness and pr_attempt branches + their follow-ups
- Test: `api/tests/Feature/Http/OnboardingNonRacePathsTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingNonRacePathsTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingNonRacePathsTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_general_fitness_path_asks_days_per_week(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'awaiting_branch'],
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'General fitness', 'chip_value' => 'general_fitness',
        ])->assertOk();

        $convo->refresh();
        $this->assertEquals('awaiting_fitness_days', $convo->meta['onboarding_step']);

        $last = AgentConversationMessage::where('conversation_id', $convo->id)
            ->where('role', 'assistant')->orderByDesc('created_at')->first();
        $this->assertEquals('chip_suggestions', $last->meta['message_type']);
        $this->assertCount(5, $last->meta['message_payload']['chips']); // 2,3,4,5,6 days
    }

    public function test_general_fitness_days_transitions_to_coach_style(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'awaiting_fitness_days', 'path' => 'general_fitness'],
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => '4 days', 'chip_value' => '4',
        ])->assertOk();

        $convo->refresh();
        $this->assertEquals('awaiting_coach_style', $convo->meta['onboarding_step']);
        $this->assertEquals(4, $convo->meta['days_per_week']);
    }

    public function test_pr_attempt_path_walks_distance_pr_days(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'awaiting_branch'],
        ]);

        // Step 1: Get faster → distance chip
        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'Get faster', 'chip_value' => 'pr_attempt',
        ])->assertOk();
        $convo->refresh();
        $this->assertEquals('awaiting_faster_distance', $convo->meta['onboarding_step']);

        // Step 2: pick 5k
        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => '5k', 'chip_value' => '5k',
        ])->assertOk();
        $convo->refresh();
        $this->assertEquals('awaiting_faster_pr_target', $convo->meta['onboarding_step']);
        $this->assertEquals('5k', $convo->meta['distance']);

        // Step 3: free text PR + target
        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'currently 22:30, target 20:00',
        ])->assertOk();
        $convo->refresh();
        $this->assertEquals('awaiting_faster_days', $convo->meta['onboarding_step']);
        $this->assertEquals('currently 22:30, target 20:00', $convo->meta['pr_target_raw']);

        // Step 4: days chip
        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => '4 days', 'chip_value' => '4',
        ])->assertOk();
        $convo->refresh();
        $this->assertEquals('awaiting_coach_style', $convo->meta['onboarding_step']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingNonRacePathsTest
```

Expected: FAIL for all three tests.

- [ ] **Step 3: Implement the general_fitness branch in `advance()`**

Inside the `awaiting_branch` case, after the race branch block, add:

```php
if ($branch === 'general_fitness') {
    $appended[] = $this->appendAssistant($conversation, 'text', "Nice — let's keep you moving. How many days per week can you run?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => '2 days', 'value' => '2'],
            ['label' => '3 days', 'value' => '3'],
            ['label' => '4 days', 'value' => '4'],
            ['label' => '5 days', 'value' => '5'],
            ['label' => '6 days', 'value' => '6'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_fitness_days');
}

if ($branch === 'pr_attempt') {
    $appended[] = $this->appendAssistant($conversation, 'text', "What distance do you want to get faster at?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => '5k', 'value' => '5k'],
            ['label' => '10k', 'value' => '10k'],
            ['label' => 'Half marathon', 'value' => 'half_marathon'],
            ['label' => 'Marathon', 'value' => 'marathon'],
            ['label' => 'Custom', 'value' => 'custom'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_faster_distance');
}
```

- [ ] **Step 4: Implement step handlers**

Add more step handlers in `advance()`:

```php
if ($step === 'awaiting_fitness_days') {
    $days = (int) ($chipValue ?? $this->resolveChip($text, ['2', '3', '4', '5', '6']));
    $meta = $conversation->meta ?? [];
    $meta['days_per_week'] = $days;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'text', "Got it. One last thing — how do you want me to coach you?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => 'Strict — hold me to it', 'value' => 'strict'],
            ['label' => 'Balanced', 'value' => 'balanced'],
            ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_coach_style');
}

if ($step === 'awaiting_faster_distance') {
    $distance = $chipValue ?? $this->resolveChip($text, ['5k', '10k', 'half_marathon', 'marathon', 'custom']);
    $meta = $conversation->meta ?? [];
    $meta['distance'] = $distance;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'text', "What's your current PR and target? e.g. \"currently 22:30, target 20:00\"");
    $this->setStep($conversation, 'awaiting_faster_pr_target');
}

if ($step === 'awaiting_faster_pr_target') {
    $meta = $conversation->meta ?? [];
    $meta['pr_target_raw'] = $text;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'text', "How many days per week?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => '2 days', 'value' => '2'],
            ['label' => '3 days', 'value' => '3'],
            ['label' => '4 days', 'value' => '4'],
            ['label' => '5 days', 'value' => '5'],
            ['label' => '6 days', 'value' => '6'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_faster_days');
}

if ($step === 'awaiting_faster_days') {
    $days = (int) ($chipValue ?? $this->resolveChip($text, ['2', '3', '4', '5', '6']));
    $meta = $conversation->meta ?? [];
    $meta['days_per_week'] = $days;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'text', "One last thing — how do you want me to coach you?");
    $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
        'chips' => [
            ['label' => 'Strict — hold me to it', 'value' => 'strict'],
            ['label' => 'Balanced', 'value' => 'balanced'],
            ['label' => 'Flexible — adapt to my life', 'value' => 'flexible'],
        ],
    ]);
    $this->setStep($conversation, 'awaiting_coach_style');
}
```

- [ ] **Step 5: Run the tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingNonRacePathsTest
```

Expected: PASS (all three).

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): onboarding general fitness + get faster paths

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 11: coach_style → plan generation + agent handoff

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — handle `awaiting_coach_style` → `plan_generating` → invoke agent
- Modify: `api/app/Models/User.php` — ensure `coach_style` is fillable (likely already is)
- Test: `api/tests/Feature/Http/OnboardingCoachStyleTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingCoachStyleTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingCoachStyleTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_coach_style_choice_stores_on_user_and_enqueues_plan_generation(): void
    {
        $user = User::factory()->create(['coach_style' => null]);
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => [
                'onboarding_step' => 'awaiting_coach_style',
                'path' => 'race',
                'race_details_raw' => 'Amsterdam Half, 18 oct 2026, sub 1:45, 4 days/week',
            ],
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'Balanced',
            'chip_value' => 'balanced',
        ])->assertOk();

        $user->refresh();
        $this->assertEquals('balanced', $user->coach_style);

        $convo->refresh();
        $this->assertEquals('plan_generating', $convo->meta['onboarding_step']);

        $last = AgentConversationMessage::where('conversation_id', $convo->id)
            ->where('role', 'assistant')->orderByDesc('created_at')->first();
        $this->assertEquals('loading_card', $last->meta['message_type']);
        $this->assertEquals('Working on your plan', $last->meta['message_payload']['label']);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingCoachStyleTest
```

Expected: FAIL.

- [ ] **Step 3: Add the handler**

In `OnboardingController::advance()`, add:

```php
if ($step === 'awaiting_coach_style') {
    $coachStyle = $chipValue ?? $this->resolveChip($text, ['strict', 'balanced', 'flexible']);

    $user = $conversation->user;
    $user->coach_style = $coachStyle;
    $user->save();

    // Also mirror into conversation meta so the plan-generation job can read it.
    $meta = $conversation->meta ?? [];
    $meta['coach_style'] = $coachStyle;
    $conversation->meta = $meta;
    $conversation->save();

    $appended[] = $this->appendAssistant($conversation, 'loading_card', '', [
        'label' => 'Working on your plan',
    ]);
    $this->setStep($conversation, 'plan_generating');

    // Dispatch agent to call CreateSchedule with accumulated context.
    \App\Jobs\RunOnboardingPlanAgentJob::dispatch($conversation->id, $user->id);
}
```

- [ ] **Step 4: Create the plan-generation job stub**

Create `api/app/Jobs/RunOnboardingPlanAgentJob.php`:

```php
<?php

namespace App\Jobs;

use Illuminate\Bus\Queueable;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Bus\Dispatchable;
use Illuminate\Queue\InteractsWithQueue;
use Illuminate\Queue\SerializesModels;
use Laravel\Ai\Agents\Conversations\AgentConversation;

class RunOnboardingPlanAgentJob implements ShouldQueue
{
    use Dispatchable, InteractsWithQueue, Queueable, SerializesModels;

    public function __construct(
        public string $conversationId,
        public int $userId,
    ) {}

    public function handle(\App\Ai\Agents\RunCoachAgent $agent): void
    {
        $conversation = AgentConversation::findOrFail($this->conversationId);
        $meta = $conversation->meta ?? [];

        $path = $meta['path'] ?? 'race';
        $seed = $this->buildSeedMessage($meta);

        // Use the existing agent prompt pathway — the conversation already has scripted history.
        $agent->setConversation($conversation);
        $agent->prompt($seed);

        // Agent will call CreateSchedule internally; proposal is stored via existing ProposalService.
        $this->advanceStep($conversation);
    }

    private function buildSeedMessage(array $meta): string
    {
        $path = $meta['path'];
        $coachStyle = $meta['coach_style'] ?? 'balanced';

        if ($path === 'race') {
            return "The user completed onboarding. Path: race. Raw race input: \""
                . ($meta['race_details_raw'] ?? '') . "\". Coach style: {$coachStyle}. "
                . "Now call CreateSchedule with goal_type='race', parsing the race input for goal_name, target_date, goal_time_seconds, distance. "
                . "Use the running profile to size the plan appropriately.";
        }

        if ($path === 'general_fitness') {
            $days = $meta['days_per_week'] ?? 3;
            return "The user completed onboarding. Path: general_fitness. Days/week: {$days}. Coach style: {$coachStyle}. "
                . "Call CreateSchedule with goal_type='general_fitness', goal_name='General fitness', target_date=null, distance=null. "
                . "Design a base-building weekly pattern with {$days} runs/week.";
        }

        if ($path === 'pr_attempt') {
            $distance = $meta['distance'] ?? '5k';
            $prRaw = $meta['pr_target_raw'] ?? '';
            $days = $meta['days_per_week'] ?? 4;
            return "The user completed onboarding. Path: pr_attempt. Distance: {$distance}. PR/target raw: \"{$prRaw}\". Days/week: {$days}. Coach style: {$coachStyle}. "
                . "Call CreateSchedule with goal_type='pr_attempt', goal_name='Get faster at {$distance}', target_date=null, distance='{$distance}'. "
                . "Parse the PR/target string for goal_time_seconds. Design a speed-focused block.";
        }

        return 'Generate a training plan based on onboarding context.';
    }

    private function advanceStep(AgentConversation $conversation): void
    {
        $meta = $conversation->meta ?? [];
        $meta['onboarding_step'] = 'plan_proposed';
        $conversation->meta = $meta;
        $conversation->save();
    }
}
```

- [ ] **Step 5: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingCoachStyleTest
```

Expected: PASS. (The test only checks the pre-job state, not the agent run.)

- [ ] **Step 6: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): coach_style → plan_generating + enqueue plan agent job

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 12: Free-text-to-chip LLM classifier

**Files:**
- Create: `api/app/Services/ChipClassifier.php`
- Modify: `api/app/Http/Controllers/OnboardingController.php` — use the classifier instead of strict string matching
- Test: `api/tests/Feature/Services/ChipClassifierTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Services/ChipClassifierTest.php`:

```php
<?php

namespace Tests\Feature\Services;

use App\Services\ChipClassifier;
use Mockery;
use OpenAI\Client as OpenAIClient;
use Tests\TestCase;

class ChipClassifierTest extends TestCase
{
    public function test_classifies_free_text_against_chip_options(): void
    {
        $openai = Mockery::mock(OpenAIClient::class);
        $chat = Mockery::mock();
        $openai->shouldReceive('chat')->andReturn($chat);
        $chat->shouldReceive('create')->once()->andReturn((object) [
            'choices' => [(object) [
                'message' => (object) ['content' => '{"value": "race"}'],
            ]],
        ]);

        $classifier = new ChipClassifier($openai);
        $result = $classifier->classify(
            'I have a marathon coming up',
            [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
                ['label' => 'Not sure yet', 'value' => 'skip'],
            ],
        );

        $this->assertEquals('race', $result);
    }

    public function test_returns_null_when_llm_says_none(): void
    {
        $openai = Mockery::mock(OpenAIClient::class);
        $chat = Mockery::mock();
        $openai->shouldReceive('chat')->andReturn($chat);
        $chat->shouldReceive('create')->once()->andReturn((object) [
            'choices' => [(object) [
                'message' => (object) ['content' => '{"value": null}'],
            ]],
        ]);

        $classifier = new ChipClassifier($openai);
        $result = $classifier->classify('tell me a joke', [
            ['label' => 'Race coming up!', 'value' => 'race'],
        ]);

        $this->assertNull($result);
    }

    public function test_returns_null_on_openai_failure(): void
    {
        $openai = Mockery::mock(OpenAIClient::class);
        $chat = Mockery::mock();
        $openai->shouldReceive('chat')->andReturn($chat);
        $chat->shouldReceive('create')->andThrow(new \Exception('down'));

        $classifier = new ChipClassifier($openai);
        $this->assertNull($classifier->classify('foo', [['label' => 'X', 'value' => 'x']]));
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=ChipClassifierTest
```

Expected: FAIL — class missing.

- [ ] **Step 3: Create the classifier**

Create `api/app/Services/ChipClassifier.php`:

```php
<?php

namespace App\Services;

use OpenAI\Client as OpenAIClient;

class ChipClassifier
{
    public function __construct(private readonly OpenAIClient $openai) {}

    /**
     * Classify free text against a list of chip options.
     *
     * @param  array<int, array{label: string, value: string}>  $chips
     * @return string|null  The matched chip value, or null if no match.
     */
    public function classify(string $text, array $chips): ?string
    {
        try {
            $options = array_map(fn ($c) => "- {$c['label']} (value: {$c['value']})", $chips);
            $prompt = "User wrote: \"{$text}\".\n\nOptions:\n" . implode("\n", $options)
                . "\n\nWhich option's value best matches the user's intent? "
                . "If no option clearly matches, return null. "
                . "Return JSON only: {\"value\": \"<value or null>\"}.";

            $response = $this->openai->chat()->create([
                'model' => config('services.openai.classifier_model', 'gpt-4o-mini'),
                'temperature' => 0.0,
                'response_format' => ['type' => 'json_object'],
                'messages' => [
                    ['role' => 'user', 'content' => $prompt],
                ],
            ]);

            $raw = $response->choices[0]->message->content ?? '{}';
            $parsed = json_decode($raw, true);
            $value = $parsed['value'] ?? null;

            $validValues = array_column($chips, 'value');
            return in_array($value, $validValues, true) ? $value : null;
        } catch (\Throwable $e) {
            \Illuminate\Support\Facades\Log::warning('Chip classification failed', ['error' => $e->getMessage()]);
            return null;
        }
    }
}
```

- [ ] **Step 4: Wire into `OnboardingController`**

In `OnboardingController.php`, replace the `resolveChip()` helper so it uses the classifier when the strict match fails:

```php
public function __construct(private readonly \App\Services\ChipClassifier $chipClassifier) {}

private function resolveChip(string $text, array $expectedValues): ?string
{
    $normalized = strtolower(trim($text));

    // Cheap path — exact or substring match.
    foreach ($expectedValues as $value) {
        if ($normalized === strtolower($value) || str_contains($normalized, strtolower($value))) {
            return $value;
        }
    }

    // LLM fallback — needs chip structure, so reshape input.
    $chips = array_map(fn ($v) => ['label' => $v, 'value' => $v], $expectedValues);
    return $this->chipClassifier->classify($text, $chips);
}
```

Note: for chip steps, the caller should pass real labels (not just values) when richer context helps the LLM. For simplicity this pass uses value-as-label; future enhancement could thread the real labels through.

- [ ] **Step 5: Handle no-match (re-prompt)**

In `advance()`, if `$branch`/`$coachStyle`/`$days`/etc. comes back null from `resolveChip`, re-prompt instead of advancing the step:

Example for `awaiting_branch`:

```php
if ($step === 'awaiting_branch') {
    $branch = $chipValue ?? $this->resolveChip($text, ['race', 'general_fitness', 'pr_attempt', 'skip']);

    if ($branch === null) {
        $appended[] = $this->appendAssistant($conversation, 'text', "I didn't quite catch that — which of these matches?");
        $appended[] = $this->appendAssistant($conversation, 'chip_suggestions', '', [
            'chips' => [
                ['label' => 'Race coming up!', 'value' => 'race'],
                ['label' => 'General fitness', 'value' => 'general_fitness'],
                ['label' => 'Get faster', 'value' => 'pr_attempt'],
                ['label' => 'Not sure yet', 'value' => 'skip'],
            ],
        ]);
        // Do not advance step
        return $appended;
    }

    // ... existing handling
}
```

Apply the same re-prompt pattern to `awaiting_fitness_days`, `awaiting_faster_distance`, `awaiting_faster_days`, `awaiting_coach_style`.

- [ ] **Step 6: Run the tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=ChipClassifier
php artisan test --filter=Onboarding
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): ChipClassifier — LLM-backed free-text → chip value mapping

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 13: "Not sure yet" — POST /onboarding/abandon

**Files:**
- Modify: `api/app/Http/Controllers/OnboardingController.php` — add `abandon` action + skip branch handler
- Modify: `api/routes/api.php`
- Test: `api/tests/Feature/Http/OnboardingAbandonTest.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/Http/OnboardingAbandonTest.php`:

```php
<?php

namespace Tests\Feature\Http;

use App\Models\User;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class OnboardingAbandonTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_not_sure_yet_chip_marks_onboarding_complete_without_goal(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);
        Sanctum::actingAs($user);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
            'meta' => ['onboarding_step' => 'awaiting_branch'],
        ]);

        $this->postJson("/api/v1/onboarding/conversations/{$convo->id}/messages", [
            'text' => 'Not sure yet',
            'chip_value' => 'skip',
        ])->assertOk();

        $user->refresh();
        $this->assertTrue($user->has_completed_onboarding);

        $convo->refresh();
        $this->assertEquals('abandoned', $convo->meta['onboarding_step']);

        $last = AgentConversationMessage::where('conversation_id', $convo->id)
            ->where('role', 'assistant')->orderByDesc('created_at')->first();
        $this->assertStringContainsString('No stress', $last->content);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingAbandonTest
```

Expected: FAIL.

- [ ] **Step 3: Handle the skip branch in `advance()`**

In the `awaiting_branch` case, add:

```php
if ($branch === 'skip') {
    $user = $conversation->user;
    $user->has_completed_onboarding = true;
    $user->save();

    $appended[] = $this->appendAssistant($conversation, 'text',
        "No stress. Your running history is in and I've got it from here. "
        . "Whenever you want to set a goal, just ask me — I'll be on the coach tab."
    );
    $this->setStep($conversation, 'abandoned');
}
```

- [ ] **Step 4: Run the test**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=OnboardingAbandonTest
```

Expected: PASS.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): onboarding 'Not sure yet' abandons with goodbye, no goal created

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 4 — AI tool updates

## Task 14: `GetRunningProfile` new tool + `RunCoachAgent` updates

**Files:**
- Create: `api/app/Ai/Tools/GetRunningProfile.php`
- Modify: `api/app/Ai/Agents/RunCoachAgent.php` — register new tool; update instructions; handle onboarding context
- Modify: `api/app/Services/ProposalService.php` — flip `has_completed_onboarding = true` when accepting a proposal in onboarding context
- Test: `api/tests/Feature/Ai/GetRunningProfileToolTest.php`
- Test: `api/tests/Feature/Services/ProposalServiceOnboardingTest.php`

- [ ] **Step 1: Write the `GetRunningProfile` test**

Create `api/tests/Feature/Ai/GetRunningProfileToolTest.php`:

```php
<?php

namespace Tests\Feature\Ai;

use App\Ai\Tools\GetRunningProfile;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Tests\TestCase;

class GetRunningProfileToolTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_returns_cached_profile_as_json(): void
    {
        $user = User::factory()->create();
        UserRunningProfile::create([
            'user_id' => $user->id,
            'metrics' => ['weekly_avg_km' => 30.0],
            'narrative_summary' => 'Strong year',
            'analyzed_at' => now(),
        ]);

        $tool = new GetRunningProfile();
        $result = $tool->handle($user, []);
        $decoded = json_decode($result, true);

        $this->assertEquals(30.0, $decoded['metrics']['weekly_avg_km']);
        $this->assertEquals('Strong year', $decoded['narrative_summary']);
    }

    public function test_returns_empty_profile_message_when_none_exists(): void
    {
        $user = User::factory()->create();
        $tool = new GetRunningProfile();
        $result = $tool->handle($user, []);
        $decoded = json_decode($result, true);
        $this->assertArrayHasKey('message', $decoded);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=GetRunningProfileToolTest
```

Expected: FAIL.

- [ ] **Step 3: Create the tool**

Create `api/app/Ai/Tools/GetRunningProfile.php`. Mirror the pattern of existing tools (`GetCurrentSchedule.php`):

```php
<?php

namespace App\Ai\Tools;

use App\Models\User;
use App\Models\UserRunningProfile;
use Laravel\Ai\Schema\Tool;

class GetRunningProfile
{
    public static function schema(): Tool
    {
        return Tool::make('get_running_profile')
            ->description('Get the cached 12-month running profile for the current user. Fast lookup — does not re-fetch from Strava. Returns metrics (weekly averages, pace, consistency, trends) and a narrative summary. Use this when you need context on the user\'s running history for planning or analysis questions. DO NOT use this for date-range queries — use search_strava_activities for that.');
    }

    public function handle(User $user, array $params): string
    {
        $profile = UserRunningProfile::where('user_id', $user->id)->first();

        if (!$profile) {
            return json_encode([
                'message' => 'No running profile cached yet. The user has not completed onboarding or analysis has not run.',
            ]);
        }

        return json_encode([
            'analyzed_at' => optional($profile->analyzed_at)->toIso8601String(),
            'metrics' => $profile->metrics,
            'narrative_summary' => $profile->narrative_summary,
        ]);
    }
}
```

- [ ] **Step 4: Register the tool in `RunCoachAgent`**

Open `api/app/Ai/Agents/RunCoachAgent.php`. In the `tools()` method (or wherever tools are registered), add `GetRunningProfile::schema()`. Add the handler mapping following the existing pattern. Update `instructions()` to mention:

```
- Use get_running_profile for a fast snapshot of the user's 12-month running history (weekly averages, pace, consistency, trends). Fast lookup, no Strava call.
- Goals can have type 'race', 'general_fitness', or 'pr_attempt'. For non-race goal types, target_date and/or distance may be null.
- When creating a schedule, always set goal_type. For general_fitness: target_date=null, distance=null. For pr_attempt: target_date can be null, distance required.
```

- [ ] **Step 5: Proposal service updates**

Open `api/app/Services/ProposalService.php`. In the `apply(CoachProposal $proposal)` method (or equivalent), after the proposal is successfully applied, check if the proposal's conversation has `context='onboarding'` and if so, set the user's `has_completed_onboarding = true`:

```php
$conversation = \Laravel\Ai\Agents\Conversations\AgentConversation::find($proposal->agentMessage->conversation_id);
if ($conversation && $conversation->context === 'onboarding') {
    $user = $proposal->user;
    $user->has_completed_onboarding = true;
    $user->save();
}
```

- [ ] **Step 6: Write the proposal-service test**

Create `api/tests/Feature/Services/ProposalServiceOnboardingTest.php`:

```php
<?php

namespace Tests\Feature\Services;

use App\Models\CoachProposal;
use App\Models\User;
use App\Services\ProposalService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Str;
use Laravel\Ai\Agents\Conversations\AgentConversation;
use Laravel\Ai\Agents\Conversations\AgentConversationMessage;
use Tests\TestCase;

class ProposalServiceOnboardingTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_accepting_proposal_in_onboarding_context_flips_flag(): void
    {
        $user = User::factory()->create(['has_completed_onboarding' => false]);

        $convo = AgentConversation::create([
            'id' => (string) Str::uuid(),
            'user_id' => $user->id,
            'title' => 'Onboarding',
            'context' => 'onboarding',
        ]);
        $msg = AgentConversationMessage::create([
            'id' => (string) Str::uuid(),
            'conversation_id' => $convo->id,
            'user_id' => $user->id,
            'agent' => 'RunCoachAgent',
            'role' => 'assistant',
            'content' => '',
        ]);
        $proposal = CoachProposal::create([
            'user_id' => $user->id,
            'agent_message_id' => $msg->id,
            'type' => 'create_schedule',
            'status' => 'pending',
            'payload' => [
                'goal_type' => 'race',
                'goal_name' => 'Amsterdam Half',
                'distance' => 'half_marathon',
                'goal_time_seconds' => 6300,
                'target_date' => '2026-10-18',
                'schedule' => ['weeks' => []],
            ],
        ]);

        app(ProposalService::class)->apply($proposal);

        $user->refresh();
        $this->assertTrue($user->has_completed_onboarding);
    }
}
```

- [ ] **Step 7: Run the tests**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --filter=GetRunningProfile
php artisan test --filter=ProposalServiceOnboarding
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add api
git commit -m "$(cat <<'EOF'
feat(api): GetRunningProfile tool + onboarding completion on proposal accept

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 5 — Flutter message types

## Task 15: Extend `CoachMessage` model + regenerate Freezed

**Files:**
- Modify: `app/lib/features/coach/models/coach_message.dart`

- [ ] **Step 1: Extend the model**

Open `app/lib/features/coach/models/coach_message.dart`. Add two fields:

```dart
@freezed
sealed class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required String id,
    required String role,
    required String content,
    @JsonKey(name: 'message_type') @Default('text') String messageType,
    @JsonKey(name: 'message_payload') Map<String, dynamic>? messagePayload,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
    String? errorDetail,
    @Default(false) bool streaming,
    String? toolIndicator,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) => _$CoachMessageFromJson(json);
}
```

- [ ] **Step 2: Regenerate code**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: updated `coach_message.freezed.dart` and `coach_message.g.dart`.

- [ ] **Step 3: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
feat(app): CoachMessage — messageType + messagePayload for rich bubbles

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 16: `StatsCardBubble` + `ChipSuggestionsRow` widgets

**Files:**
- Create: `app/lib/features/coach/widgets/stats_card_bubble.dart`
- Create: `app/lib/features/coach/widgets/chip_suggestions_row.dart`

- [ ] **Step 1: Create `StatsCardBubble`**

Create `app/lib/features/coach/widgets/stats_card_bubble.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:app/core/theme/app_theme.dart';

/// Stats card rendered inside the bot-message bubble. 2x2 grid of metric tiles.
class StatsCardBubble extends StatelessWidget {
  final Map<String, dynamic> metrics;

  const StatsCardBubble({super.key, required this.metrics});

  @override
  Widget build(BuildContext context) {
    final tiles = <_Tile>[
      _Tile(
        label: 'WEEKLY\nAVG. KM',
        value: _formatKm(metrics['weekly_avg_km']),
      ),
      _Tile(
        label: 'WEEKLY\nAVG. RUNS',
        value: '${metrics['weekly_avg_runs'] ?? 0}',
      ),
      _Tile(
        label: 'AVG PACE',
        value: _formatPace(metrics['avg_pace_seconds_per_km']),
      ),
      _Tile(
        label: 'SESSION\nAVG. TIME',
        value: _formatDuration(metrics['session_avg_duration_seconds']),
      ),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: _metric(tiles[0])),
          const SizedBox(width: 8),
          Expanded(child: _metric(tiles[1])),
        ]),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: _metric(tiles[2])),
          const SizedBox(width: 8),
          Expanded(child: _metric(tiles[3])),
        ]),
      ],
    );
  }

  Widget _metric(_Tile t) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.lightTan,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(color: Color(0x08000000), blurRadius: 16),
          ],
        ),
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              t.label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF817662),
                letterSpacing: 0.96,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              t.value,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1C1C15),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatKm(dynamic v) => v == null ? '0' : (v is num ? v.toStringAsFixed(1) : '$v');

  String _formatPace(dynamic seconds) {
    if (seconds == null || seconds is! num || seconds == 0) return '—';
    final s = seconds.toInt();
    final mins = s ~/ 60;
    final secs = s % 60;
    return "$mins'${secs.toString().padLeft(2, '0')}\"";
  }

  String _formatDuration(dynamic seconds) {
    if (seconds == null || seconds is! num || seconds == 0) return '—';
    final s = seconds.toInt();
    final mins = s ~/ 60;
    final secs = s % 60;
    return "$mins:${secs.toString().padLeft(2, '0')}";
  }
}

class _Tile {
  final String label;
  final String value;
  const _Tile({required this.label, required this.value});
}
```

- [ ] **Step 2: Create `ChipSuggestionsRow`**

Create `app/lib/features/coach/widgets/chip_suggestions_row.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

class ChipSuggestionsRow extends StatelessWidget {
  final List<Map<String, dynamic>> chips;
  final void Function(String label, String value) onTap;

  const ChipSuggestionsRow({
    super.key,
    required this.chips,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        alignment: WrapAlignment.end,
        children: chips.map((c) {
          final label = (c['label'] as String?) ?? '';
          final value = (c['value'] as String?) ?? label;
          return InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => onTap(label, value),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                label,
                style: const TextStyle(fontSize: 14, color: Colors.black),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
```

Note: `AppColors.border` — if it doesn't exist yet, use `Color(0xFFE8DCC9)` or check `app/lib/core/theme/app_theme.dart` for the right token.

- [ ] **Step 3: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
feat(app): StatsCardBubble + ChipSuggestionsRow widgets

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 17: `MessageBubble` type switch — wire rich message types

**Files:**
- Modify: `app/lib/features/coach/widgets/message_bubble.dart`
- Modify: the file that calls `MessageBubble` (probably `coach_chat_screen.dart`) — pass chip tap callback through

- [ ] **Step 1: Add type switch in `MessageBubble`**

Open `app/lib/features/coach/widgets/message_bubble.dart`. Add imports:

```dart
import 'package:app/features/coach/widgets/thinking_card.dart';
import 'package:app/features/coach/widgets/stats_card_bubble.dart';
import 'package:app/features/coach/widgets/chip_suggestions_row.dart';
```

In the `build` method, before rendering the default text bubble, dispatch on `message.messageType`:

```dart
@override
Widget build(BuildContext context) {
  final type = message.messageType;
  final payload = message.messagePayload ?? const {};

  if (type == 'loading_card') {
    return _assistantWrapper(
      ThinkingCard(label: (payload['label'] as String?) ?? 'Thinking…'),
    );
  }

  if (type == 'stats_card') {
    return _assistantWrapper(
      _StatsCardInBubble(metrics: (payload['metrics'] as Map<String, dynamic>?) ?? const {}),
    );
  }

  if (type == 'chip_suggestions') {
    return ChipSuggestionsRow(
      chips: ((payload['chips'] as List?) ?? const []).cast<Map<String, dynamic>>(),
      onTap: onChipTap ?? (_, __) {},
    );
  }

  // Default: existing text bubble rendering below...
  // (keep the existing code as-is)
}
```

Add a `final void Function(String label, String value)? onChipTap;` field to `MessageBubble` constructor params. Make it optional.

Wrap the `ThinkingCard` and `_StatsCardInBubble` in the bot-label + role chrome the existing bubbles use — extract the role label into a `_assistantWrapper(child)` helper:

```dart
Widget _assistantWrapper(Widget child) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const _RoleLabel(role: 'assistant'),
      const SizedBox(height: 8),
      child,
    ],
  );
}
```

Where `_StatsCardInBubble` is a local widget that wraps `StatsCardBubble` inside the white bot-bubble styling matching the Figma (bubble with `topRight` zero, other corners 24, white bg, border, padding 24, contains narrative text placeholder + `StatsCardBubble`):

```dart
class _StatsCardInBubble extends StatelessWidget {
  final Map<String, dynamic> metrics;
  const _StatsCardInBubble({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.zero,
            topRight: Radius.circular(24),
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
        ),
        child: StatsCardBubble(metrics: metrics),
      ),
    );
  }
}
```

- [ ] **Step 2: Thread chip tap callback through the chat screen**

Open `app/lib/features/coach/screens/coach_chat_screen.dart`. Wherever it builds `MessageBubble`, pass:

```dart
onChipTap: (label, value) => ref
    .read(coachChatProvider(conversationId).notifier)
    .sendMessage(label, chipValue: value),
```

(Positional `label`, named `chipValue`.) The `sendMessage` method on the provider should already exist — if it doesn't take `chipValue`, extend its signature:

```dart
Future<void> sendMessage(String text, {String? chipValue}) async { ... }
```

and pass `chip_value` in the POST body to `/coach/conversations/{id}/messages`.

Update `app/lib/features/coach/providers/coach_chat_provider.dart` — in `sendMessage`, accept an optional `chipValue` and pass it to the API call.

Update `app/lib/features/coach/data/coach_api.dart` — the send-message endpoint body must include `chip_value`. If it's the existing `/coach/conversations/{id}/messages` endpoint, that route needs to accept the field too (backend: update the existing send controller to accept and pass through to the model meta).

For simplicity at this step: the Flutter side assumes there's a `chipValue` param on the provider. Add it. Backend side is already set up for the onboarding route; for the regular coach route it'll just be ignored.

- [ ] **Step 3: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
feat(app): MessageBubble dispatches on messageType (loading/stats/chips)

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 18: Update `ProposalCard` to Figma layout

**Files:**
- Modify: `app/lib/features/coach/widgets/proposal_card.dart`

- [ ] **Step 1: Replace the proposal card layout**

Open `app/lib/features/coach/widgets/proposal_card.dart`. Replace the body rendering with the Figma-styled layout: summary (Weekly km | Weekly runs) + View Details ghost + Accept (yellow `#E9B638`) / Adjust (black):

```dart
import 'package:flutter/material.dart';
import 'package:app/features/coach/models/coach_proposal.dart';
import 'package:google_fonts/google_fonts.dart';

class ProposalCard extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback? onAccept;
  final VoidCallback? onAdjust;
  final VoidCallback? onViewDetails;

  const ProposalCard({
    super.key,
    required this.proposal,
    this.onAccept,
    this.onAdjust,
    this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    final payload = proposal.payload;
    final weeklyKm = _computeWeeklyKm(payload);
    final weeklyRuns = _computeWeeklyRuns(payload);
    final pending = proposal.status == 'pending';

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 296),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: const Color(0x14000000)),
          boxShadow: const [BoxShadow(color: Color(0x08000000), blurRadius: 16)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _summaryItem('WEEKLY KM', '${weeklyKm.toStringAsFixed(1)} km')),
                const SizedBox(width: 32),
                Expanded(child: _summaryItem('WEEKLY RUNS', weeklyRuns)),
              ],
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: onViewDetails,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                backgroundColor: const Color(0xFFF7F3E8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.visibility_outlined, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'VIEW DETAILS',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
            if (pending) ...[
              const SizedBox(height: 8),
              Row(children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE9B638),
                      foregroundColor: const Color(0xFF1A1A1A),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('ACCEPT PLAN', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAdjust,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A1A1A),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text('ADJUST', style: GoogleFonts.spaceGrotesk(fontSize: 12, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ] else ...[
              const SizedBox(height: 8),
              Text(
                proposal.status == 'accepted' ? 'Plan accepted.' : 'Plan rejected.',
                style: const TextStyle(color: Color(0xFF817662)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12, fontWeight: FontWeight.w500,
            color: Color(0xFF817662), letterSpacing: 0.96,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 24, fontWeight: FontWeight.w600,
            color: const Color(0xFF1C1C15),
          ),
        ),
      ],
    );
  }

  double _computeWeeklyKm(Map<String, dynamic> payload) {
    final schedule = payload['schedule'] as Map<String, dynamic>?;
    final weeks = schedule?['weeks'] as List?;
    if (weeks == null || weeks.isEmpty) return 0.0;
    final totals = weeks.map((w) => (w as Map)['total_km']).whereType<num>().toList();
    if (totals.isEmpty) return 0.0;
    return totals.reduce((a, b) => a + b) / totals.length;
  }

  String _computeWeeklyRuns(Map<String, dynamic> payload) {
    final schedule = payload['schedule'] as Map<String, dynamic>?;
    final weeks = schedule?['weeks'] as List?;
    if (weeks == null || weeks.isEmpty) return '0';
    final counts = weeks.map((w) {
      final days = ((w as Map)['days'] as List?)?.where((d) => (d as Map)['type'] != 'rest').length ?? 0;
      return days;
    }).toList();
    final min = counts.reduce((a, b) => a < b ? a : b);
    final max = counts.reduce((a, b) => a > b ? a : b);
    return min == max ? '$min' : '$min to $max';
  }
}
```

- [ ] **Step 2: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 3: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
feat(app): ProposalCard — Figma layout with weekly summary + accept/adjust

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 6 — Flutter shell + routing

## Task 19: Extract `CoachChatView` from `CoachChatScreen`

**Files:**
- Create: `app/lib/features/coach/widgets/coach_chat_view.dart`
- Modify: `app/lib/features/coach/screens/coach_chat_screen.dart` — delegate body to `CoachChatView`

- [ ] **Step 1: Create the view widget**

Create `app/lib/features/coach/widgets/coach_chat_view.dart`. Copy the body (message list + input + scroll controller logic) from `CoachChatScreen` into this new widget. It accepts a `conversationId` and builds:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/coach/providers/coach_chat_provider.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';

class CoachChatView extends ConsumerStatefulWidget {
  final String conversationId;

  const CoachChatView({super.key, required this.conversationId});

  @override
  ConsumerState<CoachChatView> createState() => _CoachChatViewState();
}

class _CoachChatViewState extends ConsumerState<CoachChatView> {
  final ScrollController _scroll = ScrollController();
  final TextEditingController _input = TextEditingController();

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachChatProvider(widget.conversationId));

    return Column(
      children: [
        Expanded(
          child: messagesAsync.when(
            data: (messages) => ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: MessageBubble(
                  message: messages[i],
                  onChipTap: (label, value) => ref
                      .read(coachChatProvider(widget.conversationId).notifier)
                      .sendMessage(label, chipValue: value),
                ),
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(children: [
              Expanded(
                child: TextField(
                  controller: _input,
                  decoration: const InputDecoration(hintText: 'Ask your coach...'),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  final text = _input.text.trim();
                  if (text.isEmpty) return;
                  ref.read(coachChatProvider(widget.conversationId).notifier).sendMessage(text);
                  _input.clear();
                },
              ),
            ]),
          ),
        ),
      ],
    );
  }
}
```

Adapt the specifics (theme colors, scroll-to-bottom behavior) from the current `CoachChatScreen` code — read that file to mirror its exact input styling.

- [ ] **Step 2: Simplify `CoachChatScreen`**

Open `app/lib/features/coach/screens/coach_chat_screen.dart`. Replace its body with `CoachChatView(conversationId: widget.conversationId)`. Keep its existing AppBar/Scaffold/back-button chrome.

- [ ] **Step 3: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 4: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
refactor(app): extract CoachChatView so onboarding can reuse it

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 20: `OnboardingShell` + `onboardingConversationProvider` + API client

**Files:**
- Create: `app/lib/features/onboarding/data/onboarding_api.dart`
- Create: `app/lib/features/onboarding/providers/onboarding_provider.dart`
- Create: `app/lib/features/onboarding/screens/onboarding_shell.dart`

- [ ] **Step 1: Retrofit API client**

Create `app/lib/features/onboarding/data/onboarding_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'onboarding_api.g.dart';

@RestApi()
abstract class OnboardingApi {
  factory OnboardingApi(Dio dio) = _OnboardingApi;

  @POST('/onboarding/start')
  Future<dynamic> start();
}

@riverpod
OnboardingApi onboardingApi(Ref ref) {
  return OnboardingApi(ref.watch(dioClientProvider));
}
```

- [ ] **Step 2: Provider**

Create `app/lib/features/onboarding/providers/onboarding_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/onboarding/data/onboarding_api.dart';

part 'onboarding_provider.g.dart';

@riverpod
Future<String> onboardingConversationId(Ref ref) async {
  final api = ref.watch(onboardingApiProvider);
  final result = await api.start();
  return (result as Map<String, dynamic>)['conversation_id'] as String;
}
```

- [ ] **Step 3: Shell**

Create `app/lib/features/onboarding/screens/onboarding_shell.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/coach/widgets/coach_chat_view.dart';
import 'package:app/features/onboarding/providers/onboarding_provider.dart';
import 'package:app/core/theme/app_theme.dart';

class OnboardingShell extends ConsumerWidget {
  const OnboardingShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(onboardingConversationIdProvider);

    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
        title: const _LogoTitle(),
      ),
      body: idAsync.when(
        data: (id) => CoachChatView(conversationId: id),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Couldn\'t start onboarding: $e')),
      ),
    );
  }
}

class _LogoTitle extends StatelessWidget {
  const _LogoTitle();

  @override
  Widget build(BuildContext context) {
    // Use existing logo widget if one exists; otherwise render brand mark + text
    return const Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.star, color: Color(0xFFE9B638)),
        SizedBox(width: 8),
        Text('RunCore', style: TextStyle(fontSize: 22, color: Colors.black)),
      ],
    );
  }
}
```

If there's already a reusable logo widget (check `app/lib/core/widgets/` or similar), swap `_LogoTitle` to use it.

- [ ] **Step 4: Register route**

Open `app/lib/router/app_router.dart`. Replace the `/onboarding` placeholder (added in Task 2) with:

```dart
GoRoute(
  path: '/onboarding',
  builder: (_, __) => const OnboardingShell(),
),
```

Add the import.

- [ ] **Step 5: Regenerate code**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 6: Analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
feat(app): OnboardingShell + onboarding API + conversationId provider

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 21: Delete old onboarding form + update auth cleanup

**Files:**
- Delete: `app/lib/features/auth/screens/onboarding_screen.dart`
- Modify: `app/lib/features/auth/providers/auth_provider.dart` — remove `updateOnboarding` method
- Modify: `app/lib/features/auth/data/auth_api.dart` (if it has an onboarding endpoint method) — remove it
- Modify: `app/lib/router/app_router.dart` — remove `/auth/onboarding` route

- [ ] **Step 1: Remove the old screen and its route**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
git rm lib/features/auth/screens/onboarding_screen.dart
```

Open `app/lib/router/app_router.dart` and delete the GoRoute for `/auth/onboarding`. Remove its import.

- [ ] **Step 2: Remove `updateOnboarding` from auth provider**

Open `app/lib/features/auth/providers/auth_provider.dart`. Delete the `updateOnboarding(...)` method entirely.

- [ ] **Step 3: Remove the old API method**

Open `app/lib/features/auth/data/auth_api.dart` (or equivalent). Delete any method that POSTs to `/profile/onboarding`. Regenerate if needed.

- [ ] **Step 4: Regenerate + analyze**

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

Expected: 0 issues.

- [ ] **Step 5: Commit**

```bash
cd /Users/erwinwijnveld/projects/runcoach
git add app
git commit -m "$(cat <<'EOF'
refactor(app): delete old onboarding form + /auth/onboarding route

Co-Authored-By: Claude Opus 4.6 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

# Phase 7 — End-to-end verification

## Task 22: Manual verification

**Files:** none (manual testing only)

- [ ] **Step 1: Start backend + Flutter**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
composer run dev
```

In another terminal:

```bash
cd /Users/erwinwijnveld/projects/runcoach/app
flutter run
```

- [ ] **Step 2: Happy path — Race**

1. On the Welcome screen, tap "Connect with Strava". Complete OAuth.
2. App should route to `/onboarding`. Confirm: centered RunCore logo, no back arrow, no bottom nav.
3. Loading card "Analysing Strava Data" appears.
4. After analysis, narrative bubble + 2×2 stats card appear, followed by "Anything you're training for, or want to work toward?" + 4 chips.
5. Tap "Race coming up!". Race prompt appears.
6. Send free text: `City 10K, 12 sep 2025, goal 55:00, 4 days/week`.
7. Coach style chips appear. Tap "Balanced".
8. "Working on your plan" card shows; after a few seconds, a proposal card appears.
9. Tap "Accept plan". App routes to `/dashboard`.
10. In MySQL, verify `goals` row exists with `type='race'`, `name` parsed correctly, `target_date='2025-09-12'`, `goal_time_seconds=3300`.
11. Relaunch the app — should go straight to `/dashboard`, not `/onboarding`.

- [ ] **Step 3: Happy path — General fitness**

Delete user + Strava token or create a new test account. Repeat OAuth.

1. In onboarding, tap "General fitness".
2. Chips appear: 2/3/4/5/6 days. Tap "4 days".
3. Coach style chips appear. Tap any.
4. "Working on your plan" → proposal.
5. Accept.
6. In DB, verify `goals.type='general_fitness'`, `target_date IS NULL`, `distance IS NULL`, `name='General fitness'` (or similar).

- [ ] **Step 4: Happy path — Get faster**

Fresh user.

1. Tap "Get faster".
2. Distance chips. Tap "5k".
3. Free text: `currently 22:30, target 20:00`.
4. Days chips. Tap "4 days".
5. Coach style. Tap any.
6. "Working on your plan" → proposal. Accept.
7. In DB, verify `goals.type='pr_attempt'`, `distance='5k'`, `goal_time_seconds=1200` (20:00), `target_date IS NULL`.

- [ ] **Step 5: Happy path — Not sure yet**

Fresh user.

1. Tap "Not sure yet".
2. Goodbye message appears.
3. App routes to `/dashboard`.
4. In DB, confirm `users.has_completed_onboarding=true`, **no** `goals` row for this user.
5. Relaunch app — goes to `/dashboard`.

- [ ] **Step 6: Edge — resume mid-onboarding**

1. Start a fresh onboarding. After the stats card shows, before tapping a chip, kill the app.
2. Relaunch. Should still route to `/onboarding`. The previous chat history should render (loading card → narrative → stats card → chips). Tap a chip, confirm it proceeds normally.

- [ ] **Step 7: Edge — free text instead of chip**

1. Fresh onboarding. When the branch chips appear, type `I have a half marathon in three months` in the text input and send.
2. The `ChipClassifier` should resolve this to `race` and proceed with the race prompt.
3. If the classifier isn't confident, the bot re-prompts with the same chips.

- [ ] **Step 8: Edge — Strava failure**

1. Revoke the Strava token for a test user (via Strava settings).
2. Start onboarding. The `AnalyzeRunningProfileJob` fails and marks the conversation `analysis_failed`. The loading card should flip to an error variant (if the error-variant bubble is wired up in `MessageBubble` — if not, note this as a follow-up task to handle).

- [ ] **Step 9: Confirm test suite still green**

```bash
cd /Users/erwinwijnveld/projects/runcoach/api
php artisan test --compact
```

Expected: all tests pass (new + existing).

- [ ] **Step 10: Final commit (if any manual-test fixes were needed)**

If Steps 2–8 revealed bugs, fix inline, commit individually with descriptive messages, and re-run the manual checklist.

---

## Done

After Task 22, the feature is complete:
- Pre-launch DB has `goals` instead of `races`, fresh schema.
- New users connect Strava → land on chat-shaped onboarding → end on an active goal (or abandon cleanly).
- Running profile is cached and reusable by the agent.
- All 4 paths exercised; all 45+ backend tests green; `flutter analyze` clean.

Follow-up work (tracked as deferred in the spec): profile refresh cron, streaming SSE, admin funnel view, re-onboarding flow, i18n.
