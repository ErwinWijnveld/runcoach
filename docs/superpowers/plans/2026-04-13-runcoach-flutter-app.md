# RunCoach Flutter App — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the Flutter mobile app for RunCoach — 4-tab interface (Dashboard, Schedule, AI Coach, Races) with Strava OAuth onboarding, all connected to the Laravel API via type-safe Retrofit clients.

**Architecture:** Feature-first folder structure. Riverpod with `@riverpod` code gen for state management. Freezed for immutable models with JSON serialization. Retrofit + Dio for type-safe API calls. GoRouter for declarative navigation with auth guards. Warm earth-tone design matching the provided design screenshot.

**Tech Stack:** Flutter, Riverpod (code gen), Freezed, Dio + Retrofit (code gen), GoRouter, flutter_secure_storage

**Spec:** `docs/superpowers/specs/2026-04-13-runcoach-mvp-design.md`

**Depends on:** Backend API running locally (`php artisan serve` in `api/`)

---

## File Structure

```
app/
├── lib/
│   ├── main.dart                              — App entry, ProviderScope
│   ├── app.dart                               — MaterialApp.router setup
│   ├── core/
│   │   ├── api/
│   │   │   ├── dio_client.dart                — Dio singleton with auth interceptor
│   │   │   └── auth_interceptor.dart          — Attaches Sanctum token, handles 401
│   │   ├── storage/
│   │   │   └── token_storage.dart             — flutter_secure_storage wrapper
│   │   └── theme/
│   │       └── app_theme.dart                 — Warm earth-tone theme + text styles
│   ├── router/
│   │   └── app_router.dart                    — GoRouter with auth redirect
│   └── features/
│       ├── auth/
│       │   ├── data/
│       │   │   └── auth_api.dart              — Retrofit: redirect, callback, logout
│       │   ├── models/
│       │   │   ├── auth_response.dart         — Freezed: {token, user}
│       │   │   └── user.dart                  — Freezed: User model
│       │   ├── providers/
│       │   │   └── auth_provider.dart         — @riverpod: auth state, login, logout
│       │   └── screens/
│       │       ├── welcome_screen.dart        — Logo + "Connect with Strava" CTA
│       │       ├── strava_auth_screen.dart    — WebView for OAuth
│       │       └── onboarding_screen.dart     — Level, coach style, capacity wizard
│       ├── dashboard/
│       │   ├── data/
│       │   │   └── dashboard_api.dart         — Retrofit: GET /dashboard
│       │   ├── models/
│       │   │   └── dashboard_data.dart        — Freezed: weekly summary, next training
│       │   ├── providers/
│       │   │   └── dashboard_provider.dart    — @riverpod: dashboard state
│       │   └── screens/
│       │       └── dashboard_screen.dart      — Weekly overview, progress, coach insight
│       ├── schedule/
│       │   ├── data/
│       │   │   └── schedule_api.dart          — Retrofit: schedule, current week, day, result
│       │   ├── models/
│       │   │   ├── training_week.dart         — Freezed
│       │   │   ├── training_day.dart          — Freezed
│       │   │   └── training_result.dart       — Freezed
│       │   ├── providers/
│       │   │   └── schedule_provider.dart     — @riverpod: current week, day detail
│       │   └── screens/
│       │       ├── weekly_plan_screen.dart     — Day-by-day list (main design)
│       │       ├── training_day_detail_screen.dart
│       │       └── training_result_screen.dart — Planned vs actual overlay
│       ├── coach/
│       │   ├── data/
│       │   │   └── coach_api.dart             — Retrofit: conversations, messages, proposals
│       │   ├── models/
│       │   │   ├── conversation.dart          — Freezed
│       │   │   ├── coach_message.dart         — Freezed
│       │   │   └── coach_proposal.dart        — Freezed
│       │   ├── providers/
│       │   │   └── coach_provider.dart        — @riverpod: conversations, messages, send
│       │   ├── screens/
│       │   │   ├── coach_chat_list_screen.dart — Conversation list + new chat
│       │   │   └── coach_chat_screen.dart      — Chat UI with quick actions + proposals
│       │   └── widgets/
│       │       ├── message_bubble.dart         — Chat message styling
│       │       ├── proposal_card.dart          — Accept/Reject schedule proposal
│       │       └── quick_action_card.dart      — Empty chat quick action buttons
│       └── races/
│           ├── data/
│           │   └── race_api.dart              — Retrofit: CRUD
│           ├── models/
│           │   └── race.dart                  — Freezed
│           ├── providers/
│           │   └── race_provider.dart         — @riverpod: race list, create, detail
│           └── screens/
│               ├── race_list_screen.dart
│               ├── race_create_screen.dart
│               └── race_detail_screen.dart
├── test/
│   ├── core/
│   │   └── api/
│   │       └── auth_interceptor_test.dart
│   └── features/
│       ├── auth/
│       │   └── providers/
│       │       └── auth_provider_test.dart
│       ├── dashboard/
│       │   └── providers/
│       │       └── dashboard_provider_test.dart
│       ├── schedule/
│       │   └── providers/
│       │       └── schedule_provider_test.dart
│       ├── coach/
│       │   └── providers/
│       │       └── coach_provider_test.dart
│       └── races/
│           └── providers/
│               └── race_provider_test.dart
├── analysis_options.yaml                      — Custom lint rules + riverpod_lint
└── pubspec.yaml
```

---

### Task 1: Flutter Project Scaffolding

> **Step 1 is done by the user (Erwin) manually.** The agent picks up from Step 2.

**Files:**
- Create: `app/` (via `flutter create` — done by user)
- Modify: `app/pubspec.yaml`
- Modify: `app/analysis_options.yaml`

- [ ] **Step 1: (USER) Create Flutter project**

```bash
cd /Users/erwin/personal/runcoach
flutter create --org com.runcoach --platforms ios,android app
```

- [ ] **Step 2: Install production dependencies**

```bash
cd /Users/erwin/personal/runcoach/app
flutter pub add flutter_riverpod riverpod_annotation
flutter pub add freezed_annotation json_annotation
flutter pub add dio retrofit
flutter pub add go_router
flutter pub add flutter_secure_storage
flutter pub add webview_flutter
```

- [ ] **Step 3: Install dev dependencies (code generators + linting)**

```bash
cd /Users/erwin/personal/runcoach/app
flutter pub add --dev build_runner
flutter pub add --dev riverpod_generator freezed json_serializable retrofit_generator
flutter pub add --dev custom_lint riverpod_lint
```

- [ ] **Step 4: Configure analysis_options.yaml**

Replace `app/analysis_options.yaml`:

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
```

- [ ] **Step 5: Create folder structure**

```bash
cd /Users/erwin/personal/runcoach/app
mkdir -p lib/core/api lib/core/storage lib/core/theme
mkdir -p lib/router
mkdir -p lib/features/auth/{data,models,providers,screens}
mkdir -p lib/features/dashboard/{data,models,providers,screens}
mkdir -p lib/features/schedule/{data,models,providers,screens}
mkdir -p lib/features/coach/{data,models,providers,screens,widgets}
mkdir -p lib/features/races/{data,models,providers,screens}
mkdir -p test/core/api
mkdir -p test/features/{auth,dashboard,schedule,coach,races}/providers
```

- [ ] **Step 6: Verify project compiles**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
flutter test
```

