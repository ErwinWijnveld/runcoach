// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'derived_zones.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DerivedZones {

 List<HrZone> get zones; String get source;@JsonKey(name: 'max_hr', fromJson: toIntOrNull) int? get maxHr;@JsonKey(name: 'sample_count', fromJson: toInt) int get sampleCount;@JsonKey(fromJson: toIntOrNull) int? get age;@JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) int? get restingHeartRate;
/// Create a copy of DerivedZones
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DerivedZonesCopyWith<DerivedZones> get copyWith => _$DerivedZonesCopyWithImpl<DerivedZones>(this as DerivedZones, _$identity);

  /// Serializes this DerivedZones to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DerivedZones&&const DeepCollectionEquality().equals(other.zones, zones)&&(identical(other.source, source) || other.source == source)&&(identical(other.maxHr, maxHr) || other.maxHr == maxHr)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount)&&(identical(other.age, age) || other.age == age)&&(identical(other.restingHeartRate, restingHeartRate) || other.restingHeartRate == restingHeartRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(zones),source,maxHr,sampleCount,age,restingHeartRate);

@override
String toString() {
  return 'DerivedZones(zones: $zones, source: $source, maxHr: $maxHr, sampleCount: $sampleCount, age: $age, restingHeartRate: $restingHeartRate)';
}


}

/// @nodoc
abstract mixin class $DerivedZonesCopyWith<$Res>  {
  factory $DerivedZonesCopyWith(DerivedZones value, $Res Function(DerivedZones) _then) = _$DerivedZonesCopyWithImpl;
@useResult
$Res call({
 List<HrZone> zones, String source,@JsonKey(name: 'max_hr', fromJson: toIntOrNull) int? maxHr,@JsonKey(name: 'sample_count', fromJson: toInt) int sampleCount,@JsonKey(fromJson: toIntOrNull) int? age,@JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) int? restingHeartRate
});




}
/// @nodoc
class _$DerivedZonesCopyWithImpl<$Res>
    implements $DerivedZonesCopyWith<$Res> {
  _$DerivedZonesCopyWithImpl(this._self, this._then);

  final DerivedZones _self;
  final $Res Function(DerivedZones) _then;

/// Create a copy of DerivedZones
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? zones = null,Object? source = null,Object? maxHr = freezed,Object? sampleCount = null,Object? age = freezed,Object? restingHeartRate = freezed,}) {
  return _then(_self.copyWith(
zones: null == zones ? _self.zones : zones // ignore: cast_nullable_to_non_nullable
as List<HrZone>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,maxHr: freezed == maxHr ? _self.maxHr : maxHr // ignore: cast_nullable_to_non_nullable
as int?,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,restingHeartRate: freezed == restingHeartRate ? _self.restingHeartRate : restingHeartRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [DerivedZones].
extension DerivedZonesPatterns on DerivedZones {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DerivedZones value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DerivedZones() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DerivedZones value)  $default,){
final _that = this;
switch (_that) {
case _DerivedZones():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DerivedZones value)?  $default,){
final _that = this;
switch (_that) {
case _DerivedZones() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<HrZone> zones,  String source, @JsonKey(name: 'max_hr', fromJson: toIntOrNull)  int? maxHr, @JsonKey(name: 'sample_count', fromJson: toInt)  int sampleCount, @JsonKey(fromJson: toIntOrNull)  int? age, @JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull)  int? restingHeartRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DerivedZones() when $default != null:
return $default(_that.zones,_that.source,_that.maxHr,_that.sampleCount,_that.age,_that.restingHeartRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<HrZone> zones,  String source, @JsonKey(name: 'max_hr', fromJson: toIntOrNull)  int? maxHr, @JsonKey(name: 'sample_count', fromJson: toInt)  int sampleCount, @JsonKey(fromJson: toIntOrNull)  int? age, @JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull)  int? restingHeartRate)  $default,) {final _that = this;
switch (_that) {
case _DerivedZones():
return $default(_that.zones,_that.source,_that.maxHr,_that.sampleCount,_that.age,_that.restingHeartRate);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<HrZone> zones,  String source, @JsonKey(name: 'max_hr', fromJson: toIntOrNull)  int? maxHr, @JsonKey(name: 'sample_count', fromJson: toInt)  int sampleCount, @JsonKey(fromJson: toIntOrNull)  int? age, @JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull)  int? restingHeartRate)?  $default,) {final _that = this;
switch (_that) {
case _DerivedZones() when $default != null:
return $default(_that.zones,_that.source,_that.maxHr,_that.sampleCount,_that.age,_that.restingHeartRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DerivedZones implements DerivedZones {
  const _DerivedZones({required final  List<HrZone> zones, required this.source, @JsonKey(name: 'max_hr', fromJson: toIntOrNull) this.maxHr, @JsonKey(name: 'sample_count', fromJson: toInt) required this.sampleCount, @JsonKey(fromJson: toIntOrNull) this.age, @JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) this.restingHeartRate}): _zones = zones;
  factory _DerivedZones.fromJson(Map<String, dynamic> json) => _$DerivedZonesFromJson(json);

 final  List<HrZone> _zones;
@override List<HrZone> get zones {
  if (_zones is EqualUnmodifiableListView) return _zones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_zones);
}

@override final  String source;
@override@JsonKey(name: 'max_hr', fromJson: toIntOrNull) final  int? maxHr;
@override@JsonKey(name: 'sample_count', fromJson: toInt) final  int sampleCount;
@override@JsonKey(fromJson: toIntOrNull) final  int? age;
@override@JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) final  int? restingHeartRate;

/// Create a copy of DerivedZones
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DerivedZonesCopyWith<_DerivedZones> get copyWith => __$DerivedZonesCopyWithImpl<_DerivedZones>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DerivedZonesToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DerivedZones&&const DeepCollectionEquality().equals(other._zones, _zones)&&(identical(other.source, source) || other.source == source)&&(identical(other.maxHr, maxHr) || other.maxHr == maxHr)&&(identical(other.sampleCount, sampleCount) || other.sampleCount == sampleCount)&&(identical(other.age, age) || other.age == age)&&(identical(other.restingHeartRate, restingHeartRate) || other.restingHeartRate == restingHeartRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_zones),source,maxHr,sampleCount,age,restingHeartRate);

