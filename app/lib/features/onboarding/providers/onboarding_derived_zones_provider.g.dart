// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_derived_zones_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
/// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
///
/// Connect-health sets it via `.notifier.set(...)`; zones-screen reads it
/// on mount to populate source-aware subtitle copy (e.g. "Based on your
/// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
/// derive call failed silently) — the zones screen falls back to generic
/// copy based on `user.heartRateZonesSource`.

@ProviderFor(OnboardingDerivedZones)
final onboardingDerivedZonesProvider = OnboardingDerivedZonesProvider._();

/// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
/// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
///
/// Connect-health sets it via `.notifier.set(...)`; zones-screen reads it
/// on mount to populate source-aware subtitle copy (e.g. "Based on your
/// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
/// derive call failed silently) — the zones screen falls back to generic
/// copy based on `user.heartRateZonesSource`.
final class OnboardingDerivedZonesProvider
    extends $NotifierProvider<OnboardingDerivedZones, DerivedZones?> {
  /// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
  /// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
  ///
  /// Connect-health sets it via `.notifier.set(...)`; zones-screen reads it
  /// on mount to populate source-aware subtitle copy (e.g. "Based on your
  /// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
  /// derive call failed silently) — the zones screen falls back to generic
  /// copy based on `user.heartRateZonesSource`.
  OnboardingDerivedZonesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingDerivedZonesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingDerivedZonesHash();

  @$internal
  @override
  OnboardingDerivedZones create() => OnboardingDerivedZones();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DerivedZones? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DerivedZones?>(value),
    );
  }
}

String _$onboardingDerivedZonesHash() =>
    r'240d2310f9b44b1a3159a33bb8e11aa6cfe76caa';

/// Carries the latest `DerivedZones` result from `/onboarding/connect-health`
/// to `/onboarding/zones` across the in-between `/onboarding/overview` screen.
///
/// Connect-health sets it via `.notifier.set(...)`; zones-screen reads it
/// on mount to populate source-aware subtitle copy (e.g. "Based on your
/// last 23 runs…"). Null = no fresh derive (deep-link, web-skip, or the
/// derive call failed silently) — the zones screen falls back to generic
/// copy based on `user.heartRateZonesSource`.

abstract class _$OnboardingDerivedZones extends $Notifier<DerivedZones?> {
  DerivedZones? build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<DerivedZones?, DerivedZones?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DerivedZones?, DerivedZones?>,
              DerivedZones?,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
