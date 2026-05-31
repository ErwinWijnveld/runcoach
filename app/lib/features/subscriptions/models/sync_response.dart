import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_response.freezed.dart';
part 'sync_response.g.dart';

/// Wire shape of `POST /api/v1/subscriptions/sync`.
///
/// The server is the source of truth — the client posts an empty body, and
/// this is what comes back after the server has consulted RevenueCat's REST
/// API and (if necessary) updated the local `subscriptions` row +
/// `users.pro_active_until`.
@freezed
sealed class SyncResponse with _$SyncResponse {
  const factory SyncResponse({
    @JsonKey(name: 'active_until') DateTime? activeUntil,
    @JsonKey(name: 'product_id') String? productId,
    @JsonKey(name: 'is_pro') required bool isPro,
  }) = _SyncResponse;

  factory SyncResponse.fromJson(Map<String, dynamic> json) =>
      _$SyncResponseFromJson(json);
}
