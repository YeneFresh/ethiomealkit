import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/models/address.dart';
import 'package:ethiomealkit/core/utils/currency.dart';
// import '../delivery/ui/delivery_window_chip.dart'; // no longer used on Pay
import 'package:ethiomealkit/core/providers/payment_providers.dart';
import 'package:ethiomealkit/core/providers/payment_controller.dart';
import 'package:ethiomealkit/core/providers/cart_pricing_providers.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';
import 'package:ethiomealkit/core/providers/address_providers.dart';
import 'package:ethiomealkit/core/providers/delivery_window_provider.dart';
import 'package:ethiomealkit/features/recipes/widgets/delivery_summary_bar.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';
import 'package:ethiomealkit/features/onboarding/widgets/onboarding_scaffold.dart';
import 'package:ethiomealkit/features/onboarding/widgets/delivery_edit_modal.dart';

/// Pay Screen - Step 5 of unified onboarding
/// Final review and payment method selection
class PayScreen extends ConsumerStatefulWidget {
  const PayScreen({super.key});

  @override
  ConsumerState<PayScreen> createState() => _PayScreenState();
}

class _PayScreenState extends ConsumerState<PayScreen> {
  Future<void> _placeOrder() async {
    final method = ref.read(paymentMethodProvider);
    // final totals = ref.read(cartTotalsProvider);
    final recipes = ref.read(selectedRecipesProvider);
    final address = ref.read(activeAddressProvider);

    if (method == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a payment method'),
          backgroundColor: AppColors.error600,
        ),
      );
      return;
    }

    if (recipes.isEmpty || address == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please complete all fields to continue'),
          backgroundColor: AppColors.error600,
        ),
      );
      return;
    }

    final orderId = await ref
        .read(paymentControllerProvider.notifier)
        .placeOrderAndPay();

    if (orderId != null && mounted) {
      // Mark pay step as complete
      await ref
          .read(userOnboardingProgressProvider.notifier)
          .completeStep(OnboardingStep.pay);

      // Navigate to success screen
      context.go('/order-success');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to place order. Please try again.'),
          backgroundColor: AppColors.error600,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final totals = ref.watch(cartTotalsProvider);
    final selectedIds = ref.watch(selectedRecipesProvider);
    final allRecipes = ref.watch(recipesProvider).value ?? [];
    final selectedRecipes = allRecipes
        .where((r) => selectedIds.contains(r.id))
        .toList();
    final address = ref.watch(activeAddressProvider);
    final window = ref.watch(deliveryWindowProvider);
    final method = ref.watch(paymentMethodProvider);
    final isPlacing = ref.watch(isPlacingOrderProvider);

    final theme = Theme.of(context);

    return OnboardingScaffold(
      currentStep: OnboardingStep.pay,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          Text(
            'Review & Pay',
            style: theme.textTheme.titleLarge?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Almost there! Review your order and complete payment.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),

          const SizedBox(height: 20),

          // Order Summary Card
          _OrderSummaryCard(recipes: selectedRecipes, totals: totals),

          const SizedBox(height: 12),

          // Address & Delivery Card
          _AddressAndDeliveryCard(address: address, window: window),

          const SizedBox(height: 12),

          // Payment Method Selector
          const _PaymentMethodSelector(),

          const SizedBox(height: 24),

          // Place Order Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  method != null &&
                      selectedRecipes.isNotEmpty &&
                      address != null &&
                      !isPlacing
                  ? _placeOrder
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(Layout.cardRadius),
                ),
              ),
              child: isPlacing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Place Order • ${CurrencyFmt.format(totals.total)}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),

          const SizedBox(height: 16),

          // Security message
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                'Payments are encrypted and processed securely.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Order Summary Card
class _OrderSummaryCard extends StatelessWidget {
  final List<Recipe> recipes;
  final CartTotals totals;

  const _OrderSummaryCard({required this.recipes, required this.totals});

  @override
  Widget build(BuildContext context) {
    return _CardWrap(
      title: 'Order Summary',
      child: Column(
        children: [
          // Recipe list
          ...recipes.map((r) => _RecipeLine(recipe: r)),

          const Divider(height: 24),

          // Totals breakdown
          _TotalsBlock(totals: totals),
        ],
      ),
    );
  }
}

