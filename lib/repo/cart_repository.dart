import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import 'meals_repository.dart';

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CartRepository(api);
});

class CartRepository {
  final ApiClient api;
  CartRepository(this.api);

  Future<Cart> getCart() => api.fetchCart();
  Future<Cart> add(String kitId, int qty) => api.addToCart(kitId, qty);
  Future<Cart> update(String kitId, int qty) => api.updateCartItem(kitId, qty);
}