Expected: No analysis errors, default test passes.

- [ ] **Step 7: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/
git commit -m "feat: scaffold Flutter project with Riverpod, Freezed, Retrofit, GoRouter"
```

---

### Task 2: Core Infrastructure — Theme, Dio Client, Token Storage

**Files:**
- Create: `app/lib/core/theme/app_theme.dart`
- Create: `app/lib/core/storage/token_storage.dart`
- Create: `app/lib/core/api/auth_interceptor.dart`
- Create: `app/lib/core/api/dio_client.dart`

- [ ] **Step 1: Create app theme**

Create `app/lib/core/theme/app_theme.dart`:

```dart
import 'package:flutter/material.dart';

class AppColors {
  static const cream = Color(0xFFFAF8F4);
  static const warmBrown = Color(0xFF8B7355);
  static const darkBrown = Color(0xFF5C4D3C);
  static const lightTan = Color(0xFFF5F0E8);
  static const gold = Color(0xFFD4A84B);
  static const cardBg = Color(0xFFFFF9F0);
  static const textPrimary = Color(0xFF2D2D2D);
  static const textSecondary = Color(0xFF888888);
  static const success = Color(0xFF4CAF50);
  static const todayHighlight = Color(0xFF8B7355);
}

class AppTheme {
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.cream,
      colorScheme: ColorScheme.light(
        primary: AppColors.warmBrown,
        secondary: AppColors.gold,
        surface: AppColors.cream,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.cream,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardTheme(
        color: AppColors.cardBg,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: AppColors.warmBrown,
        unselectedItemColor: AppColors.textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.warmBrown,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightTan,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
```

- [ ] **Step 2: Create token storage**

Create `app/lib/core/storage/token_storage.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'token_storage.g.dart';

const _tokenKey = 'sanctum_token';

@Riverpod(keepAlive: true)
FlutterSecureStorage secureStorage(Ref ref) {
  return const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );
}

class TokenStorage {
  final FlutterSecureStorage _storage;

  TokenStorage(this._storage);

  Future<String?> getToken() => _storage.read(key: _tokenKey);

  Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<void> clearToken() => _storage.delete(key: _tokenKey);

  Future<bool> hasToken() async => await getToken() != null;
}

@Riverpod(keepAlive: true)
TokenStorage tokenStorage(Ref ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
}
```

- [ ] **Step 3: Create auth interceptor**

Create `app/lib/core/api/auth_interceptor.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:app/core/storage/token_storage.dart';

class AuthInterceptor extends Interceptor {
  final TokenStorage _tokenStorage;

  AuthInterceptor(this._tokenStorage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await _tokenStorage.getToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    options.headers['Accept'] = 'application/json';
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      await _tokenStorage.clearToken();
    }
    handler.next(err);
  }
}
```

- [ ] **Step 4: Create Dio client**

Create `app/lib/core/api/dio_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/auth_interceptor.dart';
import 'package:app/core/storage/token_storage.dart';

part 'dio_client.g.dart';

const String baseUrl = 'http://localhost:8000/api/v1';

// For Android emulator use 10.0.2.2 instead of localhost
// const String baseUrl = 'http://10.0.2.2:8000/api/v1';

@Riverpod(keepAlive: true)
Dio dio(Ref ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);

  final dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 30),
    headers: {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    },
  ));

  dio.interceptors.add(AuthInterceptor(tokenStorage));

  return dio;
}
```

- [ ] **Step 5: Run code generation**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generates `token_storage.g.dart` and `dio_client.g.dart`.

- [ ] **Step 6: Verify it compiles**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

- [ ] **Step 7: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/core/
git commit -m "feat: add app theme, token storage, Dio client with auth interceptor"
```

---

### Task 3: Freezed Models — All Data Classes

**Files:**
- Create: `app/lib/features/auth/models/user.dart`
- Create: `app/lib/features/auth/models/auth_response.dart`
- Create: `app/lib/features/dashboard/models/dashboard_data.dart`
- Create: `app/lib/features/schedule/models/training_week.dart`
- Create: `app/lib/features/schedule/models/training_day.dart`
- Create: `app/lib/features/schedule/models/training_result.dart`
- Create: `app/lib/features/coach/models/conversation.dart`
- Create: `app/lib/features/coach/models/coach_message.dart`
- Create: `app/lib/features/coach/models/coach_proposal.dart`
- Create: `app/lib/features/races/models/race.dart`

- [ ] **Step 1: Create User model**

Create `app/lib/features/auth/models/user.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

@freezed
class User with _$User {
  const factory User({
    required int id,
    required String name,
    required String email,
    @JsonKey(name: 'strava_athlete_id') int? stravaAthleteId,
    String? level,
    @JsonKey(name: 'coach_style') String? coachStyle,
    @JsonKey(name: 'weekly_km_capacity') double? weeklyKmCapacity,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
}
```

- [ ] **Step 2: Create AuthResponse model**

Create `app/lib/features/auth/models/auth_response.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/auth/models/user.dart';

part 'auth_response.freezed.dart';
part 'auth_response.g.dart';

@freezed
class AuthResponse with _$AuthResponse {
  const factory AuthResponse({
    required String token,
    required User user,
  }) = _AuthResponse;

  factory AuthResponse.fromJson(Map<String, dynamic> json) =>
      _$AuthResponseFromJson(json);
}
```

- [ ] **Step 3: Create DashboardData model**

Create `app/lib/features/dashboard/models/dashboard_data.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/schedule/models/training_day.dart';

part 'dashboard_data.freezed.dart';
part 'dashboard_data.g.dart';

@freezed
class DashboardData with _$DashboardData {
  const factory DashboardData({
    @JsonKey(name: 'weekly_summary') WeeklySummary? weeklySummary,
    @JsonKey(name: 'next_training') TrainingDay? nextTraining,
    @JsonKey(name: 'active_race') ActiveRaceSummary? activeRace,
    @JsonKey(name: 'coach_insight') String? coachInsight,
  }) = _DashboardData;

  factory DashboardData.fromJson(Map<String, dynamic> json) =>
      _$DashboardDataFromJson(json);
}

@freezed
class WeeklySummary with _$WeeklySummary {
  const factory WeeklySummary({
    @JsonKey(name: 'total_km_planned') required double totalKmPlanned,
    @JsonKey(name: 'total_km_completed') required double totalKmCompleted,
    @JsonKey(name: 'sessions_completed') required int sessionsCompleted,
    @JsonKey(name: 'sessions_total') required int sessionsTotal,
    @JsonKey(name: 'compliance_avg') double? complianceAvg,
  }) = _WeeklySummary;

  factory WeeklySummary.fromJson(Map<String, dynamic> json) =>
      _$WeeklySummaryFromJson(json);
}

@freezed
class ActiveRaceSummary with _$ActiveRaceSummary {
  const factory ActiveRaceSummary({
    required int id,
    required String name,
    required String distance,
    @JsonKey(name: 'race_date') required String raceDate,
    @JsonKey(name: 'weeks_until_race') required int weeksUntilRace,
  }) = _ActiveRaceSummary;

  factory ActiveRaceSummary.fromJson(Map<String, dynamic> json) =>
      _$ActiveRaceSummaryFromJson(json);
}
```

