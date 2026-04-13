// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'race.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Race {

 int get id; String get name; String get distance;@JsonKey(name: 'custom_distance_meters') int? get customDistanceMeters;@JsonKey(name: 'goal_time_seconds') int? get goalTimeSeconds;@JsonKey(name: 'race_date') String get raceDate; String get status;
/// Create a copy of Race
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RaceCopyWith<Race> get copyWith => _$RaceCopyWithImpl<Race>(this as Race, _$identity);

  /// Serializes this Race to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Race&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.customDistanceMeters, customDistanceMeters) || other.customDistanceMeters == customDistanceMeters)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.raceDate, raceDate) || other.raceDate == raceDate)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,distance,customDistanceMeters,goalTimeSeconds,raceDate,status);

@override
String toString() {
  return 'Race(id: $id, name: $name, distance: $distance, customDistanceMeters: $customDistanceMeters, goalTimeSeconds: $goalTimeSeconds, raceDate: $raceDate, status: $status)';
}


}

/// @nodoc
abstract mixin class $RaceCopyWith<$Res>  {
  factory $RaceCopyWith(Race value, $Res Function(Race) _then) = _$RaceCopyWithImpl;
@useResult
$Res call({
 int id, String name, String distance,@JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'race_date') String raceDate, String status
});




}
/// @nodoc
class _$RaceCopyWithImpl<$Res>
    implements $RaceCopyWith<$Res> {
  _$RaceCopyWithImpl(this._self, this._then);

  final Race _self;
  final $Res Function(Race) _then;

/// Create a copy of Race
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? distance = null,Object? customDistanceMeters = freezed,Object? goalTimeSeconds = freezed,Object? raceDate = null,Object? status = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,customDistanceMeters: freezed == customDistanceMeters ? _self.customDistanceMeters : customDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,raceDate: null == raceDate ? _self.raceDate : raceDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [Race].
extension RacePatterns on Race {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Race value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Race() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Race value)  $default,){
final _that = this;
switch (_that) {
case _Race():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Race value)?  $default,){
final _that = this;
switch (_that) {
case _Race() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name,  String distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'race_date')  String raceDate,  String status)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Race() when $default != null:
return $default(_that.id,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.raceDate,_that.status);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name,  String distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'race_date')  String raceDate,  String status)  $default,) {final _that = this;
switch (_that) {
case _Race():
return $default(_that.id,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.raceDate,_that.status);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name,  String distance, @JsonKey(name: 'custom_distance_meters')  int? customDistanceMeters, @JsonKey(name: 'goal_time_seconds')  int? goalTimeSeconds, @JsonKey(name: 'race_date')  String raceDate,  String status)?  $default,) {final _that = this;
switch (_that) {
case _Race() when $default != null:
return $default(_that.id,_that.name,_that.distance,_that.customDistanceMeters,_that.goalTimeSeconds,_that.raceDate,_that.status);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Race implements Race {
  const _Race({required this.id, required this.name, required this.distance, @JsonKey(name: 'custom_distance_meters') this.customDistanceMeters, @JsonKey(name: 'goal_time_seconds') this.goalTimeSeconds, @JsonKey(name: 'race_date') required this.raceDate, required this.status});
  factory _Race.fromJson(Map<String, dynamic> json) => _$RaceFromJson(json);

@override final  int id;
@override final  String name;
@override final  String distance;
@override@JsonKey(name: 'custom_distance_meters') final  int? customDistanceMeters;
@override@JsonKey(name: 'goal_time_seconds') final  int? goalTimeSeconds;
@override@JsonKey(name: 'race_date') final  String raceDate;
@override final  String status;

/// Create a copy of Race
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RaceCopyWith<_Race> get copyWith => __$RaceCopyWithImpl<_Race>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RaceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Race&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.distance, distance) || other.distance == distance)&&(identical(other.customDistanceMeters, customDistanceMeters) || other.customDistanceMeters == customDistanceMeters)&&(identical(other.goalTimeSeconds, goalTimeSeconds) || other.goalTimeSeconds == goalTimeSeconds)&&(identical(other.raceDate, raceDate) || other.raceDate == raceDate)&&(identical(other.status, status) || other.status == status));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,distance,customDistanceMeters,goalTimeSeconds,raceDate,status);

@override
String toString() {
  return 'Race(id: $id, name: $name, distance: $distance, customDistanceMeters: $customDistanceMeters, goalTimeSeconds: $goalTimeSeconds, raceDate: $raceDate, status: $status)';
}


}

/// @nodoc
abstract mixin class _$RaceCopyWith<$Res> implements $RaceCopyWith<$Res> {
  factory _$RaceCopyWith(_Race value, $Res Function(_Race) _then) = __$RaceCopyWithImpl;
@override @useResult
$Res call({
 int id, String name, String distance,@JsonKey(name: 'custom_distance_meters') int? customDistanceMeters,@JsonKey(name: 'goal_time_seconds') int? goalTimeSeconds,@JsonKey(name: 'race_date') String raceDate, String status
});




}
/// @nodoc
class __$RaceCopyWithImpl<$Res>
    implements _$RaceCopyWith<$Res> {
  __$RaceCopyWithImpl(this._self, this._then);

  final _Race _self;
  final $Res Function(_Race) _then;

/// Create a copy of Race
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? distance = null,Object? customDistanceMeters = freezed,Object? goalTimeSeconds = freezed,Object? raceDate = null,Object? status = null,}) {
  return _then(_Race(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distance: null == distance ? _self.distance : distance // ignore: cast_nullable_to_non_nullable
as String,customDistanceMeters: freezed == customDistanceMeters ? _self.customDistanceMeters : customDistanceMeters // ignore: cast_nullable_to_non_nullable
as int?,goalTimeSeconds: freezed == goalTimeSeconds ? _self.goalTimeSeconds : goalTimeSeconds // ignore: cast_nullable_to_non_nullable
as int?,raceDate: null == raceDate ? _self.raceDate : raceDate // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
