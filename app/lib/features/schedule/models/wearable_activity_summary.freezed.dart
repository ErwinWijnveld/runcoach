// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wearable_activity_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WearableActivitySummary {

 int get id;/// Source provider: 'apple_health', 'strava', 'garmin', 'polar', etc.
 String get source;@JsonKey(name: 'source_activity_id') String get sourceActivityId; String get type; String? get name;@JsonKey(name: 'distance_meters', fromJson: toInt) int get distanceMeters;@JsonKey(name: 'duration_seconds', fromJson: toInt) int get durationSeconds;@JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull) int? get elapsedSeconds;@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt) int get averagePaceSecondsPerKm;@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? get averageHeartrate;@JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull) double? get maxHeartrate;@JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull) int? get elevationGainMeters;@JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) int? get caloriesKcal;@JsonKey(name: 'start_date') String get startDate;@JsonKey(name: 'end_date') String? get endDate;
/// Create a copy of WearableActivitySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WearableActivitySummaryCopyWith<WearableActivitySummary> get copyWith => _$WearableActivitySummaryCopyWithImpl<WearableActivitySummary>(this as WearableActivitySummary, _$identity);

  /// Serializes this WearableActivitySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WearableActivitySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceActivityId, sourceActivityId) || other.sourceActivityId == sourceActivityId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartrate, averageHeartrate) || other.averageHeartrate == averageHeartrate)&&(identical(other.maxHeartrate, maxHeartrate) || other.maxHeartrate == maxHeartrate)&&(identical(other.elevationGainMeters, elevationGainMeters) || other.elevationGainMeters == elevationGainMeters)&&(identical(other.caloriesKcal, caloriesKcal) || other.caloriesKcal == caloriesKcal)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,source,sourceActivityId,type,name,distanceMeters,durationSeconds,elapsedSeconds,averagePaceSecondsPerKm,averageHeartrate,maxHeartrate,elevationGainMeters,caloriesKcal,startDate,endDate);

