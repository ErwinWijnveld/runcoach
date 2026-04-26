// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_profile.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OnboardingProfileMetrics {

@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) double? get weeklyAvgKm;@JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) double? get weeklyAvgRuns;@JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) int? get avgPaceSecondsPerKm;@JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) int? get sessionAvgDurationSeconds;
/// Create a copy of OnboardingProfileMetrics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingProfileMetricsCopyWith<OnboardingProfileMetrics> get copyWith => _$OnboardingProfileMetricsCopyWithImpl<OnboardingProfileMetrics>(this as OnboardingProfileMetrics, _$identity);

  /// Serializes this OnboardingProfileMetrics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingProfileMetrics&&(identical(other.weeklyAvgKm, weeklyAvgKm) || other.weeklyAvgKm == weeklyAvgKm)&&(identical(other.weeklyAvgRuns, weeklyAvgRuns) || other.weeklyAvgRuns == weeklyAvgRuns)&&(identical(other.avgPaceSecondsPerKm, avgPaceSecondsPerKm) || other.avgPaceSecondsPerKm == avgPaceSecondsPerKm)&&(identical(other.sessionAvgDurationSeconds, sessionAvgDurationSeconds) || other.sessionAvgDurationSeconds == sessionAvgDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklyAvgKm,weeklyAvgRuns,avgPaceSecondsPerKm,sessionAvgDurationSeconds);

@override
String toString() {
  return 'OnboardingProfileMetrics(weeklyAvgKm: $weeklyAvgKm, weeklyAvgRuns: $weeklyAvgRuns, avgPaceSecondsPerKm: $avgPaceSecondsPerKm, sessionAvgDurationSeconds: $sessionAvgDurationSeconds)';
}


}

/// @nodoc
abstract mixin class $OnboardingProfileMetricsCopyWith<$Res>  {
  factory $OnboardingProfileMetricsCopyWith(OnboardingProfileMetrics value, $Res Function(OnboardingProfileMetrics) _then) = _$OnboardingProfileMetricsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) double? weeklyAvgKm,@JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) double? weeklyAvgRuns,@JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) int? avgPaceSecondsPerKm,@JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) int? sessionAvgDurationSeconds
});




}
/// @nodoc
class _$OnboardingProfileMetricsCopyWithImpl<$Res>
    implements $OnboardingProfileMetricsCopyWith<$Res> {
  _$OnboardingProfileMetricsCopyWithImpl(this._self, this._then);

  final OnboardingProfileMetrics _self;
  final $Res Function(OnboardingProfileMetrics) _then;

/// Create a copy of OnboardingProfileMetrics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weeklyAvgKm = freezed,Object? weeklyAvgRuns = freezed,Object? avgPaceSecondsPerKm = freezed,Object? sessionAvgDurationSeconds = freezed,}) {
  return _then(_self.copyWith(
weeklyAvgKm: freezed == weeklyAvgKm ? _self.weeklyAvgKm : weeklyAvgKm // ignore: cast_nullable_to_non_nullable
as double?,weeklyAvgRuns: freezed == weeklyAvgRuns ? _self.weeklyAvgRuns : weeklyAvgRuns // ignore: cast_nullable_to_non_nullable
as double?,avgPaceSecondsPerKm: freezed == avgPaceSecondsPerKm ? _self.avgPaceSecondsPerKm : avgPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,sessionAvgDurationSeconds: freezed == sessionAvgDurationSeconds ? _self.sessionAvgDurationSeconds : sessionAvgDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [OnboardingProfileMetrics].
extension OnboardingProfileMetricsPatterns on OnboardingProfileMetrics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingProfileMetrics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingProfileMetrics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingProfileMetrics value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingProfileMetrics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingProfileMetrics value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingProfileMetrics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull)  double? weeklyAvgKm, @JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull)  double? weeklyAvgRuns, @JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull)  int? avgPaceSecondsPerKm, @JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull)  int? sessionAvgDurationSeconds)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingProfileMetrics() when $default != null:
return $default(_that.weeklyAvgKm,_that.weeklyAvgRuns,_that.avgPaceSecondsPerKm,_that.sessionAvgDurationSeconds);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull)  double? weeklyAvgKm, @JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull)  double? weeklyAvgRuns, @JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull)  int? avgPaceSecondsPerKm, @JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull)  int? sessionAvgDurationSeconds)  $default,) {final _that = this;
switch (_that) {
case _OnboardingProfileMetrics():
return $default(_that.weeklyAvgKm,_that.weeklyAvgRuns,_that.avgPaceSecondsPerKm,_that.sessionAvgDurationSeconds);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull)  double? weeklyAvgKm, @JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull)  double? weeklyAvgRuns, @JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull)  int? avgPaceSecondsPerKm, @JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull)  int? sessionAvgDurationSeconds)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingProfileMetrics() when $default != null:
return $default(_that.weeklyAvgKm,_that.weeklyAvgRuns,_that.avgPaceSecondsPerKm,_that.sessionAvgDurationSeconds);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OnboardingProfileMetrics implements OnboardingProfileMetrics {
  const _OnboardingProfileMetrics({@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) this.weeklyAvgKm, @JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) this.weeklyAvgRuns, @JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) this.avgPaceSecondsPerKm, @JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) this.sessionAvgDurationSeconds});
  factory _OnboardingProfileMetrics.fromJson(Map<String, dynamic> json) => _$OnboardingProfileMetricsFromJson(json);

