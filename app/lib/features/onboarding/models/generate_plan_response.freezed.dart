// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'generate_plan_response.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$GeneratePlanResponse {

@JsonKey(name: 'conversation_id') String get conversationId;@JsonKey(name: 'proposal_id') int get proposalId; int get weeks;
/// Create a copy of GeneratePlanResponse
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GeneratePlanResponseCopyWith<GeneratePlanResponse> get copyWith => _$GeneratePlanResponseCopyWithImpl<GeneratePlanResponse>(this as GeneratePlanResponse, _$identity);

  /// Serializes this GeneratePlanResponse to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is GeneratePlanResponse&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.weeks, weeks) || other.weeks == weeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,proposalId,weeks);

@override
String toString() {
  return 'GeneratePlanResponse(conversationId: $conversationId, proposalId: $proposalId, weeks: $weeks)';
}


}

/// @nodoc
abstract mixin class $GeneratePlanResponseCopyWith<$Res>  {
  factory $GeneratePlanResponseCopyWith(GeneratePlanResponse value, $Res Function(GeneratePlanResponse) _then) = _$GeneratePlanResponseCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'conversation_id') String conversationId,@JsonKey(name: 'proposal_id') int proposalId, int weeks
});




}
/// @nodoc
class _$GeneratePlanResponseCopyWithImpl<$Res>
    implements $GeneratePlanResponseCopyWith<$Res> {
  _$GeneratePlanResponseCopyWithImpl(this._self, this._then);

  final GeneratePlanResponse _self;
  final $Res Function(GeneratePlanResponse) _then;

/// Create a copy of GeneratePlanResponse
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? conversationId = null,Object? proposalId = null,Object? weeks = null,}) {
  return _then(_self.copyWith(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int,weeks: null == weeks ? _self.weeks : weeks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [GeneratePlanResponse].
extension GeneratePlanResponsePatterns on GeneratePlanResponse {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _GeneratePlanResponse value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _GeneratePlanResponse() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _GeneratePlanResponse value)  $default,){
final _that = this;
switch (_that) {
case _GeneratePlanResponse():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _GeneratePlanResponse value)?  $default,){
final _that = this;
switch (_that) {
case _GeneratePlanResponse() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'proposal_id')  int proposalId,  int weeks)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _GeneratePlanResponse() when $default != null:
return $default(_that.conversationId,_that.proposalId,_that.weeks);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'proposal_id')  int proposalId,  int weeks)  $default,) {final _that = this;
switch (_that) {
case _GeneratePlanResponse():
return $default(_that.conversationId,_that.proposalId,_that.weeks);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'conversation_id')  String conversationId, @JsonKey(name: 'proposal_id')  int proposalId,  int weeks)?  $default,) {final _that = this;
switch (_that) {
case _GeneratePlanResponse() when $default != null:
return $default(_that.conversationId,_that.proposalId,_that.weeks);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _GeneratePlanResponse implements GeneratePlanResponse {
  const _GeneratePlanResponse({@JsonKey(name: 'conversation_id') required this.conversationId, @JsonKey(name: 'proposal_id') required this.proposalId, required this.weeks});
  factory _GeneratePlanResponse.fromJson(Map<String, dynamic> json) => _$GeneratePlanResponseFromJson(json);

@override@JsonKey(name: 'conversation_id') final  String conversationId;
@override@JsonKey(name: 'proposal_id') final  int proposalId;
@override final  int weeks;

/// Create a copy of GeneratePlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GeneratePlanResponseCopyWith<_GeneratePlanResponse> get copyWith => __$GeneratePlanResponseCopyWithImpl<_GeneratePlanResponse>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GeneratePlanResponseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _GeneratePlanResponse&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.weeks, weeks) || other.weeks == weeks));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,conversationId,proposalId,weeks);

@override
String toString() {
  return 'GeneratePlanResponse(conversationId: $conversationId, proposalId: $proposalId, weeks: $weeks)';
}


}

/// @nodoc
abstract mixin class _$GeneratePlanResponseCopyWith<$Res> implements $GeneratePlanResponseCopyWith<$Res> {
  factory _$GeneratePlanResponseCopyWith(_GeneratePlanResponse value, $Res Function(_GeneratePlanResponse) _then) = __$GeneratePlanResponseCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'conversation_id') String conversationId,@JsonKey(name: 'proposal_id') int proposalId, int weeks
});




}
/// @nodoc
class __$GeneratePlanResponseCopyWithImpl<$Res>
    implements _$GeneratePlanResponseCopyWith<$Res> {
  __$GeneratePlanResponseCopyWithImpl(this._self, this._then);

  final _GeneratePlanResponse _self;
  final $Res Function(_GeneratePlanResponse) _then;

/// Create a copy of GeneratePlanResponse
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? conversationId = null,Object? proposalId = null,Object? weeks = null,}) {
  return _then(_GeneratePlanResponse(
conversationId: null == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String,proposalId: null == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int,weeks: null == weeks ? _self.weeks : weeks // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
