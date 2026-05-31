// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncResponse _$SyncResponseFromJson(Map<String, dynamic> json) =>
    _SyncResponse(
      activeUntil: json['active_until'] == null
          ? null
          : DateTime.parse(json['active_until'] as String),
      productId: json['product_id'] as String?,
      isPro: json['is_pro'] as bool,
    );

Map<String, dynamic> _$SyncResponseToJson(_SyncResponse instance) =>
    <String, dynamic>{
      'active_until': instance.activeUntil?.toIso8601String(),
      'product_id': instance.productId,
      'is_pro': instance.isPro,
    };
