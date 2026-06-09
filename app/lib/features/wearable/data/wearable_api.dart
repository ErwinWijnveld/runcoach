import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/wearable/services/health_kit_service.dart';

part 'wearable_api.g.dart';

/// Batch size for ROUTE-FREE `/wearable/activities` posts (onboarding metric
/// sync). Each activity is ~500 bytes, so we can use the backend's max of 200
/// per request — a thousand runs is just five round-trips.
const int kWearableIngestChunkSize = 200;

/// Batch size for ROUTE-CARRYING posts (foreground sync + the shareable-run
/// route backfill). Each activity can be tens of KB once the GPS polyline is
/// attached, so we keep batches small to stay under PHP's `post_max_size`
/// (8 MB default) and avoid 413 Content Too Large.
const int kWearableRouteIngestChunkSize = 25;

@RestApi()
abstract class WearableApi {
  factory WearableApi(Dio dio) = _WearableApi;

  @POST('/wearable/activities')
  Future<dynamic> ingest(@Body() Map<String, dynamic> body);

  @GET('/wearable/activities')
  Future<dynamic> list();

  @GET('/wearable/activities/{id}/analysis')
  Future<dynamic> analysisStatus(@Path('id') int id);

  /// Returns the GPS polyline for a single wearable activity. Used by
  /// the shareable run-card flow. Returns an empty `points` array for
  /// treadmill / no-GPS activities rather than 404'ing.
  @GET('/wearable/activities/{id}/route')
  Future<dynamic> route(@Path('id') int id);

  @POST('/wearable/personal-records')
  Future<dynamic> ingestPersonalRecords(@Body() Map<String, dynamic> body);
}

@riverpod
WearableApi wearableApi(Ref ref) => WearableApi(ref.watch(dioProvider));

@riverpod
HealthKitService healthKitService(Ref ref) => HealthKitService();

/// On-demand HealthKit PR lookup for a single distance, cached per-distance
/// by Riverpod's family auto-caching. Used by the onboarding form's goal
/// time + current-PR steps so the field pre-fills the moment the user
/// picks a distance — including custom "Other → 26km" picks the standard
/// connect-health prefetch doesn't cover.
///
/// Returns the raw map from the MethodChannel (durationSeconds,
/// distanceMeters, date, sourceActivityId) or null when no qualifying
/// workout exists. The form converts to a parsed seconds value itself.
@riverpod
Future<Map<String, dynamic>?> personalRecordForDistance(
  Ref ref,
  int distanceMeters,
) async {
  final hk = ref.watch(healthKitServiceProvider);
  return hk.fetchPersonalRecord(distanceMeters: distanceMeters);
}
