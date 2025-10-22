import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/repo/cart_repository.dart';
import 'package:go_router/go_router.dart';

class CartBadge extends ConsumerWidget {
  final Color? backgroundColor;
  final Color? textColor;
  final double size;

  const CartBadge({
    super.key,
    this.backgroundColor,
    this.textColor,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final itemCount = cart.totalItems;

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.shopping_cart),
          onPressed: () => context.go('/cart'),
          tooltip: 'View Cart',
        ),
        if (itemCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: backgroundColor ?? Colors.red,
                borderRadius: BorderRadius.circular(size / 2),
              ),
              constraints: BoxConstraints(minWidth: size, minHeight: size),
              child: Text(
                itemCount > 99 ? '99+' : itemCount.toString(),
                style: TextStyle(
                  color: textColor ?? Colors.white,
                  fontSize: size * 0.6,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
