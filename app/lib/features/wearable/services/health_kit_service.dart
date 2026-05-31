import 'package:flutter/services.dart';
import 'package:health/health.dart';
import 'package:app/features/wearable/services/workout_route_service.dart';

/// Reads workouts and HR samples from Apple HealthKit and shapes them into
/// the payload the backend `POST /wearable/activities` endpoint expects.
///
/// Time-window queries via the `health` package are sufficient for v1 — we
/// fetch on app launch + when the connect-health screen completes. A future
/// follow-up can add a Swift `HKObserverQuery` MethodChannel for true
/// background delivery, plus `predicateForObjects(from: workout)` for
/// strictly workout-scoped HR samples (the time-window query here picks up
/// any HR samples that overlap the workout window, which usually means
/// workout HR but can include resting watch readings on either side).
class HealthKitService {
  HealthKitService([
    Health? health,
    MethodChannel? prChannel,
    WorkoutRouteService? routeService,
  ])  : _health = health ?? Health(),
        _prChannel = prChannel ?? const MethodChannel('nl.runcoach/healthkit_prs'),
        _routeService = routeService ?? WorkoutRouteService();

  final Health _health;
  final MethodChannel _prChannel;
  final WorkoutRouteService _routeService;

  static const _workoutType = HealthDataType.WORKOUT;
  static const _hrType = HealthDataType.HEART_RATE;
  static const _restingHrType = HealthDataType.RESTING_HEART_RATE;
  static const _birthDateType = HealthDataType.BIRTH_DATE;
  // BIRTH_DATE + RESTING_HEART_RATE feed the HR-zone deriver. Keep them
  // in the permission set so iOS re-prompts the next time the user lands
  // on the connect-health screen — without that, getBirthDate() /
  // getLatestRestingHeartRate() silently return null and the deriver
  // falls back to defaults.
  static const _readTypes = <HealthDataType>[
    _workoutType,
    _hrType,
    _restingHrType,
    _birthDateType,
  ];

  /// Request HealthKit read access for workouts AND heart rate in a single
  /// system prompt (iOS shows one sheet with both rows). Returns the boolean
  /// the `health` package gives us, but the caller should NOT treat `false`
  /// as "denied":
  ///
  /// - On iOS, `requestAuthorization` returns `false` whenever ANY requested
  ///   type wasn't granted — so a user who allows workouts but denies HR
  ///   shows up as `false`, even though we can perfectly well sync workouts.
  /// - Apple's `hasPermissions(READ)` is also unreliable for read-only
  ///   types (privacy: Apple won't tell apps which types they're allowed
  ///   to read).
  ///
  /// The connect-health screen treats the return value purely as a hint and
  /// always falls through to `fetchWorkouts()` — if workouts come back
  /// empty, that's surfaced as the empty-history state which lets the user
  /// continue regardless. HR is best-effort per workout
  /// (`_fetchHeartRateForWorkout` returns null when denied or absent).
  Future<bool> requestPermissions() async {
    await _health.configure();

    // permissions length must match _readTypes length — one access mode
    // per requested type. All read-only.
    return await _health.requestAuthorization(
      _readTypes,
      permissions:
          List<HealthDataAccess>.filled(_readTypes.length, HealthDataAccess.READ),
    );
  }

