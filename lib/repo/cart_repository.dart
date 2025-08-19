import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../core/providers.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CartRepository(api);
});

final cartProvider = StateNotifierProvider<CartNotifier, Cart>((ref) {
  final api = ref.watch(apiClientProvider);
  return CartNotifier(api);
});

class CartRepository {
  final ApiClient api;
  CartRepository(this.api);

  Future<Cart> getCart() => api.fetchCart();
  Future<Cart> addToCart(String mealKitId, int quantity) =>
      api.addToCart(mealKitId, quantity);
  Future<Cart> updateCartItem(String mealKitId, int quantity) =>
      api.updateCartItem(mealKitId, quantity);
}

class CartNotifier extends StateNotifier<Cart> {
  final ApiClient _api;

  CartNotifier(this._api) : super(const Cart(items: [])) {
    _loadCart();
  }

  Future<void> _loadCart() async {
    try {
      final cart = await _api.fetchCart();
      state = cart;
    } catch (e) {
      // Keep current state on error
    }
  }

  Future<void> addToCart(String mealKitId, int quantity) async {
    try {
      final cart = await _api.addToCart(mealKitId, quantity);
      state = cart;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> updateCartItem(String mealKitId, int quantity) async {
    try {
      final cart = await _api.updateCartItem(mealKitId, quantity);
      state = cart;
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  Future<void> removeFromCart(String mealKitId) async {
    await updateCartItem(mealKitId, 0);
  }

  Future<void> clearCart() async {
    try {
      // Clear all items by setting quantities to 0
      for (final item in state.items) {
        await _api.updateCartItem(item.mealKit.id, 0);
      }
      state = const Cart(items: []);
    } catch (e) {
      // Handle error
      rethrow;
    }
  }

  int get totalItems => state.items.fold(0, (sum, item) => sum + item.quantity);

  int get totalPriceCents => state.items
      .fold(0, (sum, item) => sum + (item.mealKit.priceCents * item.quantity));
}
