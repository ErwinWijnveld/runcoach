// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'analyzing_run.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AnalyzingRun {

 int get wearableActivityId; AnalyzingRunStatus get status; DateTime get startedAt; int? get trainingDayId; int? get trainingResultId; double? get complianceScore; double? get actualKm; String? get aiFeedback;
/// Create a copy of AnalyzingRun
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AnalyzingRunCopyWith<AnalyzingRun> get copyWith => _$AnalyzingRunCopyWithImpl<AnalyzingRun>(this as AnalyzingRun, _$identity);

  /// Serializes this AnalyzingRun to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AnalyzingRun&&(identical(other.wearableActivityId, wearableActivityId) || other.wearableActivityId == wearableActivityId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.trainingDayId, trainingDayId) || other.trainingDayId == trainingDayId)&&(identical(other.trainingResultId, trainingResultId) || other.trainingResultId == trainingResultId)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore)&&(identical(other.actualKm, actualKm) || other.actualKm == actualKm)&&(identical(other.aiFeedback, aiFeedback) || other.aiFeedback == aiFeedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wearableActivityId,status,startedAt,trainingDayId,trainingResultId,complianceScore,actualKm,aiFeedback);

@override
String toString() {
  return 'AnalyzingRun(wearableActivityId: $wearableActivityId, status: $status, startedAt: $startedAt, trainingDayId: $trainingDayId, trainingResultId: $trainingResultId, complianceScore: $complianceScore, actualKm: $actualKm, aiFeedback: $aiFeedback)';
}


}

/// @nodoc
abstract mixin class $AnalyzingRunCopyWith<$Res>  {
  factory $AnalyzingRunCopyWith(AnalyzingRun value, $Res Function(AnalyzingRun) _then) = _$AnalyzingRunCopyWithImpl;
@useResult
$Res call({
 int wearableActivityId, AnalyzingRunStatus status, DateTime startedAt, int? trainingDayId, int? trainingResultId, double? complianceScore, double? actualKm, String? aiFeedback
});




}
/// @nodoc
class _$AnalyzingRunCopyWithImpl<$Res>
    implements $AnalyzingRunCopyWith<$Res> {
  _$AnalyzingRunCopyWithImpl(this._self, this._then);

  final AnalyzingRun _self;
  final $Res Function(AnalyzingRun) _then;

/// Create a copy of AnalyzingRun
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wearableActivityId = null,Object? status = null,Object? startedAt = null,Object? trainingDayId = freezed,Object? trainingResultId = freezed,Object? complianceScore = freezed,Object? actualKm = freezed,Object? aiFeedback = freezed,}) {
  return _then(_self.copyWith(
wearableActivityId: null == wearableActivityId ? _self.wearableActivityId : wearableActivityId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AnalyzingRunStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,trainingDayId: freezed == trainingDayId ? _self.trainingDayId : trainingDayId // ignore: cast_nullable_to_non_nullable
as int?,trainingResultId: freezed == trainingResultId ? _self.trainingResultId : trainingResultId // ignore: cast_nullable_to_non_nullable
as int?,complianceScore: freezed == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double?,actualKm: freezed == actualKm ? _self.actualKm : actualKm // ignore: cast_nullable_to_non_nullable
as double?,aiFeedback: freezed == aiFeedback ? _self.aiFeedback : aiFeedback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AnalyzingRun].
extension AnalyzingRunPatterns on AnalyzingRun {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AnalyzingRun value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AnalyzingRun() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AnalyzingRun value)  $default,){
final _that = this;
switch (_that) {
case _AnalyzingRun():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AnalyzingRun value)?  $default,){
final _that = this;
switch (_that) {
case _AnalyzingRun() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int wearableActivityId,  AnalyzingRunStatus status,  DateTime startedAt,  int? trainingDayId,  int? trainingResultId,  double? complianceScore,  double? actualKm,  String? aiFeedback)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AnalyzingRun() when $default != null:
return $default(_that.wearableActivityId,_that.status,_that.startedAt,_that.trainingDayId,_that.trainingResultId,_that.complianceScore,_that.actualKm,_that.aiFeedback);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int wearableActivityId,  AnalyzingRunStatus status,  DateTime startedAt,  int? trainingDayId,  int? trainingResultId,  double? complianceScore,  double? actualKm,  String? aiFeedback)  $default,) {final _that = this;
switch (_that) {
case _AnalyzingRun():
return $default(_that.wearableActivityId,_that.status,_that.startedAt,_that.trainingDayId,_that.trainingResultId,_that.complianceScore,_that.actualKm,_that.aiFeedback);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int wearableActivityId,  AnalyzingRunStatus status,  DateTime startedAt,  int? trainingDayId,  int? trainingResultId,  double? complianceScore,  double? actualKm,  String? aiFeedback)?  $default,) {final _that = this;
switch (_that) {
case _AnalyzingRun() when $default != null:
return $default(_that.wearableActivityId,_that.status,_that.startedAt,_that.trainingDayId,_that.trainingResultId,_that.complianceScore,_that.actualKm,_that.aiFeedback);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AnalyzingRun implements AnalyzingRun {
  const _AnalyzingRun({required this.wearableActivityId, required this.status, required this.startedAt, this.trainingDayId, this.trainingResultId, this.complianceScore, this.actualKm, this.aiFeedback});
  factory _AnalyzingRun.fromJson(Map<String, dynamic> json) => _$AnalyzingRunFromJson(json);

@override final  int wearableActivityId;
@override final  AnalyzingRunStatus status;
@override final  DateTime startedAt;
@override final  int? trainingDayId;
@override final  int? trainingResultId;
@override final  double? complianceScore;
@override final  double? actualKm;
@override final  String? aiFeedback;

/// Create a copy of AnalyzingRun
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AnalyzingRunCopyWith<_AnalyzingRun> get copyWith => __$AnalyzingRunCopyWithImpl<_AnalyzingRun>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AnalyzingRunToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AnalyzingRun&&(identical(other.wearableActivityId, wearableActivityId) || other.wearableActivityId == wearableActivityId)&&(identical(other.status, status) || other.status == status)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.trainingDayId, trainingDayId) || other.trainingDayId == trainingDayId)&&(identical(other.trainingResultId, trainingResultId) || other.trainingResultId == trainingResultId)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore)&&(identical(other.actualKm, actualKm) || other.actualKm == actualKm)&&(identical(other.aiFeedback, aiFeedback) || other.aiFeedback == aiFeedback));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wearableActivityId,status,startedAt,trainingDayId,trainingResultId,complianceScore,actualKm,aiFeedback);

