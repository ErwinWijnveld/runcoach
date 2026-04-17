// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'available_strava_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvailableStravaActivity {

@JsonKey(name: 'strava_activity_id') int get stravaActivityId; String get name;@JsonKey(name: 'start_date') String? get startDate;@JsonKey(name: 'distance_km', fromJson: toDouble) double get distanceKm;@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int get movingTimeSeconds;@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? get averagePaceSecondsPerKm;@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? get averageHeartRate;/// Non-null if this Strava run is already matched to a training day
/// (the current day OR any other day). Used to render a "synced" badge
/// and make the row non-selectable.
@JsonKey(name: 'matched_training_day_id') int? get matchedTrainingDayId;
/// Create a copy of AvailableStravaActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableStravaActivityCopyWith<AvailableStravaActivity> get copyWith => _$AvailableStravaActivityCopyWithImpl<AvailableStravaActivity>(this as AvailableStravaActivity, _$identity);

  /// Serializes this AvailableStravaActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableStravaActivity&&(identical(other.stravaActivityId, stravaActivityId) || other.stravaActivityId == stravaActivityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.movingTimeSeconds, movingTimeSeconds) || other.movingTimeSeconds == movingTimeSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartRate, averageHeartRate) || other.averageHeartRate == averageHeartRate)&&(identical(other.matchedTrainingDayId, matchedTrainingDayId) || other.matchedTrainingDayId == matchedTrainingDayId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stravaActivityId,name,startDate,distanceKm,movingTimeSeconds,averagePaceSecondsPerKm,averageHeartRate,matchedTrainingDayId);

@override
String toString() {
  return 'AvailableStravaActivity(stravaActivityId: $stravaActivityId, name: $name, startDate: $startDate, distanceKm: $distanceKm, movingTimeSeconds: $movingTimeSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartRate: $averageHeartRate, matchedTrainingDayId: $matchedTrainingDayId)';
}


}

/// @nodoc
abstract mixin class $AvailableStravaActivityCopyWith<$Res>  {
  factory $AvailableStravaActivityCopyWith(AvailableStravaActivity value, $Res Function(AvailableStravaActivity) _then) = _$AvailableStravaActivityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'strava_activity_id') int stravaActivityId, String name,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'distance_km', fromJson: toDouble) double distanceKm,@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int movingTimeSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? averagePaceSecondsPerKm,@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? averageHeartRate,@JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId
});




}
/// @nodoc
class _$AvailableStravaActivityCopyWithImpl<$Res>
    implements $AvailableStravaActivityCopyWith<$Res> {
  _$AvailableStravaActivityCopyWithImpl(this._self, this._then);

  final AvailableStravaActivity _self;
  final $Res Function(AvailableStravaActivity) _then;

/// Create a copy of AvailableStravaActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? stravaActivityId = null,Object? name = null,Object? startDate = freezed,Object? distanceKm = null,Object? movingTimeSeconds = null,Object? averagePaceSecondsPerKm = freezed,Object? averageHeartRate = freezed,Object? matchedTrainingDayId = freezed,}) {
  return _then(_self.copyWith(
stravaActivityId: null == stravaActivityId ? _self.stravaActivityId : stravaActivityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,movingTimeSeconds: null == movingTimeSeconds ? _self.movingTimeSeconds : movingTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,averagePaceSecondsPerKm: freezed == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,averageHeartRate: freezed == averageHeartRate ? _self.averageHeartRate : averageHeartRate // ignore: cast_nullable_to_non_nullable
as double?,matchedTrainingDayId: freezed == matchedTrainingDayId ? _self.matchedTrainingDayId : matchedTrainingDayId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailableStravaActivity].
extension AvailableStravaActivityPatterns on AvailableStravaActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailableStravaActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailableStravaActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailableStravaActivity value)  $default,){
final _that = this;
switch (_that) {
case _AvailableStravaActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailableStravaActivity value)?  $default,){
final _that = this;
switch (_that) {
case _AvailableStravaActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'strava_activity_id')  int stravaActivityId,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailableStravaActivity() when $default != null:
return $default(_that.stravaActivityId,_that.name,_that.startDate,_that.distanceKm,_that.movingTimeSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'strava_activity_id')  int stravaActivityId,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)  $default,) {final _that = this;
switch (_that) {
case _AvailableStravaActivity():
return $default(_that.stravaActivityId,_that.name,_that.startDate,_that.distanceKm,_that.movingTimeSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'strava_activity_id')  int stravaActivityId,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)?  $default,) {final _that = this;
switch (_that) {
case _AvailableStravaActivity() when $default != null:
return $default(_that.stravaActivityId,_that.name,_that.startDate,_that.distanceKm,_that.movingTimeSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailableStravaActivity implements AvailableStravaActivity {
  const _AvailableStravaActivity({@JsonKey(name: 'strava_activity_id') required this.stravaActivityId, required this.name, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'distance_km', fromJson: toDouble) required this.distanceKm, @JsonKey(name: 'moving_time_seconds', fromJson: toInt) required this.movingTimeSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) this.averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) this.averageHeartRate, @JsonKey(name: 'matched_training_day_id') this.matchedTrainingDayId});
  factory _AvailableStravaActivity.fromJson(Map<String, dynamic> json) => _$AvailableStravaActivityFromJson(json);

@override@JsonKey(name: 'strava_activity_id') final  int stravaActivityId;
@override final  String name;
@override@JsonKey(name: 'start_date') final  String? startDate;
@override@JsonKey(name: 'distance_km', fromJson: toDouble) final  double distanceKm;
@override@JsonKey(name: 'moving_time_seconds', fromJson: toInt) final  int movingTimeSeconds;
@override@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) final  int? averagePaceSecondsPerKm;
@override@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) final  double? averageHeartRate;
/// Non-null if this Strava run is already matched to a training day
/// (the current day OR any other day). Used to render a "synced" badge
/// and make the row non-selectable.
@override@JsonKey(name: 'matched_training_day_id') final  int? matchedTrainingDayId;

