// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interval_blueprint.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$IntervalBlueprint {

@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) int? get warmupSeconds; List<IntervalStep> get steps;@JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) int? get cooldownSeconds;
/// Create a copy of IntervalBlueprint
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntervalBlueprintCopyWith<IntervalBlueprint> get copyWith => _$IntervalBlueprintCopyWithImpl<IntervalBlueprint>(this as IntervalBlueprint, _$identity);

  /// Serializes this IntervalBlueprint to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntervalBlueprint&&(identical(other.warmupSeconds, warmupSeconds) || other.warmupSeconds == warmupSeconds)&&const DeepCollectionEquality().equals(other.steps, steps)&&(identical(other.cooldownSeconds, cooldownSeconds) || other.cooldownSeconds == cooldownSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warmupSeconds,const DeepCollectionEquality().hash(steps),cooldownSeconds);

@override
String toString() {
  return 'IntervalBlueprint(warmupSeconds: $warmupSeconds, steps: $steps, cooldownSeconds: $cooldownSeconds)';
}


}

/// @nodoc
abstract mixin class $IntervalBlueprintCopyWith<$Res>  {
  factory $IntervalBlueprintCopyWith(IntervalBlueprint value, $Res Function(IntervalBlueprint) _then) = _$IntervalBlueprintCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) int? warmupSeconds, List<IntervalStep> steps,@JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) int? cooldownSeconds
});




}
/// @nodoc
class _$IntervalBlueprintCopyWithImpl<$Res>
    implements $IntervalBlueprintCopyWith<$Res> {
  _$IntervalBlueprintCopyWithImpl(this._self, this._then);

  final IntervalBlueprint _self;
  final $Res Function(IntervalBlueprint) _then;

/// Create a copy of IntervalBlueprint
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? warmupSeconds = freezed,Object? steps = null,Object? cooldownSeconds = freezed,}) {
  return _then(_self.copyWith(
warmupSeconds: freezed == warmupSeconds ? _self.warmupSeconds : warmupSeconds // ignore: cast_nullable_to_non_nullable
as int?,steps: null == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as List<IntervalStep>,cooldownSeconds: freezed == cooldownSeconds ? _self.cooldownSeconds : cooldownSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [IntervalBlueprint].
extension IntervalBlueprintPatterns on IntervalBlueprint {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntervalBlueprint value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntervalBlueprint() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntervalBlueprint value)  $default,){
final _that = this;
switch (_that) {
case _IntervalBlueprint():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntervalBlueprint value)?  $default,){
final _that = this;
switch (_that) {
case _IntervalBlueprint() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull)  int? warmupSeconds,  List<IntervalStep> steps, @JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull)  int? cooldownSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntervalBlueprint() when $default != null:
return $default(_that.warmupSeconds,_that.steps,_that.cooldownSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull)  int? warmupSeconds,  List<IntervalStep> steps, @JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull)  int? cooldownSeconds)  $default,) {final _that = this;
switch (_that) {
case _IntervalBlueprint():
return $default(_that.warmupSeconds,_that.steps,_that.cooldownSeconds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull)  int? warmupSeconds,  List<IntervalStep> steps, @JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull)  int? cooldownSeconds)?  $default,) {final _that = this;
switch (_that) {
case _IntervalBlueprint() when $default != null:
return $default(_that.warmupSeconds,_that.steps,_that.cooldownSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntervalBlueprint extends IntervalBlueprint {
  const _IntervalBlueprint({@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) this.warmupSeconds, final  List<IntervalStep> steps = const <IntervalStep>[], @JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) this.cooldownSeconds}): _steps = steps,super._();
  factory _IntervalBlueprint.fromJson(Map<String, dynamic> json) => _$IntervalBlueprintFromJson(json);

@override@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) final  int? warmupSeconds;
 final  List<IntervalStep> _steps;
@override@JsonKey() List<IntervalStep> get steps {
  if (_steps is EqualUnmodifiableListView) return _steps;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_steps);
}

@override@JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) final  int? cooldownSeconds;

/// Create a copy of IntervalBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntervalBlueprintCopyWith<_IntervalBlueprint> get copyWith => __$IntervalBlueprintCopyWithImpl<_IntervalBlueprint>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntervalBlueprintToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntervalBlueprint&&(identical(other.warmupSeconds, warmupSeconds) || other.warmupSeconds == warmupSeconds)&&const DeepCollectionEquality().equals(other._steps, _steps)&&(identical(other.cooldownSeconds, cooldownSeconds) || other.cooldownSeconds == cooldownSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,warmupSeconds,const DeepCollectionEquality().hash(_steps),cooldownSeconds);

@override
String toString() {
  return 'IntervalBlueprint(warmupSeconds: $warmupSeconds, steps: $steps, cooldownSeconds: $cooldownSeconds)';
}


}

