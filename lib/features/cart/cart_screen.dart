import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repo/cart_repository.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder(
      future: ref.read(cartRepositoryProvider).getCart(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cart = snapshot.data!;
        if (cart.items.isEmpty) {
          return const Center(child: Text('Your cart is empty'));
        }
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                itemCount: cart.items.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final item = cart.items[index];
                  return ListTile(
                    title: Text(item.mealKit.title),
                    subtitle: Text('x${item.quantity} • ETB ${(item.mealKit.priceCents / 100).toStringAsFixed(2)}'),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Total ETB ${(cart.totalCents / 100).toStringAsFixed(2)}'),
            )
          ],
        );
      },
    );
  }
}



