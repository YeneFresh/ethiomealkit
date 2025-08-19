import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../repo/meals_repository.dart';
import '../repo/cart_repository.dart';
import '../repo/orders_repository.dart';

// API Client Provider - overridden in main.dart
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError(
      'apiClientProvider not configured - should be overridden in main.dart');
});

// Repository Providers
final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MealsRepository(api);
});

final cartRepositoryProvider = Provider<CartRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CartRepository(api);
});

final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return OrdersRepository(api);
});
