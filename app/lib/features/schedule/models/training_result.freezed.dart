// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingResult {

 int get id;@JsonKey(name: 'compliance_score', fromJson: toDouble) double get complianceScore;@JsonKey(name: 'actual_km', fromJson: toDouble) double get actualKm;@JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt) int get actualPaceSecondsPerKm;@JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull) double? get actualAvgHeartRate;@JsonKey(name: 'pace_score', fromJson: toDouble) double get paceScore;@JsonKey(name: 'distance_score', fromJson: toDouble) double get distanceScore;@JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull) double? get heartRateScore;@JsonKey(name: 'ai_feedback') String? get aiFeedback;/// Locally-persisted Strava run that was matched to this training day.
/// Eager-loaded by the backend on `showDay`, `dayResult`, and
/// `matchActivityToDay`. Null for older results where we didn't load it.
@JsonKey(name: 'strava_activity') StravaActivitySummary? get stravaActivity;
/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingResultCopyWith<TrainingResult> get copyWith => _$TrainingResultCopyWithImpl<TrainingResult>(this as TrainingResult, _$identity);

  /// Serializes this TrainingResult to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingResult&&(identical(other.id, id) || other.id == id)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore)&&(identical(other.actualKm, actualKm) || other.actualKm == actualKm)&&(identical(other.actualPaceSecondsPerKm, actualPaceSecondsPerKm) || other.actualPaceSecondsPerKm == actualPaceSecondsPerKm)&&(identical(other.actualAvgHeartRate, actualAvgHeartRate) || other.actualAvgHeartRate == actualAvgHeartRate)&&(identical(other.paceScore, paceScore) || other.paceScore == paceScore)&&(identical(other.distanceScore, distanceScore) || other.distanceScore == distanceScore)&&(identical(other.heartRateScore, heartRateScore) || other.heartRateScore == heartRateScore)&&(identical(other.aiFeedback, aiFeedback) || other.aiFeedback == aiFeedback)&&(identical(other.stravaActivity, stravaActivity) || other.stravaActivity == stravaActivity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,complianceScore,actualKm,actualPaceSecondsPerKm,actualAvgHeartRate,paceScore,distanceScore,heartRateScore,aiFeedback,stravaActivity);

@override
String toString() {
  return 'TrainingResult(id: $id, complianceScore: $complianceScore, actualKm: $actualKm, actualPaceSecondsPerKm: $actualPaceSecondsPerKm, actualAvgHeartRate: $actualAvgHeartRate, paceScore: $paceScore, distanceScore: $distanceScore, heartRateScore: $heartRateScore, aiFeedback: $aiFeedback, stravaActivity: $stravaActivity)';
}


}

/// @nodoc
abstract mixin class $TrainingResultCopyWith<$Res>  {
  factory $TrainingResultCopyWith(TrainingResult value, $Res Function(TrainingResult) _then) = _$TrainingResultCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'compliance_score', fromJson: toDouble) double complianceScore,@JsonKey(name: 'actual_km', fromJson: toDouble) double actualKm,@JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt) int actualPaceSecondsPerKm,@JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull) double? actualAvgHeartRate,@JsonKey(name: 'pace_score', fromJson: toDouble) double paceScore,@JsonKey(name: 'distance_score', fromJson: toDouble) double distanceScore,@JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull) double? heartRateScore,@JsonKey(name: 'ai_feedback') String? aiFeedback,@JsonKey(name: 'strava_activity') StravaActivitySummary? stravaActivity
});