/// @nodoc
abstract mixin class _$IntervalBlueprintCopyWith<$Res> implements $IntervalBlueprintCopyWith<$Res> {
  factory _$IntervalBlueprintCopyWith(_IntervalBlueprint value, $Res Function(_IntervalBlueprint) _then) = __$IntervalBlueprintCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'warmup_seconds', fromJson: toIntOrNull) int? warmupSeconds, List<IntervalStep> steps,@JsonKey(name: 'cooldown_seconds', fromJson: toIntOrNull) int? cooldownSeconds
});




}
/// @nodoc
class __$IntervalBlueprintCopyWithImpl<$Res>
    implements _$IntervalBlueprintCopyWith<$Res> {
  __$IntervalBlueprintCopyWithImpl(this._self, this._then);

  final _IntervalBlueprint _self;
  final $Res Function(_IntervalBlueprint) _then;

/// Create a copy of IntervalBlueprint
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? warmupSeconds = freezed,Object? steps = null,Object? cooldownSeconds = freezed,}) {
  return _then(_IntervalBlueprint(
warmupSeconds: freezed == warmupSeconds ? _self.warmupSeconds : warmupSeconds // ignore: cast_nullable_to_non_nullable
as int?,steps: null == steps ? _self._steps : steps // ignore: cast_nullable_to_non_nullable
as List<IntervalStep>,cooldownSeconds: freezed == cooldownSeconds ? _self.cooldownSeconds : cooldownSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$IntervalStep {

 String get type;@JsonKey(fromJson: toIntOrNull) int? get reps;@JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) int? get workDistanceM;@JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) int? get workDurationSeconds;@JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) int? get workPaceSecondsPerKm;@JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) int? get recoverySeconds;@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? get durationSeconds;
/// Create a copy of IntervalStep
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$IntervalStepCopyWith<IntervalStep> get copyWith => _$IntervalStepCopyWithImpl<IntervalStep>(this as IntervalStep, _$identity);

  /// Serializes this IntervalStep to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is IntervalStep&&(identical(other.type, type) || other.type == type)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.workDistanceM, workDistanceM) || other.workDistanceM == workDistanceM)&&(identical(other.workDurationSeconds, workDurationSeconds) || other.workDurationSeconds == workDurationSeconds)&&(identical(other.workPaceSecondsPerKm, workPaceSecondsPerKm) || other.workPaceSecondsPerKm == workPaceSecondsPerKm)&&(identical(other.recoverySeconds, recoverySeconds) || other.recoverySeconds == recoverySeconds)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,reps,workDistanceM,workDurationSeconds,workPaceSecondsPerKm,recoverySeconds,durationSeconds);

@override
String toString() {
  return 'IntervalStep(type: $type, reps: $reps, workDistanceM: $workDistanceM, workDurationSeconds: $workDurationSeconds, workPaceSecondsPerKm: $workPaceSecondsPerKm, recoverySeconds: $recoverySeconds, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class $IntervalStepCopyWith<$Res>  {
  factory $IntervalStepCopyWith(IntervalStep value, $Res Function(IntervalStep) _then) = _$IntervalStepCopyWithImpl;
@useResult
$Res call({
 String type,@JsonKey(fromJson: toIntOrNull) int? reps,@JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) int? workDistanceM,@JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) int? workDurationSeconds,@JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) int? workPaceSecondsPerKm,@JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) int? recoverySeconds,@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? durationSeconds
});




}
/// @nodoc
class _$IntervalStepCopyWithImpl<$Res>
    implements $IntervalStepCopyWith<$Res> {
  _$IntervalStepCopyWithImpl(this._self, this._then);

  final IntervalStep _self;
  final $Res Function(IntervalStep) _then;

/// Create a copy of IntervalStep
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? type = null,Object? reps = freezed,Object? workDistanceM = freezed,Object? workDurationSeconds = freezed,Object? workPaceSecondsPerKm = freezed,Object? recoverySeconds = freezed,Object? durationSeconds = freezed,}) {
  return _then(_self.copyWith(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,workDistanceM: freezed == workDistanceM ? _self.workDistanceM : workDistanceM // ignore: cast_nullable_to_non_nullable
as int?,workDurationSeconds: freezed == workDurationSeconds ? _self.workDurationSeconds : workDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,workPaceSecondsPerKm: freezed == workPaceSecondsPerKm ? _self.workPaceSecondsPerKm : workPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,recoverySeconds: freezed == recoverySeconds ? _self.recoverySeconds : recoverySeconds // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [IntervalStep].
extension IntervalStepPatterns on IntervalStep {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _IntervalStep value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _IntervalStep() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _IntervalStep value)  $default,){
final _that = this;
switch (_that) {
case _IntervalStep():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _IntervalStep value)?  $default,){
final _that = this;
switch (_that) {
case _IntervalStep() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String type, @JsonKey(fromJson: toIntOrNull)  int? reps, @JsonKey(name: 'work_distance_m', fromJson: toIntOrNull)  int? workDistanceM, @JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull)  int? workDurationSeconds, @JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull)  int? workPaceSecondsPerKm, @JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull)  int? recoverySeconds, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _IntervalStep() when $default != null:
return $default(_that.type,_that.reps,_that.workDistanceM,_that.workDurationSeconds,_that.workPaceSecondsPerKm,_that.recoverySeconds,_that.durationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String type, @JsonKey(fromJson: toIntOrNull)  int? reps, @JsonKey(name: 'work_distance_m', fromJson: toIntOrNull)  int? workDistanceM, @JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull)  int? workDurationSeconds, @JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull)  int? workPaceSecondsPerKm, @JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull)  int? recoverySeconds, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds)  $default,) {final _that = this;
switch (_that) {
case _IntervalStep():
return $default(_that.type,_that.reps,_that.workDistanceM,_that.workDurationSeconds,_that.workPaceSecondsPerKm,_that.recoverySeconds,_that.durationSeconds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String type, @JsonKey(fromJson: toIntOrNull)  int? reps, @JsonKey(name: 'work_distance_m', fromJson: toIntOrNull)  int? workDistanceM, @JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull)  int? workDurationSeconds, @JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull)  int? workPaceSecondsPerKm, @JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull)  int? recoverySeconds, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull)  int? durationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _IntervalStep() when $default != null:
return $default(_that.type,_that.reps,_that.workDistanceM,_that.workDurationSeconds,_that.workPaceSecondsPerKm,_that.recoverySeconds,_that.durationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _IntervalStep implements IntervalStep {
  const _IntervalStep({required this.type, @JsonKey(fromJson: toIntOrNull) this.reps, @JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) this.workDistanceM, @JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) this.workDurationSeconds, @JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) this.workPaceSecondsPerKm, @JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) this.recoverySeconds, @JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) this.durationSeconds});
  factory _IntervalStep.fromJson(Map<String, dynamic> json) => _$IntervalStepFromJson(json);

