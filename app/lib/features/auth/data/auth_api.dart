import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/auth/models/auth_response.dart';

part 'auth_api.g.dart';

@RestApi()
abstract class AuthApi {
  factory AuthApi(Dio dio) = _AuthApi;

  @POST('/auth/apple')
  Future<AuthResponse> appleSignIn(@Body() Map<String, dynamic> body);

  @POST('/auth/dev-login')
  Future<AuthResponse> devLogin();

  @POST('/auth/logout')
  Future<void> logout();

  @DELETE('/profile')
  Future<void> deleteAccount();

  @GET('/profile')
  Future<dynamic> getProfile();

  @PUT('/profile')
  Future<dynamic> updateProfile(@Body() Map<String, dynamic> body);
}

@riverpod
AuthApi authApi(Ref ref) => AuthApi(ref.watch(dioProvider));
