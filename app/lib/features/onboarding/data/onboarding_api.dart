import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'onboarding_api.g.dart';

@RestApi()
abstract class OnboardingApi {
  factory OnboardingApi(Dio dio) = _OnboardingApi;

  @POST('/onboarding/start')
  Future<dynamic> start();

  @GET('/onboarding/conversations/{id}')
  Future<dynamic> fetchConversation(@Path('id') String id);

  @POST('/onboarding/conversations/{id}/messages')
  Future<dynamic> reply(@Path('id') String id, @Body() Map<String, dynamic> body);
}

@riverpod
OnboardingApi onboardingApi(Ref ref) => OnboardingApi(ref.watch(dioProvider));
