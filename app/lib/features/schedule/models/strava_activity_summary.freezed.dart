// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'strava_activity_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StravaActivitySummary {

 int get id;@JsonKey(name: 'strava_id', fromJson: toInt) int get stravaId; String get type; String get name;@JsonKey(name: 'distance_meters', fromJson: toInt) int get distanceMeters;@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int get movingTimeSeconds;@JsonKey(name: 'elapsed_time_seconds', fromJson: toInt) int get elapsedTimeSeconds;@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? get averageHeartrate;@JsonKey(name: 'average_speed', fromJson: toDoubleOrNull) double? get averageSpeed;@JsonKey(name: 'start_date') String get startDate;@JsonKey(name: 'summary_polyline') String? get summaryPolyline;
/// Create a copy of StravaActivitySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StravaActivitySummaryCopyWith<StravaActivitySummary> get copyWith => _$StravaActivitySummaryCopyWithImpl<StravaActivitySummary>(this as StravaActivitySummary, _$identity);

  /// Serializes this StravaActivitySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StravaActivitySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.stravaId, stravaId) || other.stravaId == stravaId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.movingTimeSeconds, movingTimeSeconds) || other.movingTimeSeconds == movingTimeSeconds)&&(identical(other.elapsedTimeSeconds, elapsedTimeSeconds) || other.elapsedTimeSeconds == elapsedTimeSeconds)&&(identical(other.averageHeartrate, averageHeartrate) || other.averageHeartrate == averageHeartrate)&&(identical(other.averageSpeed, averageSpeed) || other.averageSpeed == averageSpeed)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.summaryPolyline, summaryPolyline) || other.summaryPolyline == summaryPolyline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stravaId,type,name,distanceMeters,movingTimeSeconds,elapsedTimeSeconds,averageHeartrate,averageSpeed,startDate,summaryPolyline);

@override
String toString() {
  return 'StravaActivitySummary(id: $id, stravaId: $stravaId, type: $type, name: $name, distanceMeters: $distanceMeters, movingTimeSeconds: $movingTimeSeconds, elapsedTimeSeconds: $elapsedTimeSeconds, averageHeartrate: $averageHeartrate, averageSpeed: $averageSpeed, startDate: $startDate, summaryPolyline: $summaryPolyline)';
}


}

