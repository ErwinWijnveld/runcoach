// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
/// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
/// The conversation is created lazily on the first sendMessage server-side,
/// so `build()` returns an empty list when no chat exists yet.

@ProviderFor(WorkoutChat)
final workoutChatProvider = WorkoutChatFamily._();

/// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
/// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
/// The conversation is created lazily on the first sendMessage server-side,
/// so `build()` returns an empty list when no chat exists yet.
final class WorkoutChatProvider
    extends $AsyncNotifierProvider<WorkoutChat, List<CoachMessage>> {
  /// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
  /// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
  /// The conversation is created lazily on the first sendMessage server-side,
  /// so `build()` returns an empty list when no chat exists yet.
  WorkoutChatProvider._({
    required WorkoutChatFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'workoutChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutChatHash();

  @override
  String toString() {
    return r'workoutChatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkoutChat create() => WorkoutChat();

  @override
  bool operator ==(Object other) {
    return other is WorkoutChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutChatHash() => r'e3693d0c4251b580109b2f370b77184fb2c0df73';

/// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
/// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
/// The conversation is created lazily on the first sendMessage server-side,
/// so `build()` returns an empty list when no chat exists yet.

final class WorkoutChatFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkoutChat,
          AsyncValue<List<CoachMessage>>,
          List<CoachMessage>,
          FutureOr<List<CoachMessage>>,
          int
        > {
  WorkoutChatFamily._()
    : super(
        retry: null,
        name: r'workoutChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
  /// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
  /// The conversation is created lazily on the first sendMessage server-side,
  /// so `build()` returns an empty list when no chat exists yet.

  WorkoutChatProvider call(int trainingDayId) =>
      WorkoutChatProvider._(argument: trainingDayId, from: this);

  @override
  String toString() => r'workoutChatProvider';
}

/// Per-training-day chat. Mirrors `CoachChat` (same SSE shape) but is
/// keyed by `trainingDayId` and hits the `/workout-chat/{day}` endpoints.
/// The conversation is created lazily on the first sendMessage server-side,
/// so `build()` returns an empty list when no chat exists yet.

abstract class _$WorkoutChat extends $AsyncNotifier<List<CoachMessage>> {
  late final _$args = ref.$arg as int;
  int get trainingDayId => _$args;

  FutureOr<List<CoachMessage>> build(int trainingDayId);
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
