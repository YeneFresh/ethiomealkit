import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@freezed
class Meal with _$Meal {
  const factory Meal({
    required String id,
    required String title,
    String? description,
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    int? cookTimeMinutes,
    List<String>? tags,
    String? imageUrl,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}



