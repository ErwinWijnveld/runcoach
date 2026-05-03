// ignore: unused_import
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/models/hr_zone.dart';
import 'package:app/features/auth/models/user.dart';
import 'package:app/features/onboarding/models/plan_generation.dart';
import 'package:app/features/push/services/push_service.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class Auth extends _$Auth {
  @override
  AsyncValue<User?> build() {
    _checkAuth();
    return const AsyncValue.data(null);
  }

  Future<void> _checkAuth() async {
    final tokenStorage = ref.read(tokenStorageProvider);
    final hasToken = await tokenStorage.hasToken();
    if (hasToken) {
      await loadProfile();
      if (kDebugMode && state.hasError) {
        await tokenStorage.clearToken();
        await loginDev();
      }
    } else if (kDebugMode) {
      await loginDev();
    }
  }

  Future<void> loginDev() async {
    try {
      final api = ref.read(authApiProvider);
      final response = await api.devLogin();

      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.setToken(response.token);

      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Exchange an Apple identity token (from sign_in_with_apple) for a Sanctum
  /// bearer. `email` and `name` are only present on the *first* Apple sign-in
  /// per user; subsequent sign-ins return only the `sub`.
  Future<void> loginWithApple({
    required String identityToken,
    String? email,
    String? name,
  }) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(authApiProvider);
      final response = await api.appleSignIn({
        'identity_token': identityToken,
        if (email != null && email.isNotEmpty) 'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
      });

      final tokenStorage = ref.read(tokenStorageProvider);
      await tokenStorage.setToken(response.token);

      state = AsyncValue.data(response.user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> loadProfile() async {
    try {
      final api = ref.read(authApiProvider);
      final data = await api.getProfile();
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      state = AsyncValue.data(user);
      // Refresh the device-token row server-side. No-op (returns null) if
      // the user previously denied the iOS permission prompt.
      unawaited(ref.read(pushServiceProvider).registerIfPermitted());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    // Drop the device-token row before clearing the bearer — the unregister
    // call needs auth to scope to this user.
    try {
      await ref.read(pushServiceProvider).unregister();
    } catch (_) {}
    try {
      await api.logout();
    } catch (_) {}
    await tokenStorage.clearToken();
    state = const AsyncValue.data(null);
  }

  Future<void> updateProfile({String? name, List<HrZone>? heartRateZones}) async {
    final api = ref.read(authApiProvider);
    final body = <String, dynamic>{
      'name': ?name,
      'heart_rate_zones': ?heartRateZones?.map((z) => z.toJson()).toList(),
    };
    if (body.isEmpty) return;
    final data = await api.updateProfile(body) as Map<String, dynamic>;
    final user = User.fromJson(data['user'] as Map<String, dynamic>);
    state = AsyncValue.data(user);
  }

  Future<void> deleteAccount() async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    await api.deleteAccount();
    await tokenStorage.clearToken();
    state = const AsyncValue.data(null);
  }

  /// Patch the local pending_plan_generation field without an HTTP roundtrip.
  /// Lets the onboarding screen update local state synchronously before
  /// navigating to the chat — without this, the router's redirect would
  /// see stale `processing` status and bounce the user back to the loading
  /// screen mid-navigation.
  void patchPendingPlanGeneration(PlanGeneration? row) {
    final current = state.value;
    if (current == null) return;
    state = AsyncValue.data(current.copyWith(pendingPlanGeneration: row));
  }

  bool get isLoggedIn => state.value != null;
  bool get needsOnboarding => !(state.value?.hasCompletedOnboarding ?? false);
}
