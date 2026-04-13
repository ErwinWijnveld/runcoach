// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_proposal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CoachProposal {

 int get id; String get type; Map<String, dynamic> get payload; String get status;@JsonKey(name: 'applied_at') String? get appliedAt;
/// Create a copy of CoachProposal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachProposalCopyWith<CoachProposal> get copyWith => _$CoachProposalCopyWithImpl<CoachProposal>(this as CoachProposal, _$identity);

  /// Serializes this CoachProposal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other.payload, payload)&&(identical(other.status, status) || other.status == status)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(payload),status,appliedAt);

@override
String toString() {
  return 'CoachProposal(id: $id, type: $type, payload: $payload, status: $status, appliedAt: $appliedAt)';
}


}

/// @nodoc
abstract mixin class $CoachProposalCopyWith<$Res>  {
  factory $CoachProposalCopyWith(CoachProposal value, $Res Function(CoachProposal) _then) = _$CoachProposalCopyWithImpl;
@useResult
$Res call({
 int id, String type, Map<String, dynamic> payload, String status,@JsonKey(name: 'applied_at') String? appliedAt
});




}
/// @nodoc
class _$CoachProposalCopyWithImpl<$Res>
    implements $CoachProposalCopyWith<$Res> {
  _$CoachProposalCopyWithImpl(this._self, this._then);

  final CoachProposal _self;
  final $Res Function(CoachProposal) _then;

/// Create a copy of CoachProposal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? status = null,Object? appliedAt = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self.payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachProposal].
extension CoachProposalPatterns on CoachProposal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachProposal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachProposal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachProposal value)  $default,){
final _that = this;
switch (_that) {
case _CoachProposal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachProposal value)?  $default,){
final _that = this;
switch (_that) {
case _CoachProposal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  Map<String, dynamic> payload,  String status, @JsonKey(name: 'applied_at')  String? appliedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachProposal() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.status,_that.appliedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  Map<String, dynamic> payload,  String status, @JsonKey(name: 'applied_at')  String? appliedAt)  $default,) {final _that = this;
switch (_that) {
case _CoachProposal():
return $default(_that.id,_that.type,_that.payload,_that.status,_that.appliedAt);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  Map<String, dynamic> payload,  String status, @JsonKey(name: 'applied_at')  String? appliedAt)?  $default,) {final _that = this;
switch (_that) {
case _CoachProposal() when $default != null:
return $default(_that.id,_that.type,_that.payload,_that.status,_that.appliedAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CoachProposal implements CoachProposal {
  const _CoachProposal({required this.id, required this.type, required final  Map<String, dynamic> payload, required this.status, @JsonKey(name: 'applied_at') this.appliedAt}): _payload = payload;
  factory _CoachProposal.fromJson(Map<String, dynamic> json) => _$CoachProposalFromJson(json);

@override final  int id;
@override final  String type;
 final  Map<String, dynamic> _payload;
@override Map<String, dynamic> get payload {
  if (_payload is EqualUnmodifiableMapView) return _payload;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_payload);
}

@override final  String status;
@override@JsonKey(name: 'applied_at') final  String? appliedAt;

/// Create a copy of CoachProposal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachProposalCopyWith<_CoachProposal> get copyWith => __$CoachProposalCopyWithImpl<_CoachProposal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CoachProposalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachProposal&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&const DeepCollectionEquality().equals(other._payload, _payload)&&(identical(other.status, status) || other.status == status)&&(identical(other.appliedAt, appliedAt) || other.appliedAt == appliedAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,const DeepCollectionEquality().hash(_payload),status,appliedAt);

@override
String toString() {
  return 'CoachProposal(id: $id, type: $type, payload: $payload, status: $status, appliedAt: $appliedAt)';
}


}

/// @nodoc
abstract mixin class _$CoachProposalCopyWith<$Res> implements $CoachProposalCopyWith<$Res> {
  factory _$CoachProposalCopyWith(_CoachProposal value, $Res Function(_CoachProposal) _then) = __$CoachProposalCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, Map<String, dynamic> payload, String status,@JsonKey(name: 'applied_at') String? appliedAt
});




}
/// @nodoc
class __$CoachProposalCopyWithImpl<$Res>
    implements _$CoachProposalCopyWith<$Res> {
  __$CoachProposalCopyWithImpl(this._self, this._then);

  final _CoachProposal _self;
  final $Res Function(_CoachProposal) _then;

/// Create a copy of CoachProposal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? payload = null,Object? status = null,Object? appliedAt = freezed,}) {
  return _then(_CoachProposal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,payload: null == payload ? _self._payload : payload // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,appliedAt: freezed == appliedAt ? _self.appliedAt : appliedAt // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
