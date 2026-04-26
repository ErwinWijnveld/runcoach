import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'devices_api.g.dart';

@RestApi()
abstract class DevicesApi {
  factory DevicesApi(Dio dio) = _DevicesApi;

  @POST('/devices')
  Future<void> register(@Body() Map<String, dynamic> body);

  @DELETE('/devices')
  Future<void> unregister(@Body() Map<String, dynamic> body);
}

@riverpod
DevicesApi devicesApi(Ref ref) => DevicesApi(ref.watch(dioProvider));