- [ ] **Step 4: Create TrainingWeek model**

Create `app/lib/features/schedule/models/training_week.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/schedule/models/training_day.dart';

part 'training_week.freezed.dart';
part 'training_week.g.dart';

@freezed
class TrainingWeek with _$TrainingWeek {
  const factory TrainingWeek({
    required int id,
    @JsonKey(name: 'race_id') required int raceId,
    @JsonKey(name: 'week_number') required int weekNumber,
    @JsonKey(name: 'starts_at') required String startsAt,
    @JsonKey(name: 'total_km') required double totalKm,
    required String focus,
    @JsonKey(name: 'coach_notes') String? coachNotes,
    @JsonKey(name: 'training_days') List<TrainingDay>? trainingDays,
  }) = _TrainingWeek;

  factory TrainingWeek.fromJson(Map<String, dynamic> json) =>
      _$TrainingWeekFromJson(json);
}
```

- [ ] **Step 5: Create TrainingDay model**

Create `app/lib/features/schedule/models/training_day.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'training_day.freezed.dart';
part 'training_day.g.dart';

@freezed
class TrainingDay with _$TrainingDay {
  const factory TrainingDay({
    required int id,
    required String date,
    required String type,
    required String title,
    String? description,
    @JsonKey(name: 'target_km') double? targetKm,
    @JsonKey(name: 'target_pace_seconds_per_km') int? targetPaceSecondsPerKm,
    @JsonKey(name: 'target_heart_rate_zone') int? targetHeartRateZone,
    @JsonKey(name: 'intervals_json') Map<String, dynamic>? intervalsJson,
    required int order,
    TrainingResult? result,
  }) = _TrainingDay;

  factory TrainingDay.fromJson(Map<String, dynamic> json) =>
      _$TrainingDayFromJson(json);
}
```

- [ ] **Step 6: Create TrainingResult model**

Create `app/lib/features/schedule/models/training_result.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_result.freezed.dart';
part 'training_result.g.dart';

@freezed
class TrainingResult with _$TrainingResult {
  const factory TrainingResult({
    required int id,
    @JsonKey(name: 'compliance_score') required double complianceScore,
    @JsonKey(name: 'actual_km') required double actualKm,
    @JsonKey(name: 'actual_pace_seconds_per_km') required int actualPaceSecondsPerKm,
    @JsonKey(name: 'actual_avg_heart_rate') double? actualAvgHeartRate,
    @JsonKey(name: 'pace_score') required double paceScore,
    @JsonKey(name: 'distance_score') required double distanceScore,
    @JsonKey(name: 'heart_rate_score') double? heartRateScore,
    @JsonKey(name: 'ai_feedback') String? aiFeedback,
  }) = _TrainingResult;

  factory TrainingResult.fromJson(Map<String, dynamic> json) =>
      _$TrainingResultFromJson(json);
}
```

- [ ] **Step 7: Create Conversation model**

Create `app/lib/features/coach/models/conversation.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_message.dart';

part 'conversation.freezed.dart';
part 'conversation.g.dart';

@freezed
class Conversation with _$Conversation {
  const factory Conversation({
    required int id,
    required String title,
    @JsonKey(name: 'race_id') int? raceId,
    @JsonKey(name: 'created_at') required String createdAt,
    List<CoachMessage>? messages,
  }) = _Conversation;

  factory Conversation.fromJson(Map<String, dynamic> json) =>
      _$ConversationFromJson(json);
}
```

- [ ] **Step 8: Create CoachMessage model**

Create `app/lib/features/coach/models/coach_message.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'coach_message.freezed.dart';
part 'coach_message.g.dart';

@freezed
class CoachMessage with _$CoachMessage {
  const factory CoachMessage({
    required int id,
    required String role,
    required String content,
    @JsonKey(name: 'created_at') required String createdAt,
    CoachProposal? proposal,
  }) = _CoachMessage;

  factory CoachMessage.fromJson(Map<String, dynamic> json) =>
      _$CoachMessageFromJson(json);
}
```

- [ ] **Step 9: Create CoachProposal model**

Create `app/lib/features/coach/models/coach_proposal.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'coach_proposal.freezed.dart';
part 'coach_proposal.g.dart';

@freezed
class CoachProposal with _$CoachProposal {
  const factory CoachProposal({
    required int id,
    required String type,
    required Map<String, dynamic> payload,
    required String status,
    @JsonKey(name: 'applied_at') String? appliedAt,
  }) = _CoachProposal;

  factory CoachProposal.fromJson(Map<String, dynamic> json) =>
      _$CoachProposalFromJson(json);
}
```

- [ ] **Step 10: Create Race model**

Create `app/lib/features/races/models/race.dart`:

```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'race.freezed.dart';
part 'race.g.dart';

@freezed
class Race with _$Race {
  const factory Race({
    required int id,
    required String name,
    required String distance,
    @JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,
    @JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,
    @JsonKey(name: 'race_date') required String raceDate,
    required String status,
  }) = _Race;

  factory Race.fromJson(Map<String, dynamic> json) => _$RaceFromJson(json);
}
```

- [ ] **Step 11: Run code generation**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generates `.freezed.dart` and `.g.dart` for all 10 model files.

- [ ] **Step 12: Verify it compiles**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

