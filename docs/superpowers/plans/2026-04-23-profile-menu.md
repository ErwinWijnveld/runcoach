# Profile Menu + Account Deletion Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the static avatar in `AppHeader` with the user's Strava profile picture (fallback to a minimal Cupertino person icon), and make it tap-open a native iOS-style bottom sheet with filler settings rows plus two bottom actions: destructive "Verwijder gegevens" (delete all user data → welcome screen) and neutral "Uitloggen".

**Architecture:**
- Backend: new nullable `strava_profile_url` column on `users` (edit existing migration in place — pre-launch), populated in `StravaSyncService::createOrUpdateUser` from `profile_medium` / `profile`. New `DELETE /api/v1/profile` endpoint tears down all user-owned rows (including `agent_conversations` + `personal_access_tokens` which have no FK cascade) inside a transaction.
- Flutter: `AppHeader` becomes a `ConsumerWidget` that reads `authProvider`, renders `Image.network` if URL present else `CupertinoIcons.person_fill`, and opens a new `ProfileMenuSheet` via `showCupertinoModalPopup`. Sheet exposes 4 filler rows + destructive delete + logout. Delete calls `authProvider.deleteAccount()` → token storage cleanup → auth state null → router redirects to `/auth/welcome`.

**Tech Stack:** Laravel 13, PHPUnit, Sanctum / Flutter, Riverpod, Freezed, Retrofit, GoRouter, CupertinoModalPopup

---

## File Structure

**Backend — create:**
- `api/tests/Feature/DeleteAccountTest.php` — tests delete endpoint + cascade cleanup
- `api/tests/Feature/StravaProfilePictureTest.php` — tests `strava_profile_url` is stored on OAuth sync

**Backend — modify:**
- `api/database/migrations/0001_01_01_000000_create_users_table.php` — add `strava_profile_url` column
- `api/app/Models/User.php` — add `strava_profile_url` to `#[Fillable]`
- `api/app/Services/StravaSyncService.php` — extract + store `profile_medium` / `profile`
- `api/app/Http/Controllers/ProfileController.php` — add `destroy()` method; include `strava_profile_url` in `show()` / `update()` responses
- `api/routes/api.php` — add `DELETE /profile` route

**Flutter — create:**
- `app/lib/core/widgets/profile_menu_sheet.dart` — the bottom sheet widget + show helper

**Flutter — modify:**
- `app/lib/features/auth/models/user.dart` — add `stravaProfileUrl` field (regen `.g.dart` + `.freezed.dart`)
- `app/lib/features/auth/data/auth_api.dart` — add `deleteAccount()` method
- `app/lib/features/auth/providers/auth_provider.dart` — add `deleteAccount()` method (calls endpoint, clears token, sets state null)
- `app/lib/core/widgets/app_header.dart` — convert to `ConsumerWidget`, render profile URL/fallback icon, wire tap → sheet

---

## Task 1: Add `strava_profile_url` to users migration + model

**Files:**
- Modify: `api/database/migrations/0001_01_01_000000_create_users_table.php:18-20`
- Modify: `api/app/Models/User.php:19`

- [ ] **Step 1: Add the column to the users migration**

Edit in place (pre-launch — no new migration). Insert a line after `strava_athlete_id`:

```php
$table->bigInteger('strava_athlete_id')->unique()->nullable();
$table->string('strava_profile_url')->nullable();
$table->string('coach_style')->default('balanced');
```

- [ ] **Step 2: Add `strava_profile_url` to the `#[Fillable]` attribute on User**

```php
#[Fillable(['name', 'email', 'password', 'strava_athlete_id', 'strava_profile_url', 'coach_style', 'has_completed_onboarding', 'heart_rate_zones'])]
```

- [ ] **Step 3: Run migrate:fresh + seed**

Run: `cd api && php artisan migrate:fresh --seed`
Expected: no errors, `users` table recreated with new column.

- [ ] **Step 4: Verify column exists**

Run: `cd api && php artisan tinker --execute 'echo json_encode(Schema::getColumnListing("users"));'`
Expected: output contains `"strava_profile_url"`.

