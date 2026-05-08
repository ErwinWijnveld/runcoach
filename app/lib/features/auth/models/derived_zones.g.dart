// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'derived_zones.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DerivedZones _$DerivedZonesFromJson(Map<String, dynamic> json) =>
    _DerivedZones(
      zones: (json['zones'] as List<dynamic>)
          .map((e) => HrZone.fromJson(e as Map<String, dynamic>))
          .toList(),
      source: json['source'] as String,
      maxHr: toIntOrNull(json['max_hr']),
      sampleCount: toInt(json['sample_count']),
      age: toIntOrNull(json['age']),
      restingHeartRate: toIntOrNull(json['resting_heart_rate']),
      wasCorrected: json['was_corrected'] as bool? ?? false,
    );

Map<String, dynamic> _$DerivedZonesToJson(_DerivedZones instance) =>
    <String, dynamic>{
      'zones': instance.zones,
      'source': instance.source,
      'max_hr': instance.maxHr,
      'sample_count': instance.sampleCount,
      'age': instance.age,
      'resting_heart_rate': instance.restingHeartRate,
      'was_corrected': instance.wasCorrected,
    };