@override@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) final  double? weeklyAvgKm;
@override@JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) final  double? weeklyAvgRuns;
@override@JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) final  int? avgPaceSecondsPerKm;
@override@JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) final  int? sessionAvgDurationSeconds;

/// Create a copy of OnboardingProfileMetrics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingProfileMetricsCopyWith<_OnboardingProfileMetrics> get copyWith => __$OnboardingProfileMetricsCopyWithImpl<_OnboardingProfileMetrics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnboardingProfileMetricsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingProfileMetrics&&(identical(other.weeklyAvgKm, weeklyAvgKm) || other.weeklyAvgKm == weeklyAvgKm)&&(identical(other.weeklyAvgRuns, weeklyAvgRuns) || other.weeklyAvgRuns == weeklyAvgRuns)&&(identical(other.avgPaceSecondsPerKm, avgPaceSecondsPerKm) || other.avgPaceSecondsPerKm == avgPaceSecondsPerKm)&&(identical(other.sessionAvgDurationSeconds, sessionAvgDurationSeconds) || other.sessionAvgDurationSeconds == sessionAvgDurationSeconds));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklyAvgKm,weeklyAvgRuns,avgPaceSecondsPerKm,sessionAvgDurationSeconds);

@override
String toString() {
  return 'OnboardingProfileMetrics(weeklyAvgKm: $weeklyAvgKm, weeklyAvgRuns: $weeklyAvgRuns, avgPaceSecondsPerKm: $avgPaceSecondsPerKm, sessionAvgDurationSeconds: $sessionAvgDurationSeconds)';
}


}

