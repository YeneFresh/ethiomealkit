import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/models/models.dart';

// Cart provider and notifier
final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  return CartNotifier();
});

class CartNotifier extends StateNotifier<Cart> {
  CartNotifier() : super(const Cart(items: []));

  void addItem(MealKit mealKit, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere(
      (item) => item.mealKit.id == mealKit.id,
    );

    if (existingIndex >= 0) {
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = CartItem(
        mealKit: mealKit,
        quantity: updatedItems[existingIndex].quantity + quantity,
      );
      state = Cart(items: updatedItems);
    } else {
      state = Cart(
        items: [
          ...state.items,
          CartItem(mealKit: mealKit, quantity: quantity),
        ],
      );
    }
  }

  void removeItem(String mealKitId) {
    state = Cart(
      items: state.items.where((item) => item.mealKit.id != mealKitId).toList(),
    );
  }

  void updateQuantity(String mealKitId, int quantity) {
    if (quantity <= 0) {
      removeItem(mealKitId);
      return;
    }

    final updatedItems = state.items.map((item) {
      if (item.mealKit.id == mealKitId) {
        return CartItem(mealKit: item.mealKit, quantity: quantity);
      }
      return item;
    }).toList();

    state = Cart(items: updatedItems);
  }

  // Alias for updateQuantity for compatibility
  void updateCartItem(String mealKitId, int quantity) {
    updateQuantity(mealKitId, quantity);
  }

  // Alias for removeItem for compatibility
  void removeFromCart(String mealKitId) {
    removeItem(mealKitId);
  }

  // Get total price in cents
  int get totalPriceCents => state.totalCents;

  Future<void> clearCart() async {
    state = const Cart(items: []);
  }
}
