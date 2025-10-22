import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/layout_constants.dart';
import '../../core/providers/recipe_selection_providers.dart';
import '../delivery/ui/receipt_card.dart';

/// Post-checkout screen: delivery reassurance + modify window chip
/// Single screen shown after order placement
class DeliveryConfirmationScreen extends ConsumerWidget {
  final String orderId;

  const DeliveryConfirmationScreen({
    super.key,
    required this.orderId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final selectedRecipes = ref.watch(selectedRecipesProvider);

    // Calculate week number (simple: week of year)
    final weekNumber = ((DateTime.now()
                .difference(DateTime(DateTime.now().year, 1, 1))
                .inDays) /
            7)
        .ceil();

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: LayoutConstants.maxContentWidth),
            child: ListView(
              padding: const EdgeInsets.all(LayoutConstants.cardPaddingLarge),
              children: [
                // Success icon
                Container(
                  padding:
                      const EdgeInsets.all(LayoutConstants.cardPaddingLarge),
                  decoration: BoxDecoration(
                    color: AppColors.success600.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AppColors.success600,
                  ),
                ),

                const SizedBox(height: LayoutConstants.space6),

                // Title
                Text(
                  'Order Confirmed!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: LayoutConstants.space3),

                // Subtitle
                Text(
                  'Your fresh ingredients are on the way',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkBrown.withValues(alpha: 0.8),
                  ),
                ),

                const SizedBox(height: LayoutConstants.space8),

                // Apple Wallet-style mini receipt
                ReceiptCard(
                  weekNumber: weekNumber,
                  totalMeals: selectedRecipes.length,
                  badgeIcons: const [
                    Icons.eco,
                    Icons.star,
                    Icons.local_fire_department,
                  ],
                ),

                const SizedBox(height: LayoutConstants.space6),

                // Reassurance card
                Container(
                  padding: const EdgeInsets.all(LayoutConstants.cardPadding),
                  decoration: BoxDecoration(
                    color: AppColors.peach50,
                    borderRadius:
                        BorderRadius.circular(LayoutConstants.radiusLarge),
                    border: Border.all(
                      color: AppColors.darkBrown.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _ReassuranceRow(
                        Icons.phone_outlined,
                        'We\'ll call you before every delivery',
                      ),
                      const SizedBox(height: LayoutConstants.space2),
                      _ReassuranceRow(
                        Icons.schedule_outlined,
                        'Your delivery window is confirmed',
                      ),
                      const SizedBox(height: LayoutConstants.space2),
                      _ReassuranceRow(
                        Icons.local_shipping_outlined,
                        'Track your order in real-time',
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: LayoutConstants.space8),

                // Primary CTA
                SizedBox(
                  width: double.infinity,
                  height: LayoutConstants.buttonHeightLarge,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(LayoutConstants.radiusLarge),
                      ),
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: LayoutConstants.space3),

                // Secondary action
                Center(
                  child: TextButton(
                    onPressed: () => context.go('/orders'),
                    child: Text(
                      'View My Orders',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkBrown.withValues(alpha: 0.7),
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ReassuranceRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReassuranceRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: LayoutConstants.iconSmall,
          color: AppColors.darkBrown.withValues(alpha: 0.6),
        ),
        const SizedBox(width: LayoutConstants.space2),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkBrown.withValues(alpha: 0.7),
                ),
          ),
        ),
      ],
    );
  }
}