$StravaActivitySummaryCopyWith<$Res>? get stravaActivity;

}
/// @nodoc
class _$TrainingResultCopyWithImpl<$Res>
    implements $TrainingResultCopyWith<$Res> {
  _$TrainingResultCopyWithImpl(this._self, this._then);

  final TrainingResult _self;
  final $Res Function(TrainingResult) _then;

/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? complianceScore = null,Object? actualKm = null,Object? actualPaceSecondsPerKm = null,Object? actualAvgHeartRate = freezed,Object? paceScore = null,Object? distanceScore = null,Object? heartRateScore = freezed,Object? aiFeedback = freezed,Object? stravaActivity = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,complianceScore: null == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double,actualKm: null == actualKm ? _self.actualKm : actualKm // ignore: cast_nullable_to_non_nullable
as double,actualPaceSecondsPerKm: null == actualPaceSecondsPerKm ? _self.actualPaceSecondsPerKm : actualPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int,actualAvgHeartRate: freezed == actualAvgHeartRate ? _self.actualAvgHeartRate : actualAvgHeartRate // ignore: cast_nullable_to_non_nullable
as double?,paceScore: null == paceScore ? _self.paceScore : paceScore // ignore: cast_nullable_to_non_nullable
as double,distanceScore: null == distanceScore ? _self.distanceScore : distanceScore // ignore: cast_nullable_to_non_nullable
as double,heartRateScore: freezed == heartRateScore ? _self.heartRateScore : heartRateScore // ignore: cast_nullable_to_non_nullable
as double?,aiFeedback: freezed == aiFeedback ? _self.aiFeedback : aiFeedback // ignore: cast_nullable_to_non_nullable
as String?,stravaActivity: freezed == stravaActivity ? _self.stravaActivity : stravaActivity // ignore: cast_nullable_to_non_nullable
as StravaActivitySummary?,
  ));
}
/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StravaActivitySummaryCopyWith<$Res>? get stravaActivity {
    if (_self.stravaActivity == null) {
    return null;
  }

  return $StravaActivitySummaryCopyWith<$Res>(_self.stravaActivity!, (value) {
    return _then(_self.copyWith(stravaActivity: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrainingResult].
extension TrainingResultPatterns on TrainingResult {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingResult value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingResult() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingResult value)  $default,){
final _that = this;
switch (_that) {
case _TrainingResult():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingResult value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingResult() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'compliance_score', fromJson: toDouble)  double complianceScore, @JsonKey(name: 'actual_km', fromJson: toDouble)  double actualKm, @JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt)  int actualPaceSecondsPerKm, @JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull)  double? actualAvgHeartRate, @JsonKey(name: 'pace_score', fromJson: toDouble)  double paceScore, @JsonKey(name: 'distance_score', fromJson: toDouble)  double distanceScore, @JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull)  double? heartRateScore, @JsonKey(name: 'ai_feedback')  String? aiFeedback, @JsonKey(name: 'strava_activity')  StravaActivitySummary? stravaActivity)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingResult() when $default != null:
return $default(_that.id,_that.complianceScore,_that.actualKm,_that.actualPaceSecondsPerKm,_that.actualAvgHeartRate,_that.paceScore,_that.distanceScore,_that.heartRateScore,_that.aiFeedback,_that.stravaActivity);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'compliance_score', fromJson: toDouble)  double complianceScore, @JsonKey(name: 'actual_km', fromJson: toDouble)  double actualKm, @JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt)  int actualPaceSecondsPerKm, @JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull)  double? actualAvgHeartRate, @JsonKey(name: 'pace_score', fromJson: toDouble)  double paceScore, @JsonKey(name: 'distance_score', fromJson: toDouble)  double distanceScore, @JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull)  double? heartRateScore, @JsonKey(name: 'ai_feedback')  String? aiFeedback, @JsonKey(name: 'strava_activity')  StravaActivitySummary? stravaActivity)  $default,) {final _that = this;
switch (_that) {
case _TrainingResult():
return $default(_that.id,_that.complianceScore,_that.actualKm,_that.actualPaceSecondsPerKm,_that.actualAvgHeartRate,_that.paceScore,_that.distanceScore,_that.heartRateScore,_that.aiFeedback,_that.stravaActivity);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'compliance_score', fromJson: toDouble)  double complianceScore, @JsonKey(name: 'actual_km', fromJson: toDouble)  double actualKm, @JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt)  int actualPaceSecondsPerKm, @JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull)  double? actualAvgHeartRate, @JsonKey(name: 'pace_score', fromJson: toDouble)  double paceScore, @JsonKey(name: 'distance_score', fromJson: toDouble)  double distanceScore, @JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull)  double? heartRateScore, @JsonKey(name: 'ai_feedback')  String? aiFeedback, @JsonKey(name: 'strava_activity')  StravaActivitySummary? stravaActivity)?  $default,) {final _that = this;
switch (_that) {
case _TrainingResult() when $default != null:
return $default(_that.id,_that.complianceScore,_that.actualKm,_that.actualPaceSecondsPerKm,_that.actualAvgHeartRate,_that.paceScore,_that.distanceScore,_that.heartRateScore,_that.aiFeedback,_that.stravaActivity);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingResult implements TrainingResult {
  const _TrainingResult({required this.id, @JsonKey(name: 'compliance_score', fromJson: toDouble) required this.complianceScore, @JsonKey(name: 'actual_km', fromJson: toDouble) required this.actualKm, @JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt) required this.actualPaceSecondsPerKm, @JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull) this.actualAvgHeartRate, @JsonKey(name: 'pace_score', fromJson: toDouble) required this.paceScore, @JsonKey(name: 'distance_score', fromJson: toDouble) required this.distanceScore, @JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull) this.heartRateScore, @JsonKey(name: 'ai_feedback') this.aiFeedback, @JsonKey(name: 'strava_activity') this.stravaActivity});
  factory _TrainingResult.fromJson(Map<String, dynamic> json) => _$TrainingResultFromJson(json);