  /// Pull workouts in the given window and shape them for the backend.
  /// Default window is **the last 12 months** so the runner's profile (which
  /// the backend analyzes over 52 weeks) reflects their full year of running.
  /// HealthKit has no real upper bound on past dates — 365 days returns in
  /// well under a second even for runners with hundreds of workouts.
  ///
  /// For each surviving workout, also queries HR samples in its time window
  /// to surface `average_heartrate` / `max_heartrate`. These come back as
  /// SEPARATE HealthKit samples (HR is a quantity stream, not a workout
  /// summary field), so without this extra pass the backend would see
  /// every Apple Health workout as HR-less and the coach would say
  /// "I don't have heart-rate data for these runs".
  /// When [includeRoutes] is false, the slow per-workout GPS route queries are
  /// skipped and `raw_data.route` is left empty. The onboarding/metrics sync
  /// passes false: routes are only needed for the shareable run-card (a much
  /// smaller, recent window) and are backfilled lazily afterwards. Stripping
  /// them keeps each activity ~500 bytes instead of tens of KB, so even a
  /// thousand runs sync in a few small batches without tripping
  /// `post_max_size`.
  Future<List<Map<String, dynamic>>> fetchWorkouts({
    Duration window = const Duration(days: 365),
    bool includeRoutes = true,
  }) async {
    final now = DateTime.now();
    final start = now.subtract(window);

    final samples = await _health.getHealthDataFromTypes(
      types: const [_workoutType],
      startTime: start,
      endTime: now,
    );

    int skippedNonRun = 0;
    int skippedZeroDistance = 0;

    // First pass: shape + filter. No HR queries yet — we batch those next.
    final pending = <(HealthDataPoint, Map<String, dynamic>)>[];
    for (final point in samples) {
      if (point.value is! WorkoutHealthValue) continue;
      final shaped = _shape(point);
      if (shaped == null) {
        skippedNonRun++;
        continue;
      }
      if ((shaped['distance_meters'] as int) <= 0) {
        // Treadmill runs the watch couldn't track come back as
        // distance=null/0. They're noise for pace + km aggregates so we
        // drop them — the user can still see them in Apple Health itself.
        skippedZeroDistance++;
        continue;
      }
      pending.add((point, shaped));
    }

    // HR queries used to run sequentially per workout — 200 runs = 200
    // round-trips ≈ 30s of perceived "stuck on Pulling your runs…". Run
    // them in parallel batches of 10 so HealthKit isn't slammed but we
    // also don't wait on a single slow query.
    int hrAttached = 0;
    const hrBatchSize = 10;
    for (var i = 0; i < pending.length; i += hrBatchSize) {
      final end =
          (i + hrBatchSize < pending.length) ? i + hrBatchSize : pending.length;
      final batch = pending.sublist(i, end);
      final hrs = await Future.wait(batch.map((entry) =>
          _fetchHeartRateForWorkout(entry.$1.dateFrom, entry.$1.dateTo)));
      for (var j = 0; j < batch.length; j++) {
        final hr = hrs[j];
        if (hr != null) {
          batch[j].$2['average_heartrate'] = hr.average;
          batch[j].$2['max_heartrate'] = hr.max;
          hrAttached++;
        }
      }
    }

    // GPS route per workout — feeds the shareable run-card flow. Empty
    // arrays (treadmill / no-GPS / permission denied) are persisted as
    // `raw_data.route: []` so the card flow can confidently render the
    // no-route variant without re-querying HealthKit. Skipped entirely for
    // metric-only syncs (onboarding) — see [includeRoutes].
    int routesAttached = 0;
    if (includeRoutes) {
      const routeBatchSize = 10;
      for (var i = 0; i < pending.length; i += routeBatchSize) {
        final end = (i + routeBatchSize < pending.length)
            ? i + routeBatchSize
            : pending.length;
        final batch = pending.sublist(i, end);
        final routes = await Future.wait(
          batch.map((entry) => _routeService.fetchRoute(entry.$1.uuid)),
        );
        for (var j = 0; j < batch.length; j++) {
          final points = routes[j];
          if (points.isEmpty) continue;
          final shaped = batch[j].$2;
          final rawData = Map<String, dynamic>.from(
            shaped['raw_data'] as Map? ?? const <String, dynamic>{},
          );
          rawData['route'] =
              points.map((p) => p.toJson()).toList(growable: false);
          shaped['raw_data'] = rawData;
          routesAttached++;
        }
      }
    }

    final workouts = pending.map((e) => e.$2).toList();

    // ignore: avoid_print
    print('[HealthKit] window=${window.inDays}d found ${workouts.length} runs '
        '(hr_attached=$hrAttached, routes_attached=$routesAttached, '
        'skipped non-run=$skippedNonRun, zero-distance=$skippedZeroDistance)');

    return workouts;
  }