/// Address and Delivery Card with inline editing
class _AddressAndDeliveryCard extends ConsumerWidget {
  final Address? address;
  final DeliveryWindow? window;

  const _AddressAndDeliveryCard({required this.address, required this.window});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Copy to local variable for null promotion
    final w = window;
    final theme = Theme.of(context);

    return _CardWrap(
      title: 'Delivery Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Address section
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.home_outlined, size: 20, color: AppColors.gold),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Deliver to',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      address?.fullAddress ?? 'No address set',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => context.push('/onboarding/map-picker'),
                style: TextButton.styleFrom(foregroundColor: AppColors.gold),
                child: const Text('Edit'),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: Colors.grey[300], height: 1),
          const SizedBox(height: 16),

          // Delivery window section (standardized)
          DeliverySummaryBar(
            location: w?.city ?? 'Addis Ababa',
            timeSlot: w != null
                ? '${w.dayLabel} • ${w.timeLabel}'
                : 'No window selected',
            recommended: w?.isRecommended == true,
            onEdit: () => showDeliveryEditModal(context, ref),
          ),
        ],
      ),
    );
  }
}

/// Payment Method Selector
class _PaymentMethodSelector extends ConsumerWidget {
  const _PaymentMethodSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final method = ref.watch(paymentMethodProvider);

    return _CardWrap(
      title: 'Payment Method',
      child: Column(
        children: [
          _PaymentTile(
            method: PaymentMethod.chapa,
            selected: method == PaymentMethod.chapa,
            onTap: () => ref.read(paymentMethodProvider.notifier).state =
                PaymentMethod.chapa,
          ),
          const SizedBox(height: 12),
          _PaymentTile(
            method: PaymentMethod.telebirr,
            selected: method == PaymentMethod.telebirr,
            onTap: () => ref.read(paymentMethodProvider.notifier).state =
                PaymentMethod.telebirr,
          ),
        ],
      ),
    );
  }
}

// ========== COMPONENTS ==========

/// Recipe line item
class _RecipeLine extends StatelessWidget {
  final Recipe recipe;

  const _RecipeLine({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: recipe.imageUrl.isEmpty
                ? Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image, color: Colors.grey),
                  )
                : Image.network(
                    recipe.imageUrl,
                    width: 56,
                    height: 56,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 56,
                      height: 56,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image, color: Colors.grey),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              recipe.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Totals breakdown block
class _TotalsBlock extends StatelessWidget {
  final CartTotals totals;

  const _TotalsBlock({required this.totals});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final rows = <MapEntry<String, double>>[
      MapEntry('Subtotal', totals.subtotal),
      if (totals.discount > 0) MapEntry('Discount (JOIN40)', -totals.discount),
      MapEntry('VAT (15%)', totals.vat),
      MapEntry('Delivery', totals.delivery),
    ];

    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Text(
                  row.key,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBrown,
                  ),
                ),
                const Spacer(),
                Text(
                  row.value == 0 && row.key == 'Delivery'
                      ? 'FREE'
                      : CurrencyFmt.formatWithSign(row.value),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color:
                        row.value < 0 ||
                            (row.value == 0 && row.key == 'Delivery')
                        ? AppColors.success600
                        : AppColors.darkBrown,
                    fontWeight:
                        row.value < 0 ||
                            (row.value == 0 && row.key == 'Delivery')
                        ? FontWeight.w600
                        : FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        const Divider(height: 20),
        Row(
          children: [
            Text(
              'Total due',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              CurrencyFmt.format(totals.total),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Payment method tile
class _PaymentTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? AppColors.gold
                : AppColors.darkBrown.withOpacity(0.2),
            width: selected ? 2 : 1,
          ),
          color: selected ? AppColors.gold.withOpacity(0.05) : Colors.white,
        ),
        child: Row(
          children: [
            Icon(
              method.icon,
              color: selected ? AppColors.gold : AppColors.darkBrown,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    method.displayName,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    method.description,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Radio<bool>(
              value: true,
              groupValue: selected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.gold,
            ),
          ],
        ),
      ),
    );
  }
}

// _LabeledRow unused; removed to satisfy linter

/// Card wrapper
class _CardWrap extends StatelessWidget {
  final String title;
  final Widget child;

  const _CardWrap({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      elevation: 1,
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}
