import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';

part 'organization_api.g.dart';

@RestApi()
abstract class OrganizationApi {
  factory OrganizationApi(Dio dio) = _OrganizationApi;

  @GET('/organizations/search')
  Future<dynamic> searchOrganizations(
    @Query('q') String? q,
    @Query('page') int? page,
    @Query('per_page') int? perPage,
  );

  @GET('/me/memberships')
  Future<dynamic> listMemberships();

  @POST('/me/memberships/invites/token/{token}/accept')
  Future<dynamic> acceptInviteByToken(@Path() String token);

  @POST('/me/memberships/invites/{id}/accept')
  Future<dynamic> acceptInvite(@Path() int id);

  @POST('/me/memberships/invites/{id}/reject')
  Future<void> rejectInvite(@Path() int id);

  @POST('/me/memberships/requests')
  Future<dynamic> requestJoin(@Body() Map<String, dynamic> body);

  @DELETE('/me/memberships/requests/{id}')
  Future<void> cancelRequest(@Path() int id);

  @POST('/me/memberships/leave')
  Future<void> leaveOrganization();
}

@riverpod
OrganizationApi organizationApi(Ref ref) =>
    OrganizationApi(ref.watch(dioProvider));
