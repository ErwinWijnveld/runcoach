// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recent_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecentRun {

 WearableActivitySummary get run;@JsonKey(name: 'training_day_id', fromJson: toIntOrNull) int? get trainingDayId;@JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull) double? get complianceScore;
/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RecentRunCopyWith<RecentRun> get copyWith => _$RecentRunCopyWithImpl<RecentRun>(this as RecentRun, _$identity);

  /// Serializes this RecentRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RecentRun&&(identical(other.run, run) || other.run == run)&&(identical(other.trainingDayId, trainingDayId) || other.trainingDayId == trainingDayId)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,run,trainingDayId,complianceScore);

@override
String toString() {
  return 'RecentRun(run: $run, trainingDayId: $trainingDayId, complianceScore: $complianceScore)';
}


}

/// @nodoc
abstract mixin class $RecentRunCopyWith<$Res>  {
  factory $RecentRunCopyWith(RecentRun value, $Res Function(RecentRun) _then) = _$RecentRunCopyWithImpl;
@useResult
$Res call({
 WearableActivitySummary run,@JsonKey(name: 'training_day_id', fromJson: toIntOrNull) int? trainingDayId,@JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull) double? complianceScore
});


$WearableActivitySummaryCopyWith<$Res> get run;

}
/// @nodoc
class _$RecentRunCopyWithImpl<$Res>
    implements $RecentRunCopyWith<$Res> {
  _$RecentRunCopyWithImpl(this._self, this._then);

  final RecentRun _self;
  final $Res Function(RecentRun) _then;

/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? run = null,Object? trainingDayId = freezed,Object? complianceScore = freezed,}) {
  return _then(_self.copyWith(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as WearableActivitySummary,trainingDayId: freezed == trainingDayId ? _self.trainingDayId : trainingDayId // ignore: cast_nullable_to_non_nullable
as int?,complianceScore: freezed == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WearableActivitySummaryCopyWith<$Res> get run {
  
  return $WearableActivitySummaryCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}


/// Adds pattern-matching-related methods to [RecentRun].
extension RecentRunPatterns on RecentRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RecentRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RecentRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RecentRun value)  $default,){
final _that = this;
switch (_that) {
case _RecentRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RecentRun value)?  $default,){
final _that = this;
switch (_that) {
case _RecentRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WearableActivitySummary run, @JsonKey(name: 'training_day_id', fromJson: toIntOrNull)  int? trainingDayId, @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull)  double? complianceScore)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RecentRun() when $default != null:
return $default(_that.run,_that.trainingDayId,_that.complianceScore);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WearableActivitySummary run, @JsonKey(name: 'training_day_id', fromJson: toIntOrNull)  int? trainingDayId, @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull)  double? complianceScore)  $default,) {final _that = this;
switch (_that) {
case _RecentRun():
return $default(_that.run,_that.trainingDayId,_that.complianceScore);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WearableActivitySummary run, @JsonKey(name: 'training_day_id', fromJson: toIntOrNull)  int? trainingDayId, @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull)  double? complianceScore)?  $default,) {final _that = this;
switch (_that) {
case _RecentRun() when $default != null:
return $default(_that.run,_that.trainingDayId,_that.complianceScore);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RecentRun implements RecentRun {
  const _RecentRun({required this.run, @JsonKey(name: 'training_day_id', fromJson: toIntOrNull) this.trainingDayId, @JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull) this.complianceScore});
  factory _RecentRun.fromJson(Map<String, dynamic> json) => _$RecentRunFromJson(json);

@override final  WearableActivitySummary run;
@override@JsonKey(name: 'training_day_id', fromJson: toIntOrNull) final  int? trainingDayId;
@override@JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull) final  double? complianceScore;

/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RecentRunCopyWith<_RecentRun> get copyWith => __$RecentRunCopyWithImpl<_RecentRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RecentRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RecentRun&&(identical(other.run, run) || other.run == run)&&(identical(other.trainingDayId, trainingDayId) || other.trainingDayId == trainingDayId)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,run,trainingDayId,complianceScore);

@override
String toString() {
  return 'RecentRun(run: $run, trainingDayId: $trainingDayId, complianceScore: $complianceScore)';
}


}

/// @nodoc
abstract mixin class _$RecentRunCopyWith<$Res> implements $RecentRunCopyWith<$Res> {
  factory _$RecentRunCopyWith(_RecentRun value, $Res Function(_RecentRun) _then) = __$RecentRunCopyWithImpl;
@override @useResult
$Res call({
 WearableActivitySummary run,@JsonKey(name: 'training_day_id', fromJson: toIntOrNull) int? trainingDayId,@JsonKey(name: 'compliance_score', fromJson: toDoubleOrNull) double? complianceScore
});


@override $WearableActivitySummaryCopyWith<$Res> get run;

}
/// @nodoc
class __$RecentRunCopyWithImpl<$Res>
    implements _$RecentRunCopyWith<$Res> {
  __$RecentRunCopyWithImpl(this._self, this._then);

  final _RecentRun _self;
  final $Res Function(_RecentRun) _then;

/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? run = null,Object? trainingDayId = freezed,Object? complianceScore = freezed,}) {
  return _then(_RecentRun(
run: null == run ? _self.run : run // ignore: cast_nullable_to_non_nullable
as WearableActivitySummary,trainingDayId: freezed == trainingDayId ? _self.trainingDayId : trainingDayId // ignore: cast_nullable_to_non_nullable
as int?,complianceScore: freezed == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of RecentRun
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WearableActivitySummaryCopyWith<$Res> get run {
  
  return $WearableActivitySummaryCopyWith<$Res>(_self.run, (value) {
    return _then(_self.copyWith(run: value));
  });
}
}

// dart format on
