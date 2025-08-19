import 'package:freezed_annotation/freezed_annotation.dart';
import 'meal_kit.dart';

part 'cart.freezed.dart';
part 'cart.g.dart';

@freezed
class CartItem with _$CartItem {
  const factory CartItem({
    required MealKit mealKit,
    required int quantity,
  }) = _CartItem;
  factory CartItem.fromJson(Map<String, dynamic> json) => _$CartItemFromJson(json);
}

@freezed
class Cart with _$Cart {
  const factory Cart({
    required List<CartItem> items,
  }) = _Cart;
  const Cart._();

  int get totalCents => items.fold(0, (sum, i) => sum + i.mealKit.priceCents * i.quantity);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory Cart.fromJson(Map<String, dynamic> json) => _$CartFromJson(json);
}



