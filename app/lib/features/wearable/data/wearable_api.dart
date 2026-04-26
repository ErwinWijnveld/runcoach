import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/wearable/services/health_kit_service.dart';

part 'wearable_api.g.dart';

@RestApi()
abstract class WearableApi {
  factory WearableApi(Dio dio) = _WearableApi;

  @POST('/wearable/activities')
  Future<dynamic> ingest(@Body() Map<String, dynamic> body);

  @GET('/wearable/activities')
  Future<dynamic> list();

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
