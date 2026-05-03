import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'coach_api.g.dart';

@RestApi()
abstract class CoachApi {
  factory CoachApi(Dio dio) = _CoachApi;

  @GET('/coach/conversations')
  Future<dynamic> getConversations();

  @POST('/coach/conversations')
  Future<dynamic> createConversation(@Body() Map<String, dynamic> body);

  @GET('/coach/conversations/{id}')
  Future<dynamic> getConversation(@Path() String id);

  @DELETE('/coach/conversations/{id}')
  Future<void> deleteConversation(@Path() String id);

  @POST('/coach/proposals/{id}/accept')
  Future<void> acceptProposal(@Path() int id);

  @POST('/coach/proposals/{id}/reject')
  Future<void> rejectProposal(@Path() int id);

}

@riverpod
CoachApi coachApi(Ref ref) => CoachApi(ref.watch(dioProvider));
