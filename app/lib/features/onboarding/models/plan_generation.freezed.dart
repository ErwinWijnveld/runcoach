// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'plan_generation.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanGeneration {

 int get id; PlanGenerationStatus get status;@JsonKey(name: 'conversation_id') String? get conversationId;@JsonKey(name: 'proposal_id') int? get proposalId;@JsonKey(name: 'error_message') String? get errorMessage;
/// Create a copy of PlanGeneration
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanGenerationCopyWith<PlanGeneration> get copyWith => _$PlanGenerationCopyWithImpl<PlanGeneration>(this as PlanGeneration, _$identity);

  /// Serializes this PlanGeneration to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanGeneration&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,conversationId,proposalId,errorMessage);

@override
String toString() {
  return 'PlanGeneration(id: $id, status: $status, conversationId: $conversationId, proposalId: $proposalId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class $PlanGenerationCopyWith<$Res>  {
  factory $PlanGenerationCopyWith(PlanGeneration value, $Res Function(PlanGeneration) _then) = _$PlanGenerationCopyWithImpl;
@useResult
$Res call({
 int id, PlanGenerationStatus status,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'proposal_id') int? proposalId,@JsonKey(name: 'error_message') String? errorMessage
});




}
/// @nodoc
class _$PlanGenerationCopyWithImpl<$Res>
    implements $PlanGenerationCopyWith<$Res> {
  _$PlanGenerationCopyWithImpl(this._self, this._then);

  final PlanGeneration _self;
  final $Res Function(PlanGeneration) _then;

/// Create a copy of PlanGeneration
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? status = null,Object? conversationId = freezed,Object? proposalId = freezed,Object? errorMessage = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanGenerationStatus,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,proposalId: freezed == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanGeneration].
extension PlanGenerationPatterns on PlanGeneration {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanGeneration value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanGeneration() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanGeneration value)  $default,){
final _that = this;
switch (_that) {
case _PlanGeneration():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanGeneration value)?  $default,){
final _that = this;
switch (_that) {
case _PlanGeneration() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  PlanGenerationStatus status, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'error_message')  String? errorMessage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanGeneration() when $default != null:
return $default(_that.id,_that.status,_that.conversationId,_that.proposalId,_that.errorMessage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  PlanGenerationStatus status, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'error_message')  String? errorMessage)  $default,) {final _that = this;
switch (_that) {
case _PlanGeneration():
return $default(_that.id,_that.status,_that.conversationId,_that.proposalId,_that.errorMessage);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  PlanGenerationStatus status, @JsonKey(name: 'conversation_id')  String? conversationId, @JsonKey(name: 'proposal_id')  int? proposalId, @JsonKey(name: 'error_message')  String? errorMessage)?  $default,) {final _that = this;
switch (_that) {
case _PlanGeneration() when $default != null:
return $default(_that.id,_that.status,_that.conversationId,_that.proposalId,_that.errorMessage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanGeneration implements PlanGeneration {
  const _PlanGeneration({required this.id, required this.status, @JsonKey(name: 'conversation_id') this.conversationId, @JsonKey(name: 'proposal_id') this.proposalId, @JsonKey(name: 'error_message') this.errorMessage});
  factory _PlanGeneration.fromJson(Map<String, dynamic> json) => _$PlanGenerationFromJson(json);

@override final  int id;
@override final  PlanGenerationStatus status;
@override@JsonKey(name: 'conversation_id') final  String? conversationId;
@override@JsonKey(name: 'proposal_id') final  int? proposalId;
@override@JsonKey(name: 'error_message') final  String? errorMessage;

/// Create a copy of PlanGeneration
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanGenerationCopyWith<_PlanGeneration> get copyWith => __$PlanGenerationCopyWithImpl<_PlanGeneration>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanGenerationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanGeneration&&(identical(other.id, id) || other.id == id)&&(identical(other.status, status) || other.status == status)&&(identical(other.conversationId, conversationId) || other.conversationId == conversationId)&&(identical(other.proposalId, proposalId) || other.proposalId == proposalId)&&(identical(other.errorMessage, errorMessage) || other.errorMessage == errorMessage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,status,conversationId,proposalId,errorMessage);

@override
String toString() {
  return 'PlanGeneration(id: $id, status: $status, conversationId: $conversationId, proposalId: $proposalId, errorMessage: $errorMessage)';
}


}

/// @nodoc
abstract mixin class _$PlanGenerationCopyWith<$Res> implements $PlanGenerationCopyWith<$Res> {
  factory _$PlanGenerationCopyWith(_PlanGeneration value, $Res Function(_PlanGeneration) _then) = __$PlanGenerationCopyWithImpl;
@override @useResult
$Res call({
 int id, PlanGenerationStatus status,@JsonKey(name: 'conversation_id') String? conversationId,@JsonKey(name: 'proposal_id') int? proposalId,@JsonKey(name: 'error_message') String? errorMessage
});




}
/// @nodoc
class __$PlanGenerationCopyWithImpl<$Res>
    implements _$PlanGenerationCopyWith<$Res> {
  __$PlanGenerationCopyWithImpl(this._self, this._then);

  final _PlanGeneration _self;
  final $Res Function(_PlanGeneration) _then;

/// Create a copy of PlanGeneration
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? status = null,Object? conversationId = freezed,Object? proposalId = freezed,Object? errorMessage = freezed,}) {
  return _then(_PlanGeneration(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PlanGenerationStatus,conversationId: freezed == conversationId ? _self.conversationId : conversationId // ignore: cast_nullable_to_non_nullable
as String?,proposalId: freezed == proposalId ? _self.proposalId : proposalId // ignore: cast_nullable_to_non_nullable
as int?,errorMessage: freezed == errorMessage ? _self.errorMessage : errorMessage // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
