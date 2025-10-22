import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/providers/cart_pricing_providers.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';

/// Helper: format currency (ETB for now)
String _formatCurrency(double value) => 'ETB ${value.toStringAsFixed(0)}';

/// Sticky bottom bar showing cart summary and "Review & Pay" button
class CartSummaryBar extends ConsumerWidget {
  final VoidCallback? onOpenDrawer;

  const CartSummaryBar({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartTotalsProvider);
    final remaining = ref.watch(remainingSelectionsProvider);
    final quota = ref.watch(boxQuotaProvider);
    final selected = quota - remaining;

    final theme = Theme.of(context);

    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.darkBrown.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              // Left: Selection status and total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$selected/$quota selected',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Total: ${_formatCurrency(totals.total)}',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkBrown.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),

              // Right: Review & Pay button
              ElevatedButton(
                onPressed: onOpenDrawer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Layout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Review & Pay',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
