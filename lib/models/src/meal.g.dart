// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'meal.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MealImpl _$$MealImplFromJson(Map<String, dynamic> json) => _$MealImpl(
  id: json['id'] as String,
  title: json['title'] as String,
  description: json['description'] as String?,
  calories: (json['calories'] as num?)?.toInt(),
  protein: (json['protein'] as num?)?.toInt(),
  carbs: (json['carbs'] as num?)?.toInt(),
  fat: (json['fat'] as num?)?.toInt(),
  cookTimeMinutes: (json['cookTimeMinutes'] as num?)?.toInt(),
  tags: (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList(),
  imageUrl: json['imageUrl'] as String?,
);

Map<String, dynamic> _$$MealImplToJson(_$MealImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'calories': instance.calories,
      'protein': instance.protein,
      'carbs': instance.carbs,
      'fat': instance.fat,
      'cookTimeMinutes': instance.cookTimeMinutes,
      'tags': instance.tags,
      'imageUrl': instance.imageUrl,
    };
