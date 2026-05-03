// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedule_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(schedule)
final scheduleProvider = ScheduleFamily._();

final class ScheduleProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<TrainingWeek>>,
          List<TrainingWeek>,
          FutureOr<List<TrainingWeek>>
        >
    with
        $FutureModifier<List<TrainingWeek>>,
        $FutureProvider<List<TrainingWeek>> {
  ScheduleProvider._({
    required ScheduleFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'scheduleProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$scheduleHash();

  @override
  String toString() {
    return r'scheduleProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<TrainingWeek>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<TrainingWeek>> create(Ref ref) {
    final argument = this.argument as int;
    return schedule(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$scheduleHash() => r'bfa3a0effd6cdf483e8207088057a92c0ac55d6a';

final class ScheduleFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<TrainingWeek>>, int> {
  ScheduleFamily._()
    : super(
        retry: null,
        name: r'scheduleProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ScheduleProvider call(int goalId) =>
      ScheduleProvider._(argument: goalId, from: this);

  @override
  String toString() => r'scheduleProvider';
}

@ProviderFor(currentWeek)
final currentWeekProvider = CurrentWeekFamily._();

final class CurrentWeekProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrainingWeek?>,
          TrainingWeek?,
          FutureOr<TrainingWeek?>
        >
    with $FutureModifier<TrainingWeek?>, $FutureProvider<TrainingWeek?> {
  CurrentWeekProvider._({
    required CurrentWeekFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'currentWeekProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$currentWeekHash();

  @override
  String toString() {
    return r'currentWeekProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrainingWeek?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrainingWeek?> create(Ref ref) {
    final argument = this.argument as int;
    return currentWeek(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CurrentWeekProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$currentWeekHash() => r'49f4d9dc29228e801d0431d63f9feae4e54840ea';

final class CurrentWeekFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrainingWeek?>, int> {
  CurrentWeekFamily._()
    : super(
        retry: null,
        name: r'currentWeekProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CurrentWeekProvider call(int goalId) =>
      CurrentWeekProvider._(argument: goalId, from: this);

  @override
  String toString() => r'currentWeekProvider';
}

@ProviderFor(trainingDayDetail)
final trainingDayDetailProvider = TrainingDayDetailFamily._();

final class TrainingDayDetailProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrainingDay>,
          TrainingDay,
          FutureOr<TrainingDay>
        >
    with $FutureModifier<TrainingDay>, $FutureProvider<TrainingDay> {
  TrainingDayDetailProvider._({
    required TrainingDayDetailFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'trainingDayDetailProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trainingDayDetailHash();

  @override
  String toString() {
    return r'trainingDayDetailProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrainingDay> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrainingDay> create(Ref ref) {
    final argument = this.argument as int;
    return trainingDayDetail(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrainingDayDetailProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trainingDayDetailHash() => r'53d21f2ffd82aa9a1ba6fc1ce85db132e2a1dbf6';

final class TrainingDayDetailFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrainingDay>, int> {
  TrainingDayDetailFamily._()
    : super(
        retry: null,
        name: r'trainingDayDetailProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrainingDayDetailProvider call(int dayId) =>
      TrainingDayDetailProvider._(argument: dayId, from: this);

  @override
  String toString() => r'trainingDayDetailProvider';
}

@ProviderFor(trainingDayResult)
final trainingDayResultProvider = TrainingDayResultFamily._();

final class TrainingDayResultProvider
    extends
        $FunctionalProvider<
          AsyncValue<TrainingResult?>,
          TrainingResult?,
          FutureOr<TrainingResult?>
        >
    with $FutureModifier<TrainingResult?>, $FutureProvider<TrainingResult?> {
  TrainingDayResultProvider._({
    required TrainingDayResultFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'trainingDayResultProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trainingDayResultHash();

  @override
  String toString() {
    return r'trainingDayResultProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<TrainingResult?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<TrainingResult?> create(Ref ref) {
    final argument = this.argument as int;
    return trainingDayResult(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrainingDayResultProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trainingDayResultHash() => r'10ffd4a3b90182e99971a0c396be1b5dc5ca2594';

final class TrainingDayResultFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<TrainingResult?>, int> {
  TrainingDayResultFamily._()
    : super(
        retry: null,
        name: r'trainingDayResultProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  TrainingDayResultProvider call(int dayId) =>
      TrainingDayResultProvider._(argument: dayId, from: this);

  @override
  String toString() => r'trainingDayResultProvider';
}

/// Wearable activities the runner has synced near a training day's date,
/// each flagged with whether they're already matched. Feeds the
/// "Pick activity" modal on the day detail screen.

@ProviderFor(availableActivities)
final availableActivitiesProvider = AvailableActivitiesFamily._();

/// Wearable activities the runner has synced near a training day's date,
/// each flagged with whether they're already matched. Feeds the
/// "Pick activity" modal on the day detail screen.

final class AvailableActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<AvailableActivity>>,
          List<AvailableActivity>,
          FutureOr<List<AvailableActivity>>
        >
    with
        $FutureModifier<List<AvailableActivity>>,
        $FutureProvider<List<AvailableActivity>> {
  /// Wearable activities the runner has synced near a training day's date,
  /// each flagged with whether they're already matched. Feeds the
  /// "Pick activity" modal on the day detail screen.
  AvailableActivitiesProvider._({
    required AvailableActivitiesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'availableActivitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availableActivitiesHash();

  @override
  String toString() {
    return r'availableActivitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<AvailableActivity>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<AvailableActivity>> create(Ref ref) {
    final argument = this.argument as int;
    return availableActivities(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableActivitiesProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableActivitiesHash() =>
    r'6daf8028bbae0e9534679a0eed62a84d7c9205cf';

/// Wearable activities the runner has synced near a training day's date,
/// each flagged with whether they're already matched. Feeds the
/// "Pick activity" modal on the day detail screen.

final class AvailableActivitiesFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<AvailableActivity>>, int> {
  AvailableActivitiesFamily._()
    : super(
        retry: null,
        name: r'availableActivitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Wearable activities the runner has synced near a training day's date,
  /// each flagged with whether they're already matched. Feeds the
  /// "Pick activity" modal on the day detail screen.

  AvailableActivitiesProvider call(int dayId) =>
      AvailableActivitiesProvider._(argument: dayId, from: this);

  @override
  String toString() => r'availableActivitiesProvider';
}

/// Manually match (or unlink) a wearable activity for a training day.
///
/// Mutators capture every cross-provider dependency BEFORE awaiting the
/// API call. The host widget (e.g. the activity-picker sheet) can be torn
/// down while the request is in flight — autoDispose then disposes this
/// provider's `ref` and any `ref.read(...)` after the await throws. By
/// dereferencing once up-front we operate on stable handles and the awaited
/// future settles cleanly even if the caller already navigated away.

@ProviderFor(ManualMatchActivity)
final manualMatchActivityProvider = ManualMatchActivityProvider._();

/// Manually match (or unlink) a wearable activity for a training day.
///
/// Mutators capture every cross-provider dependency BEFORE awaiting the
/// API call. The host widget (e.g. the activity-picker sheet) can be torn
/// down while the request is in flight — autoDispose then disposes this
/// provider's `ref` and any `ref.read(...)` after the await throws. By
/// dereferencing once up-front we operate on stable handles and the awaited
/// future settles cleanly even if the caller already navigated away.
final class ManualMatchActivityProvider
    extends $NotifierProvider<ManualMatchActivity, void> {
  /// Manually match (or unlink) a wearable activity for a training day.
  ///
  /// Mutators capture every cross-provider dependency BEFORE awaiting the
  /// API call. The host widget (e.g. the activity-picker sheet) can be torn
  /// down while the request is in flight — autoDispose then disposes this
  /// provider's `ref` and any `ref.read(...)` after the await throws. By
  /// dereferencing once up-front we operate on stable handles and the awaited
  /// future settles cleanly even if the caller already navigated away.
  ManualMatchActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualMatchActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualMatchActivityHash();

  @$internal
  @override
  ManualMatchActivity create() => ManualMatchActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$manualMatchActivityHash() =>
    r'a2f5604002d02ed44cef50830d70fcc1f458948d';

/// Manually match (or unlink) a wearable activity for a training day.
///
/// Mutators capture every cross-provider dependency BEFORE awaiting the
/// API call. The host widget (e.g. the activity-picker sheet) can be torn
/// down while the request is in flight — autoDispose then disposes this
/// provider's `ref` and any `ref.read(...)` after the await throws. By
/// dereferencing once up-front we operate on stable handles and the awaited
/// future settles cleanly even if the caller already navigated away.

abstract class _$ManualMatchActivity extends $Notifier<void> {
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

/// Move a training day to a new date. The backend re-assigns the day to the
/// matching training week if the new date crosses a week boundary.

@ProviderFor(RescheduleDay)
final rescheduleDayProvider = RescheduleDayProvider._();

/// Move a training day to a new date. The backend re-assigns the day to the
/// matching training week if the new date crosses a week boundary.
final class RescheduleDayProvider
    extends $NotifierProvider<RescheduleDay, void> {
  /// Move a training day to a new date. The backend re-assigns the day to the
  /// matching training week if the new date crosses a week boundary.
  RescheduleDayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'rescheduleDayProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$rescheduleDayHash();

  @$internal
  @override
  RescheduleDay create() => RescheduleDay();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$rescheduleDayHash() => r'a607cdcbaf6dab6af6e2139adc687a79668a10c6';

/// Move a training day to a new date. The backend re-assigns the day to the
/// matching training week if the new date crosses a week boundary.

abstract class _$RescheduleDay extends $Notifier<void> {
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

/// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
/// then yields the text and closes. Yields `null` while pending so the UI can
/// keep the spinner on screen. Auto-disposes when the screen leaves.

@ProviderFor(trainingDayAiFeedback)
final trainingDayAiFeedbackProvider = TrainingDayAiFeedbackFamily._();

/// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
/// then yields the text and closes. Yields `null` while pending so the UI can
/// keep the spinner on screen. Auto-disposes when the screen leaves.

final class TrainingDayAiFeedbackProvider
    extends $FunctionalProvider<AsyncValue<String?>, String?, Stream<String?>>
    with $FutureModifier<String?>, $StreamProvider<String?> {
  /// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
  /// then yields the text and closes. Yields `null` while pending so the UI can
  /// keep the spinner on screen. Auto-disposes when the screen leaves.
  TrainingDayAiFeedbackProvider._({
    required TrainingDayAiFeedbackFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'trainingDayAiFeedbackProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$trainingDayAiFeedbackHash();

  @override
  String toString() {
    return r'trainingDayAiFeedbackProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $StreamProviderElement<String?> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<String?> create(Ref ref) {
    final argument = this.argument as int;
    return trainingDayAiFeedback(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is TrainingDayAiFeedbackProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$trainingDayAiFeedbackHash() =>
    r'2562a9a69a33da7b9c84891891dd6e297f520415';

/// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
/// then yields the text and closes. Yields `null` while pending so the UI can
/// keep the spinner on screen. Auto-disposes when the screen leaves.

final class TrainingDayAiFeedbackFamily extends $Family
    with $FunctionalFamilyOverride<Stream<String?>, int> {
  TrainingDayAiFeedbackFamily._()
    : super(
        retry: null,
        name: r'trainingDayAiFeedbackProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Polls `/training-days/{id}/result` every 5s until `ai_feedback` is non-null,
  /// then yields the text and closes. Yields `null` while pending so the UI can
  /// keep the spinner on screen. Auto-disposes when the screen leaves.

  TrainingDayAiFeedbackProvider call(int dayId) =>
      TrainingDayAiFeedbackProvider._(argument: dayId, from: this);

  @override
  String toString() => r'trainingDayAiFeedbackProvider';
}
