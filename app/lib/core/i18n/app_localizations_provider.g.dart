// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_localizations_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Exposes [AppLocalizations] outside of widget trees.
///
/// Use cases: services that compose user-visible strings (e.g. error
/// formatters, notification body assemblers), Riverpod providers that
/// need localized copy in their state, etc.
///
/// In widget code prefer `context.l10n.foo` (cheaper, synchronous).
///
/// Rebuilds whenever [appLocaleProvider] emits a new locale.

@ProviderFor(appLocalizations)
final appLocalizationsProvider = AppLocalizationsProvider._();

/// Exposes [AppLocalizations] outside of widget trees.
///
/// Use cases: services that compose user-visible strings (e.g. error
/// formatters, notification body assemblers), Riverpod providers that
/// need localized copy in their state, etc.
///
/// In widget code prefer `context.l10n.foo` (cheaper, synchronous).
///
/// Rebuilds whenever [appLocaleProvider] emits a new locale.

final class AppLocalizationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<AppLocalizations>,
          AppLocalizations,
          FutureOr<AppLocalizations>
        >
    with $FutureModifier<AppLocalizations>, $FutureProvider<AppLocalizations> {
  /// Exposes [AppLocalizations] outside of widget trees.
  ///
  /// Use cases: services that compose user-visible strings (e.g. error
  /// formatters, notification body assemblers), Riverpod providers that
  /// need localized copy in their state, etc.
  ///
  /// In widget code prefer `context.l10n.foo` (cheaper, synchronous).
  ///
  /// Rebuilds whenever [appLocaleProvider] emits a new locale.
  AppLocalizationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appLocalizationsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appLocalizationsHash();

  @$internal
  @override
  $FutureProviderElement<AppLocalizations> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AppLocalizations> create(Ref ref) {
    return appLocalizations(ref);
  }
}

String _$appLocalizationsHash() => r'40f24b0017677f8543d80dfd6d3217f61cea382a';