- [ ] **Step 5: Run pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`
Expected: either "No files need to be fixed" or a small list of fixed files.

- [ ] **Step 6: Commit**

```bash
git add api/database/migrations/0001_01_01_000000_create_users_table.php api/app/Models/User.php
git commit -m "feat(api): add strava_profile_url column to users"
```

---

## Task 2: Store Strava profile picture URL on OAuth sync (TDD)

**Files:**
- Create: `api/tests/Feature/StravaProfilePictureTest.php`
- Modify: `api/app/Services/StravaSyncService.php:38-48`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/StravaProfilePictureTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Services\StravaSyncService;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class StravaProfilePictureTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_profile_medium_url_is_stored_on_user(): void
    {
        // Stub the athlete/zones call to avoid the outbound HTTP request.
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999001,
                'firstname' => 'Eliud',
                'lastname' => 'Kipchoge',
                'email' => 'eliud@example.com',
                'profile_medium' => 'https://dgalywyr863hv.cloudfront.net/pictures/athletes/medium.jpg',
                'profile' => 'https://dgalywyr863hv.cloudfront.net/pictures/athletes/large.jpg',
            ],
        ]);

        $this->assertSame(
            'https://dgalywyr863hv.cloudfront.net/pictures/athletes/medium.jpg',
            $user->fresh()->strava_profile_url,
        );
    }

    public function test_falls_back_to_profile_when_medium_missing(): void
    {
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999002,
                'firstname' => 'A',
                'lastname' => 'B',
                'email' => 'a@b.com',
                'profile' => 'https://example.com/fallback.jpg',
            ],
        ]);

        $this->assertSame('https://example.com/fallback.jpg', $user->fresh()->strava_profile_url);
    }

    public function test_null_when_strava_returns_placeholder(): void
    {
        Http::fake([
            'https://www.strava.com/api/v3/athlete/zones' => Http::response([], 200),
        ]);

        $service = app(StravaSyncService::class);

        // Strava returns the literal string "avatar/athlete/large.png" when the
        // athlete has no profile picture set.
        $user = $service->createOrUpdateUser([
            'access_token' => 'at',
            'refresh_token' => 'rt',
            'expires_at' => now()->addHour()->timestamp,
            'athlete' => [
                'id' => 999003,
                'firstname' => 'A',
                'lastname' => 'B',
                'email' => 'c@d.com',
                'profile_medium' => 'avatar/athlete/medium.png',
                'profile' => 'avatar/athlete/large.png',
            ],
        ]);

        $this->assertNull($user->fresh()->strava_profile_url);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd api && php artisan test --compact --filter=StravaProfilePictureTest`