/// @nodoc
abstract mixin class _$OnboardingProfileMetricsCopyWith<$Res> implements $OnboardingProfileMetricsCopyWith<$Res> {
  factory _$OnboardingProfileMetricsCopyWith(_OnboardingProfileMetrics value, $Res Function(_OnboardingProfileMetrics) _then) = __$OnboardingProfileMetricsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'weekly_avg_km', fromJson: toDoubleOrNull) double? weeklyAvgKm,@JsonKey(name: 'weekly_avg_runs', fromJson: toDoubleOrNull) double? weeklyAvgRuns,@JsonKey(name: 'avg_pace_seconds_per_km', fromJson: toIntOrNull) int? avgPaceSecondsPerKm,@JsonKey(name: 'session_avg_duration_seconds', fromJson: toIntOrNull) int? sessionAvgDurationSeconds
});




}
/// @nodoc
class __$OnboardingProfileMetricsCopyWithImpl<$Res>
    implements _$OnboardingProfileMetricsCopyWith<$Res> {
  __$OnboardingProfileMetricsCopyWithImpl(this._self, this._then);

  final _OnboardingProfileMetrics _self;
  final $Res Function(_OnboardingProfileMetrics) _then;

/// Create a copy of OnboardingProfileMetrics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weeklyAvgKm = freezed,Object? weeklyAvgRuns = freezed,Object? avgPaceSecondsPerKm = freezed,Object? sessionAvgDurationSeconds = freezed,}) {
  return _then(_OnboardingProfileMetrics(
weeklyAvgKm: freezed == weeklyAvgKm ? _self.weeklyAvgKm : weeklyAvgKm // ignore: cast_nullable_to_non_nullable
as double?,weeklyAvgRuns: freezed == weeklyAvgRuns ? _self.weeklyAvgRuns : weeklyAvgRuns // ignore: cast_nullable_to_non_nullable
as double?,avgPaceSecondsPerKm: freezed == avgPaceSecondsPerKm ? _self.avgPaceSecondsPerKm : avgPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,sessionAvgDurationSeconds: freezed == sessionAvgDurationSeconds ? _self.sessionAvgDurationSeconds : sessionAvgDurationSeconds // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$PersonalRecord {

@JsonKey(name: 'duration_seconds', fromJson: toInt) int get durationSeconds;@JsonKey(name: 'distance_meters', fromJson: toInt) int get distanceMeters; String? get date;
/// Create a copy of PersonalRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PersonalRecordCopyWith<PersonalRecord> get copyWith => _$PersonalRecordCopyWithImpl<PersonalRecord>(this as PersonalRecord, _$identity);

  /// Serializes this PersonalRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PersonalRecord&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationSeconds,distanceMeters,date);

@override
String toString() {
  return 'PersonalRecord(durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, date: $date)';
}


}

/// @nodoc
abstract mixin class $PersonalRecordCopyWith<$Res>  {
  factory $PersonalRecordCopyWith(PersonalRecord value, $Res Function(PersonalRecord) _then) = _$PersonalRecordCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters, String? date
});




}
/// @nodoc
class _$PersonalRecordCopyWithImpl<$Res>
    implements $PersonalRecordCopyWith<$Res> {
  _$PersonalRecordCopyWithImpl(this._self, this._then);

  final PersonalRecord _self;
  final $Res Function(PersonalRecord) _then;

/// Create a copy of PersonalRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? durationSeconds = null,Object? distanceMeters = null,Object? date = freezed,}) {
  return _then(_self.copyWith(
durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [PersonalRecord].
extension PersonalRecordPatterns on PersonalRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PersonalRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PersonalRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PersonalRecord value)  $default,){
final _that = this;
switch (_that) {
case _PersonalRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PersonalRecord value)?  $default,){
final _that = this;
switch (_that) {
case _PersonalRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters,  String? date)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PersonalRecord() when $default != null:
return $default(_that.durationSeconds,_that.distanceMeters,_that.date);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters,  String? date)  $default,) {final _that = this;
switch (_that) {
case _PersonalRecord():
return $default(_that.durationSeconds,_that.distanceMeters,_that.date);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'duration_seconds', fromJson: toInt)  int durationSeconds, @JsonKey(name: 'distance_meters', fromJson: toInt)  int distanceMeters,  String? date)?  $default,) {final _that = this;
switch (_that) {
case _PersonalRecord() when $default != null:
return $default(_that.durationSeconds,_that.distanceMeters,_that.date);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PersonalRecord implements PersonalRecord {
  const _PersonalRecord({@JsonKey(name: 'duration_seconds', fromJson: toInt) required this.durationSeconds, @JsonKey(name: 'distance_meters', fromJson: toInt) required this.distanceMeters, this.date});
  factory _PersonalRecord.fromJson(Map<String, dynamic> json) => _$PersonalRecordFromJson(json);

@override@JsonKey(name: 'duration_seconds', fromJson: toInt) final  int durationSeconds;
@override@JsonKey(name: 'distance_meters', fromJson: toInt) final  int distanceMeters;
@override final  String? date;

/// Create a copy of PersonalRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PersonalRecordCopyWith<_PersonalRecord> get copyWith => __$PersonalRecordCopyWithImpl<_PersonalRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PersonalRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PersonalRecord&&(identical(other.durationSeconds, durationSeconds) || other.durationSeconds == durationSeconds)&&(identical(other.distanceMeters, distanceMeters) || other.distanceMeters == distanceMeters)&&(identical(other.date, date) || other.date == date));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,durationSeconds,distanceMeters,date);

@override
String toString() {
  return 'PersonalRecord(durationSeconds: $durationSeconds, distanceMeters: $distanceMeters, date: $date)';
}


}

/// @nodoc
abstract mixin class _$PersonalRecordCopyWith<$Res> implements $PersonalRecordCopyWith<$Res> {
  factory _$PersonalRecordCopyWith(_PersonalRecord value, $Res Function(_PersonalRecord) _then) = __$PersonalRecordCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'duration_seconds', fromJson: toInt) int durationSeconds,@JsonKey(name: 'distance_meters', fromJson: toInt) int distanceMeters, String? date
});




}
/// @nodoc
class __$PersonalRecordCopyWithImpl<$Res>
    implements _$PersonalRecordCopyWith<$Res> {
  __$PersonalRecordCopyWithImpl(this._self, this._then);

  final _PersonalRecord _self;
  final $Res Function(_PersonalRecord) _then;

/// Create a copy of PersonalRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? durationSeconds = null,Object? distanceMeters = null,Object? date = freezed,}) {
  return _then(_PersonalRecord(
durationSeconds: null == durationSeconds ? _self.durationSeconds : durationSeconds // ignore: cast_nullable_to_non_nullable
as int,distanceMeters: null == distanceMeters ? _self.distanceMeters : distanceMeters // ignore: cast_nullable_to_non_nullable
as int,date: freezed == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$OnboardingProfile {

 String get status;// 'ready' | 'syncing'
 OnboardingProfileMetrics? get metrics;@JsonKey(name: 'narrative_summary') String? get narrativeSummary;@JsonKey(name: 'analyzed_at') DateTime? get analyzedAt;/// All-time PRs keyed by '5k' | '10k' | 'half' | 'marathon'. Map values
/// can be null when no qualifying workout exists for that distance.
@JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? get personalRecords;
/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingProfileCopyWith<OnboardingProfile> get copyWith => _$OnboardingProfileCopyWithImpl<OnboardingProfile>(this as OnboardingProfile, _$identity);

  /// Serializes this OnboardingProfile to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingProfile&&(identical(other.status, status) || other.status == status)&&(identical(other.metrics, metrics) || other.metrics == metrics)&&(identical(other.narrativeSummary, narrativeSummary) || other.narrativeSummary == narrativeSummary)&&(identical(other.analyzedAt, analyzedAt) || other.analyzedAt == analyzedAt)&&const DeepCollectionEquality().equals(other.personalRecords, personalRecords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,metrics,narrativeSummary,analyzedAt,const DeepCollectionEquality().hash(personalRecords));

@override
String toString() {
  return 'OnboardingProfile(status: $status, metrics: $metrics, narrativeSummary: $narrativeSummary, analyzedAt: $analyzedAt, personalRecords: $personalRecords)';
}


}

/// @nodoc
abstract mixin class $OnboardingProfileCopyWith<$Res>  {
  factory $OnboardingProfileCopyWith(OnboardingProfile value, $Res Function(OnboardingProfile) _then) = _$OnboardingProfileCopyWithImpl;
@useResult
$Res call({
 String status, OnboardingProfileMetrics? metrics,@JsonKey(name: 'narrative_summary') String? narrativeSummary,@JsonKey(name: 'analyzed_at') DateTime? analyzedAt,@JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? personalRecords
});


$OnboardingProfileMetricsCopyWith<$Res>? get metrics;

}
/// @nodoc
class _$OnboardingProfileCopyWithImpl<$Res>
    implements $OnboardingProfileCopyWith<$Res> {
  _$OnboardingProfileCopyWithImpl(this._self, this._then);

  final OnboardingProfile _self;
  final $Res Function(OnboardingProfile) _then;

/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? status = null,Object? metrics = freezed,Object? narrativeSummary = freezed,Object? analyzedAt = freezed,Object? personalRecords = freezed,}) {
  return _then(_self.copyWith(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as OnboardingProfileMetrics?,narrativeSummary: freezed == narrativeSummary ? _self.narrativeSummary : narrativeSummary // ignore: cast_nullable_to_non_nullable
as String?,analyzedAt: freezed == analyzedAt ? _self.analyzedAt : analyzedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,personalRecords: freezed == personalRecords ? _self.personalRecords : personalRecords // ignore: cast_nullable_to_non_nullable
as Map<String, PersonalRecord?>?,
  ));
}
/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OnboardingProfileMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
    return null;
  }

  return $OnboardingProfileMetricsCopyWith<$Res>(_self.metrics!, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingProfile].
extension OnboardingProfilePatterns on OnboardingProfile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingProfile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingProfile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingProfile value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingProfile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingProfile value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingProfile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String status,  OnboardingProfileMetrics? metrics, @JsonKey(name: 'narrative_summary')  String? narrativeSummary, @JsonKey(name: 'analyzed_at')  DateTime? analyzedAt, @JsonKey(name: 'personal_records')  Map<String, PersonalRecord?>? personalRecords)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingProfile() when $default != null:
return $default(_that.status,_that.metrics,_that.narrativeSummary,_that.analyzedAt,_that.personalRecords);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String status,  OnboardingProfileMetrics? metrics, @JsonKey(name: 'narrative_summary')  String? narrativeSummary, @JsonKey(name: 'analyzed_at')  DateTime? analyzedAt, @JsonKey(name: 'personal_records')  Map<String, PersonalRecord?>? personalRecords)  $default,) {final _that = this;
switch (_that) {
case _OnboardingProfile():
return $default(_that.status,_that.metrics,_that.narrativeSummary,_that.analyzedAt,_that.personalRecords);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String status,  OnboardingProfileMetrics? metrics, @JsonKey(name: 'narrative_summary')  String? narrativeSummary, @JsonKey(name: 'analyzed_at')  DateTime? analyzedAt, @JsonKey(name: 'personal_records')  Map<String, PersonalRecord?>? personalRecords)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingProfile() when $default != null:
return $default(_that.status,_that.metrics,_that.narrativeSummary,_that.analyzedAt,_that.personalRecords);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _OnboardingProfile implements OnboardingProfile {
  const _OnboardingProfile({required this.status, this.metrics, @JsonKey(name: 'narrative_summary') this.narrativeSummary, @JsonKey(name: 'analyzed_at') this.analyzedAt, @JsonKey(name: 'personal_records') final  Map<String, PersonalRecord?>? personalRecords}): _personalRecords = personalRecords;
  factory _OnboardingProfile.fromJson(Map<String, dynamic> json) => _$OnboardingProfileFromJson(json);

@override final  String status;
// 'ready' | 'syncing'
@override final  OnboardingProfileMetrics? metrics;
@override@JsonKey(name: 'narrative_summary') final  String? narrativeSummary;
@override@JsonKey(name: 'analyzed_at') final  DateTime? analyzedAt;
/// All-time PRs keyed by '5k' | '10k' | 'half' | 'marathon'. Map values
/// can be null when no qualifying workout exists for that distance.
 final  Map<String, PersonalRecord?>? _personalRecords;
/// All-time PRs keyed by '5k' | '10k' | 'half' | 'marathon'. Map values
/// can be null when no qualifying workout exists for that distance.
@override@JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? get personalRecords {
  final value = _personalRecords;
  if (value == null) return null;
  if (_personalRecords is EqualUnmodifiableMapView) return _personalRecords;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingProfileCopyWith<_OnboardingProfile> get copyWith => __$OnboardingProfileCopyWithImpl<_OnboardingProfile>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$OnboardingProfileToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingProfile&&(identical(other.status, status) || other.status == status)&&(identical(other.metrics, metrics) || other.metrics == metrics)&&(identical(other.narrativeSummary, narrativeSummary) || other.narrativeSummary == narrativeSummary)&&(identical(other.analyzedAt, analyzedAt) || other.analyzedAt == analyzedAt)&&const DeepCollectionEquality().equals(other._personalRecords, _personalRecords));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,status,metrics,narrativeSummary,analyzedAt,const DeepCollectionEquality().hash(_personalRecords));

@override
String toString() {
  return 'OnboardingProfile(status: $status, metrics: $metrics, narrativeSummary: $narrativeSummary, analyzedAt: $analyzedAt, personalRecords: $personalRecords)';
}


}