@override final  int id;
@override@JsonKey(name: 'compliance_score', fromJson: toDouble) final  double complianceScore;
@override@JsonKey(name: 'actual_km', fromJson: toDouble) final  double actualKm;
@override@JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt) final  int actualPaceSecondsPerKm;
@override@JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull) final  double? actualAvgHeartRate;
@override@JsonKey(name: 'pace_score', fromJson: toDouble) final  double paceScore;
@override@JsonKey(name: 'distance_score', fromJson: toDouble) final  double distanceScore;
@override@JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull) final  double? heartRateScore;
@override@JsonKey(name: 'ai_feedback') final  String? aiFeedback;
/// Locally-persisted Strava run that was matched to this training day.
/// Eager-loaded by the backend on `showDay`, `dayResult`, and
/// `matchActivityToDay`. Null for older results where we didn't load it.
@override@JsonKey(name: 'strava_activity') final  StravaActivitySummary? stravaActivity;

/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingResultCopyWith<_TrainingResult> get copyWith => __$TrainingResultCopyWithImpl<_TrainingResult>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingResultToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingResult&&(identical(other.id, id) || other.id == id)&&(identical(other.complianceScore, complianceScore) || other.complianceScore == complianceScore)&&(identical(other.actualKm, actualKm) || other.actualKm == actualKm)&&(identical(other.actualPaceSecondsPerKm, actualPaceSecondsPerKm) || other.actualPaceSecondsPerKm == actualPaceSecondsPerKm)&&(identical(other.actualAvgHeartRate, actualAvgHeartRate) || other.actualAvgHeartRate == actualAvgHeartRate)&&(identical(other.paceScore, paceScore) || other.paceScore == paceScore)&&(identical(other.distanceScore, distanceScore) || other.distanceScore == distanceScore)&&(identical(other.heartRateScore, heartRateScore) || other.heartRateScore == heartRateScore)&&(identical(other.aiFeedback, aiFeedback) || other.aiFeedback == aiFeedback)&&(identical(other.stravaActivity, stravaActivity) || other.stravaActivity == stravaActivity));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,complianceScore,actualKm,actualPaceSecondsPerKm,actualAvgHeartRate,paceScore,distanceScore,heartRateScore,aiFeedback,stravaActivity);