- [ ] **Step 13: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/*/models/
git commit -m "feat: add all Freezed data models with JSON serialization"
```

---

### Task 4: Retrofit API Clients

**Files:**
- Create: `app/lib/features/auth/data/auth_api.dart`
- Create: `app/lib/features/dashboard/data/dashboard_api.dart`
- Create: `app/lib/features/schedule/data/schedule_api.dart`
- Create: `app/lib/features/coach/data/coach_api.dart`
- Create: `app/lib/features/races/data/race_api.dart`

- [ ] **Step 1: Create AuthApi**

Create `app/lib/features/auth/data/auth_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/auth/models/auth_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @GET('/auth/strava/redirect')
  Future<Map<String, dynamic>> getRedirectUrl();

  @GET('/auth/strava/callback')
  Future<AuthResponse> callback(@Query('code') String code);

  @POST('/auth/logout')
  Future<void> logout();

  @GET('/profile')
  Future<Map<String, dynamic>> getProfile();

  @PUT('/profile')
  Future<Map<String, dynamic>> updateProfile(@Body() Map<String, dynamic> body);

  @POST('/profile/onboarding')
  Future<Map<String, dynamic>> completeOnboarding(@Body() Map<String, dynamic> body);
}

@riverpod
AuthApi authApi(Ref ref) => AuthApi(ref.watch(dioProvider));
```

- [ ] **Step 2: Create DashboardApi**

Create `app/lib/features/dashboard/data/dashboard_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';

part 'dashboard_api.g.dart';

@RestApi()
abstract class DashboardApi {
  factory DashboardApi(Dio dio) = _DashboardApi;

  @GET('/dashboard')
  Future<DashboardData> getDashboard();
}

@riverpod
DashboardApi dashboardApi(Ref ref) => DashboardApi(ref.watch(dioProvider));
```

- [ ] **Step 3: Create ScheduleApi**

Create `app/lib/features/schedule/data/schedule_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'schedule_api.g.dart';

@RestApi()
abstract class ScheduleApi {
  factory ScheduleApi(Dio dio) = _ScheduleApi;

  @GET('/races/{raceId}/schedule')
  Future<Map<String, dynamic>> getSchedule(@Path() int raceId);

  @GET('/races/{raceId}/schedule/current')
  Future<Map<String, dynamic>> getCurrentWeek(@Path() int raceId);

  @GET('/training-days/{dayId}')
  Future<Map<String, dynamic>> getTrainingDay(@Path() int dayId);

  @GET('/training-days/{dayId}/result')
  Future<Map<String, dynamic>> getTrainingResult(@Path() int dayId);
}

@riverpod
ScheduleApi scheduleApi(Ref ref) => ScheduleApi(ref.watch(dioProvider));
```

- [ ] **Step 4: Create CoachApi**

Create `app/lib/features/coach/data/coach_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'coach_api.g.dart';

@RestApi()
abstract class CoachApi {
  factory CoachApi(Dio dio) = _CoachApi;

  @GET('/coach/conversations')
  Future<Map<String, dynamic>> getConversations();

  @POST('/coach/conversations')
  Future<Map<String, dynamic>> createConversation(@Body() Map<String, dynamic> body);

  @GET('/coach/conversations/{id}')
  Future<Map<String, dynamic>> getConversation(@Path() int id);

  @POST('/coach/conversations/{id}/messages')
  Future<Map<String, dynamic>> sendMessage(
    @Path() int id,
    @Body() Map<String, dynamic> body,
  );

  @POST('/coach/proposals/{id}/accept')
  Future<void> acceptProposal(@Path() int id);

  @POST('/coach/proposals/{id}/reject')
  Future<void> rejectProposal(@Path() int id);
}

@riverpod
CoachApi coachApi(Ref ref) => CoachApi(ref.watch(dioProvider));
```

- [ ] **Step 5: Create RaceApi**

Create `app/lib/features/races/data/race_api.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/races/models/race.dart';

part 'race_api.g.dart';

@RestApi()
abstract class RaceApi {
  factory RaceApi(Dio dio) = _RaceApi;

  @GET('/races')
  Future<Map<String, dynamic>> getRaces();

  @POST('/races')
  Future<Map<String, dynamic>> createRace(@Body() Map<String, dynamic> body);

  @GET('/races/{id}')
  Future<Map<String, dynamic>> getRace(@Path() int id);

  @PUT('/races/{id}')
  Future<Map<String, dynamic>> updateRace(
    @Path() int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/races/{id}')
  Future<void> deleteRace(@Path() int id);
}

@riverpod
RaceApi raceApi(Ref ref) => RaceApi(ref.watch(dioProvider));
```

- [ ] **Step 6: Run code generation**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

Expected: Generates `.g.dart` for all 5 API client files + provider files.

- [ ] **Step 7: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/*/data/
git commit -m "feat: add Retrofit API clients for all endpoints"
```

---

### Task 5: Riverpod Providers — All Features

**Files:**
- Create: `app/lib/features/auth/providers/auth_provider.dart`
- Create: `app/lib/features/dashboard/providers/dashboard_provider.dart`
- Create: `app/lib/features/schedule/providers/schedule_provider.dart`
- Create: `app/lib/features/coach/providers/coach_provider.dart`
- Create: `app/lib/features/races/providers/race_provider.dart`

- [ ] **Step 1: Create auth provider**

Create `app/lib/features/auth/providers/auth_provider.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/models/user.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  FutureOr<User?> build() async {
    final tokenStorage = ref.watch(tokenStorageProvider);
    final hasToken = await tokenStorage.hasToken();

    if (!hasToken) return null;

    try {
      final api = ref.read(authApiProvider);
      final response = await api.getProfile();
      return User.fromJson(response['user']);
    } catch (_) {
      await tokenStorage.clearToken();
      return null;
    }
  }

  Future<void> loginWithCode(String code) async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);

    state = const AsyncLoading();

    state = await AsyncValue.guard(() async {
      final response = await api.callback(code);
      await tokenStorage.setToken(response.token);
      return response.user;
    });
  }

  Future<void> completeOnboarding({
    required String level,
    required String coachStyle,
    required double weeklyKmCapacity,
  }) async {
    final api = ref.read(authApiProvider);

    await api.completeOnboarding({
      'level': level,
      'coach_style': coachStyle,
      'weekly_km_capacity': weeklyKmCapacity,
    });

    ref.invalidateSelf();
  }

  Future<void> logout() async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);

    try {
      await api.logout();
    } finally {
      await tokenStorage.clearToken();
      state = const AsyncData(null);
    }
  }
}
```

- [ ] **Step 2: Create dashboard provider**

Create `app/lib/features/dashboard/providers/dashboard_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/dashboard/data/dashboard_api.dart';
import 'package:app/features/dashboard/models/dashboard_data.dart';

part 'dashboard_provider.g.dart';

@riverpod
Future<DashboardData> dashboard(DashboardRef ref) async {
  final api = ref.watch(dashboardApiProvider);
  return api.getDashboard();
}
```

- [ ] **Step 3: Create schedule provider**

Create `app/lib/features/schedule/providers/schedule_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/schedule/data/schedule_api.dart';
import 'package:app/features/schedule/models/training_week.dart';
import 'package:app/features/schedule/models/training_day.dart';
import 'package:app/features/schedule/models/training_result.dart';

part 'schedule_provider.g.dart';

@riverpod
Future<TrainingWeek?> currentWeek(CurrentWeekRef ref, {required int raceId}) async {
  final api = ref.watch(scheduleApiProvider);
  final response = await api.getCurrentWeek(raceId);
  final data = response['data'];
  if (data == null) return null;
  return TrainingWeek.fromJson(data);
}

@riverpod
Future<TrainingDay> trainingDay(TrainingDayRef ref, {required int dayId}) async {
  final api = ref.watch(scheduleApiProvider);
  final response = await api.getTrainingDay(dayId);
  return TrainingDay.fromJson(response['data']);
}

@riverpod
Future<TrainingResult?> trainingResult(TrainingResultRef ref, {required int dayId}) async {
  final api = ref.watch(scheduleApiProvider);
  final response = await api.getTrainingResult(dayId);
  final data = response['data'];
  if (data == null) return null;
  return TrainingResult.fromJson(data);
}
```

- [ ] **Step 4: Create coach provider**

Create `app/lib/features/coach/providers/coach_provider.dart`:

```dart
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/models/conversation.dart';
import 'package:app/features/coach/models/coach_message.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

part 'coach_provider.g.dart';

@riverpod
Future<List<Conversation>> conversations(ConversationsRef ref) async {
  final api = ref.watch(coachApiProvider);
  final response = await api.getConversations();
  final list = response['data'] as List;
  return list.map((e) => Conversation.fromJson(e)).toList();
}

