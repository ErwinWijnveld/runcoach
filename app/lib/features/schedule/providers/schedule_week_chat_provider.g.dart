// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_week_chat_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Per-training-week chat using the regular RunCoachAgent. Keyed by
/// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
/// (12-18 May)") that will be stored on the conversation row when it
/// gets lazy-created on the first send.
///
/// Unlike [WorkoutChat], this provider talks to the normal coach
/// endpoints (`/coach/conversations/*`) so the conversation surfaces in
/// the regular chat list and is re-openable from `/coach/chat/{id}`.

@ProviderFor(ScheduleWeekChat)
final scheduleWeekChatProvider = ScheduleWeekChatFamily._();

/// Per-training-week chat using the regular RunCoachAgent. Keyed by
/// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
/// (12-18 May)") that will be stored on the conversation row when it
/// gets lazy-created on the first send.
///
/// Unlike [WorkoutChat], this provider talks to the normal coach
/// endpoints (`/coach/conversations/*`) so the conversation surfaces in
/// the regular chat list and is re-openable from `/coach/chat/{id}`.
final class ScheduleWeekChatProvider
    extends $AsyncNotifierProvider<ScheduleWeekChat, List<CoachMessage>> {
  /// Per-training-week chat using the regular RunCoachAgent. Keyed by
  /// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
  /// (12-18 May)") that will be stored on the conversation row when it
  /// gets lazy-created on the first send.
  ///
  /// Unlike [WorkoutChat], this provider talks to the normal coach
  /// endpoints (`/coach/conversations/*`) so the conversation surfaces in
  /// the regular chat list and is re-openable from `/coach/chat/{id}`.
  ScheduleWeekChatProvider._({
    required ScheduleWeekChatFamily super.from,
    required (int, String) super.argument,
  }) : super(
         retry: null,
         name: r'scheduleWeekChatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scheduleWeekChatHash();

  @override
  String toString() {
    return r'scheduleWeekChatProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  ScheduleWeekChat create() => ScheduleWeekChat();

  @override
  bool operator ==(Object other) {
    return other is ScheduleWeekChatProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scheduleWeekChatHash() => r'f62041e069dcc6d98e389f151c3d41c05132aa96';

/// Per-training-week chat using the regular RunCoachAgent. Keyed by
/// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
/// (12-18 May)") that will be stored on the conversation row when it
/// gets lazy-created on the first send.
///
/// Unlike [WorkoutChat], this provider talks to the normal coach
/// endpoints (`/coach/conversations/*`) so the conversation surfaces in
/// the regular chat list and is re-openable from `/coach/chat/{id}`.

final class ScheduleWeekChatFamily extends $Family
    with
        $ClassFamilyOverride<
          ScheduleWeekChat,
          AsyncValue<List<CoachMessage>>,
          List<CoachMessage>,
          FutureOr<List<CoachMessage>>,
          (int, String)
        > {
  ScheduleWeekChatFamily._()
    : super(
        retry: null,
        name: r'scheduleWeekChatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Per-training-week chat using the regular RunCoachAgent. Keyed by
  /// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
  /// (12-18 May)") that will be stored on the conversation row when it
  /// gets lazy-created on the first send.
  ///
  /// Unlike [WorkoutChat], this provider talks to the normal coach
  /// endpoints (`/coach/conversations/*`) so the conversation surfaces in
  /// the regular chat list and is re-openable from `/coach/chat/{id}`.

  ScheduleWeekChatProvider call(int weekId, String weekTitle) =>
      ScheduleWeekChatProvider._(argument: (weekId, weekTitle), from: this);

  @override
  String toString() => r'scheduleWeekChatProvider';
}

/// Per-training-week chat using the regular RunCoachAgent. Keyed by
/// (weekId, weekTitle) so the sheet can pre-set the title (e.g. "Week 3
/// (12-18 May)") that will be stored on the conversation row when it
/// gets lazy-created on the first send.
///
/// Unlike [WorkoutChat], this provider talks to the normal coach
/// endpoints (`/coach/conversations/*`) so the conversation surfaces in
/// the regular chat list and is re-openable from `/coach/chat/{id}`.

abstract class _$ScheduleWeekChat extends $AsyncNotifier<List<CoachMessage>> {
  late final _$args = ref.$arg as (int, String);
  int get weekId => _$args.$1;
  String get weekTitle => _$args.$2;

  FutureOr<List<CoachMessage>> build(int weekId, String weekTitle);
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
    element.handleCreate(ref, () => build(_$args.$1, _$args.$2));
  }
}
