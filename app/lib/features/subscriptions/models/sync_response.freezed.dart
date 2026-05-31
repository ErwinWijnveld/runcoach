// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncResponse {

@JsonKey(name: 'active_until') DateTime? get activeUntil;@JsonKey(name: 'product_id') String? get productId;@JsonKey(name: 'is_pro') bool get isPro;
/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SyncResponseCopyWith<SyncResponse> get copyWith => _$SyncResponseCopyWithImpl<SyncResponse>(this as SyncResponse, _$identity);

  /// Serializes this SyncResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SyncResponse&&(identical(other.activeUntil, activeUntil) || other.activeUntil == activeUntil)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeUntil,productId,isPro);

@override
String toString() {
  return 'SyncResponse(activeUntil: $activeUntil, productId: $productId, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class $SyncResponseCopyWith<$Res>  {
  factory $SyncResponseCopyWith(SyncResponse value, $Res Function(SyncResponse) _then) = _$SyncResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'active_until') DateTime? activeUntil,@JsonKey(name: 'product_id') String? productId,@JsonKey(name: 'is_pro') bool isPro
});




}
/// @nodoc
class _$SyncResponseCopyWithImpl<$Res>
    implements $SyncResponseCopyWith<$Res> {
  _$SyncResponseCopyWithImpl(this._self, this._then);

  final SyncResponse _self;
  final $Res Function(SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? activeUntil = freezed,Object? productId = freezed,Object? isPro = null,}) {
  return _then(_self.copyWith(
activeUntil: freezed == activeUntil ? _self.activeUntil : activeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [SyncResponse].
extension SyncResponsePatterns on SyncResponse {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SyncResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SyncResponse value)  $default,){
final _that = this;
switch (_that) {
case _SyncResponse():
return $default(_that);}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SyncResponse value)?  $default,){
final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'active_until')  DateTime? activeUntil, @JsonKey(name: 'product_id')  String? productId, @JsonKey(name: 'is_pro')  bool isPro)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.activeUntil,_that.productId,_that.isPro);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'active_until')  DateTime? activeUntil, @JsonKey(name: 'product_id')  String? productId, @JsonKey(name: 'is_pro')  bool isPro)  $default,) {final _that = this;
switch (_that) {
case _SyncResponse():
return $default(_that.activeUntil,_that.productId,_that.isPro);}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'active_until')  DateTime? activeUntil, @JsonKey(name: 'product_id')  String? productId, @JsonKey(name: 'is_pro')  bool isPro)?  $default,) {final _that = this;
switch (_that) {
case _SyncResponse() when $default != null:
return $default(_that.activeUntil,_that.productId,_that.isPro);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SyncResponse implements SyncResponse {
  const _SyncResponse({@JsonKey(name: 'active_until') this.activeUntil, @JsonKey(name: 'product_id') this.productId, @JsonKey(name: 'is_pro') required this.isPro});
  factory _SyncResponse.fromJson(Map<String, dynamic> json) => _$SyncResponseFromJson(json);

@override@JsonKey(name: 'active_until') final  DateTime? activeUntil;
@override@JsonKey(name: 'product_id') final  String? productId;
@override@JsonKey(name: 'is_pro') final  bool isPro;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SyncResponseCopyWith<_SyncResponse> get copyWith => __$SyncResponseCopyWithImpl<_SyncResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SyncResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SyncResponse&&(identical(other.activeUntil, activeUntil) || other.activeUntil == activeUntil)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.isPro, isPro) || other.isPro == isPro));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,activeUntil,productId,isPro);

@override
String toString() {
  return 'SyncResponse(activeUntil: $activeUntil, productId: $productId, isPro: $isPro)';
}


}

/// @nodoc
abstract mixin class _$SyncResponseCopyWith<$Res> implements $SyncResponseCopyWith<$Res> {
  factory _$SyncResponseCopyWith(_SyncResponse value, $Res Function(_SyncResponse) _then) = __$SyncResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'active_until') DateTime? activeUntil,@JsonKey(name: 'product_id') String? productId,@JsonKey(name: 'is_pro') bool isPro
});




}
/// @nodoc
class __$SyncResponseCopyWithImpl<$Res>
    implements _$SyncResponseCopyWith<$Res> {
  __$SyncResponseCopyWithImpl(this._self, this._then);

  final _SyncResponse _self;
  final $Res Function(_SyncResponse) _then;

/// Create a copy of SyncResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? activeUntil = freezed,Object? productId = freezed,Object? isPro = null,}) {
  return _then(_SyncResponse(
activeUntil: freezed == activeUntil ? _self.activeUntil : activeUntil // ignore: cast_nullable_to_non_nullable
as DateTime?,productId: freezed == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String?,isPro: null == isPro ? _self.isPro : isPro // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