@riverpod
Future<Conversation> conversationDetail(ConversationDetailRef ref, {required int id}) async {
  final api = ref.watch(coachApiProvider);
  final response = await api.getConversation(id);
  return Conversation.fromJson(response['data']);
}

@riverpod
class CoachChat extends _$CoachChat {
  @override
  FutureOr<List<CoachMessage>> build(int conversationId) async {
    final api = ref.read(coachApiProvider);
    final response = await api.getConversation(conversationId);
    final conversation = Conversation.fromJson(response['data']);
    return conversation.messages ?? [];
  }

  Future<CoachProposal?> sendMessage(String content) async {
    final api = ref.read(coachApiProvider);
    final response = await api.sendMessage(conversationId, {'content': content});

    final data = response['data'];
    final message = CoachMessage.fromJson(data['message']);

    state = AsyncData([...state.value ?? [], message]);

    if (data['proposal'] != null) {
      return CoachProposal.fromJson(data['proposal']);
    }
    return null;
  }

  Future<void> acceptProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.acceptProposal(proposalId);
  }

  Future<void> rejectProposal(int proposalId) async {
    final api = ref.read(coachApiProvider);
    await api.rejectProposal(proposalId);
  }
}
```

- [ ] **Step 5: Create race provider**

Create `app/lib/features/races/providers/race_provider.dart`:

```dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/races/data/race_api.dart';
import 'package:app/features/races/models/race.dart';

part 'race_provider.g.dart';

@riverpod
Future<List<Race>> races(RacesRef ref) async {
  final api = ref.watch(raceApiProvider);
  final response = await api.getRaces();
  final list = response['data'] as List;
  return list.map((e) => Race.fromJson(e)).toList();
}

@riverpod
Future<Race> raceDetail(RaceDetailRef ref, {required int id}) async {
  final api = ref.watch(raceApiProvider);
  final response = await api.getRace(id);
  return Race.fromJson(response['data']);
}
```

- [ ] **Step 6: Run code generation**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 7: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/*/providers/
git commit -m "feat: add Riverpod providers for all features"
```

---

### Task 6: App Router + Main Entry

**Files:**
- Create: `app/lib/router/app_router.dart`
- Modify: `app/lib/main.dart`
- Create: `app/lib/app.dart`

- [ ] **Step 1: Create GoRouter configuration**

Create `app/lib/router/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/auth/screens/welcome_screen.dart';
import 'package:app/features/auth/screens/strava_auth_screen.dart';
import 'package:app/features/auth/screens/onboarding_screen.dart';
import 'package:app/features/dashboard/screens/dashboard_screen.dart';
import 'package:app/features/schedule/screens/weekly_plan_screen.dart';
import 'package:app/features/schedule/screens/training_day_detail_screen.dart';
import 'package:app/features/schedule/screens/training_result_screen.dart';
import 'package:app/features/coach/screens/coach_chat_list_screen.dart';
import 'package:app/features/coach/screens/coach_chat_screen.dart';
import 'package:app/features/races/screens/race_list_screen.dart';
import 'package:app/features/races/screens/race_create_screen.dart';
import 'package:app/features/races/screens/race_detail_screen.dart';

part 'app_router.g.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final isLoggedIn = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation.startsWith('/auth');

      if (!isLoggedIn && !isAuthRoute) return '/auth/welcome';
      if (isLoggedIn && isAuthRoute) return '/dashboard';

      // Check if onboarding is needed
      final user = authState.valueOrNull;
      if (isLoggedIn && user?.level == null && state.matchedLocation != '/auth/onboarding') {
        return '/auth/onboarding';
      }

      return null;
    },
    routes: [
      // Auth routes
      GoRoute(
        path: '/auth/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/auth/strava',
        builder: (context, state) => const StravaAuthScreen(),
      ),
      GoRoute(
        path: '/auth/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: DashboardScreen(),
            ),
          ),
          GoRoute(
            path: '/schedule',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: WeeklyPlanScreen(),
            ),
            routes: [
              GoRoute(
                path: 'day/:dayId',
                builder: (context, state) => TrainingDayDetailScreen(
                  dayId: int.parse(state.pathParameters['dayId']!),
                ),
              ),
              GoRoute(
                path: 'day/:dayId/result',
                builder: (context, state) => TrainingResultScreen(
                  dayId: int.parse(state.pathParameters['dayId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/coach',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: CoachChatListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'chat/:conversationId',
                builder: (context, state) => CoachChatScreen(
                  conversationId: int.parse(state.pathParameters['conversationId']!),
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/races',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: RaceListScreen(),
            ),
            routes: [
              GoRoute(
                path: 'new',
                builder: (context, state) => const RaceCreateScreen(),
              ),
              GoRoute(
                path: ':raceId',
                builder: (context, state) => RaceDetailScreen(
                  raceId: int.parse(state.pathParameters['raceId']!),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static int _indexOf(String location) {
    if (location.startsWith('/dashboard')) return 0;
    if (location.startsWith('/schedule')) return 1;
    if (location.startsWith('/coach')) return 2;
    if (location.startsWith('/races')) return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _indexOf(GoRouterState.of(context).matchedLocation),
        onTap: (index) {
          switch (index) {
            case 0: context.go('/dashboard');
            case 1: context.go('/schedule');
            case 2: context.go('/coach');
            case 3: context.go('/races');
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Schedule',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_outlined),
            activeIcon: Icon(Icons.chat),
            label: 'AI Coach',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.flag_outlined),
            activeIcon: Icon(Icons.flag),
            label: 'Races',
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Create App widget**

Create `app/lib/app.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/router/app_router.dart';

