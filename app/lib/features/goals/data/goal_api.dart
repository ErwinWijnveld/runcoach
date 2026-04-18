import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'goal_api.g.dart';

@RestApi()
abstract class GoalApi {
  factory GoalApi(Dio dio) = _GoalApi;

  @GET('/goals')
  Future<dynamic> getGoals();

  @POST('/goals')
  Future<dynamic> createGoal(@Body() Map<String, dynamic> body);

  @GET('/goals/{id}')
  Future<dynamic> getGoal(@Path() int id);

  @PUT('/goals/{id}')
  Future<dynamic> updateGoal(
    @Path() int id,
    @Body() Map<String, dynamic> body,
  );

  @DELETE('/goals/{id}')
  Future<void> deleteGoal(@Path() int id);

  @POST('/goals/{id}/activate')
  Future<dynamic> activateGoal(@Path() int id);
}

@riverpod
GoalApi goalApi(Ref ref) => GoalApi(ref.watch(dioProvider));
