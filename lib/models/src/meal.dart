import 'package:freezed_annotation/freezed_annotation.dart';

part 'meal.freezed.dart';
part 'meal.g.dart';

@freezed
class Meal with _$Meal {
  const factory Meal({
    required String id,
    String? slug, // immutable
    required String name,
    String? cuisine,
    List<String>? tags, // never NULL in API but nullable for backwards compatibility
    String? chefNote,
    required int priceCents, // int cents
    required int kcal, // int kcal  
    List<String>? badges, // all prettified badges
    List<String>? badgesTop3, // prioritized, length 0..3
    List<String>? badgesOverflow, // remainder
    int? protein, // int grams if derived, else 0
    String? proteinLabel, // short printable
    String? description,
    String? imageUrl,
  }) = _Meal;

  factory Meal.fromJson(Map<String, dynamic> json) => _$MealFromJson(json);
}