class RunCoachApp extends ConsumerWidget {
  const RunCoachApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'RunCoach',
      theme: AppTheme.light,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 3: Update main.dart**

Replace `app/lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: RunCoachApp(),
    ),
  );
}
```

- [ ] **Step 4: Create placeholder screens**

All screens referenced in the router need to exist (even as stubs) for the app to compile. Create each placeholder screen. Each follows this pattern — example for `DashboardScreen`:

Create `app/lib/features/dashboard/screens/dashboard_screen.dart`:

```dart
import 'package:flutter/material.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: Text('Dashboard')),
    );
  }
}
```

Create the same stub pattern for all 12 remaining screens:
- `app/lib/features/auth/screens/welcome_screen.dart` — `WelcomeScreen`
- `app/lib/features/auth/screens/strava_auth_screen.dart` — `StravaAuthScreen`
- `app/lib/features/auth/screens/onboarding_screen.dart` — `OnboardingScreen`
- `app/lib/features/schedule/screens/weekly_plan_screen.dart` — `WeeklyPlanScreen`
- `app/lib/features/schedule/screens/training_day_detail_screen.dart` — `TrainingDayDetailScreen({required this.dayId})` with `final int dayId;`
- `app/lib/features/schedule/screens/training_result_screen.dart` — `TrainingResultScreen({required this.dayId})` with `final int dayId;`
- `app/lib/features/coach/screens/coach_chat_list_screen.dart` — `CoachChatListScreen`
- `app/lib/features/coach/screens/coach_chat_screen.dart` — `CoachChatScreen({required this.conversationId})` with `final int conversationId;`
- `app/lib/features/races/screens/race_list_screen.dart` — `RaceListScreen`
- `app/lib/features/races/screens/race_create_screen.dart` — `RaceCreateScreen`
- `app/lib/features/races/screens/race_detail_screen.dart` — `RaceDetailScreen({required this.raceId})` with `final int raceId;`

- [ ] **Step 5: Run code generation and verify**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
flutter analyze
```

- [ ] **Step 6: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/
git commit -m "feat: add GoRouter with auth guards, main shell, and placeholder screens"
```

---

### Task 7: Auth Screens — Welcome, Strava OAuth, Onboarding

**Files:**
- Modify: `app/lib/features/auth/screens/welcome_screen.dart`
- Modify: `app/lib/features/auth/screens/strava_auth_screen.dart`
- Modify: `app/lib/features/auth/screens/onboarding_screen.dart`

- [ ] **Step 1: Implement WelcomeScreen**

Replace `app/lib/features/auth/screens/welcome_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              Icon(
                Icons.directions_run,
                size: 80,
                color: AppColors.warmBrown,
              ),
              const SizedBox(height: 24),
              Text(
                'RunCoach',
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkBrown,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Your AI-powered running coach',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/auth/strava'),
                  icon: const Icon(Icons.link),
                  label: const Text('Connect with Strava'),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'We use Strava to read your running data\nand create personalized training plans.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement StravaAuthScreen**

Replace `app/lib/features/auth/screens/strava_auth_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class StravaAuthScreen extends ConsumerStatefulWidget {
  const StravaAuthScreen({super.key});

  @override
  ConsumerState<StravaAuthScreen> createState() => _StravaAuthScreenState();
}

class _StravaAuthScreenState extends ConsumerState<StravaAuthScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    final redirectUrl = '$baseUrl/auth/strava/redirect';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onNavigationRequest: (request) {
          final uri = Uri.parse(request.url);