/// @nodoc
abstract mixin class $StravaActivitySummaryCopyWith<$Res>  {
  factory $StravaActivitySummaryCopyWith(StravaActivitySummary value, $Res Function(StravaActivitySummary) _then) = _$StravaActivitySummaryCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'strava_id', fromJson: toInt) int stravaId, String type, String name,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters,@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int movingTimeSeconds,@JsonKey(name: 'elapsed_time_seconds', fromJson: toInt) int elapsedTimeSeconds,@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? averageHeartrate,@JsonKey(name: 'average_speed', fromJson: toDoubleOrNull) double? averageSpeed,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'summary_polyline') String? summaryPolyline
});




}
/// @nodoc
class _$StravaActivitySummaryCopyWithImpl<$Res>
    implements $StravaActivitySummaryCopyWith<$Res> {
  _$StravaActivitySummaryCopyWithImpl(this._self, this._then);

  final StravaActivitySummary _self;
  final $Res Function(StravaActivitySummary) _then;

/// Create a copy of StravaActivitySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? stravaId = null,Object? type = null,Object? name = null,Object? distanceMeters = null,Object? movingTimeSeconds = null,Object? elapsedTimeSeconds = null,Object? averageHeartrate = freezed,Object? averageSpeed = freezed,Object? startDate = null,Object? summaryPolyline = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stravaId: null == stravaId ? _self.stravaId : stravaId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,movingTimeSeconds: null == movingTimeSeconds ? _self.movingTimeSeconds : movingTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedTimeSeconds: null == elapsedTimeSeconds ? _self.elapsedTimeSeconds : elapsedTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,averageHeartrate: freezed == averageHeartrate ? _self.averageHeartrate : averageHeartrate // ignore: cast_nullable_to_non_nullable
as double?,averageSpeed: freezed == averageSpeed ? _self.averageSpeed : averageSpeed // ignore: cast_nullable_to_non_nullable
as double?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,summaryPolyline: freezed == summaryPolyline ? _self.summaryPolyline : summaryPolyline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [StravaActivitySummary].
extension StravaActivitySummaryPatterns on StravaActivitySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StravaActivitySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StravaActivitySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StravaActivitySummary value)  $default,){
final _that = this;
switch (_that) {
case _StravaActivitySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StravaActivitySummary value)?  $default,){
final _that = this;
switch (_that) {
case _StravaActivitySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'strava_id', fromJson: toInt)  int stravaId,  String type,  String name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'elapsed_time_seconds', fromJson: toInt)  int elapsedTimeSeconds, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'average_speed', fromJson: toDoubleOrNull)  double? averageSpeed, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'summary_polyline')  String? summaryPolyline)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StravaActivitySummary() when $default != null:
return $default(_that.id,_that.stravaId,_that.type,_that.name,_that.distanceMeters,_that.movingTimeSeconds,_that.elapsedTimeSeconds,_that.averageHeartrate,_that.averageSpeed,_that.startDate,_that.summaryPolyline);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'strava_id', fromJson: toInt)  int stravaId,  String type,  String name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'elapsed_time_seconds', fromJson: toInt)  int elapsedTimeSeconds, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'average_speed', fromJson: toDoubleOrNull)  double? averageSpeed, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'summary_polyline')  String? summaryPolyline)  $default,) {final _that = this;
switch (_that) {
case _StravaActivitySummary():
return $default(_that.id,_that.stravaId,_that.type,_that.name,_that.distanceMeters,_that.movingTimeSeconds,_that.elapsedTimeSeconds,_that.averageHeartrate,_that.averageSpeed,_that.startDate,_that.summaryPolyline);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'strava_id', fromJson: toInt)  int stravaId,  String type,  String name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'moving_time_seconds', fromJson: toInt)  int movingTimeSeconds, @JsonKey(name: 'elapsed_time_seconds', fromJson: toInt)  int elapsedTimeSeconds, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'average_speed', fromJson: toDoubleOrNull)  double? averageSpeed, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'summary_polyline')  String? summaryPolyline)?  $default,) {final _that = this;
switch (_that) {
case _StravaActivitySummary() when $default != null:
return $default(_that.id,_that.stravaId,_that.type,_that.name,_that.distanceMeters,_that.movingTimeSeconds,_that.elapsedTimeSeconds,_that.averageHeartrate,_that.averageSpeed,_that.startDate,_that.summaryPolyline);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StravaActivitySummary implements StravaActivitySummary {
  const _StravaActivitySummary({required this.id, @JsonKey(name: 'strava_id', fromJson: toInt) required this.stravaId, required this.type, required this.name, @JsonKey(name: 'distance_meters', fromJson: toInt) required this.distanceMeters, @JsonKey(name: 'moving_time_seconds', fromJson: toInt) required this.movingTimeSeconds, @JsonKey(name: 'elapsed_time_seconds', fromJson: toInt) required this.elapsedTimeSeconds, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) this.averageHeartrate, @JsonKey(name: 'average_speed', fromJson: toDoubleOrNull) this.averageSpeed, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'summary_polyline') this.summaryPolyline});
  factory _StravaActivitySummary.fromJson(Map<String, dynamic> json) => _$StravaActivitySummaryFromJson(json);

@override final  int id;
@override@JsonKey(name: 'strava_id', fromJson: toInt) final  int stravaId;
@override final  String type;
@override final  String name;
@override@JsonKey(name: 'distance_meters', fromJson: toInt) final  int distanceMeters;
@override@JsonKey(name: 'moving_time_seconds', fromJson: toInt) final  int movingTimeSeconds;
@override@JsonKey(name: 'elapsed_time_seconds', fromJson: toInt) final  int elapsedTimeSeconds;
@override@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) final  double? averageHeartrate;
@override@JsonKey(name: 'average_speed', fromJson: toDoubleOrNull) final  double? averageSpeed;
@override@JsonKey(name: 'start_date') final  String startDate;
@override@JsonKey(name: 'summary_polyline') final  String? summaryPolyline;

