// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(AppLocale)
final appLocaleProvider = AppLocaleProvider._();

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
final class AppLocaleProvider
    extends $AsyncNotifierProvider<AppLocale, Locale> {
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
  AppLocaleProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocaleProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocaleHash();

  @$internal
  @override
  AppLocale create() => AppLocale();
}

String _$appLocaleHash() => r'895315593a2780896ee0da8677ce67296fd7569b';

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

abstract class _$AppLocale extends $AsyncNotifier<Locale> {
  FutureOr<Locale> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<Locale>, Locale>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<Locale>, Locale>,
              AsyncValue<Locale>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
