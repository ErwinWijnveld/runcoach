import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'race_api.g.dart';

@RestApi()
abstract class RaceApi {
  factory RaceApi(Dio dio) = _RaceApi;

  @GET('/races')
  Future<dynamic> getRaces();

  @POST('/races')
  Future<dynamic> createRace(@Body() Map<String, dynamic> body);

  @GET('/races/{id}')
  Future<dynamic> getRace(@Path() int id);

  @PUT('/races/{id}')
  Future<dynamic> updateRace(
    @Path() int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/races/{id}')
  Future<void> deleteRace(@Path() int id);
}

@riverpod
RaceApi raceApi(Ref ref) => RaceApi(ref.watch(dioProvider));
