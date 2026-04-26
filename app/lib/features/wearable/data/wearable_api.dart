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
}

@riverpod
WearableApi wearableApi(Ref ref) => WearableApi(ref.watch(dioProvider));

@riverpod
HealthKitService healthKitService(Ref ref) => HealthKitService();
