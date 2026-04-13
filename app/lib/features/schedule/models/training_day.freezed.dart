// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingDay {

 int get id; String get date; String get type; String get title; String? get description;@JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? get targetKm;@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? get targetPaceSecondsPerKm;@JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) int? get targetHeartRateZone;@JsonKey(name: 'intervals_json') Map<String, dynamic>? get intervalsJson;@JsonKey(fromJson: toInt) int get order; TrainingResult? get result;
/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TrainingDayCopyWith<TrainingDay> get copyWith => _$TrainingDayCopyWithImpl<TrainingDay>(this as TrainingDay, _$identity);

  /// Serializes this TrainingDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TrainingDay&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetKm, targetKm) || other.targetKm == targetKm)&&(identical(other.targetPaceSecondsPerKm, targetPaceSecondsPerKm) || other.targetPaceSecondsPerKm == targetPaceSecondsPerKm)&&(identical(other.targetHeartRateZone, targetHeartRateZone) || other.targetHeartRateZone == targetHeartRateZone)&&const DeepCollectionEquality().equals(other.intervalsJson, intervalsJson)&&(identical(other.order, order) || other.order == order)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,type,title,description,targetKm,targetPaceSecondsPerKm,targetHeartRateZone,const DeepCollectionEquality().hash(intervalsJson),order,result);

@override
String toString() {
  return 'TrainingDay(id: $id, date: $date, type: $type, title: $title, description: $description, targetKm: $targetKm, targetPaceSecondsPerKm: $targetPaceSecondsPerKm, targetHeartRateZone: $targetHeartRateZone, intervalsJson: $intervalsJson, order: $order, result: $result)';
}


}

/// @nodoc
abstract mixin class $TrainingDayCopyWith<$Res>  {
  factory $TrainingDayCopyWith(TrainingDay value, $Res Function(TrainingDay) _then) = _$TrainingDayCopyWithImpl;
@useResult
$Res call({
 int id, String date, String type, String title, String? description,@JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? targetKm,@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? targetPaceSecondsPerKm,@JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) int? targetHeartRateZone,@JsonKey(name: 'intervals_json') Map<String, dynamic>? intervalsJson,@JsonKey(fromJson: toInt) int order, TrainingResult? result
});


$TrainingResultCopyWith<$Res>? get result;

}
/// @nodoc
class _$TrainingDayCopyWithImpl<$Res>
    implements $TrainingDayCopyWith<$Res> {
  _$TrainingDayCopyWithImpl(this._self, this._then);

  final TrainingDay _self;
  final $Res Function(TrainingDay) _then;

/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? date = null,Object? type = null,Object? title = null,Object? description = freezed,Object? targetKm = freezed,Object? targetPaceSecondsPerKm = freezed,Object? targetHeartRateZone = freezed,Object? intervalsJson = freezed,Object? order = null,Object? result = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,targetKm: freezed == targetKm ? _self.targetKm : targetKm // ignore: cast_nullable_to_non_nullable
as double?,targetPaceSecondsPerKm: freezed == targetPaceSecondsPerKm ? _self.targetPaceSecondsPerKm : targetPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,targetHeartRateZone: freezed == targetHeartRateZone ? _self.targetHeartRateZone : targetHeartRateZone // ignore: cast_nullable_to_non_nullable
as int?,intervalsJson: freezed == intervalsJson ? _self.intervalsJson : intervalsJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TrainingResult?,
  ));
}
/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $TrainingResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}


/// Adds pattern-matching-related methods to [TrainingDay].
extension TrainingDayPatterns on TrainingDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TrainingDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TrainingDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TrainingDay value)  $default,){
final _that = this;
switch (_that) {
case _TrainingDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TrainingDay value)?  $default,){
final _that = this;
switch (_that) {
case _TrainingDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String date,  String type,  String title,  String? description, @JsonKey(name: 'target_km', fromJson: toDoubleOrNull)  double? targetKm, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm, @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull)  int? targetHeartRateZone, @JsonKey(name: 'intervals_json')  Map<String, dynamic>? intervalsJson, @JsonKey(fromJson: toInt)  int order,  TrainingResult? result)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TrainingDay() when $default != null:
return $default(_that.id,_that.date,_that.type,_that.title,_that.description,_that.targetKm,_that.targetPaceSecondsPerKm,_that.targetHeartRateZone,_that.intervalsJson,_that.order,_that.result);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String date,  String type,  String title,  String? description, @JsonKey(name: 'target_km', fromJson: toDoubleOrNull)  double? targetKm, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm, @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull)  int? targetHeartRateZone, @JsonKey(name: 'intervals_json')  Map<String, dynamic>? intervalsJson, @JsonKey(fromJson: toInt)  int order,  TrainingResult? result)  $default,) {final _that = this;
switch (_that) {
case _TrainingDay():
return $default(_that.id,_that.date,_that.type,_that.title,_that.description,_that.targetKm,_that.targetPaceSecondsPerKm,_that.targetHeartRateZone,_that.intervalsJson,_that.order,_that.result);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String date,  String type,  String title,  String? description, @JsonKey(name: 'target_km', fromJson: toDoubleOrNull)  double? targetKm, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull)  int? targetPaceSecondsPerKm, @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull)  int? targetHeartRateZone, @JsonKey(name: 'intervals_json')  Map<String, dynamic>? intervalsJson, @JsonKey(fromJson: toInt)  int order,  TrainingResult? result)?  $default,) {final _that = this;
switch (_that) {
case _TrainingDay() when $default != null:
return $default(_that.id,_that.date,_that.type,_that.title,_that.description,_that.targetKm,_that.targetPaceSecondsPerKm,_that.targetHeartRateZone,_that.intervalsJson,_that.order,_that.result);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TrainingDay implements TrainingDay {
  const _TrainingDay({required this.id, required this.date, required this.type, required this.title, this.description, @JsonKey(name: 'target_km', fromJson: toDoubleOrNull) this.targetKm, @JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) this.targetPaceSecondsPerKm, @JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) this.targetHeartRateZone, @JsonKey(name: 'intervals_json') final  Map<String, dynamic>? intervalsJson, @JsonKey(fromJson: toInt) required this.order, this.result}): _intervalsJson = intervalsJson;
  factory _TrainingDay.fromJson(Map<String, dynamic> json) => _$TrainingDayFromJson(json);

@override final  int id;
@override final  String date;
@override final  String type;
@override final  String title;
@override final  String? description;
@override@JsonKey(name: 'target_km', fromJson: toDoubleOrNull) final  double? targetKm;
@override@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) final  int? targetPaceSecondsPerKm;
@override@JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) final  int? targetHeartRateZone;
 final  Map<String, dynamic>? _intervalsJson;
