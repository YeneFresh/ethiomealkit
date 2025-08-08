// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'delivery_window.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$DeliveryWindowImpl _$$DeliveryWindowImplFromJson(Map<String, dynamic> json) =>
    _$DeliveryWindowImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      dayOfWeek: json['dayOfWeek'] as String?,
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
    );

Map<String, dynamic> _$$DeliveryWindowImplToJson(
  _$DeliveryWindowImpl instance,
) => <String, dynamic>{
  'id': instance.id,
  'label': instance.label,
  'dayOfWeek': instance.dayOfWeek,
  'startTime': instance.startTime,
  'endTime': instance.endTime,
};
