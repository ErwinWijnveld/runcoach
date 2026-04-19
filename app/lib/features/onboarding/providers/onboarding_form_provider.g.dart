// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_form_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the user's choices while they step through the onboarding form.
/// Values accumulate across steps; the generating screen reads the final
/// snapshot and posts it.

@ProviderFor(OnboardingForm)
final onboardingFormProvider = OnboardingFormProvider._();

/// Holds the user's choices while they step through the onboarding form.
/// Values accumulate across steps; the generating screen reads the final
/// snapshot and posts it.
final class OnboardingFormProvider
    extends $NotifierProvider<OnboardingForm, OnboardingFormData> {
  /// Holds the user's choices while they step through the onboarding form.
  /// Values accumulate across steps; the generating screen reads the final
  /// snapshot and posts it.
  OnboardingFormProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingFormProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingFormHash();

  @$internal
  @override
  OnboardingForm create() => OnboardingForm();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingFormData value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingFormData>(value),
    );
  }
}

String _$onboardingFormHash() => r'd4825aa8a6d60202c9802ad436decb362c8ab07e';

/// Holds the user's choices while they step through the onboarding form.
/// Values accumulate across steps; the generating screen reads the final
/// snapshot and posts it.

abstract class _$OnboardingForm extends $Notifier<OnboardingFormData> {
  OnboardingFormData build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<OnboardingFormData, OnboardingFormData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<OnboardingFormData, OnboardingFormData>,
              OnboardingFormData,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
