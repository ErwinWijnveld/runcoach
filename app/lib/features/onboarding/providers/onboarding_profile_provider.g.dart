// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the running profile for the onboarding overview screen. The first
/// call after Strava auth blocks on a server-side inline Strava history sync
/// (30-90s) and returns `status: 'ready'` directly — no polling needed.

@ProviderFor(OnboardingProfileController)
final onboardingProfileControllerProvider =
    OnboardingProfileControllerProvider._();

/// Fetches the running profile for the onboarding overview screen. The first
/// call after Strava auth blocks on a server-side inline Strava history sync
/// (30-90s) and returns `status: 'ready'` directly — no polling needed.
final class OnboardingProfileControllerProvider
    extends
        $AsyncNotifierProvider<OnboardingProfileController, OnboardingProfile> {
  /// Fetches the running profile for the onboarding overview screen. The first
  /// call after Strava auth blocks on a server-side inline Strava history sync
  /// (30-90s) and returns `status: 'ready'` directly — no polling needed.
  OnboardingProfileControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingProfileControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingProfileControllerHash();

  @$internal
  @override
  OnboardingProfileController create() => OnboardingProfileController();
}

String _$onboardingProfileControllerHash() =>
    r'22fbb61a87440662c59fd719cf3bfc454055e4e0';

/// Fetches the running profile for the onboarding overview screen. The first
/// call after Strava auth blocks on a server-side inline Strava history sync
/// (30-90s) and returns `status: 'ready'` directly — no polling needed.

abstract class _$OnboardingProfileController
    extends $AsyncNotifier<OnboardingProfile> {
  FutureOr<OnboardingProfile> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<OnboardingProfile>, OnboardingProfile>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<OnboardingProfile>, OnboardingProfile>,
              AsyncValue<OnboardingProfile>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