/// @nodoc
abstract mixin class _$OnboardingProfileCopyWith<$Res> implements $OnboardingProfileCopyWith<$Res> {
  factory _$OnboardingProfileCopyWith(_OnboardingProfile value, $Res Function(_OnboardingProfile) _then) = __$OnboardingProfileCopyWithImpl;
@override @useResult
$Res call({
 String status, OnboardingProfileMetrics? metrics,@JsonKey(name: 'narrative_summary') String? narrativeSummary,@JsonKey(name: 'analyzed_at') DateTime? analyzedAt,@JsonKey(name: 'personal_records') Map<String, PersonalRecord?>? personalRecords
});


@override $OnboardingProfileMetricsCopyWith<$Res>? get metrics;

}
/// @nodoc
class __$OnboardingProfileCopyWithImpl<$Res>
    implements _$OnboardingProfileCopyWith<$Res> {
  __$OnboardingProfileCopyWithImpl(this._self, this._then);

  final _OnboardingProfile _self;
  final $Res Function(_OnboardingProfile) _then;

/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? status = null,Object? metrics = freezed,Object? narrativeSummary = freezed,Object? analyzedAt = freezed,Object? personalRecords = freezed,}) {
  return _then(_OnboardingProfile(
status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,metrics: freezed == metrics ? _self.metrics : metrics // ignore: cast_nullable_to_non_nullable
as OnboardingProfileMetrics?,narrativeSummary: freezed == narrativeSummary ? _self.narrativeSummary : narrativeSummary // ignore: cast_nullable_to_non_nullable
as String?,analyzedAt: freezed == analyzedAt ? _self.analyzedAt : analyzedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,personalRecords: freezed == personalRecords ? _self._personalRecords : personalRecords // ignore: cast_nullable_to_non_nullable
as Map<String, PersonalRecord?>?,
  ));
}

/// Create a copy of OnboardingProfile
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$OnboardingProfileMetricsCopyWith<$Res>? get metrics {
    if (_self.metrics == null) {
    return null;
  }

  return $OnboardingProfileMetricsCopyWith<$Res>(_self.metrics!, (value) {
    return _then(_self.copyWith(metrics: value));
  });
}
}

// dart format on
