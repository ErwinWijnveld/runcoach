import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'notifications_api.g.dart';

@RestApi()
abstract class NotificationsApi {
  factory NotificationsApi(Dio dio) = _NotificationsApi;

  @GET('/notifications')
  Future<dynamic> list();

  @POST('/notifications/{id}/accept')
  Future<dynamic> accept(@Path() int id);

  @POST('/notifications/{id}/dismiss')
  Future<dynamic> dismiss(@Path() int id);
}

@riverpod
NotificationsApi notificationsApi(Ref ref) =>
    NotificationsApi(ref.watch(dioProvider));
