// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(OnboardingChat)
final onboardingChatProvider = OnboardingChatFamily._();

final class OnboardingChatProvider
    extends $AsyncNotifierProvider<OnboardingChat, List<CoachMessage>> {
  OnboardingChatProvider._({
    required OnboardingChatFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'onboardingChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$onboardingChatHash();

  @override
  String toString() {
    return r'onboardingChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  OnboardingChat create() => OnboardingChat();

  @override
  bool operator ==(Object other) {
    return other is OnboardingChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$onboardingChatHash() => r'9ef1985031313568f62c1d55af7a5eacd235dd82';

final class OnboardingChatFamily extends $Family
    with
        $ClassFamilyOverride<
          OnboardingChat,
          AsyncValue<List<CoachMessage>>,
          List<CoachMessage>,
          FutureOr<List<CoachMessage>>,
          String
        > {
  OnboardingChatFamily._()
    : super(
        retry: null,
        name: r'onboardingChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  OnboardingChatProvider call(String conversationId) =>
      OnboardingChatProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'onboardingChatProvider';
}

abstract class _$OnboardingChat extends $AsyncNotifier<List<CoachMessage>> {
  late final _$args = ref.$arg as String;
  String get conversationId => _$args;

  FutureOr<List<CoachMessage>> build(String conversationId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<List<CoachMessage>>, List<CoachMessage>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CoachMessage>>, List<CoachMessage>>,
              AsyncValue<List<CoachMessage>>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}