@override
String toString() {
  return 'WearableActivitySummary(id: $id, source: $source, sourceActivityId: $sourceActivityId, type: $type, name: $name, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, elapsedSeconds: $elapsedSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartrate: $averageHeartrate, maxHeartrate: $maxHeartrate, elevationGainMeters: $elevationGainMeters, caloriesKcal: $caloriesKcal, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class $WearableActivitySummaryCopyWith<$Res>  {
  factory $WearableActivitySummaryCopyWith(WearableActivitySummary value, $Res Function(WearableActivitySummary) _then) = _$WearableActivitySummaryCopyWithImpl;
@useResult
$Res call({
 int id, String source,@JsonKey(name: 'source_activity_id') String sourceActivityId, String type, String? name,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters,@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull) int? elapsedSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt) int averagePaceSecondsPerKm,@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? averageHeartrate,@JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull) double? maxHeartrate,@JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull) int? elevationGainMeters,@JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) int? caloriesKcal,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate
});




}
/// @nodoc
class _$WearableActivitySummaryCopyWithImpl<$Res>
    implements $WearableActivitySummaryCopyWith<$Res> {
  _$WearableActivitySummaryCopyWithImpl(this._self, this._then);

  final WearableActivitySummary _self;
  final $Res Function(WearableActivitySummary) _then;

/// Create a copy of WearableActivitySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? source = null,Object? sourceActivityId = null,Object? type = null,Object? name = freezed,Object? distanceMeters = null,Object? durationSeconds = null,Object? elapsedSeconds = freezed,Object? averagePaceSecondsPerKm = null,Object? averageHeartrate = freezed,Object? maxHeartrate = freezed,Object? elevationGainMeters = freezed,Object? caloriesKcal = freezed,Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceActivityId: null == sourceActivityId ? _self.sourceActivityId : sourceActivityId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,averagePaceSecondsPerKm: null == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int,averageHeartrate: freezed == averageHeartrate ? _self.averageHeartrate : averageHeartrate // ignore: cast_nullable_to_non_nullable
as double?,maxHeartrate: freezed == maxHeartrate ? _self.maxHeartrate : maxHeartrate // ignore: cast_nullable_to_non_nullable
as double?,elevationGainMeters: freezed == elevationGainMeters ? _self.elevationGainMeters : elevationGainMeters // ignore: cast_nullable_to_non_nullable
as int?,caloriesKcal: freezed == caloriesKcal ? _self.caloriesKcal : caloriesKcal // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WearableActivitySummary].
extension WearableActivitySummaryPatterns on WearableActivitySummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WearableActivitySummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WearableActivitySummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WearableActivitySummary value)  $default,){
final _that = this;
switch (_that) {
case _WearableActivitySummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WearableActivitySummary value)?  $default,){
final _that = this;
switch (_that) {
case _WearableActivitySummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String source, @JsonKey(name: 'source_activity_id')  String sourceActivityId,  String type,  String? name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull)  int? elapsedSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt)  int averagePaceSecondsPerKm, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull)  double? maxHeartrate, @JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull)  int? elevationGainMeters, @JsonKey(name: 'calories_kcal', fromJson: toIntOrNull)  int? caloriesKcal, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WearableActivitySummary() when $default != null:
return $default(_that.id,_that.source,_that.sourceActivityId,_that.type,_that.name,_that.distanceMeters,_that.durationSeconds,_that.elapsedSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartrate,_that.maxHeartrate,_that.elevationGainMeters,_that.caloriesKcal,_that.startDate,_that.endDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String source, @JsonKey(name: 'source_activity_id')  String sourceActivityId,  String type,  String? name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull)  int? elapsedSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt)  int averagePaceSecondsPerKm, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull)  double? maxHeartrate, @JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull)  int? elevationGainMeters, @JsonKey(name: 'calories_kcal', fromJson: toIntOrNull)  int? caloriesKcal, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)  $default,) {final _that = this;
switch (_that) {
case _WearableActivitySummary():
return $default(_that.id,_that.source,_that.sourceActivityId,_that.type,_that.name,_that.distanceMeters,_that.durationSeconds,_that.elapsedSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartrate,_that.maxHeartrate,_that.elevationGainMeters,_that.caloriesKcal,_that.startDate,_that.endDate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String source, @JsonKey(name: 'source_activity_id')  String sourceActivityId,  String type,  String? name, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters, @JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull)  int? elapsedSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt)  int averagePaceSecondsPerKm, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull)  double? averageHeartrate, @JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull)  double? maxHeartrate, @JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull)  int? elevationGainMeters, @JsonKey(name: 'calories_kcal', fromJson: toIntOrNull)  int? caloriesKcal, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String? endDate)?  $default,) {final _that = this;
switch (_that) {
case _WearableActivitySummary() when $default != null:
return $default(_that.id,_that.source,_that.sourceActivityId,_that.type,_that.name,_that.distanceMeters,_that.durationSeconds,_that.elapsedSeconds,_that.averagePaceSecondsPerKm,_that.averageHeartrate,_that.maxHeartrate,_that.elevationGainMeters,_that.caloriesKcal,_that.startDate,_that.endDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WearableActivitySummary implements WearableActivitySummary {
  const _WearableActivitySummary({required this.id, required this.source, @JsonKey(name: 'source_activity_id') required this.sourceActivityId, required this.type, this.name, @JsonKey(name: 'distance_meters', fromJson: toInt) required this.distanceMeters, @JsonKey(name: 'duration_seconds', fromJson: toInt) required this.durationSeconds, @JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull) this.elapsedSeconds, @JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt) required this.averagePaceSecondsPerKm, @JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) this.averageHeartrate, @JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull) this.maxHeartrate, @JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull) this.elevationGainMeters, @JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) this.caloriesKcal, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') this.endDate});
  factory _WearableActivitySummary.fromJson(Map<String, dynamic> json) => _$WearableActivitySummaryFromJson(json);

@override final  int id;
/// Source provider: 'apple_health', 'strava', 'garmin', 'polar', etc.
@override final  String source;
@override@JsonKey(name: 'source_activity_id') final  String sourceActivityId;
@override final  String type;
@override final  String? name;
@override@JsonKey(name: 'distance_meters', fromJson: toInt) final  int distanceMeters;
@override@JsonKey(name: 'duration_seconds', fromJson: toInt) final  int durationSeconds;
@override@JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull) final  int? elapsedSeconds;
@override@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt) final  int averagePaceSecondsPerKm;
@override@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) final  double? averageHeartrate;
@override@JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull) final  double? maxHeartrate;
@override@JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull) final  int? elevationGainMeters;
@override@JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) final  int? caloriesKcal;
@override@JsonKey(name: 'start_date') final  String startDate;
@override@JsonKey(name: 'end_date') final  String? endDate;

