import 'api_client.dart';
import '../models/models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApiClient implements ApiClient {
  final SupabaseClient client;
  SupabaseApiClient(this.client);

  @override
  Future<List<MealKit>> fetchMealKits() async {
    // TODO: implement select from meals table
    return <MealKit>[];
  }

  @override
  Future<MealKit> fetchMealKitDetail(String id) async {
    // TODO: implement select one
    throw UnimplementedError();
  }

  @override
  Future<Cart> fetchCart() async {
    // TODO: implement cart persistence if desired
    return const Cart(items: []);
  }

  @override
  Future<Cart> addToCart(String mealKitId, int quantity) async {
    // TODO: server-side cart optional; client-side handled in repository
    return const Cart(items: []);
  }

  @override
  Future<Cart> updateCartItem(String mealKitId, int quantity) async {
    return const Cart(items: []);
  }

  @override
  Future<Order> createOrder({required String addressId, required String deliveryWindowId, required bool cashOnDelivery}) async {
    // TODO: call RPC create_order
    throw UnimplementedError();
  }

  @override
  Future<List<Order>> fetchOrders() async {
    // TODO: select orders
    return const <Order>[];
  }

  @override
  Future<Order> fetchOrderDetail(String orderId) async {
    // TODO: select order detail
    throw UnimplementedError();
  }
}