@override
String toString() {
  return 'TrainingResult(id: $id, complianceScore: $complianceScore, actualKm: $actualKm, actualPaceSecondsPerKm: $actualPaceSecondsPerKm, actualAvgHeartRate: $actualAvgHeartRate, paceScore: $paceScore, distanceScore: $distanceScore, heartRateScore: $heartRateScore, aiFeedback: $aiFeedback, stravaActivity: $stravaActivity)';
}


}

/// @nodoc
abstract mixin class _$TrainingResultCopyWith<$Res> implements $TrainingResultCopyWith<$Res> {
  factory _$TrainingResultCopyWith(_TrainingResult value, $Res Function(_TrainingResult) _then) = __$TrainingResultCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'compliance_score', fromJson: toDouble) double complianceScore,@JsonKey(name: 'actual_km', fromJson: toDouble) double actualKm,@JsonKey(name: 'actual_pace_seconds_per_km', fromJson: toInt) int actualPaceSecondsPerKm,@JsonKey(name: 'actual_avg_heart_rate', fromJson: toDoubleOrNull) double? actualAvgHeartRate,@JsonKey(name: 'pace_score', fromJson: toDouble) double paceScore,@JsonKey(name: 'distance_score', fromJson: toDouble) double distanceScore,@JsonKey(name: 'heart_rate_score', fromJson: toDoubleOrNull) double? heartRateScore,@JsonKey(name: 'ai_feedback') String? aiFeedback,@JsonKey(name: 'strava_activity') StravaActivitySummary? stravaActivity
});


@override $StravaActivitySummaryCopyWith<$Res>? get stravaActivity;

}
/// @nodoc
class __$TrainingResultCopyWithImpl<$Res>
    implements _$TrainingResultCopyWith<$Res> {
  __$TrainingResultCopyWithImpl(this._self, this._then);

  final _TrainingResult _self;
  final $Res Function(_TrainingResult) _then;

/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? complianceScore = null,Object? actualKm = null,Object? actualPaceSecondsPerKm = null,Object? actualAvgHeartRate = freezed,Object? paceScore = null,Object? distanceScore = null,Object? heartRateScore = freezed,Object? aiFeedback = freezed,Object? stravaActivity = freezed,}) {
  return _then(_TrainingResult(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,complianceScore: null == complianceScore ? _self.complianceScore : complianceScore // ignore: cast_nullable_to_non_nullable
as double,actualKm: null == actualKm ? _self.actualKm : actualKm // ignore: cast_nullable_to_non_nullable
as double,actualPaceSecondsPerKm: null == actualPaceSecondsPerKm ? _self.actualPaceSecondsPerKm : actualPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int,actualAvgHeartRate: freezed == actualAvgHeartRate ? _self.actualAvgHeartRate : actualAvgHeartRate // ignore: cast_nullable_to_non_nullable
as double?,paceScore: null == paceScore ? _self.paceScore : paceScore // ignore: cast_nullable_to_non_nullable
as double,distanceScore: null == distanceScore ? _self.distanceScore : distanceScore // ignore: cast_nullable_to_non_nullable
as double,heartRateScore: freezed == heartRateScore ? _self.heartRateScore : heartRateScore // ignore: cast_nullable_to_non_nullable
as double?,aiFeedback: freezed == aiFeedback ? _self.aiFeedback : aiFeedback // ignore: cast_nullable_to_non_nullable
as String?,stravaActivity: freezed == stravaActivity ? _self.stravaActivity : stravaActivity // ignore: cast_nullable_to_non_nullable
as StravaActivitySummary?,
  ));
}

/// Create a copy of TrainingResult
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StravaActivitySummaryCopyWith<$Res>? get stravaActivity {
    if (_self.stravaActivity == null) {
    return null;
  }

  return $StravaActivitySummaryCopyWith<$Res>(_self.stravaActivity!, (value) {
    return _then(_self.copyWith(stravaActivity: value));
  });
}
}

// dart format on
