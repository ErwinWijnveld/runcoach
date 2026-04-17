// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_interval.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingInterval {

/// `warmup | work | recovery | cooldown` — drives how the row is styled
/// in the session table.
 String get kind;/// Short human label the runner sees ("Warm up", "800m @ 10k pace",
/// "Recovery jog", "Cool down").
 String get label;@JsonKey(name: 'distance_m', fromJson: toIntOrNull) int? get distanceM;@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? get durationSeconds;@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? get targetPaceSecondsPerKm;
/// Create a copy of TrainingInterval
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingIntervalCopyWith<TrainingInterval> get copyWith => _$TrainingIntervalCopyWithImpl<TrainingInterval>(this as TrainingInterval, _$identity);

  /// Serializes this TrainingInterval to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingInterval&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.targetPaceSecondsPerKm, targetPaceSecondsPerKm) || other.targetPaceSecondsPerKm == targetPaceSecondsPerKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,label,distanceM,durationSeconds,targetPaceSecondsPerKm);

@override
String toString() {
  return 'TrainingInterval(kind: $kind, label: $label, distanceM: $distanceM, durationSeconds: $durationSeconds, targetPaceSecondsPerKm: $targetPaceSecondsPerKm)';
}


}

/// @nodoc
abstract mixin class $TrainingIntervalCopyWith<$Res>  {
  factory $TrainingIntervalCopyWith(TrainingInterval value, $Res Function(TrainingInterval) _then) = _$TrainingIntervalCopyWithImpl;
@useResult
$Res call({
 String kind, String label,@JsonKey(name: 'distance_m', fromJson: toIntOrNull) int? distanceM,@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? durationSeconds,@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? targetPaceSecondsPerKm
});




}
/// @nodoc
class _$TrainingIntervalCopyWithImpl<$Res>
    implements $TrainingIntervalCopyWith<$Res> {
  _$TrainingIntervalCopyWithImpl(this._self, this._then);

  final TrainingInterval _self;
  final $Res Function(TrainingInterval) _then;

/// Create a copy of TrainingInterval
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? label = null,Object? distanceM = freezed,Object? durationSeconds = freezed,Object? targetPaceSecondsPerKm = freezed,}) {
  return _then(_self.copyWith(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,targetPaceSecondsPerKm: freezed == targetPaceSecondsPerKm ? _self.targetPaceSecondsPerKm : targetPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [TrainingInterval].
extension TrainingIntervalPatterns on TrainingInterval {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingInterval value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingInterval() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingInterval value)  $default,){
final _that = this;
switch (_that) {
case _TrainingInterval():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingInterval value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingInterval() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String kind,  String label, @JsonKey(name: 'distance_m', fromJson: toIntOrNull)  int? distanceM, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingInterval() when $default != null:
return $default(_that.kind,_that.label,_that.distanceM,_that.durationSeconds,_that.targetPaceSecondsPerKm);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String kind,  String label, @JsonKey(name: 'distance_m', fromJson: toIntOrNull)  int? distanceM, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm)  $default,) {final _that = this;
switch (_that) {
case _TrainingInterval():
return $default(_that.kind,_that.label,_that.distanceM,_that.durationSeconds,_that.targetPaceSecondsPerKm);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String kind,  String label, @JsonKey(name: 'distance_m', fromJson: toIntOrNull)  int? distanceM, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm)?  $default,) {final _that = this;
switch (_that) {
case _TrainingInterval() when $default != null:
return $default(_that.kind,_that.label,_that.distanceM,_that.durationSeconds,_that.targetPaceSecondsPerKm);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingInterval implements TrainingInterval {
  const _TrainingInterval({required this.kind, required this.label, @JsonKey(name: 'distance_m', fromJson: toIntOrNull) this.distanceM, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) this.durationSeconds, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) this.targetPaceSecondsPerKm});
  factory _TrainingInterval.fromJson(Map<String, dynamic> json) => _$TrainingIntervalFromJson(json);

/// `warmup | work | recovery | cooldown` — drives how the row is styled
/// in the session table.
@override final  String kind;
/// Short human label the runner sees ("Warm up", "800m @ 10k pace",
/// "Recovery jog", "Cool down").
@override final  String label;
@override@JsonKey(name: 'distance_m', fromJson: toIntOrNull) final  int? distanceM;
@override@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) final  int? durationSeconds;
@override@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) final  int? targetPaceSecondsPerKm;

/// Create a copy of TrainingInterval
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingIntervalCopyWith<_TrainingInterval> get copyWith => __$TrainingIntervalCopyWithImpl<_TrainingInterval>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingIntervalToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingInterval&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.label, label) || other.label == label)&&(identical(other.distanceM, distanceM) || other.distanceM == distanceM)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.targetPaceSecondsPerKm, targetPaceSecondsPerKm) || other.targetPaceSecondsPerKm == targetPaceSecondsPerKm));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,kind,label,distanceM,durationSeconds,targetPaceSecondsPerKm);

@override
String toString() {
  return 'TrainingInterval(kind: $kind, label: $label, distanceM: $distanceM, durationSeconds: $durationSeconds, targetPaceSecondsPerKm: $targetPaceSecondsPerKm)';
}


}

/// @nodoc
abstract mixin class _$TrainingIntervalCopyWith<$Res> implements $TrainingIntervalCopyWith<$Res> {
  factory _$TrainingIntervalCopyWith(_TrainingInterval value, $Res Function(_TrainingInterval) _then) = __$TrainingIntervalCopyWithImpl;
@override @useResult
$Res call({
 String kind, String label,@JsonKey(name: 'distance_m', fromJson: toIntOrNull) int? distanceM,@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? durationSeconds,@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? targetPaceSecondsPerKm
});




}
/// @nodoc
class __$TrainingIntervalCopyWithImpl<$Res>
    implements _$TrainingIntervalCopyWith<$Res> {
  __$TrainingIntervalCopyWithImpl(this._self, this._then);

  final _TrainingInterval _self;
  final $Res Function(_TrainingInterval) _then;

/// Create a copy of TrainingInterval
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? label = null,Object? distanceM = freezed,Object? durationSeconds = freezed,Object? targetPaceSecondsPerKm = freezed,}) {
  return _then(_TrainingInterval(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,distanceM: freezed == distanceM ? _self.distanceM : distanceM // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,targetPaceSecondsPerKm: freezed == targetPaceSecondsPerKm ? _self.targetPaceSecondsPerKm : targetPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
