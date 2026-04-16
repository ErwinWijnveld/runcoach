// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(onboardingConversationId)
final onboardingConversationIdProvider = OnboardingConversationIdProvider._();

final class OnboardingConversationIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  OnboardingConversationIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingConversationIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingConversationIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return onboardingConversationId(ref);
  }
}

String _$onboardingConversationIdHash() =>
    r'a8c64deeca0bb483bae839e7d7214c60837eb0ad';
