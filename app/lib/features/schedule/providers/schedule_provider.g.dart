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

String _$scheduleHash() => r'bcd6e658baed6db6f974acd06ba50a888ed58513';

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

String _$currentWeekHash() => r'94d43966786c3efb50d7494aff21ec070e74ae2f';

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

String _$trainingDayDetailHash() => r'afbf174a686bacdd83e29f7d567f150bcdc05e9f';

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

String _$trainingDayResultHash() => r'a2225c4c98dd04d6dc95f039a6ad525ad8a055d8';

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

/// Recent Strava runs near a training day's date, with a flag on each
/// indicating whether it's already matched to a training day (same user).
/// Feeds the "Select Strava run" modal.

@ProviderFor(availableStravaActivities)
final availableStravaActivitiesProvider = AvailableStravaActivitiesFamily._();

/// Recent Strava runs near a training day's date, with a flag on each
/// indicating whether it's already matched to a training day (same user).
/// Feeds the "Select Strava run" modal.

final class AvailableStravaActivitiesProvider
    extends
        $FunctionalProvider<
          AsyncValue<AvailableStravaActivitiesResult>,
          AvailableStravaActivitiesResult,
          FutureOr<AvailableStravaActivitiesResult>
        >
    with
        $FutureModifier<AvailableStravaActivitiesResult>,
        $FutureProvider<AvailableStravaActivitiesResult> {
  /// Recent Strava runs near a training day's date, with a flag on each
  /// indicating whether it's already matched to a training day (same user).
  /// Feeds the "Select Strava run" modal.
  AvailableStravaActivitiesProvider._({
    required AvailableStravaActivitiesFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'availableStravaActivitiesProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$availableStravaActivitiesHash();

  @override
  String toString() {
    return r'availableStravaActivitiesProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<AvailableStravaActivitiesResult> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<AvailableStravaActivitiesResult> create(Ref ref) {
    final argument = this.argument as int;
    return availableStravaActivities(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is AvailableStravaActivitiesProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$availableStravaActivitiesHash() =>
    r'4d4bd672da5d72e1aa29c8300692d9adb6fae628';

/// Recent Strava runs near a training day's date, with a flag on each
/// indicating whether it's already matched to a training day (same user).
/// Feeds the "Select Strava run" modal.

final class AvailableStravaActivitiesFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<AvailableStravaActivitiesResult>,
          int
        > {
  AvailableStravaActivitiesFamily._()
    : super(
        retry: null,
        name: r'availableStravaActivitiesProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Recent Strava runs near a training day's date, with a flag on each
  /// indicating whether it's already matched to a training day (same user).
  /// Feeds the "Select Strava run" modal.

  AvailableStravaActivitiesProvider call(int dayId) =>
      AvailableStravaActivitiesProvider._(argument: dayId, from: this);

  @override
  String toString() => r'availableStravaActivitiesProvider';
}

/// Manually match (or unlink) a Strava activity for a training day.
/// The caller invalidates `trainingDayDetailProvider(dayId)` + the weekly
/// schedule providers afterwards to refresh the UI.

@ProviderFor(ManualMatchStravaActivity)
final manualMatchStravaActivityProvider = ManualMatchStravaActivityProvider._();

/// Manually match (or unlink) a Strava activity for a training day.
/// The caller invalidates `trainingDayDetailProvider(dayId)` + the weekly
/// schedule providers afterwards to refresh the UI.
final class ManualMatchStravaActivityProvider
    extends $NotifierProvider<ManualMatchStravaActivity, void> {
  /// Manually match (or unlink) a Strava activity for a training day.
  /// The caller invalidates `trainingDayDetailProvider(dayId)` + the weekly
  /// schedule providers afterwards to refresh the UI.
  ManualMatchStravaActivityProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'manualMatchStravaActivityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$manualMatchStravaActivityHash();

  @$internal
  @override
  ManualMatchStravaActivity create() => ManualMatchStravaActivity();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(void value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<void>(value),
    );
  }
}

String _$manualMatchStravaActivityHash() =>
    r'cba8522119a7511bee13daa2ef593eeb86705837';

/// Manually match (or unlink) a Strava activity for a training day.
/// The caller invalidates `trainingDayDetailProvider(dayId)` + the weekly
/// schedule providers afterwards to refresh the UI.

abstract class _$ManualMatchStravaActivity extends $Notifier<void> {
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
