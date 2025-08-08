import 'package:freezed_annotation/freezed_annotation.dart';
import 'meal.dart';

part 'meal_kit.freezed.dart';
part 'meal_kit.g.dart';

@freezed
class MealKit with _$MealKit {
  const factory MealKit({
    required String id,
    required String title,
    String? description,
    required int priceCents,
    String? imageUrl,
    List<Meal>? meals,
  }) = _MealKit;

  factory MealKit.fromJson(Map<String, dynamic> json) => _$MealKitFromJson(json);
}