@override
String toString() {
  return 'DerivedZones(zones: $zones, source: $source, maxHr: $maxHr, sampleCount: $sampleCount, age: $age, restingHeartRate: $restingHeartRate)';
}


}

/// @nodoc
abstract mixin class _$DerivedZonesCopyWith<$Res> implements $DerivedZonesCopyWith<$Res> {
  factory _$DerivedZonesCopyWith(_DerivedZones value, $Res Function(_DerivedZones) _then) = __$DerivedZonesCopyWithImpl;
@override @useResult
$Res call({
 List<HrZone> zones, String source,@JsonKey(name: 'max_hr', fromJson: toIntOrNull) int? maxHr,@JsonKey(name: 'sample_count', fromJson: toInt) int sampleCount,@JsonKey(fromJson: toIntOrNull) int? age,@JsonKey(name: 'resting_heart_rate', fromJson: toIntOrNull) int? restingHeartRate
});




}
/// @nodoc
class __$DerivedZonesCopyWithImpl<$Res>
    implements _$DerivedZonesCopyWith<$Res> {
  __$DerivedZonesCopyWithImpl(this._self, this._then);

  final _DerivedZones _self;
  final $Res Function(_DerivedZones) _then;

/// Create a copy of DerivedZones
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? zones = null,Object? source = null,Object? maxHr = freezed,Object? sampleCount = null,Object? age = freezed,Object? restingHeartRate = freezed,}) {
  return _then(_DerivedZones(
zones: null == zones ? _self._zones : zones // ignore: cast_nullable_to_non_nullable
as List<HrZone>,source: null == source ? _self.source : source // ignore: cast_nullable_to_non_nullable
as String,maxHr: freezed == maxHr ? _self.maxHr : maxHr // ignore: cast_nullable_to_non_nullable
as int?,sampleCount: null == sampleCount ? _self.sampleCount : sampleCount // ignore: cast_nullable_to_non_nullable
as int,age: freezed == age ? _self.age : age // ignore: cast_nullable_to_non_nullable
as int?,restingHeartRate: freezed == restingHeartRate ? _self.restingHeartRate : restingHeartRate // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
