import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import '../core/providers.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return OrdersRepository(api);
});

class OrdersRepository {
  final ApiClient api;
  OrdersRepository(this.api);

  Future<List<Order>> getOrders() => api.fetchOrders();
  Future<Order> createOrder(
          {required String addressId,
          required String deliveryWindowId,
          required bool cashOnDelivery}) =>
      api.createOrder(
          addressId: addressId,
          deliveryWindowId: deliveryWindowId,
          cashOnDelivery: cashOnDelivery);
  Future<Order> getOrderDetail(String orderId) => api.fetchOrderDetail(orderId);
}