@override final  String type;
@override@JsonKey(fromJson: toIntOrNull) final  int? reps;
@override@JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) final  int? workDistanceM;
@override@JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) final  int? workDurationSeconds;
@override@JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) final  int? workPaceSecondsPerKm;
@override@JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) final  int? recoverySeconds;
@override@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) final  int? durationSeconds;

/// Create a copy of IntervalStep
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$IntervalStepCopyWith<_IntervalStep> get copyWith => __$IntervalStepCopyWithImpl<_IntervalStep>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$IntervalStepToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _IntervalStep&&(identical(other.type, type) || other.type == type)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.workDistanceM, workDistanceM) || other.workDistanceM == workDistanceM)&&(identical(other.workDurationSeconds, workDurationSeconds) || other.workDurationSeconds == workDurationSeconds)&&(identical(other.workPaceSecondsPerKm, workPaceSecondsPerKm) || other.workPaceSecondsPerKm == workPaceSecondsPerKm)&&(identical(other.recoverySeconds, recoverySeconds) || other.recoverySeconds == recoverySeconds)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,type,reps,workDistanceM,workDurationSeconds,workPaceSecondsPerKm,recoverySeconds,durationSeconds);

@override
String toString() {
  return 'IntervalStep(type: $type, reps: $reps, workDistanceM: $workDistanceM, workDurationSeconds: $workDurationSeconds, workPaceSecondsPerKm: $workPaceSecondsPerKm, recoverySeconds: $recoverySeconds, durationSeconds: $durationSeconds)';
}


}

/// @nodoc
abstract mixin class _$IntervalStepCopyWith<$Res> implements $IntervalStepCopyWith<$Res> {
  factory _$IntervalStepCopyWith(_IntervalStep value, $Res Function(_IntervalStep) _then) = __$IntervalStepCopyWithImpl;
@override @useResult
$Res call({
 String type,@JsonKey(fromJson: toIntOrNull) int? reps,@JsonKey(name: 'work_distance_m', fromJson: toIntOrNull) int? workDistanceM,@JsonKey(name: 'work_duration_seconds', fromJson: toIntOrNull) int? workDurationSeconds,@JsonKey(name: 'work_pace_seconds_per_km', fromJson: toIntOrNull) int? workPaceSecondsPerKm,@JsonKey(name: 'recovery_seconds', fromJson: toIntOrNull) int? recoverySeconds,@JsonKey(name: 'duration_seconds', fromJson: toIntOrNull) int? durationSeconds
});




}
/// @nodoc
class __$IntervalStepCopyWithImpl<$Res>
    implements _$IntervalStepCopyWith<$Res> {
  __$IntervalStepCopyWithImpl(this._self, this._then);

  final _IntervalStep _self;
  final $Res Function(_IntervalStep) _then;

/// Create a copy of IntervalStep
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? type = null,Object? reps = freezed,Object? workDistanceM = freezed,Object? workDurationSeconds = freezed,Object? workPaceSecondsPerKm = freezed,Object? recoverySeconds = freezed,Object? durationSeconds = freezed,}) {
  return _then(_IntervalStep(
type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,reps: freezed == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int?,workDistanceM: freezed == workDistanceM ? _self.workDistanceM : workDistanceM // ignore: cast_nullable_to_non_nullable
as int?,workDurationSeconds: freezed == workDurationSeconds ? _self.workDurationSeconds : workDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,workPaceSecondsPerKm: freezed == workPaceSecondsPerKm ? _self.workPaceSecondsPerKm : workPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,recoverySeconds: freezed == recoverySeconds ? _self.recoverySeconds : recoverySeconds // ignore: cast_nullable_to_non_nullable
as int?,durationSeconds: freezed == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
