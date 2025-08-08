import 'package:freezed_annotation/freezed_annotation.dart';
import 'meal_kit.dart';

part 'order.freezed.dart';
part 'order.g.dart';

@freezed
class OrderItem with _$OrderItem {
  const factory OrderItem({
    required MealKit mealKit,
    required int quantity,
    required int unitPriceCents,
  }) = _OrderItem;
  factory OrderItem.fromJson(Map<String, dynamic> json) => _$OrderItemFromJson(json);
}

@freezed
class Order with _$Order {
  const factory Order({
    required String id,
    required List<OrderItem> items,
    required int totalCents,
    required String status,
    required DateTime createdAt,
  }) = _Order;
  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);
}



