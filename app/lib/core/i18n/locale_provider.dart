import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/i18n/current_locale.dart';
import 'package:app/core/utils/date_formatter.dart';
import 'package:app/features/auth/data/auth_api.dart';

part 'locale_provider.g.dart';

/// Single source of truth for the app's active locale.
///
/// On first launch, auto-detects from the device's preferred languages
/// (returns Dutch only when one of the device's preferred languages
/// is Dutch; everything else falls back to English). The rationale for
/// language-only matching — not country-based — is in the design doc
/// `docs/superpowers/specs/2026-05-12-i18n-multilingual-research.md` §3.2.
///
/// Persists user override in `shared_preferences` under [_overrideKey].
/// Passing null to [setOverride] clears the override and reverts to
/// auto-detection on next read.
@Riverpod(keepAlive: true)
class AppLocale extends _$AppLocale {
  static const _overrideKey = 'app_locale_override';
  static const _supported = {'en', 'nl'};

  @override
  Future<Locale> build() async {
    final prefs = await SharedPreferences.getInstance();
    final override = prefs.getString(_overrideKey);
    final resolved = (override != null && _supported.contains(override))
        ? Locale(override)
        : detectDeviceLocale();

    _syncSideEffects(resolved);
    return resolved;
  }

  /// Picks the first device-preferred language that's Dutch; otherwise
  /// defaults to English. Public so tests + first-frame code paths can
  /// resolve without spinning up a ProviderContainer.
  static Locale detectDeviceLocale() {
    final preferred = WidgetsBinding.instance.platformDispatcher.locales;
    for (final loc in preferred) {
      if (loc.languageCode.toLowerCase() == 'nl') {
        return const Locale('nl');
      }
    }
    return const Locale('en');
  }

  /// Sets an explicit user override (English / Dutch) or clears it
  /// (pass null → reverts to device auto-detection on next launch).
  ///
  /// Also pushes the choice to the backend (`PUT /profile`) so queue
  /// workers (notifications, agent runs that don't see an HTTP request)
  /// read it from `users.locale`. The push is fire-and-forget — the
  /// local override applies instantly regardless, and the next API call
  /// with `Accept-Language: <new>` re-syncs server-side resolution.
  Future<void> setOverride(Locale? locale) async {
    // Capture cross-provider deps BEFORE the first await, per the
    // mutator-providers convention in app/CLAUDE.md §1b.
    final api = ref.read(authApiProvider);

    final prefs = await SharedPreferences.getInstance();
    if (locale == null) {
      await prefs.remove(_overrideKey);
      final resolved = detectDeviceLocale();
      _syncSideEffects(resolved);
      state = AsyncData(resolved);
      unawaited(_pushToBackend(api, null));
      return;
    }

    if (!_supported.contains(locale.languageCode)) {
      throw ArgumentError.value(locale, 'locale', 'Unsupported locale');
    }

    await prefs.setString(_overrideKey, locale.languageCode);
    _syncSideEffects(locale);
    state = AsyncData(locale);
    unawaited(_pushToBackend(api, locale.languageCode));
  }

  void _syncSideEffects(Locale locale) {
    currentAppLocaleTag = locale.languageCode;
    appDateLocale = locale.languageCode;
  }

  Future<void> _pushToBackend(AuthApi api, String? localeCode) async {
    try {
      await api.updateProfile({'locale': localeCode});
    } catch (e, st) {
      // Best-effort. Common reason: the user isn't signed in yet (the
      // override may have been picked up from shared_preferences on a
      // fresh launch before auth completes). The local override is
      // already applied; the next manual change or sign-in will re-sync.
      if (kDebugMode) {
        debugPrint('[i18n] failed to push locale to backend: $e\n$st');
      }
    }
  }
}
