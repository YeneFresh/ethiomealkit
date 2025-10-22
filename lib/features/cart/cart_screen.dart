import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/repo/cart_repository.dart';
import 'package:ethiomealkit/models/models.dart';
import 'package:go_router/go_router.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartNotifier = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Clear Cart'),
                    content: const Text(
                      'Are you sure you want to remove all items from your cart?',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Clear'),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  await cartNotifier.clearCart();
                }
              },
              child: const Text('Clear'),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : _buildCartItems(context, cart, cartNotifier),
      bottomNavigationBar: cart.items.isNotEmpty
          ? _buildBottomBar(context, cart, cartNotifier)
          : null,
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            size: 100,
            color: Colors.grey,
          ),
          const SizedBox(height: 24),
          const Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          const Text(
            'Add some delicious Ethiopian meal kits to get started!',
            style: TextStyle(fontSize: 16, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => context.go('/meals'),
            icon: const Icon(Icons.restaurant_menu),
            label: const Text('Browse Meals'),
            style: ElevatedButton.styleFrom(minimumSize: const Size(200, 48)),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItems(
    BuildContext context,
    Cart cart,
    CartNotifier cartNotifier,
  ) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: cart.items.length,
      itemBuilder: (context, index) {
        final item = cart.items[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.mealKit.imageUrl != null
                      ? Image.network(
                          item.mealKit.imageUrl!,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 80,
                              height: 80,
                              color: Colors.grey[300],
                              child: const Icon(
                                Icons.restaurant,
                                color: Colors.grey,
                              ),
                            );
                          },
                        )
                      : Container(
                          width: 80,
                          height: 80,
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.restaurant,
                            color: Colors.grey,
                          ),
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.mealKit.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'ETB ${(item.mealKit.priceCents / 100).toStringAsFixed(2)} each',
                        style: TextStyle(color: Colors.grey[600], fontSize: 14),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          IconButton(
                            onPressed: item.quantity > 1
                                ? () => cartNotifier.updateCartItem(
                                    item.mealKit.id,
                                    item.quantity - 1,
                                  )
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                            iconSize: 24,
                          ),
                          Container(
                            width: 40,
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.quantity.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                          IconButton(
                            onPressed: () => cartNotifier.updateCartItem(
                              item.mealKit.id,
                              item.quantity + 1,
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            iconSize: 24,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'ETB ${((item.mealKit.priceCents * item.quantity) / 100).toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      onPressed: () =>
                          cartNotifier.removeFromCart(item.mealKit.id),
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remove item',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBottomBar(
    BuildContext context,
    Cart cart,
    CartNotifier cartNotifier,
  ) {
    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total:',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                Text(
                  'ETB ${(cartNotifier.totalPriceCents / 100).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.go('/checkout'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Proceed to Checkout',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
