import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/providers/cart_pricing_providers.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';

/// Helper: format currency (ETB)
String _formatCurrency(double value) => 'ETB ${value.toStringAsFixed(0)}';

/// Show mini cart drawer as modal bottom sheet
Future<void> showMiniCartDrawer(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.offWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) => ProviderScope(
      parent: ProviderScope.containerOf(context),
      child: const _MiniCartDrawer(),
    ),
  );
}

class _MiniCartDrawer extends ConsumerWidget {
  const _MiniCartDrawer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final totals = ref.watch(cartTotalsProvider);
    final quota = ref.watch(boxQuotaProvider);
    final remaining = ref.watch(remainingSelectionsProvider);
    final selected = quota - remaining;
    final canProceed = remaining == 0;

    final selectedIds = ref.watch(selectedRecipesProvider);
    final allRecipes = ref.watch(recipesProvider).value ?? [];
    final selectedRecipes = allRecipes
        .where((r) => selectedIds.contains(r.id))
        .toList();

    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (ctx, scrollCtrl) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Your box',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.darkBrown,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Under-cap warning
            if (!canProceed)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.amber.shade200),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 20,
                      color: AppColors.darkBrown,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add $remaining more recipe${remaining == 1 ? '' : 's'} to your box to continue.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.darkBrown,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Scrollable content
            Expanded(
              child: ListView(
                controller: scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                children: [
                  // Selected recipes list
                  if (selectedRecipes.isNotEmpty)
                    ...selectedRecipes.map((r) => _RecipeRow(recipe: r)),

                  if (selectedRecipes.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 32),
                      child: Center(
                        child: Text(
                          'No recipes selected yet',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),

                  const SizedBox(height: 12),

                  // People × Meals context
                  Text(
                    '${totals.people} people × $selected recipe${selected == 1 ? '' : 's'} = ${totals.servings} servings',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.darkBrown,
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Totals breakdown
                  _TotalsBlock(totals: totals),

                  const SizedBox(height: 12),

                  // Promo info
                  const _PromoRow(),

                  const SizedBox(height: 16),

                  // Secondary actions
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: selectedRecipes.isEmpty
                            ? null
                            : () {
                                ref
                                    .read(selectedRecipesProvider.notifier)
                                    .clear();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkBrown,
                        ),
                        child: const Text('Clear all'),
                      ),
                      const SizedBox(width: 12),
                      OutlinedButton(
                        onPressed: canProceed
                            ? null
                            : () {
                                ref
                                    .read(autoSelectControllerProvider)
                                    .fillRemaining();
                              },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.gold,
                        ),
                        child: const Text('Auto-complete'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Primary CTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: canProceed
                          ? () {
                              Navigator.of(context).pop();
                              context.go('/onboarding/map-picker');
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.gold,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        'Proceed to Delivery  •  ${_formatCurrency(totals.total)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Recipe row in cart
class _RecipeRow extends StatelessWidget {
  final Recipe recipe;

  const _RecipeRow({required this.recipe});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: recipe.imageUrl.isEmpty
                ? Container(
                    width: 72,
                    height: 72,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: const Icon(Icons.restaurant_menu, size: 32),
                  )
                : Image.network(
                    recipe.imageUrl,
                    width: 72,
                    height: 72,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 72,
                      height: 72,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.restaurant_menu, size: 32),
                    ),
                  ),
          ),
          const SizedBox(width: 12),

          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (recipe.tags.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      recipe.tags.take(2).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '${recipe.prepMinutes + recipe.cookMinutes} min • ${recipe.calories} kcal',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
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

    final rows = <_LineItem>[
      _LineItem('Subtotal', totals.subtotal),
      if (totals.discount > 0) _LineItem('Discount (JOIN40)', -totals.discount),
      _LineItem('VAT (15%)', totals.vat),
      _LineItem('Delivery', totals.delivery, isFree: totals.delivery == 0),
    ];

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          for (final li in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Text(
                    li.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    li.isFree
                        ? 'FREE'
                        : (li.value >= 0 ? '' : '−') +
                              _formatCurrency(li.value.abs()),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: li.isFree
                          ? AppColors.success600
                          : li.value < 0
                          ? AppColors.success600
                          : AppColors.darkBrown,
                      fontWeight: li.isFree || li.value < 0
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
                'Total due this week',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Text(
                _formatCurrency(totals.total),
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _LineItem {
  final String label;
  final double value;
  final bool isFree;

  _LineItem(this.label, this.value, {this.isFree = false});
}

/// Promo info row
class _PromoRow extends ConsumerWidget {
  const _PromoRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final promoApplied = ref.watch(promoAppliedProvider);
    final theme = Theme.of(context);

    if (!promoApplied) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.success600.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.success600.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, size: 18, color: AppColors.success600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'JOIN40 promo applied! You\'re saving 40% on your first order.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.darkBrown,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
