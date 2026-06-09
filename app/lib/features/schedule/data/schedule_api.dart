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

  @PATCH('/training-days/{dayId}')
  Future<dynamic> updateTrainingDay(
    @Path() int dayId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/training-days/{dayId}/result')
  Future<dynamic> getTrainingResult(@Path() int dayId);

  @GET('/training-days/{dayId}/available-activities')
  Future<dynamic> getAvailableActivities(@Path() int dayId);

  @POST('/training-days/{dayId}/match-activity')
  Future<dynamic> matchActivity(
    @Path() int dayId,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/training-days/{dayId}/match-activity')
  Future<void> unlinkActivity(@Path() int dayId);

  /// Link an off-plan run to a planned session. The backend relocates that
  /// session's calendar entry onto the run's actual date and scores it.
  @POST('/wearable/activities/{activityId}/link-day')
  Future<dynamic> linkActivityToDay(
    @Path() int activityId,
    @Body() Map<String, dynamic> body,
  );

  @GET('/workout-chat/{dayId}')
  Future<dynamic> getWorkoutChat(@Path() int dayId);

  /// Look up the RunCoachAgent conversation attached to this training
  /// week, if any. Returns `{data: {id}}` or `{data: null}`. The
  /// conversation itself is created lazily via the regular
  /// `POST /coach/conversations` (with subject binding) on first send.
  @GET('/schedule/weeks/{weekId}/chat')
  Future<dynamic> getWeekChat(@Path() int weekId);
}

@riverpod
ScheduleApi scheduleApi(Ref ref) => ScheduleApi(ref.watch(dioProvider));