/// Create a copy of StravaActivitySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StravaActivitySummaryCopyWith<_StravaActivitySummary> get copyWith => __$StravaActivitySummaryCopyWithImpl<_StravaActivitySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StravaActivitySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StravaActivitySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.stravaId, stravaId) || other.stravaId == stravaId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.movingTimeSeconds, movingTimeSeconds) || other.movingTimeSeconds == movingTimeSeconds)&&(identical(other.elapsedTimeSeconds, elapsedTimeSeconds) || other.elapsedTimeSeconds == elapsedTimeSeconds)&&(identical(other.averageHeartrate, averageHeartrate) || other.averageHeartrate == averageHeartrate)&&(identical(other.averageSpeed, averageSpeed) || other.averageSpeed == averageSpeed)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.summaryPolyline, summaryPolyline) || other.summaryPolyline == summaryPolyline));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,stravaId,type,name,distanceMeters,movingTimeSeconds,elapsedTimeSeconds,averageHeartrate,averageSpeed,startDate,summaryPolyline);

@override
String toString() {
  return 'StravaActivitySummary(id: $id, stravaId: $stravaId, type: $type, name: $name, distanceMeters: $distanceMeters, movingTimeSeconds: $movingTimeSeconds, elapsedTimeSeconds: $elapsedTimeSeconds, averageHeartrate: $averageHeartrate, averageSpeed: $averageSpeed, startDate: $startDate, summaryPolyline: $summaryPolyline)';
}


}

/// @nodoc
abstract mixin class _$StravaActivitySummaryCopyWith<$Res> implements $StravaActivitySummaryCopyWith<$Res> {
  factory _$StravaActivitySummaryCopyWith(_StravaActivitySummary value, $Res Function(_StravaActivitySummary) _then) = __$StravaActivitySummaryCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'strava_id', fromJson: toInt) int stravaId, String type, String name,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters,@JsonKey(name: 'moving_time_seconds', fromJson: toInt) int movingTimeSeconds,@JsonKey(name: 'elapsed_time_seconds', fromJson: toInt) int elapsedTimeSeconds,@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? averageHeartrate,@JsonKey(name: 'average_speed', fromJson: toDoubleOrNull) double? averageSpeed,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'summary_polyline') String? summaryPolyline
});




}
/// @nodoc
class __$StravaActivitySummaryCopyWithImpl<$Res>
    implements _$StravaActivitySummaryCopyWith<$Res> {
  __$StravaActivitySummaryCopyWithImpl(this._self, this._then);

  final _StravaActivitySummary _self;
  final $Res Function(_StravaActivitySummary) _then;

/// Create a copy of StravaActivitySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? stravaId = null,Object? type = null,Object? name = null,Object? distanceMeters = null,Object? movingTimeSeconds = null,Object? elapsedTimeSeconds = null,Object? averageHeartrate = freezed,Object? averageSpeed = freezed,Object? startDate = null,Object? summaryPolyline = freezed,}) {
  return _then(_StravaActivitySummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,stravaId: null == stravaId ? _self.stravaId : stravaId // ignore: cast_nullable_to_non_nullable
as int,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,movingTimeSeconds: null == movingTimeSeconds ? _self.movingTimeSeconds : movingTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedTimeSeconds: null == elapsedTimeSeconds ? _self.elapsedTimeSeconds : elapsedTimeSeconds // ignore: cast_nullable_to_non_nullable
as int,averageHeartrate: freezed == averageHeartrate ? _self.averageHeartrate : averageHeartrate // ignore: cast_nullable_to_non_nullable
as double?,averageSpeed: freezed == averageSpeed ? _self.averageSpeed : averageSpeed // ignore: cast_nullable_to_non_nullable
as double?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,summaryPolyline: freezed == summaryPolyline ? _self.summaryPolyline : summaryPolyline // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
