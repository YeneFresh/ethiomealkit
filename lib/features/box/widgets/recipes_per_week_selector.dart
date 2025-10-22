import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../providers/box_selection_providers.dart';

/// Selector for number of meals per week with pricing
class RecipesPerWeekSelector extends ConsumerWidget {
  const RecipesPerWeekSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedMealsProvider);
    final theme = Theme.of(context);
    final promoApplied = ref.watch(promoAppliedProvider);
    final discountPercent = ref.watch(promoDiscountProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'How many recipes would you like per week?',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 12),

        // 3 recipes
        _MealPlanCard(
          meals: 3,
          originalPrice: 55.0,
          discountPercent: promoApplied ? discountPercent : 0,
          isSelected: selected == 3,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedMealsProvider.notifier).state = 3;
          },
        ),
        const SizedBox(height: 12),

        // 4 recipes (popular)
        _MealPlanCard(
          meals: 4,
          originalPrice: 49.0,
          discountPercent: promoApplied ? discountPercent : 0,
          isSelected: selected == 4,
          isPopular: true,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedMealsProvider.notifier).state = 4;
          },
        ),
        const SizedBox(height: 12),

        // 5 recipes (best value)
        _MealPlanCard(
          meals: 5,
          originalPrice: 45.0,
          discountPercent: promoApplied ? discountPercent : 0,
          isSelected: selected == 5,
          isBestValue: true,
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(selectedMealsProvider.notifier).state = 5;
          },
        ),
      ],
    );
  }
}

class _MealPlanCard extends StatelessWidget {
  final int meals;
  final double originalPrice;
  final int discountPercent;
  final bool isSelected;
  final bool isPopular;
  final bool isBestValue;
  final VoidCallback onTap;

  const _MealPlanCard({
    required this.meals,
    required this.originalPrice,
    required this.discountPercent,
    required this.isSelected,
    this.isPopular = false,
    this.isBestValue = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final discountedPrice = originalPrice * (1 - discountPercent / 100);
    final hasDiscount = discountPercent > 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color:
                  isSelected ? AppColors.gold.withOpacity(0.1) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.darkBrown.withOpacity(0.15),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // Left: Meal info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '$meals recipes',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.darkBrown,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (isPopular)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.gold,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'POPULAR',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          if (isBestValue)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.success600,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'BEST VALUE',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$meals fresh recipes delivered weekly',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                // Right: Pricing
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (hasDiscount) ...[
                      Text(
                        'ETB ${originalPrice.toStringAsFixed(0)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[500],
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'ETB ${discountedPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? AppColors.gold
                                : AppColors.darkBrown,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ serving',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    if (hasDiscount)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.success600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Save $discountPercent%',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: AppColors.success600,
                          ),
                        ),
                      ),
                  ],
                ),

                // Selection indicator
                const SizedBox(width: 12),
                Icon(
                  isSelected ? Icons.check_circle : Icons.circle_outlined,
                  color: isSelected ? AppColors.gold : Colors.grey[400],
                  size: 28,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}



