import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:app/core/i18n/current_locale.dart';
import 'package:app/core/i18n/locale_provider.dart';

void main() {
  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    currentAppLocaleTag = 'en';
  });

  test('persists override across rebuilds', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container
        .read(appLocaleProvider.notifier)
        .setOverride(const Locale('nl'));
    expect(currentAppLocaleTag, 'nl');

    // New container = simulates app restart with the same shared_preferences.
    final container2 = ProviderContainer();
    addTearDown(container2.dispose);
    final resolved = await container2.read(appLocaleProvider.future);

    expect(resolved.languageCode, 'nl');
    expect(currentAppLocaleTag, 'nl');
  });

  test('clearing override falls back to detected device locale', () async {
    SharedPreferences.setMockInitialValues({
      'app_locale_override': 'nl',
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final resolvedBefore = await container.read(appLocaleProvider.future);
    expect(resolvedBefore.languageCode, 'nl');

    await container.read(appLocaleProvider.notifier).setOverride(null);

    // Test harness's device locale is en_US → detection returns 'en'.
    expect(container.read(appLocaleProvider).value?.languageCode, 'en');
    expect(currentAppLocaleTag, 'en');
  });

  test('throws on unsupported locale', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      () => container
          .read(appLocaleProvider.notifier)
          .setOverride(const Locale('fr')),
      throwsArgumentError,
    );
  });
}