/// Create a copy of AvailableStravaActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailableStravaActivityCopyWith<_AvailableStravaActivity> get copyWith => __$AvailableStravaActivityCopyWithImpl<_AvailableStravaActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailableStravaActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailableStravaActivity&&(identical(other.stravaActivityId, stravaActivityId) || other.stravaActivityId == stravaActivityId)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.movingTimeSeconds, movingTimeSeconds) || other.movingTimeSeconds == movingTimeSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartRate, averageHeartRate) || other.averageHeartRate == averageHeartRate)&&(identical(other.matchedTrainingDayId, matchedTrainingDayId) || other.matchedTrainingDayId == matchedTrainingDayId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,stravaActivityId,name,startDate,distanceKm,movingTimeSeconds,averagePaceSecondsPerKm,averageHeartRate,matchedTrainingDayId);

@override
String toString() {
  return 'AvailableStravaActivity(stravaActivityId: $stravaActivityId, name: $name, startDate: $startDate, distanceKm: $distanceKm, movingTimeSeconds: $movingTimeSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartRate: $averageHeartRate, matchedTrainingDayId: $matchedTrainingDayId)';
}


}

/// @nodoc
abstract mixin class _$AvailableStravaActivityCopyWith<$Res> implements $AvailableStravaActivityCopyWith<$Res> {
  factory _$AvailableStravaActivityCopyWith(_AvailableStravaActivity value, $Res Function(_AvailableStravaActivity) _then) = __$AvailableStravaActivityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'strava_activity_id') int stravaActivityId, String name,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'distance_km', fromJson: toDouble) double distanceKm,@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int movingTimeSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? averagePaceSecondsPerKm,@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? averageHeartRate,@JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId
});




}
/// @nodoc
class __$AvailableStravaActivityCopyWithImpl<$Res>
    implements _$AvailableStravaActivityCopyWith<$Res> {
  __$AvailableStravaActivityCopyWithImpl(this._self, this._then);

  final _AvailableStravaActivity _self;
  final $Res Function(_AvailableStravaActivity) _then;

/// Create a copy of AvailableStravaActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? stravaActivityId = null,Object? name = null,Object? startDate = freezed,Object? distanceKm = null,Object? movingTimeSeconds = null,Object? averagePaceSecondsPerKm = freezed,Object? averageHeartRate = freezed,Object? matchedTrainingDayId = freezed,}) {
  return _then(_AvailableStravaActivity(
stravaActivityId: null == stravaActivityId ? _self.stravaActivityId : stravaActivityId // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,movingTimeSeconds: null == movingTimeSeconds ? _self.movingTimeSeconds : movingTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,averagePaceSecondsPerKm: freezed == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,averageHeartRate: freezed == averageHeartRate ? _self.averageHeartRate : averageHeartRate // ignore: cast_nullable_to_non_nullable
as double?,matchedTrainingDayId: freezed == matchedTrainingDayId ? _self.matchedTrainingDayId : matchedTrainingDayId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
