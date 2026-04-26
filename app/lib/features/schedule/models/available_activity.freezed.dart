// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'available_activity.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AvailableActivity {

@JsonKey(name: 'wearable_activity_id') int get wearableActivityId; String get source; String get name;@JsonKey(name: 'start_date') String? get startDate;@JsonKey(name: 'distance_km', fromJson: toDouble) double get distanceKm;@JsonKey(name: 'duration_seconds', fromJson: toInt) int get durationSeconds;@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? get averagePaceSecondsPerKm;@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? get averageHeartRate;/// Non-null if this run is already matched to a training day. Used to
/// render a "synced" badge and disable the row.
@JsonKey(name: 'matched_training_day_id') int? get matchedTrainingDayId;
/// Create a copy of AvailableActivity
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AvailableActivityCopyWith<AvailableActivity> get copyWith => _$AvailableActivityCopyWithImpl<AvailableActivity>(this as AvailableActivity, _$identity);

  /// Serializes this AvailableActivity to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AvailableActivity&&(identical(other.wearableActivityId, wearableActivityId) || other.wearableActivityId == wearableActivityId)&&(identical(other.source, source) || other.source == source)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartRate, averageHeartRate) || other.averageHeartRate == averageHeartRate)&&(identical(other.matchedTrainingDayId, matchedTrainingDayId) || other.matchedTrainingDayId == matchedTrainingDayId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wearableActivityId,source,name,startDate,distanceKm,durationSeconds,averagePaceSecondsPerKm,averageHeartRate,matchedTrainingDayId);

@override
String toString() {
  return 'AvailableActivity(wearableActivityId: $wearableActivityId, source: $source, name: $name, startDate: $startDate, distanceKm: $distanceKm, durationSeconds: $durationSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartRate: $averageHeartRate, matchedTrainingDayId: $matchedTrainingDayId)';
}


}

/// @nodoc
abstract mixin class $AvailableActivityCopyWith<$Res>  {
  factory $AvailableActivityCopyWith(AvailableActivity value, $Res Function(AvailableActivity) _then) = _$AvailableActivityCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'wearable_activity_id') int wearableActivityId, String source, String name,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'distance_km', fromJson: toDouble) double distanceKm,@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? averagePaceSecondsPerKm,@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? averageHeartRate,@JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId
});




}
/// @nodoc
class _$AvailableActivityCopyWithImpl<$Res>
    implements $AvailableActivityCopyWith<$Res> {
  _$AvailableActivityCopyWithImpl(this._self, this._then);

  final AvailableActivity _self;
  final $Res Function(AvailableActivity) _then;

/// Create a copy of AvailableActivity
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? wearableActivityId = null,Object? source = null,Object? name = null,Object? startDate = freezed,Object? distanceKm = null,Object? durationSeconds = null,Object? averagePaceSecondsPerKm = freezed,Object? averageHeartRate = freezed,Object? matchedTrainingDayId = freezed,}) {
  return _then(_self.copyWith(
wearableActivityId: null == wearableActivityId ? _self.wearableActivityId : wearableActivityId // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,averagePaceSecondsPerKm: freezed == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,averageHeartRate: freezed == averageHeartRate ? _self.averageHeartRate : averageHeartRate // ignore: cast_nullable_to_non_nullable
as double?,matchedTrainingDayId: freezed == matchedTrainingDayId ? _self.matchedTrainingDayId : matchedTrainingDayId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AvailableActivity].
extension AvailableActivityPatterns on AvailableActivity {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AvailableActivity value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AvailableActivity() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AvailableActivity value)  $default,){
final _that = this;
switch (_that) {
case _AvailableActivity():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AvailableActivity value)?  $default,){
final _that = this;
switch (_that) {
case _AvailableActivity() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'wearable_activity_id')  int wearableActivityId,  String source,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AvailableActivity() when $default != null:
return $default(_that.wearableActivityId,_that.source,_that.name,_that.startDate,_that.distanceKm,_that.durationSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'wearable_activity_id')  int wearableActivityId,  String source,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)  $default,) {final _that = this;
switch (_that) {
case _AvailableActivity():
return $default(_that.wearableActivityId,_that.source,_that.name,_that.startDate,_that.distanceKm,_that.durationSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'wearable_activity_id')  int wearableActivityId,  String source,  String name, @JsonKey(name: 'start_date')  String? startDate, @JsonKey(name: 'distance_km', fromJson: toDouble)  double distanceKm, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull)  int? averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull)  double? averageHeartRate, @JsonKey(name: 'matched_training_day_id')  int? matchedTrainingDayId)?  $default,) {final _that = this;
switch (_that) {
case _AvailableActivity() when $default != null:
return $default(_that.wearableActivityId,_that.source,_that.name,_that.startDate,_that.distanceKm,_that.durationSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartRate,_that.matchedTrainingDayId);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _AvailableActivity implements AvailableActivity {
  const _AvailableActivity({@JsonKey(name: 'wearable_activity_id') required this.wearableActivityId, required this.source, required this.name, @JsonKey(name: 'start_date') this.startDate, @JsonKey(name: 'distance_km', fromJson: toDouble) required this.distanceKm, @JsonKey(name: 'duration_seconds', fromJson: toInt) required this.durationSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) this.averagePaceSecondsPerKm, @JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) this.averageHeartRate, @JsonKey(name: 'matched_training_day_id') this.matchedTrainingDayId});
  factory _AvailableActivity.fromJson(Map<String, dynamic> json) => _$AvailableActivityFromJson(json);

@override@JsonKey(name: 'wearable_activity_id') final  int wearableActivityId;
@override final  String source;
@override final  String name;
@override@JsonKey(name: 'start_date') final  String? startDate;
@override@JsonKey(name: 'distance_km', fromJson: toDouble) final  double distanceKm;
@override@JsonKey(name: 'duration_seconds', fromJson: toInt) final  int durationSeconds;
@override@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) final  int? averagePaceSecondsPerKm;
@override@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) final  double? averageHeartRate;
/// Non-null if this run is already matched to a training day. Used to
/// render a "synced" badge and disable the row.
@override@JsonKey(name: 'matched_training_day_id') final  int? matchedTrainingDayId;