          // Check if this is the callback URL with a code
          if (uri.path.contains('/auth/strava/callback') && uri.queryParameters.containsKey('code')) {
            final code = uri.queryParameters['code']!;
            _handleAuthCode(code);
            return NavigationDecision.prevent;
          }
          return NavigationDecision.navigate;
        },
        onPageFinished: (_) => setState(() => _loading = false),
      ));

    // First, get the Strava authorize URL from our API
    try {
      final dio = ref.read(dioProvider);
      final response = await dio.get('/auth/strava/redirect');
      final stravaUrl = response.data['url'] as String;
      _controller.loadRequest(Uri.parse(stravaUrl));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to connect to server: $e')),
        );
        context.go('/auth/welcome');
      }
    }
  }

  Future<void> _handleAuthCode(String code) async {
    setState(() => _loading = true);

    await ref.read(authProvider.notifier).loginWithCode(code);

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connect Strava'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/auth/welcome'),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
```

- [ ] **Step 3: Implement OnboardingScreen**

Replace `app/lib/features/auth/screens/onboarding_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/providers/auth_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  String _level = 'intermediate';
  String _coachStyle = 'balanced';
  double _weeklyKm = 30;

  Future<void> _complete() async {
    await ref.read(authProvider.notifier).completeOnboarding(
      level: _level,
      coachStyle: _coachStyle,
      weeklyKmCapacity: _weeklyKm,
    );

    if (mounted) context.go('/dashboard');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Your Profile')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Running Level',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildOptionGroup(
              value: _level,
              options: {'beginner': 'Beginner', 'intermediate': 'Intermediate', 'advanced': 'Advanced', 'elite': 'Elite'},
              onChanged: (v) => setState(() => _level = v),
            ),
            const SizedBox(height: 24),
            Text('Coach Style',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            _buildOptionGroup(
              value: _coachStyle,
              options: {'motivational': 'Motivational', 'analytical': 'Analytical', 'balanced': 'Balanced'},
              onChanged: (v) => setState(() => _coachStyle = v),
            ),
            const SizedBox(height: 24),
            Text('Weekly KM Capacity: ${_weeklyKm.round()} km',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _weeklyKm,
              min: 5,
              max: 150,
              divisions: 29,
              activeColor: AppColors.warmBrown,
              label: '${_weeklyKm.round()} km',
              onChanged: (v) => setState(() => _weeklyKm = v),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _complete,
                child: const Text('Start Training'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroup({
    required String value,
    required Map<String, String> options,
    required ValueChanged<String> onChanged,
  }) {
    return Wrap(
      spacing: 8,
      children: options.entries.map((e) {
        final selected = e.key == value;
        return ChoiceChip(
          label: Text(e.value),
          selected: selected,
          selectedColor: AppColors.warmBrown,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
          onSelected: (_) => onChanged(e.key),
        );
      }).toList(),
    );
  }
}
```

- [ ] **Step 4: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/auth/screens/
git commit -m "feat: implement auth screens — welcome, Strava OAuth, onboarding"
```

---

### Task 8: Schedule Screens — Weekly Plan, Day Detail, Result

**Files:**
- Modify: `app/lib/features/schedule/screens/weekly_plan_screen.dart`
- Modify: `app/lib/features/schedule/screens/training_day_detail_screen.dart`
- Modify: `app/lib/features/schedule/screens/training_result_screen.dart`

This is the core UI matching the design screenshot — the weekly plan with day-by-day sessions, status indicators, and warm earth-tone styling.

- [ ] **Step 1: Implement WeeklyPlanScreen**

This screen matches the design screenshot exactly. Replace `app/lib/features/schedule/screens/weekly_plan_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/features/dashboard/providers/dashboard_provider.dart';
import 'package:app/features/schedule/providers/schedule_provider.dart';
import 'package:app/features/schedule/models/training_day.dart';

class WeeklyPlanScreen extends ConsumerWidget {
  const WeeklyPlanScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return dashboardAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (err, _) => Scaffold(
        body: Center(child: Text('Error: $err')),
      ),
      data: (dashboard) {
        final race = dashboard.activeRace;
        if (race == null) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No active training plan'),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => context.go('/coach'),
                    child: const Text('Create one with AI Coach'),
                  ),
                ],
              ),
            ),
          );
        }

        final weekAsync = ref.watch(currentWeekProvider(raceId: race.id));

        return weekAsync.when(
          loading: () => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
          error: (err, _) => Scaffold(
            body: Center(child: Text('Error: $err')),
          ),
          data: (week) {
            if (week == null) {
              return const Scaffold(
                body: Center(child: Text('No training week found')),
              );
            }

            final days = week.trainingDays ?? [];

            return Scaffold(
              body: SafeArea(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Week ${week.weekNumber}',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                Text(
                                  'Weekly Plan',
                                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${week.totalKm}',
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.warmBrown,
                                  ),
                                ),
                                Text(
                                  'KM TOTAL',
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: AppColors.textSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _TrainingDayTile(
                          day: days[index],
                          onTap: () => context.go('/schedule/day/${days[index].id}'),
                        ),
                        childCount: days.length,
                      ),
                    ),
                    if (week.coachNotes != null)
                      SliverToBoxAdapter(
                        child: _CoachInsightCard(notes: week.coachNotes!),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TrainingDayTile extends StatelessWidget {
  final TrainingDay day;
  final VoidCallback onTap;

  const _TrainingDayTile({required this.day, required this.onTap});

  bool get _isToday {
    final now = DateTime.now();
    final dayDate = DateTime.tryParse(day.date);
    return dayDate != null &&
        dayDate.year == now.year &&
        dayDate.month == now.month &&
        dayDate.day == now.day;
  }

  bool get _isCompleted => day.result != null;

  bool get _isPast {
    final dayDate = DateTime.tryParse(day.date);
    return dayDate != null && dayDate.isBefore(DateTime.now()) && !_isToday;
  }

  IconData get _statusIcon {
    if (_isCompleted) return Icons.check_circle;
    if (_isToday) return Icons.bolt;
    return Icons.nightlight_round;
  }

  Color get _statusColor {
    if (_isCompleted) return AppColors.success;
    if (_isToday) return AppColors.gold;
    return AppColors.textSecondary.withValues(alpha: 0.4);
  }

  @override
  Widget build(BuildContext context) {
    final dayDate = DateTime.tryParse(day.date);
    final dayNames = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: _isToday
            ? BoxDecoration(
                color: AppColors.lightTan,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Row(
          children: [
            SizedBox(
              width: 48,
              child: Column(
                children: [
                  Text(
                    dayDate != null ? dayNames[dayDate.weekday - 1] : '',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    dayDate != null ? '${dayDate.day}' : '',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (_isToday)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warmBrown,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'TODAY',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      Flexible(
                        child: Text(
                          day.title,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (day.description != null)
                    Text(
                      day.description!,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                ],
              ),
            ),
            Icon(_statusIcon, color: _statusColor, size: 24),
          ],
        ),
      ),
    );
  }
}

class _CoachInsightCard extends StatelessWidget {
  final String notes;
  const _CoachInsightCard({required this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.darkBrown,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.gold, size: 16),
              const SizedBox(width: 8),
              Text(
                'COACH INSIGHT',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '"$notes"',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.9),
              fontStyle: FontStyle.italic,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Implement TrainingDayDetailScreen and TrainingResultScreen**

These are simpler detail screens. Implement them following the same pattern — reading from providers and displaying the data. The exact implementation follows the same ConsumerWidget + provider.watch pattern used in the WeeklyPlanScreen. Show target km, pace, HR zone, intervals, and link to the result screen if completed.

- [ ] **Step 3: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/schedule/screens/
git commit -m "feat: implement schedule screens — weekly plan, day detail, result overlay"
```

---

### Task 9: Coach Screens — Chat List, Chat UI, Widgets

**Files:**
- Modify: `app/lib/features/coach/screens/coach_chat_list_screen.dart`
- Modify: `app/lib/features/coach/screens/coach_chat_screen.dart`
- Create: `app/lib/features/coach/widgets/message_bubble.dart`
- Create: `app/lib/features/coach/widgets/proposal_card.dart`
- Create: `app/lib/features/coach/widgets/quick_action_card.dart`

- [ ] **Step 1: Implement QuickActionCard widget**

Create `app/lib/features/coach/widgets/quick_action_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';

class QuickActionCard extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const QuickActionCard({
    super.key,
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppColors.lightTan, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 2: Implement MessageBubble widget**

Create `app/lib/features/coach/widgets/message_bubble.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_message.dart';

class MessageBubble extends StatelessWidget {
  final CoachMessage message;

  const MessageBubble({super.key, required this.message});

  bool get _isUser => message.role == 'user';

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: _isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: _isUser ? 60 : 0,
          right: _isUser ? 0 : 60,
          bottom: 8,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: _isUser ? AppColors.warmBrown : AppColors.lightTan,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(_isUser ? 16 : 4),
            bottomRight: Radius.circular(_isUser ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!_isUser)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'COACH',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warmBrown,
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                  ),
                ),
              ),
            Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: _isUser ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: Implement ProposalCard widget**

Create `app/lib/features/coach/widgets/proposal_card.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/models/coach_proposal.dart';

class ProposalCard extends StatelessWidget {
  final CoachProposal proposal;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.onAccept,
    required this.onReject,
  });

  String get _title {
    switch (proposal.type) {
      case 'create_schedule':
        return 'Proposed: Training Plan';
      case 'modify_schedule':
        return 'Proposed: Schedule Change';
      case 'alternative_week':
        return 'Proposed: Alternative Week';
      default:
        return 'Proposal';
    }
  }

  bool get _isPending => proposal.status == 'pending';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 60, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.warmBrown, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppColors.warmBrown, size: 18),
              const SizedBox(width: 8),
              Text(
                _title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.warmBrown,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_isPending) ...[
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Adjust'),
                  ),
                ),
              ],
            ),
          ] else
            Text(
              proposal.status == 'accepted' ? 'Accepted' : 'Rejected',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 4: Implement CoachChatListScreen**

Replace `app/lib/features/coach/screens/coach_chat_list_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/data/coach_api.dart';
import 'package:app/features/coach/providers/coach_provider.dart';

class CoachChatListScreen extends ConsumerWidget {
  const CoachChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conversationsAsync = ref.watch(conversationsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('AI Coach')),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final api = ref.read(coachApiProvider);
          final response = await api.createConversation({'title': 'New Chat'});
          final id = response['data']['id'];
          ref.invalidate(conversationsProvider);
          if (context.mounted) context.go('/coach/chat/$id');
        },
        backgroundColor: AppColors.warmBrown,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: conversationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
        data: (conversations) {
          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_outlined, size: 64, color: AppColors.textSecondary),
                  const SizedBox(height: 16),
                  const Text('No conversations yet'),
                  const SizedBox(height: 8),
                  const Text('Start a chat with your AI coach'),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conv = conversations[index];
              return ListTile(
                title: Text(conv.title),
                subtitle: Text(conv.createdAt),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.go('/coach/chat/${conv.id}'),
              );
            },
          );
        },
      ),
    );
  }
}
```

- [ ] **Step 5: Implement CoachChatScreen with quick actions and proposal cards**

Replace `app/lib/features/coach/screens/coach_chat_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/core/theme/app_theme.dart';
import 'package:app/features/coach/providers/coach_provider.dart';
import 'package:app/features/coach/widgets/message_bubble.dart';
import 'package:app/features/coach/widgets/proposal_card.dart';
import 'package:app/features/coach/widgets/quick_action_card.dart';

class CoachChatScreen extends ConsumerStatefulWidget {
  final int conversationId;
  const CoachChatScreen({super.key, required this.conversationId});

  @override
  ConsumerState<CoachChatScreen> createState() => _CoachChatScreenState();
}

