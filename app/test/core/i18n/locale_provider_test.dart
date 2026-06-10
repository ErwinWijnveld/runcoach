import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/i18n/current_locale.dart';
import 'package:app/core/i18n/locale_provider.dart';
import 'package:app/features/auth/data/auth_api.dart';

/// Records `PUT /profile` bodies instead of hitting the real Dio stack —
/// the real client's AuthInterceptor reads flutter_secure_storage, which
/// has no implementation in tests.
class _RecordingAuthApi implements AuthApi {
  final profileUpdates = <Map<String, dynamic>>[];

  @override
  Future<dynamic> updateProfile(Map<String, dynamic> body) async {
    profileUpdates.add(body);
    return <String, dynamic>{};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late _RecordingAuthApi api;

  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [authApiProvider.overrideWithValue(api)],
    );
    addTearDown(container.dispose);
    return container;
  }

  /// The backend push is fire-and-forget; give its microtask/timer a turn
  /// before asserting on it.
  Future<void> settlePush() => Future<void>.delayed(Duration.zero);

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    currentAppLocaleTag = 'en';
    api = _RecordingAuthApi();
  });

  test('persists override across rebuilds', () async {
    final container = makeContainer();

    await container
        .read(appLocaleProvider.notifier)
        .setOverride(const Locale('nl'));
    expect(currentAppLocaleTag, 'nl');

    await settlePush();
    expect(api.profileUpdates, [
      {'locale': 'nl'},
    ]);

    // New container = simulates app restart with the same shared_preferences.
    final container2 = makeContainer();
    final resolved = await container2.read(appLocaleProvider.future);

    expect(resolved.languageCode, 'nl');
    expect(currentAppLocaleTag, 'nl');
  });

  test('clearing override falls back to detected device locale', () async {
    SharedPreferences.setMockInitialValues({
      'app_locale_override': 'nl',
    });
    final container = makeContainer();

    final resolvedBefore = await container.read(appLocaleProvider.future);
    expect(resolvedBefore.languageCode, 'nl');

    await container.read(appLocaleProvider.notifier).setOverride(null);

    // Test harness's device locale is en_US → detection returns 'en'.
    expect(container.read(appLocaleProvider).value?.languageCode, 'en');
    expect(currentAppLocaleTag, 'en');

    await settlePush();
    expect(api.profileUpdates, [
      {'locale': null},
    ]);
  });

  test('throws on unsupported locale', () async {
    final container = makeContainer();

    expect(
      () => container
          .read(appLocaleProvider.notifier)
          .setOverride(const Locale('fr')),
      throwsArgumentError,
    );
  });
}
