// ignore: unused_import
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/storage/token_storage.dart';
import 'package:app/features/auth/data/auth_api.dart';
import 'package:app/features/auth/models/user.dart';

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

  Future<void> loginWithStrava(String code) async {
    state = const AsyncValue.loading();
    try {
      final api = ref.read(authApiProvider);
      final response = await api.callback(code);

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
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    try {
      await api.logout();
    } catch (_) {}
    await tokenStorage.clearToken();
    state = const AsyncValue.data(null);
  }

  Future<void> deleteAccount() async {
    final api = ref.read(authApiProvider);
    final tokenStorage = ref.read(tokenStorageProvider);
    await api.deleteAccount();
    await tokenStorage.clearToken();
    state = const AsyncValue.data(null);
  }

  bool get isLoggedIn => state.value != null;
  bool get needsOnboarding => !(state.value?.hasCompletedOnboarding ?? false);
}