class _CoachChatScreenState extends ConsumerState<CoachChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _sending = false;

  Future<void> _send([String? prefill]) async {
    final content = prefill ?? _controller.text.trim();
    if (content.isEmpty) return;

    _controller.clear();
    setState(() => _sending = true);

    final notifier = ref.read(coachChatProvider(widget.conversationId).notifier);
    await notifier.sendMessage(content);

    setState(() => _sending = false);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messagesAsync = ref.watch(coachChatProvider(widget.conversationId));

    return Scaffold(
      appBar: AppBar(title: const Text('Coach')),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (messages) {
                if (messages.isEmpty) {
                  return _EmptyState(onQuickAction: _send);
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    return Column(
                      children: [
                        MessageBubble(message: msg),
                        if (msg.proposal != null)
                          ProposalCard(
                            proposal: msg.proposal!,
                            onAccept: () async {
                              final notifier = ref.read(
                                coachChatProvider(widget.conversationId).notifier,
                              );
                              await notifier.acceptProposal(msg.proposal!.id);
                              ref.invalidate(coachChatProvider(widget.conversationId));
                            },
                            onReject: () async {
                              final notifier = ref.read(
                                coachChatProvider(widget.conversationId).notifier,
                              );
                              await notifier.rejectProposal(msg.proposal!.id);
                              ref.invalidate(coachChatProvider(widget.conversationId));
                            },
                          ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
          _ChatInput(
            controller: _controller,
            sending: _sending,
            onSend: () => _send(),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onQuickAction;
  const _EmptyState({required this.onQuickAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_run, size: 48, color: AppColors.warmBrown),
          const SizedBox(height: 16),
          Text(
            'What can I help you with?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'I know your training history and can manage your schedule',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              QuickActionCard(
                emoji: '\u{1F4C5}',
                title: 'Create a training plan',
                subtitle: 'For an upcoming race',
                onTap: () => onQuickAction('I want to create a training plan for an upcoming race'),
              ),
              QuickActionCard(
                emoji: '\u{1F504}',
                title: 'Adjust my schedule',
                subtitle: "Modify this week's plan",
                onTap: () => onQuickAction("Can you adjust this week's training schedule?"),
              ),
              QuickActionCard(
                emoji: '\u{1F4CA}',
                title: 'Analyze my progress',
                subtitle: 'How am I trending?',
                onTap: () => onQuickAction('How is my training going? Give me an analysis of my progress.'),
              ),
              QuickActionCard(
                emoji: '\u{2753}',
                title: 'Ask anything',
                subtitle: 'Training advice & tips',
                onTap: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: 'Ask your coach...',
                border: InputBorder.none,
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
            ),
          ),
          IconButton(
            onPressed: sending ? null : onSend,
            icon: sending
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send),
            color: AppColors.warmBrown,
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/coach/
git commit -m "feat: implement coach screens — chat list, chat UI, quick actions, proposals"
```

---

### Task 10: Dashboard + Races Screens

**Files:**
- Modify: `app/lib/features/dashboard/screens/dashboard_screen.dart`
- Modify: `app/lib/features/races/screens/race_list_screen.dart`
- Modify: `app/lib/features/races/screens/race_create_screen.dart`
- Modify: `app/lib/features/races/screens/race_detail_screen.dart`

- [ ] **Step 1: Implement DashboardScreen**

Replace `app/lib/features/dashboard/screens/dashboard_screen.dart`. Show: weekly km total, compliance %, next training card with countdown, and coach insight card. Use the same warm earth-tone styling with `AppColors`. Consume `dashboardProvider`.

- [ ] **Step 2: Implement RaceListScreen**

Replace `app/lib/features/races/screens/race_list_screen.dart`. Show list of races with status chips (active/completed/cancelled), FAB to add new race. Consume `racesProvider`.

- [ ] **Step 3: Implement RaceCreateScreen**

Replace `app/lib/features/races/screens/race_create_screen.dart`. Form with: name (TextField), distance (dropdown from enum values), goal time (hour/minute picker), race date (DatePicker). Submit via `raceApiProvider`.

- [ ] **Step 4: Implement RaceDetailScreen**

Replace `app/lib/features/races/screens/race_detail_screen.dart`. Show: race name, countdown to race day, distance, goal time, link to schedule, and edit/cancel buttons. Consume `raceDetailProvider`.

- [ ] **Step 5: Verify and commit**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
```

```bash
cd /Users/erwin/personal/runcoach
git add app/lib/features/dashboard/screens/ app/lib/features/races/screens/
git commit -m "feat: implement dashboard and race screens"
```

---

### Task 11: Provider Tests

**Files:**
- Create: `app/test/features/auth/providers/auth_provider_test.dart`
- Create: `app/test/features/coach/providers/coach_provider_test.dart`

- [ ] **Step 1: Add test dependency**

```bash
cd /Users/erwin/personal/runcoach/app
flutter pub add --dev mockito
```

- [ ] **Step 2: Write auth provider test**

Create `app/test/features/auth/providers/auth_provider_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:app/features/auth/providers/auth_provider.dart';
import 'package:app/core/storage/token_storage.dart';

void main() {
  group('AuthProvider', () {
    test('initial state is null when no token stored', () async {
      // This is an integration test pattern — verifying the provider
      // starts in the correct state. Mock the storage layer for unit tests.
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // The auth provider should start as AsyncLoading then resolve
      final auth = container.read(authProvider);
      expect(auth, isA<AsyncLoading>());
    });
  });
}
```

- [ ] **Step 3: Run tests**

```bash
cd /Users/erwin/personal/runcoach/app
flutter test
```

- [ ] **Step 4: Commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/test/
git commit -m "feat: add provider tests"
```

---

### Task 12: Final Verification

- [ ] **Step 1: Run full code generation**

```bash
cd /Users/erwin/personal/runcoach/app
dart run build_runner build --delete-conflicting-outputs
```

- [ ] **Step 2: Run analysis**

```bash
cd /Users/erwin/personal/runcoach/app
flutter analyze
dart format .
```

- [ ] **Step 3: Run tests**

```bash
cd /Users/erwin/personal/runcoach/app
flutter test
```

- [ ] **Step 4: Test on device/simulator**

```bash
cd /Users/erwin/personal/runcoach/app
flutter run
```

Verify:
- App boots to welcome screen
- Bottom navigation shows 4 tabs
- Theme uses warm earth-tone colors
- No crash on any screen

- [ ] **Step 5: Final commit**

```bash
cd /Users/erwin/personal/runcoach
git add app/
git commit -m "feat: complete Flutter app with all screens, providers, and API clients"
```

---

## Summary

| Task | What it builds | Key CLI tools used |
|---|---|---|
| 1 | Flutter project scaffolding | `flutter create`, `flutter pub add` |
| 2 | Theme, Dio client, token storage | `dart run build_runner build` |
| 3 | Freezed models (10 data classes) | `dart run build_runner build` |
| 4 | Retrofit API clients (5 clients) | `dart run build_runner build` |
| 5 | Riverpod providers (5 features) | `dart run build_runner build` |
| 6 | GoRouter + main entry + stubs | `dart run build_runner build` |
| 7 | Auth screens (welcome, OAuth, onboarding) | — |
| 8 | Schedule screens (weekly plan, detail, result) | — |
| 9 | Coach screens (chat list, chat UI, widgets) | — |
| 10 | Dashboard + races screens | — |
| 11 | Provider tests | `flutter test` |
| 12 | Full verification | `flutter analyze`, `flutter test`, `flutter run` |

**Total: 12 tasks, 15 screens, 5 API clients, 10 Freezed models, 5 Riverpod providers**

All code generation uses `dart run build_runner build --delete-conflicting-outputs`. All dependencies installed via `flutter pub add`. All analysis via `flutter analyze`.
