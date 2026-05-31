import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'plan_evaluations_api.g.dart';

@RestApi()
abstract class PlanEvaluationsApi {
  factory PlanEvaluationsApi(Dio dio) = _PlanEvaluationsApi;

  /// All evaluations for the user's currently active goal.
  @GET('/plan-evaluations')
  Future<dynamic> listForActiveGoal();

  @GET('/plan-evaluations/{id}')
  Future<dynamic> show(@Path() int id);
}

@riverpod
PlanEvaluationsApi planEvaluationsApi(Ref ref) =>
    PlanEvaluationsApi(ref.watch(dioProvider));