/// Create a copy of AvailableActivity
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AvailableActivityCopyWith<_AvailableActivity> get copyWith => __$AvailableActivityCopyWithImpl<_AvailableActivity>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$AvailableActivityToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AvailableActivity&&(identical(other.wearableActivityId, wearableActivityId) || other.wearableActivityId == wearableActivityId)&&(identical(other.source, source) || other.source == source)&&(identical(other.name, name) || other.name == name)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.distanceKm, distanceKm) || other.distanceKm == distanceKm)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartRate, averageHeartRate) || other.averageHeartRate == averageHeartRate)&&(identical(other.matchedTrainingDayId, matchedTrainingDayId) || other.matchedTrainingDayId == matchedTrainingDayId));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,wearableActivityId,source,name,startDate,distanceKm,durationSeconds,averagePaceSecondsPerKm,averageHeartRate,matchedTrainingDayId);

@override
String toString() {
  return 'AvailableActivity(wearableActivityId: $wearableActivityId, source: $source, name: $name, startDate: $startDate, distanceKm: $distanceKm, durationSeconds: $durationSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartRate: $averageHeartRate, matchedTrainingDayId: $matchedTrainingDayId)';
}


}

/// @nodoc
abstract mixin class _$AvailableActivityCopyWith<$Res> implements $AvailableActivityCopyWith<$Res> {
  factory _$AvailableActivityCopyWith(_AvailableActivity value, $Res Function(_AvailableActivity) _then) = __$AvailableActivityCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'wearable_activity_id') int wearableActivityId, String source, String name,@JsonKey(name: 'start_date') String? startDate,@JsonKey(name: 'distance_km', fromJson: toDouble) double distanceKm,@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toIntOrNull) int? averagePaceSecondsPerKm,@JsonKey(name: 'average_heart_rate', fromJson: toDoubleOrNull) double? averageHeartRate,@JsonKey(name: 'matched_training_day_id') int? matchedTrainingDayId
});




}
/// @nodoc
class __$AvailableActivityCopyWithImpl<$Res>
    implements _$AvailableActivityCopyWith<$Res> {
  __$AvailableActivityCopyWithImpl(this._self, this._then);

  final _AvailableActivity _self;
  final $Res Function(_AvailableActivity) _then;

/// Create a copy of AvailableActivity
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? wearableActivityId = null,Object? source = null,Object? name = null,Object? startDate = freezed,Object? distanceKm = null,Object? durationSeconds = null,Object? averagePaceSecondsPerKm = freezed,Object? averageHeartRate = freezed,Object? matchedTrainingDayId = freezed,}) {
  return _then(_AvailableActivity(
wearableActivityId: null == wearableActivityId ? _self.wearableActivityId : wearableActivityId // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,startDate: freezed == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String?,distanceKm: null == distanceKm ? _self.distanceKm : distanceKm // ignore: cast_nullable_to_non_nullable
as double,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,averagePaceSecondsPerKm: freezed == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,averageHeartRate: freezed == averageHeartRate ? _self.averageHeartRate : averageHeartRate // ignore: cast_nullable_to_non_nullable
as double?,matchedTrainingDayId: freezed == matchedTrainingDayId ? _self.matchedTrainingDayId : matchedTrainingDayId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
