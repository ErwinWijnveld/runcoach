// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'goal.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Goal {

 int get id; String get type; String get name; String? get distance;@JsonKey(name: 'custom_distance_meters') int? get customDistanceMeters;@JsonKey(name: 'goal_time_seconds') int? get goalTimeSeconds;@JsonKey(name: 'target_date') String? get targetDate; String get status;
/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$GoalCopyWith<Goal> get copyWith => _$GoalCopyWithImpl<Goal>(this as Goal, _$identity);

  /// Serializes this Goal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Goal&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.customDistanceMeters, customDistanceMeters) || other.customDistanceMeters == customDistanceMeters)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,distance,customDistanceMeters,goalTimeSeconds,targetDate,status);

@override
String toString() {
  return 'Goal(id: $id, type: $type, name: $name, distance: $distance, customDistanceMeters: $customDistanceMeters, goalTimeSeconds: $goalTimeSeconds, targetDate: $targetDate, status: $status)';
}


}

/// @nodoc
abstract mixin class $GoalCopyWith<$Res>  {
  factory $GoalCopyWith(Goal value, $Res Function(Goal) _then) = _$GoalCopyWithImpl;
@useResult
$Res call({
 int id, String type, String name, String? distance,@JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'target_date') String? targetDate, String status
});




}
/// @nodoc
class _$GoalCopyWithImpl<$Res>
    implements $GoalCopyWith<$Res> {
  _$GoalCopyWithImpl(this._self, this._then);

  final Goal _self;
  final $Res Function(Goal) _then;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? type = null,Object? name = null,Object? distance = freezed,Object? customDistanceMeters = freezed,Object? goalTimeSeconds = freezed,Object? targetDate = freezed,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String?,customDistanceMeters: freezed == customDistanceMeters ? _self.customDistanceMeters : customDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Goal].
extension GoalPatterns on Goal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Goal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Goal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Goal value)  $default,){
final _that = this;
switch (_that) {
case _Goal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Goal value)?  $default,){
final _that = this;
switch (_that) {
case _Goal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'target_date')  String? targetDate,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Goal() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.targetDate,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'target_date')  String? targetDate,  String status)  $default,) {final _that = this;
switch (_that) {
case _Goal():
return $default(_that.id,_that.type,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.targetDate,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String type,  String name,  String? distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'target_date')  String? targetDate,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Goal() when $default != null:
return $default(_that.id,_that.type,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.targetDate,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Goal implements Goal {
  const _Goal({required this.id, required this.type, required this.name, this.distance, @JsonKey(name: 'custom_distance_meters') this.customDistanceMeters, @JsonKey(name: 'goal_time_seconds') this.goalTimeSeconds, @JsonKey(name: 'target_date') this.targetDate, required this.status});
  factory _Goal.fromJson(Map<String, dynamic> json) => _$GoalFromJson(json);

@override final  int id;
@override final  String type;
@override final  String name;
@override final  String? distance;
@override@JsonKey(name: 'custom_distance_meters') final  int? customDistanceMeters;
@override@JsonKey(name: 'goal_time_seconds') final  int? goalTimeSeconds;
@override@JsonKey(name: 'target_date') final  String? targetDate;
@override final  String status;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$GoalCopyWith<_Goal> get copyWith => __$GoalCopyWithImpl<_Goal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$GoalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Goal&&(identical(other.id, id) || other.id == id)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.customDistanceMeters, customDistanceMeters) || other.customDistanceMeters == customDistanceMeters)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.targetDate, targetDate) || other.targetDate == targetDate)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,type,name,distance,customDistanceMeters,goalTimeSeconds,targetDate,status);

@override
String toString() {
  return 'Goal(id: $id, type: $type, name: $name, distance: $distance, customDistanceMeters: $customDistanceMeters, goalTimeSeconds: $goalTimeSeconds, targetDate: $targetDate, status: $status)';
}


}

/// @nodoc
abstract mixin class _$GoalCopyWith<$Res> implements $GoalCopyWith<$Res> {
  factory _$GoalCopyWith(_Goal value, $Res Function(_Goal) _then) = __$GoalCopyWithImpl;
@override @useResult
$Res call({
 int id, String type, String name, String? distance,@JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'target_date') String? targetDate, String status
});




}
/// @nodoc
class __$GoalCopyWithImpl<$Res>
    implements _$GoalCopyWith<$Res> {
  __$GoalCopyWithImpl(this._self, this._then);

  final _Goal _self;
  final $Res Function(_Goal) _then;

/// Create a copy of Goal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? type = null,Object? name = null,Object? distance = freezed,Object? customDistanceMeters = freezed,Object? goalTimeSeconds = freezed,Object? targetDate = freezed,Object? status = null,}) {
  return _then(_Goal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: freezed == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String?,customDistanceMeters: freezed == customDistanceMeters ? _self.customDistanceMeters : customDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,targetDate: freezed == targetDate ? _self.targetDate : targetDate // ignore: cast_nullable_to_non_nullable
as String?,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