@override
String toString() {
  return 'AnalyzingRun(wearableActivityId: $wearableActivityId, status: $status, startedAt: $startedAt, trainingDayId: $trainingDayId, trainingResultId: $trainingResultId, complianceScore: $complianceScore, actualKm: $actualKm, aiFeedback: $aiFeedback)';
}


}

/// @nodoc
abstract mixin class _$AnalyzingRunCopyWith<$Res> implements $AnalyzingRunCopyWith<$Res> {
  factory _$AnalyzingRunCopyWith(_AnalyzingRun value, $Res Function(_AnalyzingRun) _then) = __$AnalyzingRunCopyWithImpl;
@override @useResult
$Res call({
 int wearableActivityId, AnalyzingRunStatus status, DateTime startedAt, int? trainingDayId, int? trainingResultId, double? complianceScore, double? actualKm, String? aiFeedback
});




}
/// @nodoc
class __$AnalyzingRunCopyWithImpl<$Res>
    implements _$AnalyzingRunCopyWith<$Res> {
  __$AnalyzingRunCopyWithImpl(this._self, this._then);

  final _AnalyzingRun _self;
  final $Res Function(_AnalyzingRun) _then;

/// Create a copy of AnalyzingRun
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wearableActivityId = null,Object? status = null,Object? startedAt = null,Object? trainingDayId = freezed,Object? trainingResultId = freezed,Object? complianceScore = freezed,Object? actualKm = freezed,Object? aiFeedback = freezed,}) {
  return _then(_AnalyzingRun(
wearableActivityId: null == wearableActivityId ? _self.wearableActivityId : wearableActivityId // ignore: cast_nullable_to_non_nullable
as int,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AnalyzingRunStatus,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,trainingDayId: freezed == trainingDayId ? _self.trainingDayId : trainingDayId // ignore: cast_nullable_to_non_nullable
as int?,trainingResultId: freezed == trainingResultId ? _self.trainingResultId : trainingResultId // ignore: cast_nullable_to_non_nullable
as int?,complianceScore: freezed == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double?,actualKm: freezed == actualKm ? _self.actualKm : actualKm // ignore: cast_nullable_to_non_nullable
as double?,aiFeedback: freezed == aiFeedback ? _self.aiFeedback : aiFeedback // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
