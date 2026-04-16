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

String _$coachChatHash() => r'e5e382149768aa994bc7403c94dfd86293f01f07';

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
