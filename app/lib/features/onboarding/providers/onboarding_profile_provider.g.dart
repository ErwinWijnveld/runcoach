// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_profile_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fetches the running profile for the onboarding overview screen. While the
/// backend is still syncing Strava history it returns `status: 'syncing'` on
/// HTTP 202 — we poll every 3s up to ~36s before giving up.

@ProviderFor(OnboardingProfileController)
final onboardingProfileControllerProvider =
    OnboardingProfileControllerProvider._();

/// Fetches the running profile for the onboarding overview screen. While the
/// backend is still syncing Strava history it returns `status: 'syncing'` on
/// HTTP 202 — we poll every 3s up to ~36s before giving up.
final class OnboardingProfileControllerProvider
    extends
        $AsyncNotifierProvider<OnboardingProfileController, OnboardingProfile> {
  /// Fetches the running profile for the onboarding overview screen. While the
  /// backend is still syncing Strava history it returns `status: 'syncing'` on
  /// HTTP 202 — we poll every 3s up to ~36s before giving up.
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
    r'bd4ea6ea2ac0d25641d526acb0e97c79ff1f56ee';

/// Fetches the running profile for the onboarding overview screen. While the
/// backend is still syncing Strava history it returns `status: 'syncing'` on
/// HTTP 202 — we poll every 3s up to ~36s before giving up.

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
