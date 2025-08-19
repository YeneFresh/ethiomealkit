import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:logging/logging.dart';
import 'api_client.dart';
import '../models/models.dart';

final supa = Supabase.instance.client;

class SupabaseApiClient implements ApiClient {
  @override
  Future<List<MealKit>> fetchMealKits() async {
    try {
      final res = await supa.from('meals').select();
      return res
          .map((e) => MealKit.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      // Fallback to mock data if Supabase fails
      return _getMockMealKits();
    }
  }

  @override
  Future<MealKit> fetchMealKitDetail(String id) async {
    try {
      final res = await supa.from('meals').select().eq('id', id).single();
      return MealKit.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      // Fallback to mock data if Supabase fails
      return _getMockMealKits().firstWhere((k) => k.id == id);
    }
  }

  @override
  Future<Cart> fetchCart() async {
    try {
      final userId = supa.auth.currentUser?.id;
      if (userId == null) {
        return const Cart(items: []);
      }

      // Fetch cart items from the cart table
      final res = await supa.from('cart').select('''
            id,
            meal_kit_id,
            quantity,
            meals!inner(
              id,
              title,
              description,
              price_cents,
              image_url
            )
          ''').eq('user_id', userId);

      if (res.isEmpty) {
        return const Cart(items: []);
      }

      // Convert the response to CartItem objects
      final cartItems = res.map((item) {
        final mealData = item['meals'] as Map<String, dynamic>;
        final mealKit = MealKit.fromJson(Map<String, dynamic>.from(mealData));

        return CartItem(mealKit: mealKit, quantity: item['quantity'] as int);
      }).toList();

      return Cart(items: cartItems);
    } catch (e) {
      // Log the error for debugging
      final logger = Logger('SupabaseApiClient');
      logger.warning('Error fetching cart: $e');
      return const Cart(items: []);
    }
  }

  @override
  Future<Cart> addToCart(String mealKitId, int quantity) async {
    try {
      final userId = supa.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Check if item already exists in cart
      final existingItem = await supa
          .from('cart')
          .select()
          .eq('user_id', userId)
          .eq('meal_kit_id', mealKitId)
          .maybeSingle();

      if (existingItem != null) {
        // Update existing item quantity
        final newQuantity = (existingItem['quantity'] as int) + quantity;
        await supa
            .from('cart')
            .update({'quantity': newQuantity}).eq('id', existingItem['id']);
      } else {
        // Insert new cart item
        await supa.from('cart').insert({
          'user_id': userId,
          'meal_kit_id': mealKitId,
          'quantity': quantity,
        });
      }

      // Return updated cart
      return await fetchCart();
    } catch (e) {
      final logger = Logger('SupabaseApiClient');
      logger.warning('Error adding to cart: $e');
      throw Exception('Failed to add to cart: $e');
    }
  }

  @override
  Future<Cart> updateCartItem(String mealKitId, int quantity) async {
    try {
      final userId = supa.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      if (quantity <= 0) {
        // Remove item from cart if quantity is 0 or negative
        await supa
            .from('cart')
            .delete()
            .eq('user_id', userId)
            .eq('meal_kit_id', mealKitId);
      } else {
        // Update item quantity
        await supa
            .from('cart')
            .update({'quantity': quantity})
            .eq('user_id', userId)
            .eq('meal_kit_id', mealKitId);
      }

      // Return updated cart
      return await fetchCart();
    } catch (e) {
      final logger = Logger('SupabaseApiClient');
      logger.warning('Error updating cart item: $e');
      throw Exception('Failed to update cart item: $e');
    }
  }

  @override
  Future<Order> createOrder({
    required String addressId,
    required String deliveryWindowId,
    required bool cashOnDelivery,
  }) async {
    try {
      final userId = supa.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      // Get current cart items
      final cart = await fetchCart();
      if (cart.items.isEmpty) {
        throw Exception('Cannot create order with empty cart');
      }

      // Calculate total
      final totalCents = cart.totalCents;

      // Create order
      final orderRes = await supa
          .from('orders')
          .insert({
            'user_id': userId,
            'address_id': addressId,
            'delivery_window_id': deliveryWindowId,
            'cash_on_delivery': cashOnDelivery,
            'total_cents': totalCents,
            'status': 'pending',
          })
          .select()
          .single();

      // Create order items
      final orderItems = cart.items
          .map((item) => {
                'order_id': orderRes['id'],
                'meal_kit_id': item.mealKit.id,
                'quantity': item.quantity,
                'unit_price_cents': item.mealKit.priceCents,
              })
          .toList();

      await supa.from('order_items').insert(orderItems);

      // Clear the cart after successful order creation
      for (final item in cart.items) {
        await updateCartItem(item.mealKit.id, 0);
      }

      // Return the created order
      return await fetchOrderDetail(orderRes['id']);
    } catch (e) {
      final logger = Logger('SupabaseApiClient');
      logger.warning('Error creating order: $e');
      throw Exception('Failed to create order: $e');
    }
  }

  @override
  Future<List<Order>> fetchOrders() async {
    try {
      final res = await supa
          .from('orders')
          .select()
          .eq('user_id', supa.auth.currentUser!.id);
      return res
          .map((e) => Order.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<Order> fetchOrderDetail(String orderId) async {
    try {
      final res = await supa.from('orders').select().eq('id', orderId).single();
      return Order.fromJson(Map<String, dynamic>.from(res));
    } catch (e) {
      throw Exception('Failed to fetch order: $e');
    }
  }

  Future<String> addAddress({
    required String label,
    required String line1,
    double? lat,
    double? lng,
    String? notes,
  }) async {
    try {
      final res = await supa
          .from('addresses')
          .insert({
            'user_id': supa.auth.currentUser!.id,
            'label': label,
            'line1': line1,
            'latitude': lat,
            'longitude': lng,
            'notes': notes,
          })
          .select('id')
          .single();
      return res['id'] as String;
    } catch (e) {
      throw Exception('Failed to add address: $e');
    }
  }

  // Mock data fallbacks
  List<MealKit> _getMockMealKits() {
    return [
      MealKit(
        id: '1',
        title: 'Misir Wat',
        description: 'Spiced red lentils with berbere spice blend',
        priceCents: 1299,
        imageUrl:
            'https://images.unsplash.com/photo-1546833999/b9f581a1996d?w=400',
      ),
      MealKit(
        id: '2',
        title: 'Gomen',
        description: 'Collard greens sautéed with garlic and ginger',
        priceCents: 1199,
        imageUrl:
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
      ),
      MealKit(
        id: '3',
        title: 'Kitfo',
        description: 'Ethiopian beef tartare with spices and clarified butter',
        priceCents: 1899,
        imageUrl:
            'https://images.unsplash.com/photo-1546833999/b9f581a1996d?w=400',
      ),
      MealKit(
        id: '4',
        title: 'Atkilt Alicha',
        description:
            'Mild turmeric-spiced vegetables with potatoes and carrots',
        priceCents: 1099,
        imageUrl:
            'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=400',
      ),
      MealKit(
        id: '5',
        title: 'Yebeg Tibs',
        description: 'Sautéed lamb with rosemary and vegetables',
        priceCents: 1999,
        imageUrl:
            'https://images.unsplash.com/photo-1546833999/b9f581a1996d?w=400',
      ),
    ];
  }
}