/// Create a copy of WearableActivitySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WearableActivitySummaryCopyWith<_WearableActivitySummary> get copyWith => __$WearableActivitySummaryCopyWithImpl<_WearableActivitySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WearableActivitySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WearableActivitySummary&&(identical(other.id, id) || other.id == id)&&(identical(other.source, source) || other.source == source)&&(identical(other.sourceActivityId, sourceActivityId) || other.sourceActivityId == sourceActivityId)&&(identical(other.type, type) || other.type == type)&&(identical(other.name, name) || other.name == name)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.elapsedSeconds, elapsedSeconds) || other.elapsedSeconds == elapsedSeconds)&&(identical(other.averagePaceSecondsPerKm, averagePaceSecondsPerKm) || other.averagePaceSecondsPerKm == averagePaceSecondsPerKm)&&(identical(other.averageHeartrate, averageHeartrate) || other.averageHeartrate == averageHeartrate)&&(identical(other.maxHeartrate, maxHeartrate) || other.maxHeartrate == maxHeartrate)&&(identical(other.elevationGainMeters, elevationGainMeters) || other.elevationGainMeters == elevationGainMeters)&&(identical(other.caloriesKcal, caloriesKcal) || other.caloriesKcal == caloriesKcal)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,source,sourceActivityId,type,name,distanceMeters,durationSeconds,elapsedSeconds,averagePaceSecondsPerKm,averageHeartrate,maxHeartrate,elevationGainMeters,caloriesKcal,startDate,endDate);

@override
String toString() {
  return 'WearableActivitySummary(id: $id, source: $source, sourceActivityId: $sourceActivityId, type: $type, name: $name, distanceMeters: $distanceMeters, durationSeconds: $durationSeconds, elapsedSeconds: $elapsedSeconds, averagePaceSecondsPerKm: $averagePaceSecondsPerKm, averageHeartrate: $averageHeartrate, maxHeartrate: $maxHeartrate, elevationGainMeters: $elevationGainMeters, caloriesKcal: $caloriesKcal, startDate: $startDate, endDate: $endDate)';
}


}

/// @nodoc
abstract mixin class _$WearableActivitySummaryCopyWith<$Res> implements $WearableActivitySummaryCopyWith<$Res> {
  factory _$WearableActivitySummaryCopyWith(_WearableActivitySummary value, $Res Function(_WearableActivitySummary) _then) = __$WearableActivitySummaryCopyWithImpl;
@override @useResult
$Res call({
 int id, String source,@JsonKey(name: 'source_activity_id') String sourceActivityId, String type, String? name,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters,@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'elapsed_seconds', fromJson: toIntOrNull) int? elapsedSeconds,@JsonKey(name: 'average_pace_seconds_per_km', fromJson: toInt) int averagePaceSecondsPerKm,@JsonKey(name: 'average_heartrate', fromJson: toDoubleOrNull) double? averageHeartrate,@JsonKey(name: 'max_heartrate', fromJson: toDoubleOrNull) double? maxHeartrate,@JsonKey(name: 'elevation_gain_meters', fromJson: toIntOrNull) int? elevationGainMeters,@JsonKey(name: 'calories_kcal', fromJson: toIntOrNull) int? caloriesKcal,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String? endDate
});




}
/// @nodoc
class __$WearableActivitySummaryCopyWithImpl<$Res>
    implements _$WearableActivitySummaryCopyWith<$Res> {
  __$WearableActivitySummaryCopyWithImpl(this._self, this._then);

  final _WearableActivitySummary _self;
  final $Res Function(_WearableActivitySummary) _then;

/// Create a copy of WearableActivitySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? source = null,Object? sourceActivityId = null,Object? type = null,Object? name = freezed,Object? distanceMeters = null,Object? durationSeconds = null,Object? elapsedSeconds = freezed,Object? averagePaceSecondsPerKm = null,Object? averageHeartrate = freezed,Object? maxHeartrate = freezed,Object? elevationGainMeters = freezed,Object? caloriesKcal = freezed,Object? startDate = null,Object? endDate = freezed,}) {
  return _then(_WearableActivitySummary(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,sourceActivityId: null == sourceActivityId ? _self.sourceActivityId : sourceActivityId // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,name: freezed == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String?,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,elapsedSeconds: freezed == elapsedSeconds ? _self.elapsedSeconds : elapsedSeconds // ignore: cast_nullable_to_non_nullable
as int?,averagePaceSecondsPerKm: null == averagePaceSecondsPerKm ? _self.averagePaceSecondsPerKm : averagePaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int,averageHeartrate: freezed == averageHeartrate ? _self.averageHeartrate : averageHeartrate // ignore: cast_nullable_to_non_nullable
as double?,maxHeartrate: freezed == maxHeartrate ? _self.maxHeartrate : maxHeartrate // ignore: cast_nullable_to_non_nullable
as double?,elevationGainMeters: freezed == elevationGainMeters ? _self.elevationGainMeters : elevationGainMeters // ignore: cast_nullable_to_non_nullable
as int?,caloriesKcal: freezed == caloriesKcal ? _self.caloriesKcal : caloriesKcal // ignore: cast_nullable_to_non_nullable
as int?,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: freezed == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
