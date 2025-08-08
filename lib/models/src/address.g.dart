// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'address.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AddressImpl _$$AddressImplFromJson(Map<String, dynamic> json) =>
    _$AddressImpl(
      id: json['id'] as String,
      label: json['label'] as String?,
      line1: json['line1'] as String,
      line2: json['line2'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      instructions: json['instructions'] as String?,
      isDefault: json['isDefault'] as bool? ?? false,
    );

Map<String, dynamic> _$$AddressImplToJson(_$AddressImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'line1': instance.line1,
      'line2': instance.line2,
      'city': instance.city,
      'region': instance.region,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'instructions': instance.instructions,
      'isDefault': instance.isDefault,
    };
