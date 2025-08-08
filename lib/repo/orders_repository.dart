import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';
import 'meals_repository.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return OrdersRepository(api);
});

class OrdersRepository {
  final ApiClient api;
  OrdersRepository(this.api);

  Future<Order> create({required String addressId, required String deliveryWindowId, required bool cod}) =>
      api.createOrder(addressId: addressId, deliveryWindowId: deliveryWindowId, cashOnDelivery: cod);

  Future<List<Order>> list() => api.fetchOrders();
  Future<Order> detail(String orderId) => api.fetchOrderDetail(orderId);
}


