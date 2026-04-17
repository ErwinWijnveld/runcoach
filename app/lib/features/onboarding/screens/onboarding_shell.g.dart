// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_shell.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(_onboardingConversationId)
final _onboardingConversationIdProvider = _OnboardingConversationIdProvider._();

final class _OnboardingConversationIdProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  _OnboardingConversationIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'_onboardingConversationIdProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$_onboardingConversationIdHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return _onboardingConversationId(ref);
  }
}

String _$_onboardingConversationIdHash() =>
    r'4db9f20df318fab60da5ece5763c9e9dadfadd4a';