Expected: FAIL — `strava_profile_url` is null (code doesn't extract it yet).

- [ ] **Step 3: Update `createOrUpdateUser` to extract and store the URL**

Replace the `User::updateOrCreate` block in `api/app/Services/StravaSyncService.php` (lines 42-48):

```php
$profileUrl = $this->extractProfileUrl($athlete);

$user = User::updateOrCreate(
    ['strava_athlete_id' => $athlete['id']],
    [
        'name' => trim($athlete['firstname'].' '.$athlete['lastname']),
        'email' => $athlete['email'] ?? $athlete['id'].'@strava.runcoach',
        'strava_profile_url' => $profileUrl,
    ]
);
```

Then add the helper method at the bottom of the class (before the closing `}`):

```php
/**
 * Extract a usable profile picture URL from Strava's athlete payload.
 * Prefers `profile_medium`, falls back to `profile`. Strava returns the
 * literal path "avatar/athlete/..." when the user has no picture set —
 * we treat that as null.
 */
private function extractProfileUrl(array $athlete): ?string
{
    $url = $athlete['profile_medium'] ?? $athlete['profile'] ?? null;

    if (! is_string($url) || $url === '') {
        return null;
    }

    if (! str_starts_with($url, 'http')) {
        return null;
    }

    return $url;
}
```

- [ ] **Step 4: Run test to verify it passes**

Run: `cd api && php artisan test --compact --filter=StravaProfilePictureTest`
Expected: PASS — 3 assertions.

- [ ] **Step 5: Run pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 6: Commit**

```bash
git add api/app/Services/StravaSyncService.php api/tests/Feature/StravaProfilePictureTest.php
git commit -m "feat(api): store Strava profile picture URL on user sync"
```

---

## Task 3: Include `strava_profile_url` in profile responses

**Files:**
- Modify: `api/app/Http/Controllers/ProfileController.php:11-31`

- [ ] **Step 1: Add `strava_profile_url` to both `show()` and `update()` whitelists**

Replace the `only([...])` lists in `ProfileController`:

```php
public function show(Request $request): JsonResponse
{
    return response()->json([
        'user' => $request->user()->only([
            'id', 'name', 'email', 'strava_athlete_id', 'strava_profile_url',
            'coach_style', 'has_completed_onboarding',
        ]),
    ]);
}

public function update(UpdateProfileRequest $request): JsonResponse
{
    $request->user()->update($request->validated());

    return response()->json([
        'user' => $request->user()->fresh()->only([
            'id', 'name', 'email', 'strava_athlete_id', 'strava_profile_url',
            'coach_style', 'has_completed_onboarding',
        ]),
    ]);
}
```

- [ ] **Step 2: Run existing profile tests to ensure nothing regressed**

Run: `cd api && php artisan test --compact --filter=Profile`
Expected: PASS (all existing profile-related tests).

- [ ] **Step 3: Run pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 4: Commit**

```bash
git add api/app/Http/Controllers/ProfileController.php
git commit -m "feat(api): expose strava_profile_url in profile endpoint"
```

---

## Task 4: Implement `DELETE /api/v1/profile` endpoint (TDD)

This endpoint must remove ALL data owned by the user:
- Cascade via FK (already in place): `strava_tokens`, `strava_activities`, `goals` → `training_weeks` → `training_days` → `training_results`, `coach_proposals`, `user_running_profiles`.
- Null-on-delete (keeps anonymised history): `token_usages`.
- **No FK cascade** — must be deleted explicitly: `agent_conversations` + `agent_conversation_messages` (`user_id` is nullable bigint, not a foreign key), and `personal_access_tokens` (Sanctum polymorphic).

**Files:**
- Create: `api/tests/Feature/DeleteAccountTest.php`
- Modify: `api/app/Http/Controllers/ProfileController.php`
- Modify: `api/routes/api.php`

- [ ] **Step 1: Write the failing test**

Create `api/tests/Feature/DeleteAccountTest.php`:

```php
<?php

namespace Tests\Feature;

use App\Models\CoachProposal;
use App\Models\Goal;
use App\Models\StravaActivity;
use App\Models\StravaToken;
use App\Models\TrainingDay;
use App\Models\TrainingResult;
use App\Models\TrainingWeek;
use App\Models\User;
use App\Models\UserRunningProfile;
use Illuminate\Foundation\Testing\LazilyRefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DeleteAccountTest extends TestCase
{
    use LazilyRefreshDatabase;

    public function test_unauthenticated_request_is_rejected(): void
    {
        $this->deleteJson('/api/v1/profile')->assertStatus(401);
    }

    public function test_deletes_user_and_all_owned_rows(): void
    {
        $user = User::factory()->create();

        // Seed rows across every user-owned table.
        StravaToken::factory()->create(['user_id' => $user->id]);
        StravaActivity::factory()->create(['user_id' => $user->id]);
        UserRunningProfile::factory()->create(['user_id' => $user->id]);
        $goal = Goal::factory()->create(['user_id' => $user->id]);
        $week = TrainingWeek::factory()->create(['goal_id' => $goal->id]);
        $day = TrainingDay::factory()->create(['training_week_id' => $week->id]);
        TrainingResult::factory()->create(['training_day_id' => $day->id]);

        // Agent conversation (no FK — must delete manually).
        DB::table('agent_conversations')->insert([
            'id' => 'conv-'.$user->id,
            'user_id' => $user->id,
            'context' => 'coach',
            'created_at' => now(),
            'updated_at' => now(),
        ]);
        DB::table('agent_conversation_messages')->insert([
            'id' => 'msg-'.$user->id,
            'conversation_id' => 'conv-'.$user->id,
            'role' => 'user',
            'content' => 'hi',
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertNull(User::find($user->id));
        $this->assertSame(0, StravaToken::where('user_id', $user->id)->count());
        $this->assertSame(0, StravaActivity::where('user_id', $user->id)->count());
        $this->assertSame(0, UserRunningProfile::where('user_id', $user->id)->count());
        $this->assertSame(0, Goal::where('user_id', $user->id)->count());
        $this->assertSame(0, TrainingWeek::where('goal_id', $goal->id)->count());
        $this->assertSame(0, TrainingDay::where('training_week_id', $week->id)->count());
        $this->assertSame(0, TrainingResult::where('training_day_id', $day->id)->count());
        $this->assertSame(0, DB::table('agent_conversations')->where('user_id', $user->id)->count());
        $this->assertSame(0, DB::table('agent_conversation_messages')->where('conversation_id', 'conv-'.$user->id)->count());
    }

    public function test_deletes_sanctum_tokens_for_user(): void
    {
        $user = User::factory()->create();
        $user->createToken('device-1');
        $user->createToken('device-2');

        $this->assertSame(2, DB::table('personal_access_tokens')
            ->where('tokenable_id', $user->id)
            ->where('tokenable_type', User::class)
            ->count());

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertSame(0, DB::table('personal_access_tokens')
            ->where('tokenable_id', $user->id)
            ->where('tokenable_type', User::class)
            ->count());
    }

    public function test_does_not_delete_other_users_data(): void
    {
        $victim = User::factory()->create();
        $bystander = User::factory()->create();

        Goal::factory()->create(['user_id' => $victim->id]);
        $bystanderGoal = Goal::factory()->create(['user_id' => $bystander->id]);

        $this->actingAs($victim, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        $this->assertNotNull(User::find($bystander->id));
        $this->assertNotNull(Goal::find($bystanderGoal->id));
    }

    public function test_preserves_anonymised_token_usage_history(): void
    {
        $user = User::factory()->create();
        DB::table('token_usages')->insert([
            'user_id' => $user->id,
            'agent_class' => 'App\\Ai\\Agents\\RunCoachAgent',
            'context' => 'coach',
            'provider' => 'anthropic',
            'model' => 'claude-sonnet-4-6',
            'prompt_tokens' => 100,
            'completion_tokens' => 50,
            'cache_read_input_tokens' => 0,
            'cache_write_input_tokens' => 0,
            'reasoning_tokens' => 0,
            'total_tokens' => 150,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        $this->actingAs($user, 'sanctum')
            ->deleteJson('/api/v1/profile')
            ->assertStatus(204);

        // Row survives, but user_id is nulled (nullOnDelete FK).
        $this->assertSame(1, DB::table('token_usages')->count());
        $this->assertNull(DB::table('token_usages')->first()->user_id);
    }
}
```

- [ ] **Step 2: Run test to verify it fails**

Run: `cd api && php artisan test --compact --filter=DeleteAccountTest`
Expected: FAIL — route doesn't exist yet (404 or 405).

- [ ] **Step 3: Add the route**

Edit `api/routes/api.php`, inside the `auth:sanctum` group, under the existing profile routes:

```php
// Profile
Route::get('profile', [ProfileController::class, 'show']);
Route::put('profile', [ProfileController::class, 'update']);
Route::delete('profile', [ProfileController::class, 'destroy']);
```

- [ ] **Step 4: Implement the controller method**

Add to `api/app/Http/Controllers/ProfileController.php`:

```php
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;
use App\Models\User;
```

Then the method:

```php
public function destroy(Request $request): Response
{
    /** @var User $user */
    $user = $request->user();

    DB::transaction(function () use ($user) {
        // Sanctum tokens: polymorphic, no FK cascade from users.
        $user->tokens()->delete();

        // Laravel AI SDK tables: `user_id` is a nullable bigint with no FK
        // constraint, so user deletion does not cascade. Delete explicitly.
        $conversationIds = DB::table('agent_conversations')
            ->where('user_id', $user->id)
            ->pluck('id');

        if ($conversationIds->isNotEmpty()) {
            DB::table('agent_conversation_messages')
                ->whereIn('conversation_id', $conversationIds)
                ->delete();

            DB::table('agent_conversations')
                ->whereIn('id', $conversationIds)
                ->delete();
        }

        // Everything else (strava_tokens, strava_activities, goals →
        // training_weeks → training_days → training_results, coach_proposals,
        // user_running_profiles) cascades via FK. token_usages is preserved
        // with user_id set to null (nullOnDelete).
        $user->delete();
    });

    return response()->noContent();
}
```

- [ ] **Step 5: Run the test to verify it passes**

Run: `cd api && php artisan test --compact --filter=DeleteAccountTest`
Expected: PASS — 5 assertions.

- [ ] **Step 6: Run the full test suite to check for regressions**

Run: `cd api && php artisan test --compact`
Expected: All 91+ tests pass.

- [ ] **Step 7: Run pint**

Run: `cd api && vendor/bin/pint --dirty --format agent`

- [ ] **Step 8: Commit**

```bash
git add api/app/Http/Controllers/ProfileController.php api/routes/api.php api/tests/Feature/DeleteAccountTest.php
git commit -m "feat(api): add DELETE /profile endpoint to wipe user data"
```

---

## Task 5: Add `stravaProfileUrl` to Flutter User model

**Files:**
- Modify: `app/lib/features/auth/models/user.dart`
- Regen: `app/lib/features/auth/models/user.freezed.dart`, `app/lib/features/auth/models/user.g.dart`

- [ ] **Step 1: Add the field to the freezed model**

Replace the body of `user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
sealed class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'strava_athlete_id') int? stravaAthleteId,
    @JsonKey(name: 'strava_profile_url') String? stravaProfileUrl,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'has_completed_onboarding') @Default(false) bool hasCompletedOnboarding,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

- [ ] **Step 2: Regenerate code**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: successful build, `user.freezed.dart` and `user.g.dart` refreshed.

- [ ] **Step 3: Analyze to catch missing references**

Run: `cd app && flutter analyze`
Expected: clean, or warnings unrelated to this change.

- [ ] **Step 4: Commit**

```bash
git add app/lib/features/auth/models/user.dart app/lib/features/auth/models/user.freezed.dart app/lib/features/auth/models/user.g.dart
git commit -m "feat(app): add stravaProfileUrl to User model"
```

---

## Task 6: Add `deleteAccount` API call + provider method

**Files:**
- Modify: `app/lib/features/auth/data/auth_api.dart:23`
- Modify: `app/lib/features/auth/providers/auth_provider.dart:72-80`
- Regen: `app/lib/features/auth/data/auth_api.g.dart`, `app/lib/features/auth/providers/auth_provider.g.dart`

- [ ] **Step 1: Add `deleteAccount` to the Retrofit API**

In `app/lib/features/auth/data/auth_api.dart`, add a method just after `logout()`:

```dart
@POST('/auth/logout')
Future<void> logout();

@DELETE('/profile')
Future<void> deleteAccount();

@GET('/profile')
Future<dynamic> getProfile();
```

- [ ] **Step 2: Add `deleteAccount` method to the auth provider**

In `app/lib/features/auth/providers/auth_provider.dart`, add below `logout()`:

```dart
Future<void> deleteAccount() async {
  final api = ref.read(authApiProvider);
  final tokenStorage = ref.read(tokenStorageProvider);
  await api.deleteAccount();
  await tokenStorage.clearToken();
  state = const AsyncValue.data(null);
}
```

Note: unlike `logout()`, this does NOT swallow errors — if the server call fails we want the sheet to surface the error and NOT clear local auth state (so the user can retry).

- [ ] **Step 3: Regenerate code**

Run: `cd app && dart run build_runner build --delete-conflicting-outputs`
Expected: successful build.

- [ ] **Step 4: Analyze**

Run: `cd app && flutter analyze`
Expected: clean.

- [ ] **Step 5: Commit**

```bash
git add app/lib/features/auth/data/auth_api.dart app/lib/features/auth/data/auth_api.g.dart app/lib/features/auth/providers/auth_provider.dart app/lib/features/auth/providers/auth_provider.g.dart
git commit -m "feat(app): add deleteAccount API call + provider method"
```

---

## Task 7: Build the `ProfileMenuSheet` widget

A bottom sheet opened via `showCupertinoModalPopup` with:
- Grabber + cream card container
- User header (avatar 64×64 + name + email)
- 4 filler settings rows (CupertinoListTile-style — leading icon, label, chevron). Tap: no-op for now (do not dismiss).
- Spacer divider
- Destructive "Verwijder gegevens" button (red text, confirms via `showAppConfirm`)
- "Uitloggen" button (secondary text)
- Safe-area bottom padding

**Files:**
- Create: `app/lib/core/widgets/profile_menu_sheet.dart`

- [ ] **Step 1: Create the file**

Write `app/lib/core/widgets/profile_menu_sheet.dart`:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/app_widgets.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

Future<void> showProfileMenuSheet(BuildContext context) {
  return showCupertinoModalPopup<void>(
    context: context,
    builder: (_) => const ProfileMenuSheet(),
  );
}

class ProfileMenuSheet extends ConsumerWidget {
  const ProfileMenuSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            const SizedBox(height: 20),
            _UserHeader(
              name: user?.name ?? 'Runner',
              email: user?.email ?? '',
              profileUrl: user?.stravaProfileUrl,
            ),
            const SizedBox(height: 24),
            const _SettingsSection(children: [
              _SettingRow(icon: CupertinoIcons.person_circle, label: 'Account'),
              _SettingRow(icon: CupertinoIcons.bell, label: 'Notificaties'),
              _SettingRow(icon: CupertinoIcons.lock, label: 'Privacy'),
              _SettingRow(icon: CupertinoIcons.info_circle, label: 'Over'),
            ]),
            const SizedBox(height: 24),
            _DeleteButton(),
            const SizedBox(height: 8),
            const _LogoutButton(),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _UserHeader extends StatelessWidget {
  final String name;
  final String email;
  final String? profileUrl;

  const _UserHeader({required this.name, required this.email, this.profileUrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFFECE8DC),
            borderRadius: BorderRadius.circular(22),
          ),
          clipBehavior: Clip.antiAlias,
          child: profileUrl != null
              ? Image.network(
                  profileUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const _FallbackAvatar(size: 32),
                )
              : const _FallbackAvatar(size: 32),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          email,
          style: TextStyle(
            fontSize: 13,
            color: AppColors.secondary.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  final double size;
  const _FallbackAvatar({required this.size});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: size,
        color: AppColors.secondary.withValues(alpha: 0.6),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final List<Widget> children;
  const _SettingsSection({required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(Container(
          margin: const EdgeInsets.only(left: 52),
          height: 0.5,
          color: AppColors.lightTan,
        ));
      }
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(children: rows),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SettingRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return CupertinoButton(
      padding: EdgeInsets.zero,
      onPressed: () {
        // Filler — not wired yet.
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: AppColors.secondary, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              size: 16,
              color: AppColors.secondary.withValues(alpha: 0.4),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteButton extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        onPressed: () => _confirmAndDelete(context, ref),
        child: const Text(
          'Verwijder gegevens',
          style: TextStyle(
            color: CupertinoColors.systemRed,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showAppConfirm(
      context,
      title: 'Verwijder gegevens',
      message:
          'Dit verwijdert je account, doelen, trainingsschema en chats. Dit kan niet ongedaan worden gemaakt.',
      confirmLabel: 'Verwijder',
      cancelLabel: 'Annuleer',
      destructive: true,
    );
    if (!confirmed) return;
    if (!context.mounted) return;

    try {
      await ref.read(authProvider.notifier).deleteAccount();
      if (!context.mounted) return;
      // Close the sheet — router redirect takes over because auth state is null.
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      await showAppAlert(
        context,
        title: 'Kon gegevens niet verwijderen',
        message: 'Probeer het opnieuw. ($e)',
      );
    }
  }
}

class _LogoutButton extends ConsumerWidget {
  const _LogoutButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: CupertinoButton(
        padding: const EdgeInsets.symmetric(vertical: 14),
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        onPressed: () async {
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;
          Navigator.of(context).pop();
        },
        child: const Text(
          'Uitloggen',
          style: TextStyle(
            color: AppColors.secondary,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
```

> Note: if `AppColors.secondary`, `AppColors.cream`, `AppColors.cardBg`, or `AppColors.lightTan` don't exist or differ, inspect `app/lib/core/theme/app_theme.dart` and adjust the references to match existing theme tokens. Don't invent new ones.

- [ ] **Step 2: Analyze to catch errors**

Run: `cd app && flutter analyze`
Expected: clean (or only warnings about unused imports that you fix).

- [ ] **Step 3: Commit**

```bash
git add app/lib/core/widgets/profile_menu_sheet.dart
git commit -m "feat(app): add ProfileMenuSheet with settings + delete + logout"
```

---

## Task 8: Wire `AppHeader` to show Strava picture + open sheet on tap

**Files:**
- Modify: `app/lib/core/widgets/app_header.dart`

- [ ] **Step 1: Replace the header with a `ConsumerWidget`**

Overwrite the file contents:

```dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/core/widgets/profile_menu_sheet.dart';
import 'package:app/core/widgets/runcore_logo.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class AppHeader extends ConsumerWidget {
  const AppHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).value;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        height: 56,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const RunCoreLogo(starSize: 19, textSize: 20, gap: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.notifications,
                  color: AppColors.secondary,
                  size: 24,
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => showProfileMenuSheet(context),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFECE8DC),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _Avatar(url: user?.stravaProfileUrl),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  final String? url;
  const _Avatar({this.url});

  @override
  Widget build(BuildContext context) {
    if (url == null) {
      return _fallback();
    }
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => _fallback(),
      loadingBuilder: (ctx, child, progress) {
        if (progress == null) return child;
        return _fallback();
      },
    );
  }

  Widget _fallback() {
    return Center(
      child: Icon(
        CupertinoIcons.person_fill,
        size: 18,
        color: AppColors.secondary.withValues(alpha: 0.6),
      ),
    );
  }
}
```

- [ ] **Step 2: Analyze**

Run: `cd app && flutter analyze`
Expected: clean.

- [ ] **Step 3: Run the app and manually verify**

Run: `cd app && flutter run` (or hot reload if already running).
Verify:
- Header avatar shows the Strava profile picture (if the logged-in user has one) OR a subtle person icon.
- Tapping the avatar opens the bottom sheet.
- User name and email appear in the sheet.
- The 4 filler rows are tappable but do nothing visible.
- "Uitloggen" closes the sheet and returns to the welcome screen.
- "Verwijder gegevens" shows a destructive confirm dialog; confirming wipes account and returns to the welcome screen.

(If you can't run a device, skip manual verification and note it in your report.)

- [ ] **Step 4: Commit**

```bash
git add app/lib/core/widgets/app_header.dart
git commit -m "feat(app): open profile menu sheet from header avatar"
```

---

## Task 9: Clean up the old static avatar asset (if unused)

The old header rendered `assets/images/user_avatar.png`. Confirm nothing else references it and remove the file to keep the asset bundle tidy.

**Files:**
- Possibly delete: `app/assets/images/user_avatar.png`

- [ ] **Step 1: Search for remaining references**

Run: `grep -rn "user_avatar" app/lib app/assets 2>/dev/null`
Expected: no hits. If there are hits outside of the old header reference (which we already removed), leave the asset alone and skip the rest of this task.

- [ ] **Step 2: Delete the asset if unused**

Run: `rm app/assets/images/user_avatar.png`

- [ ] **Step 3: Build the app once to make sure nothing references it via asset manifest**

Run: `cd app && flutter analyze && flutter build ios --simulator --no-codesign --debug` (or `flutter run` if already running).
Expected: no asset-manifest errors.

- [ ] **Step 4: Commit (skip if asset still referenced)**

```bash
git add app/assets/images/
git commit -m "chore(app): remove unused static user avatar asset"
```

---

## Task 10: Run full test + analyze pass

- [ ] **Step 1: Run backend tests**

Run: `cd api && php artisan test --compact`
Expected: all tests pass.

- [ ] **Step 2: Run Flutter analyze**

Run: `cd app && flutter analyze`
Expected: clean.

- [ ] **Step 3: Run Flutter tests**

Run: `cd app && flutter test`
Expected: pass.

- [ ] **Step 4: Sanity-check composer.lock sync (Laravel Cloud quirk)**

If `api/composer.lock` changed during this plan (it shouldn't have — no composer updates), run:
```bash
cmp api/composer.lock composer.lock || cp api/composer.lock composer.lock
```
and commit the root `composer.lock` update separately. Skip if the files still match.

---

## Notes / gotchas collected during planning

- **Pre-launch migration rule**: the user memory says to edit migrations in place and `migrate:fresh` rather than adding new migrations. Task 1 follows this.
- **FK coverage audit**: `strava_tokens`, `strava_activities`, `goals` → `training_weeks` → `training_days` → `training_results`, `coach_proposals`, `user_running_profiles` all `cascadeOnDelete`. `token_usages` uses `nullOnDelete` (keeps anonymised history). `agent_conversations` + `agent_conversation_messages` have `user_id` as a plain nullable bigint **without FK constraint** — Task 4 deletes them manually. Sanctum `personal_access_tokens` is polymorphic and also requires explicit deletion via `$user->tokens()->delete()`.
- **No `cached_network_image` in pubspec**: use stock `Image.network` with `errorBuilder` + `loadingBuilder`. Don't add a new dependency for this.
- **`showAppConfirm` signature**: uses `destructive: bool`, NOT `isDestructiveAction`. See `app/lib/core/widgets/app_widgets.dart:335`.
- **Router redirect on auth change**: `app/lib/router/app_router.dart` already redirects to `/auth/welcome` when `authProvider` state becomes null. No explicit `context.go('/auth/welcome')` needed after delete/logout — just clear the state.
- **Strava placeholder URLs**: Strava returns the literal path `avatar/athlete/large.png` (not a full URL) when the athlete has no profile picture. Task 2's `extractProfileUrl` guards against that by requiring `http` prefix.
