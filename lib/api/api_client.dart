import '../models/models.dart';

abstract class ApiClient {
  Future<List<MealKit>> fetchMealKits();
  Future<MealKit> fetchMealKitDetail(String id);
  Future<Cart> fetchCart();
  Future<Cart> addToCart(String mealKitId, int quantity);
  Future<Cart> updateCartItem(String mealKitId, int quantity);
  Future<Order> createOrder({required String addressId, required String deliveryWindowId, required bool cashOnDelivery});
  Future<List<Order>> fetchOrders();
  Future<Order> fetchOrderDetail(String orderId);
}


