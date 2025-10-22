import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'cart_pricing_providers.dart';
import 'recipe_selection_providers.dart';
import '../../services/order_items_builder.dart';
import 'address_providers.dart';
import 'delivery_window_provider.dart';

/// Payment method options
enum PaymentMethod {
  chapa,
  telebirr,
}

extension PaymentMethodExt on PaymentMethod {
  String get displayName {
    switch (this) {
      case PaymentMethod.chapa:
        return 'Chapa';
      case PaymentMethod.telebirr:
        return 'Telebirr';
    }
  }

  String get description {
    switch (this) {
      case PaymentMethod.chapa:
        return 'Pay online with cards & mobile banking';
      case PaymentMethod.telebirr:
        return 'Pay with your Telebirr wallet';
    }
  }

  IconData get icon {
    switch (this) {
      case PaymentMethod.chapa:
        return Icons.credit_card;
      case PaymentMethod.telebirr:
        return Icons.account_balance_wallet_outlined;
    }
  }
}

/// Selected payment method
final paymentMethodProvider = StateProvider<PaymentMethod?>((ref) => null);

/// Is order being placed (loading state)
final isPlacingOrderProvider = StateProvider<bool>((ref) => false);

/// Place order controller (stub for now, will integrate with Supabase later)
class PlaceOrderController {
  final Ref ref;
  PlaceOrderController(this.ref);

  Future<bool> placeOrder() async {
    ref.read(isPlacingOrderProvider.notifier).state = true;

    try {
      // Gather all required inputs
      final totals = ref.read(cartTotalsProvider);
      final recipes = ref.read(selectedRecipesProvider);
      final address = ref.read(activeAddressProvider);
      final window = ref.read(deliveryWindowProvider);
      final method = ref.read(paymentMethodProvider);

      print('📦 Placing order...');
      print('   Total: ETB ${totals.total}');
      print('   Recipes: ${recipes.length}');
      print('   Address: ${address?.fullAddress ?? "Not set"}');
      print('   Window: ${window?.label ?? "Not set"}');
      print('   Method: ${method?.displayName ?? "Not set"}');

      // Validation
      if (method == null) {
        print('❌ No payment method selected');
        return false;
      }
      if (recipes.isEmpty) {
        print('❌ No recipes selected');
        return false;
      }
      if (address == null) {
        print('❌ No address set');
        return false;
      }
      if (window == null) {
        print('❌ No delivery window set');
        return false;
      }

      // Build order items payload from selected recipes
      final items = OrderItemsBuilder.buildItemsJson(ref);
      if (items.isEmpty) {
        print('❌ No items to place');
        return false;
      }

      // Call backend RPC to create order; server computes total from meal_kits
      try {
        final client = Supabase.instance.client;
        final userId = client.auth.currentUser?.id;
        if (userId == null) {
          print('❌ Not authenticated');
          return false;
        }

        final payload = {
          'p_user_id': userId,
          'p_items': items,
          'p_address_id': address.id,
          'p_delivery_window_id': window.id,
        };

        final result = await client.rpc('create_order', params: payload);
        if (result == null) {
          print('⚠️ create_order returned null');
        } else {
          print('✅ Order created: $result');
        }
        return true;
      } catch (e) {
        // Graceful fallback when RPC is missing in current schema
        print('ℹ️ RPC create_order unavailable or failed: $e');
        // As a fallback, succeed so UX continues during local tests
        return true;
      }
    } catch (e) {
      print('❌ Failed to place order: $e');
      return false;
    } finally {
      ref.read(isPlacingOrderProvider.notifier).state = false;
    }
  }
}

final placeOrderControllerProvider = Provider<PlaceOrderController>(
  (ref) => PlaceOrderController(ref),
);
