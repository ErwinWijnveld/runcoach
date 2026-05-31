// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(conversations)
final conversationsProvider = ConversationsProvider._();

final class ConversationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Conversation>>,
          List<Conversation>,
          FutureOr<List<Conversation>>
        >
    with
        $FutureModifier<List<Conversation>>,
        $FutureProvider<List<Conversation>> {
  ConversationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'conversationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$conversationsHash();

  @$internal
  @override
  $FutureProviderElement<List<Conversation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Conversation>> create(Ref ref) {
    return conversations(ref);
  }
}

String _$conversationsHash() => r'2e10a6a3adfefcacaa630ffa97b1cca79ad7854c';

/// Whether [conversationId] is the onboarding conversation. Reads the show
/// endpoint's `context` field directly so it's correct on a cold-start deep
/// link (the conversation list isn't consulted). Used by the chat screen to
/// hide the agent's priming first user message during onboarding.

@ProviderFor(conversationIsOnboarding)
final conversationIsOnboardingProvider = ConversationIsOnboardingFamily._();

/// Whether [conversationId] is the onboarding conversation. Reads the show
/// endpoint's `context` field directly so it's correct on a cold-start deep
/// link (the conversation list isn't consulted). Used by the chat screen to
/// hide the agent's priming first user message during onboarding.

final class ConversationIsOnboardingProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, FutureOr<bool>>
    with $FutureModifier<bool>, $FutureProvider<bool> {
  /// Whether [conversationId] is the onboarding conversation. Reads the show
  /// endpoint's `context` field directly so it's correct on a cold-start deep
  /// link (the conversation list isn't consulted). Used by the chat screen to
  /// hide the agent's priming first user message during onboarding.
  ConversationIsOnboardingProvider._({
    required ConversationIsOnboardingFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'conversationIsOnboardingProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$conversationIsOnboardingHash();

  @override
  String toString() {
    return r'conversationIsOnboardingProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<bool> create(Ref ref) {
    final argument = this.argument as String;
    return conversationIsOnboarding(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationIsOnboardingProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$conversationIsOnboardingHash() =>
    r'ff4e60ee709e37b4a2b99e332d0cdde68ccb9256';

/// Whether [conversationId] is the onboarding conversation. Reads the show
/// endpoint's `context` field directly so it's correct on a cold-start deep
/// link (the conversation list isn't consulted). Used by the chat screen to
/// hide the agent's priming first user message during onboarding.

final class ConversationIsOnboardingFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<bool>, String> {
  ConversationIsOnboardingFamily._()
    : super(
        retry: null,
        name: r'conversationIsOnboardingProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Whether [conversationId] is the onboarding conversation. Reads the show
  /// endpoint's `context` field directly so it's correct on a cold-start deep
  /// link (the conversation list isn't consulted). Used by the chat screen to
  /// hide the agent's priming first user message during onboarding.

  ConversationIsOnboardingProvider call(String conversationId) =>
      ConversationIsOnboardingProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'conversationIsOnboardingProvider';
}

/// Standalone accept/reject helpers so onboarding can use them without
/// activating [CoachChat] (which would load messages from the wrong endpoint).

@ProviderFor(ProposalActions)
final proposalActionsProvider = ProposalActionsProvider._();

/// Standalone accept/reject helpers so onboarding can use them without
/// activating [CoachChat] (which would load messages from the wrong endpoint).
final class ProposalActionsProvider
    extends $NotifierProvider<ProposalActions, void> {
  /// Standalone accept/reject helpers so onboarding can use them without
  /// activating [CoachChat] (which would load messages from the wrong endpoint).
  ProposalActionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'proposalActionsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$proposalActionsHash();

  @$internal
  @override
  ProposalActions create() => ProposalActions();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$proposalActionsHash() => r'34c3f53d9ea32385bf0c8a8f08987030b80e81e1';

/// Standalone accept/reject helpers so onboarding can use them without
/// activating [CoachChat] (which would load messages from the wrong endpoint).

abstract class _$ProposalActions extends $Notifier<void> {
  void build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<void, void>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<void, void>,
              void,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CoachChat)
final coachChatProvider = CoachChatFamily._();

final class CoachChatProvider
    extends $AsyncNotifierProvider<CoachChat, List<CoachMessage>> {
  CoachChatProvider._({
    required CoachChatFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'coachChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachChatHash();

  @override
  String toString() {
    return r'coachChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CoachChat create() => CoachChat();

  @override
  bool operator ==(Object other) {
    return other is CoachChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachChatHash() => r'c8984f2a65a2e4678eaac7712133dba132f32f18';

final class CoachChatFamily extends $Family
    with
        $ClassFamilyOverride<
          CoachChat,
          AsyncValue<List<CoachMessage>>,
          List<CoachMessage>,
          FutureOr<List<CoachMessage>>,
          String
        > {
  CoachChatFamily._()
    : super(
        retry: null,
        name: r'coachChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoachChatProvider call(String conversationId) =>
      CoachChatProvider._(argument: conversationId, from: this);

  @override
  String toString() => r'coachChatProvider';
}

abstract class _$CoachChat extends $AsyncNotifier<List<CoachMessage>> {
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
