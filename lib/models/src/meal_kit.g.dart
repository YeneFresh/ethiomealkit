// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal_kit.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealKitImpl _$$MealKitImplFromJson(Map<String, dynamic> json) =>
    _$MealKitImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      priceCents: (json['priceCents'] as num).toInt(),
      imageUrl: json['imageUrl'] as String?,
      meals: (json['meals'] as List<dynamic>?)
          ?.map((e) => Meal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$$MealKitImplToJson(_$MealKitImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'priceCents': instance.priceCents,
      'imageUrl': instance.imageUrl,
      'meals': instance.meals,
    };