  /// Pull HR samples bounded by [start]–[end], compute avg + max. Returns
  /// null when there are no samples in the window (manually-logged runs,
  /// runs done without an Apple Watch, etc.) so the backend keeps the
  /// columns null instead of writing 0.
  Future<({double average, double max})?> _fetchHeartRateForWorkout(
    DateTime start,
    DateTime end,
  ) async {
    if (!end.isAfter(start)) return null;

    try {
      final samples = await _health.getHealthDataFromTypes(
        types: const [_hrType],
        startTime: start,
        endTime: end,
      );

      final values = <double>[];
      for (final s in samples) {
        if (s.value is! NumericHealthValue) continue;
        final v = (s.value as NumericHealthValue).numericValue.toDouble();
        // HealthKit BPM range. Anything outside is bad data (watch glitch,
        // simulator junk) — drop it instead of letting it skew the average.
        if (v >= 30 && v <= 250) values.add(v);
      }

      if (values.isEmpty) return null;

      final avg = values.reduce((a, b) => a + b) / values.length;
      final max = values.reduce((a, b) => a > b ? a : b);
      return (average: avg, max: max);
    } catch (_) {
      // HealthKit denies HR access for some runs (e.g. third-party imports).
      // Don't fail the whole sync — just leave HR null on this row.
      return null;
    }
  }

  Map<String, dynamic>? _shape(HealthDataPoint point) {
    final w = point.value as WorkoutHealthValue;

    final type = _normalizeType(w.workoutActivityType);
    if (type == null) return null;

    final start = point.dateFrom;
    final end = point.dateTo;
    final durationSeconds = end.difference(start).inSeconds;
    if (durationSeconds <= 0) return null;

    final distanceMeters = (w.totalDistance ?? 0).round();

    return {
      'source': 'apple_health',
      'source_activity_id': point.uuid,
      'source_user_id': point.sourceId,
      'type': type,
      'name': null,
      'distance_meters': distanceMeters,
      'duration_seconds': durationSeconds,
      'elapsed_seconds': durationSeconds,
      'start_date': start.toUtc().toIso8601String(),
      'end_date': end.toUtc().toIso8601String(),
      'calories_kcal': (w.totalEnergyBurned ?? 0).round(),
      'raw_data': const <String, dynamic>{},
    };
  }

  /// Map HealthKit's running enums to our backend `type` strings.
  /// Returns null for non-running activity types so the caller can skip them.
  String? _normalizeType(HealthWorkoutActivityType type) {
    switch (type) {
      case HealthWorkoutActivityType.RUNNING:
      case HealthWorkoutActivityType.RUNNING_TREADMILL:
        return 'Run';
      default:
        return null;
    }
  }

  /// All-time personal records for an arbitrary set of distances. Bridges
  /// to native Swift (`HealthKitPersonalRecords.swift`) which uses
  /// `HKQuery.predicateForWorkouts(operatorType:totalDistance:)` + sort by
  /// duration ASC + limit 1 to find each fastest matching workout in
  /// milliseconds, regardless of how many years of HealthKit history the
  /// runner has. Pulling the equivalent into Dart and filtering would mean
  /// loading hundreds of HKWorkout objects per query.
  ///
  /// Returns a map keyed by **stringified integer meters** so the caller
  /// can mix standard distances (5000, 10000, 21097, 42195) with any
  /// custom distance (e.g. 26000 when the user picks "Other → 26km" in
  /// the onboarding form):
  ///   {
  ///     '5000':  {duration_seconds: 1685, distance_meters: 5023, date: '2024-09-12T...', source_activity_id: '...'},
  ///     '10000': {duration_seconds: 3620, ...},
  ///     '21097': null,    // no qualifying workout
  ///     '42195': null,
  ///   }
  ///
  /// Tolerance: ±[toleranceFraction] on distance (default 2%, so a
  /// 4900-5100m run counts as a 5k). Both `.running` and
  /// `.runningTreadmill` workouts qualify.
  Future<Map<String, Map<String, dynamic>?>> fetchPersonalRecords({
    required List<num> distancesMeters,
    double toleranceFraction = 0.02,
  }) async {
    if (distancesMeters.isEmpty) return const {};

    try {
      // Hard cap on the native call. The Swift side fires N parallel
      // HKSampleQueries via DispatchGroup; if any one's callback never
      // fires (very rare HealthKit edge case on permission revocation
      // mid-flight) the group never notifies and the await would hang
      // the entire onboarding screen. 15s is generous for hundreds of
      // queries against a fully-indexed HealthKit store.
      final raw = await _prChannel
          .invokeMethod<Map<Object?, Object?>>(
            'getPersonalRecords',
            {
              'distances': distancesMeters.map((d) => d.toDouble()).toList(),
              'toleranceFraction': toleranceFraction,
            },
          )
          .timeout(const Duration(seconds: 15), onTimeout: () => null);
      if (raw == null) return const {};

      final out = <String, Map<String, dynamic>?>{};
      raw.forEach((key, value) {
        if (key is! String) return;
        if (value == null) {
          out[key] = null;
          return;
        }
        if (value is Map) {
          out[key] = Map<String, dynamic>.from(value);
        }
      });

      // ignore: avoid_print
      print('[HealthKit] PRs: ${out.entries.where((e) => e.value != null).length} of ${out.length} distances');

      return out;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('[HealthKit] PR query failed: ${e.code} ${e.message}');
      return const {};
    } on MissingPluginException {
      // Running on simulator without the native bridge wired up, or in a
      // unit test without a method-channel mock. Don't crash the flow.
      return const {};
    }
  }

