import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:app/core/api/dio_client.dart';
import 'package:app/features/subscriptions/models/sync_response.dart';

part 'subscriptions_api.g.dart';

/// Single-call API client for the entitlement sync endpoint.
///
/// Posts an empty body — the server doesn't trust client payloads and pulls
/// truth from RevenueCat's REST API directly (defense-in-depth against webhook
/// delays). The response carries the authoritative `is_pro` + `active_until`.
@RestApi()
abstract class SubscriptionsApi {
  factory SubscriptionsApi(Dio dio) = _SubscriptionsApi;

  /// Body carries the client's RevenueCat entitlement claim under
  /// `client_entitlement` — the server IGNORES it in production (RC REST is
  /// authoritative there) and only trusts it in local dev when REST can't
  /// verify (Test Store). Pass an empty map when there's no claim.
  @POST('/subscriptions/sync')
  Future<SyncResponse> sync(@Body() Map<String, dynamic> body);

  /// LOCAL-DEV ONLY (404 elsewhere). Simulate a successful purchase.
  @POST('/subscriptions/dev-activate')
  Future<SyncResponse> devActivate();

  /// LOCAL-DEV ONLY (404 elsewhere). Reset entitlement to free.
  @POST('/subscriptions/dev-deactivate')
  Future<SyncResponse> devDeactivate();
}

@riverpod
SubscriptionsApi subscriptionsApi(Ref ref) =>
    SubscriptionsApi(ref.watch(dioProvider));
