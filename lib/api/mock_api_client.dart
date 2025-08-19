import 'dart:async';
import 'api_client.dart';
import '../models/models.dart';

class MockApiClient implements ApiClient {
  final List<MealKit> _kits = [
    MealKit(
      id: 'kit1',
      title: 'Doro Wat with Injera',
      description: 'Classic Ethiopian chicken stew with berbere and injera. Spicy, flavorful, and authentic.',
      priceCents: 1200,
      imageUrl: 'https://picsum.photos/seed/doro/600/400',
    ),
    MealKit(
      id: 'kit2',
      title: 'Shiro Tegamino',
      description: 'Chickpea flour stew, veggie friendly. Rich, creamy, and perfect for vegetarians.',
      priceCents: 900,
      imageUrl: 'https://picsum.photos/seed/shiro/600/400',
    ),
    MealKit(
      id: 'kit3',
      title: 'Tibs with Injera',
      description: 'Pan-seared beef tibs with awaze. Tender beef with Ethiopian spices and herbs.',
      priceCents: 1100,
      imageUrl: 'https://picsum.photos/seed/tibs/600/400',
    ),
    MealKit(
      id: 'kit4',
      title: 'Misir Wat',
      description: 'Spiced red lentils with berbere. A hearty, protein-rich vegetarian option.',
      priceCents: 800,
      imageUrl: 'https://picsum.photos/seed/misir/600/400',
    ),
    MealKit(
      id: 'kit5',
      title: 'Gomen with Injera',
      description: 'Collard greens cooked with garlic and ginger. Fresh, healthy, and traditional.',
      priceCents: 700,
      imageUrl: 'https://picsum.photos/seed/gomen/600/400',
    ),
    MealKit(
      id: 'kit6',
      title: 'Kitfo with Injera',
      description: 'Ethiopian beef tartare with mitmita and niter kibbeh. Bold flavors and tender meat.',
      priceCents: 1300,
      imageUrl: 'https://picsum.photos/seed/kitfo/600/400',
    ),
    MealKit(
      id: 'kit7',
      title: 'Atkilt Alicha',
      description: 'Mild turmeric cabbage and carrots. A gentle introduction to Ethiopian cuisine.',
      priceCents: 600,
      imageUrl: 'https://picsum.photos/seed/atkilt/600/400',
    ),
    MealKit(
      id: 'kit8',
      title: 'Yebeg Tibs',
      description: 'Lamb tibs with rosemary and garlic. Rich, aromatic, and perfect for special occasions.',
      priceCents: 1400,
      imageUrl: 'https://picsum.photos/seed/yebeg/600/400',
    ),
  ];

  Cart _cart = const Cart(items: []);

  Future<T> _delay<T>(T value) async {
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return value;
  }

  @override
  Future<List<MealKit>> fetchMealKits() => _delay(_kits);

  @override
  Future<MealKit> fetchMealKitDetail(String id) =>
      _delay(_kits.firstWhere((k) => k.id == id));

  @override
  Future<Cart> fetchCart() => _delay(_cart);

  @override
  Future<Cart> addToCart(String mealKitId, int quantity) async {
    final kit = _kits.firstWhere((k) => k.id == mealKitId);
    final existing = _cart.items.where((i) => i.mealKit.id == mealKitId).toList();
    List<CartItem> newItems;
    if (existing.isEmpty) {
      newItems = [..._cart.items, CartItem(mealKit: kit, quantity: quantity)];
    } else {
      newItems = _cart.items
          .map((i) => i.mealKit.id == mealKitId ? i.copyWith(quantity: i.quantity + quantity) : i)
          .toList();
    }
    _cart = _cart.copyWith(items: newItems);
    return _delay(_cart);
  }

  @override
  Future<Cart> updateCartItem(String mealKitId, int quantity) async {
    final newItems = _cart.items
        .map((i) => i.mealKit.id == mealKitId ? i.copyWith(quantity: quantity) : i)
        .where((i) => i.quantity > 0)
        .toList();
    _cart = _cart.copyWith(items: newItems);
    return _delay(_cart);
  }

  @override
  Future<Order> createOrder({required String addressId, required String deliveryWindowId, required bool cashOnDelivery}) async {
    final totalCents = _cart.items.fold<int>(0, (sum, i) => sum + i.mealKit.priceCents * i.quantity);
    final order = Order(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      items: _cart.items
          .map((i) => OrderItem(mealKit: i.mealKit, quantity: i.quantity, unitPriceCents: i.mealKit.priceCents))
          .toList(),
      totalCents: totalCents,
      status: 'confirmed',
      createdAt: DateTime.now(),
    );
    _cart = const Cart(items: []);
    return _delay(order);
  }

  @override
  Future<List<Order>> fetchOrders() => _delay(const <Order>[]);

  @override
  Future<Order> fetchOrderDetail(String orderId) =>
      _delay(Order(id: orderId, items: const [], totalCents: 0, status: 'confirmed', createdAt: DateTime.now()));
}