@override@JsonKey(name: 'intervals_json') Map<String, dynamic>? get intervalsJson {
  final value = _intervalsJson;
  if (value == null) return null;
  if (_intervalsJson is EqualUnmodifiableMapView) return _intervalsJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}

@override@JsonKey(fromJson: toInt) final  int order;
@override final  TrainingResult? result;

/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TrainingDayCopyWith<_TrainingDay> get copyWith => __$TrainingDayCopyWithImpl<_TrainingDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TrainingDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TrainingDay&&(identical(other.id, id) || other.id == id)&&(identical(other.date, date) || other.date == date)&&(identical(other.type, type) || other.type == type)&&(identical(other.title, title) || other.title == title)&&(identical(other.description, description) || other.description == description)&&(identical(other.targetKm, targetKm) || other.targetKm == targetKm)&&(identical(other.targetPaceSecondsPerKm, targetPaceSecondsPerKm) || other.targetPaceSecondsPerKm == targetPaceSecondsPerKm)&&(identical(other.targetHeartRateZone, targetHeartRateZone) || other.targetHeartRateZone == targetHeartRateZone)&&const DeepCollectionEquality().equals(other._intervalsJson, _intervalsJson)&&(identical(other.order, order) || other.order == order)&&(identical(other.result, result) || other.result == result));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,date,type,title,description,targetKm,targetPaceSecondsPerKm,targetHeartRateZone,const DeepCollectionEquality().hash(_intervalsJson),order,result);

@override
String toString() {
  return 'TrainingDay(id: $id, date: $date, type: $type, title: $title, description: $description, targetKm: $targetKm, targetPaceSecondsPerKm: $targetPaceSecondsPerKm, targetHeartRateZone: $targetHeartRateZone, intervalsJson: $intervalsJson, order: $order, result: $result)';
}


}

/// @nodoc
abstract mixin class _$TrainingDayCopyWith<$Res> implements $TrainingDayCopyWith<$Res> {
  factory _$TrainingDayCopyWith(_TrainingDay value, $Res Function(_TrainingDay) _then) = __$TrainingDayCopyWithImpl;
@override @useResult
$Res call({
 int id, String date, String type, String title, String? description,@JsonKey(name: 'target_km', fromJson: toDoubleOrNull) double? targetKm,@JsonKey(name: 'target_pace_seconds_per_km', fromJson: toIntOrNull) int? targetPaceSecondsPerKm,@JsonKey(name: 'target_heart_rate_zone', fromJson: toIntOrNull) int? targetHeartRateZone,@JsonKey(name: 'intervals_json') Map<String, dynamic>? intervalsJson,@JsonKey(fromJson: toInt) int order, TrainingResult? result
});


@override $TrainingResultCopyWith<$Res>? get result;

}
/// @nodoc
class __$TrainingDayCopyWithImpl<$Res>
    implements _$TrainingDayCopyWith<$Res> {
  __$TrainingDayCopyWithImpl(this._self, this._then);

  final _TrainingDay _self;
  final $Res Function(_TrainingDay) _then;

/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? date = null,Object? type = null,Object? title = null,Object? description = freezed,Object? targetKm = freezed,Object? targetPaceSecondsPerKm = freezed,Object? targetHeartRateZone = freezed,Object? intervalsJson = freezed,Object? order = null,Object? result = freezed,}) {
  return _then(_TrainingDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,title: null == title ? _self.title : title // ignore: cast_nullable_to_non_nullable
as String,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,targetKm: freezed == targetKm ? _self.targetKm : targetKm // ignore: cast_nullable_to_non_nullable
as double?,targetPaceSecondsPerKm: freezed == targetPaceSecondsPerKm ? _self.targetPaceSecondsPerKm : targetPaceSecondsPerKm // ignore: cast_nullable_to_non_nullable
as int?,targetHeartRateZone: freezed == targetHeartRateZone ? _self.targetHeartRateZone : targetHeartRateZone // ignore: cast_nullable_to_non_nullable
as int?,intervalsJson: freezed == intervalsJson ? _self._intervalsJson : intervalsJson // ignore: cast_nullable_to_non_nullable
as Map<String, dynamic>?,order: null == order ? _self.order : order // ignore: cast_nullable_to_non_nullable
as int,result: freezed == result ? _self.result : result // ignore: cast_nullable_to_non_nullable
as TrainingResult?,
  ));
}

/// Create a copy of TrainingDay
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TrainingResultCopyWith<$Res>? get result {
    if (_self.result == null) {
    return null;
  }

  return $TrainingResultCopyWith<$Res>(_self.result!, (value) {
    return _then(_self.copyWith(result: value));
  });
}
}

// dart format on
