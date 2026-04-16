import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'schedule_api.g.dart';

@RestApi()
abstract class ScheduleApi {
  factory ScheduleApi(Dio dio) = _ScheduleApi;

  @GET('/goals/{goalId}/schedule')
  Future<dynamic> getSchedule(@Path() int goalId);

  @GET('/goals/{goalId}/schedule/current')
  Future<dynamic> getCurrentWeek(@Path() int goalId);

  @GET('/training-days/{dayId}')
  Future<dynamic> getTrainingDay(@Path() int dayId);

  @GET('/training-days/{dayId}/result')
  Future<dynamic> getTrainingResult(@Path() int dayId);
}

@riverpod
ScheduleApi scheduleApi(Ref ref) => ScheduleApi(ref.watch(dioProvider));