  /// Date of birth from HealthKit's `dateOfBirth` characteristic. Used
  /// by the HR-zone deriver (and the yearly birthday push) — the
  /// backend computes age from DOB at runtime so it stays accurate over
  /// years.
  ///
  /// Returns null on:
  ///   - permission denied (Apple silently no-ops on characteristic
  ///     reads the user hasn't granted),
  ///   - DOB not set in the Health app,
  ///   - any platform exception (we never block the deriver on this).
  ///
  /// The `health` package's BIRTH_DATE on iOS surfaces a single
  /// HealthDataPoint whose value carries the DOB. Different package
  /// versions use either NumericHealthValue (year only) or attach the
  /// date to `dateFrom` — try both and pick the more specific one.
  Future<DateTime?> getBirthDate() async {
    try {
      await _health.configure();
      final samples = await _health.getHealthDataFromTypes(
        types: const [_birthDateType],
        startTime: DateTime(1900),
        endTime: DateTime.now(),
      );
      if (samples.isEmpty) return null;
      final s = samples.last;
      final v = s.value;
      DateTime? dob;
      if (v is NumericHealthValue) {
        // Year-only — fabricate Jan 1. Better than nothing, accurate
        // enough for Tanaka (the formula is age in whole years).
        final year = v.numericValue.toInt();
        if (year > 1900 && year < DateTime.now().year) {
          dob = DateTime(year, 1, 1);
        }
      }
      // Fall back to the sample's start date — some plugin versions
      // attach the full DOB there.
      dob ??= s.dateFrom;
      // Sanity check: implausibly young or old → treat as no signal.
      final age = _yearsBetween(dob, DateTime.now());
      if (age < 5 || age > 120) return null;
      return dob;
    } catch (_) {
      return null;
    }
  }

  int _yearsBetween(DateTime from, DateTime to) {
    var years = to.year - from.year;
    if (to.month < from.month ||
        (to.month == from.month && to.day < from.day)) {
      years -= 1;
    }
    return years;
  }

  /// Latest resting heart-rate sample from HealthKit. Apple Watch updates
  /// this throughout the day — taking the most recent sample is fine
  /// (running 7-day averages aren't worth the extra complexity for v1).
  /// Used as the resting-HR input to Karvonen-method zone derivation.
  ///
  /// Returns null when no sample exists or when permission was denied.
  Future<int?> getLatestRestingHeartRate() async {
    try {
      await _health.configure();
      final samples = await _health.getHealthDataFromTypes(
        types: const [_restingHrType],
        startTime: DateTime.now().subtract(const Duration(days: 90)),
        endTime: DateTime.now(),
      );
      if (samples.isEmpty) return null;
      // Latest sample wins.
      samples.sort((a, b) => b.dateFrom.compareTo(a.dateFrom));
      final v = samples.first.value;
      if (v is! NumericHealthValue) return null;
      final bpm = v.numericValue.toDouble();
      if (bpm < 30 || bpm > 120) return null;
      return bpm.round();
    } catch (_) {
      return null;
    }
  }

  /// Convenience: lookup the PR for a single distance. Returns null when
  /// no qualifying workout exists. Used by the onboarding form's
  /// `personalRecordForDistanceProvider` when the user picks a distance —
  /// caches in Riverpod so going back+forward through the form doesn't
  /// re-query HealthKit.
  Future<Map<String, dynamic>?> fetchPersonalRecord({
    required int distanceMeters,
    double toleranceFraction = 0.02,
  }) async {
    final result = await fetchPersonalRecords(
      distancesMeters: [distanceMeters],
      toleranceFraction: toleranceFraction,
    );
    return result[distanceMeters.toString()];
  }
}
