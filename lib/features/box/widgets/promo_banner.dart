import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';

/// Dismissible promo code banner showing active discount
class PromoBanner extends ConsumerWidget {
  const PromoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoApplied = ref.watch(promoAppliedProvider);
    final promoCode = ref.watch(promoCodeProvider);
    final discountPercent = ref.watch(promoDiscountProvider);
    final theme = Theme.of(context);

    if (!promoApplied || promoCode == null) {
      return const SizedBox.shrink();
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.success600.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.success600.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.celebration,
              color: AppColors.success600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBrown,
                  ),
                  children: [
                    TextSpan(
                      text: "'$promoCode'",
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(
                      text:
                          ' applied! You\'re saving $discountPercent% on your first order.',
                    ),
                  ],
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                Icons.close,
                size: 18,
                color: AppColors.darkBrown.withOpacity(0.6),
              ),
              onPressed: () {
                ref.read(promoNotifierProvider.notifier).togglePromo();
              },
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }
}
