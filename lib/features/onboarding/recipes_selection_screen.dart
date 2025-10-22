import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/app_colors.dart';
import '../../core/providers/recipe_selection_providers.dart';
import '../../core/widgets/cart_summary_bar.dart';
import '../../core/widgets/mini_cart_drawer.dart';
import '../box/providers/box_selection_providers.dart';
import 'providers/user_onboarding_progress_provider.dart';
import 'widgets/onboarding_scaffold.dart';
import 'widgets/filter_bar.dart';
import 'widgets/recipe_grid_card.dart';
import '../../features/delivery/ui/delivery_window_chip.dart';
import '../../features/delivery/ui/delivery_gradient_bg.dart';
import '../../features/delivery/state/delivery_providers.dart';
import '../../features/delivery/ui/location_toggle.dart';

/// Recipes Selection Screen - Step 3 of unified onboarding
/// Two-column grid with auto-select, filters, and confetti celebration
class RecipesSelectionScreen extends ConsumerStatefulWidget {
  const RecipesSelectionScreen({super.key});

  @override
  ConsumerState<RecipesSelectionScreen> createState() =>
      _RecipesSelectionScreenState();
}

class _RecipesSelectionScreenState
    extends ConsumerState<RecipesSelectionScreen> {
  @override
  void initState() {
    super.initState();
    _performAutoSelection();
  }

  Future<void> _performAutoSelection() async {
    // Smart delivery provider handles auto-selection with 1s delay
    // No need to manually trigger - it auto-runs in init()

    // Wait for recipes to load
    await Future.delayed(const Duration(milliseconds: 500));

    if (!mounted) return;

    final recipesAsync = ref.read(recipesProvider);
    final selectedIds = ref.read(selectedRecipesProvider);
    final quota = ref.read(boxQuotaProvider);

    // Only auto-select if nothing selected yet (and quota > 0)
    if (selectedIds.isEmpty && recipesAsync.value != null) {
      final recipes = recipesAsync.value!;
      if (recipes.isEmpty) return;

      // Pick top-rated or chef's choice recipes
      final autoSelectIds = recipes
          .where((r) =>
              r.tags.any((t) => t.toLowerCase().contains("chef")) ||
              r.tags.any((t) => t.toLowerCase().contains("recommended")))
          .take(quota)
          .map((r) => r.id)
          .toList();

      // If not enough chef's choice, fill with first recipes
      if (autoSelectIds.length < quota) {
        final needed = quota - autoSelectIds.length;
        final additional = recipes
            .where((r) => !autoSelectIds.contains(r.id))
            .take(needed)
            .map((r) => r.id);
        autoSelectIds.addAll(additional);
      }

      if (autoSelectIds.isNotEmpty) {
        ref.read(selectedRecipesProvider.notifier).setAll(autoSelectIds);
        print('🤖 Auto-selected ${autoSelectIds.length} recipes');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipesAsync = ref.watch(recipesProvider);
    final filteredRecipes = ref.watch(filteredRecipesProvider);
    final theme = Theme.of(context);

    // Listen for selection nudges and show snackbar
    ref.listen(selectionNudgeProvider, (_, next) {
      if (next.showOverCap) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "You've reached your box limit. Remove one or use Auto-complete.",
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
      if (next.showSwapRequired) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Your box is full! Remove a recipe first, or tap Swap to replace one.",
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
            action: SnackBarAction(
              label: 'Auto-complete',
              textColor: AppColors.gold,
              onPressed: () {
                ref.read(autoSelectControllerProvider).fillRemaining();
              },
            ),
          ),
        );
      }
      if (next.showSelectBoxFirst) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select your box size first'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 2),
          ),
        );
      }
    });

    final dwAsync = ref.watch(deliveryWindowControllerProvider);
    final dw = dwAsync.value;

    return OnboardingScaffold(
      currentStep: OnboardingStep.recipes,
      showBackButton: true,
      child: Stack(
        children: [
          // Gradient background (dynamic based on time of day)
          if (dw != null)
            Positioned.fill(
              child: DeliveryGradientBg(daypart: dw.daypart),
            ),

          // Main content
          CustomScrollView(
            slivers: [
              // Delivery window chip + location toggle
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      const DeliveryWindowChip(),
                      const SizedBox(height: 8),
                      const LocationToggle(),
                    ],
                  ),
                ),
              ),

              // Filter bar
              const SliverToBoxAdapter(
                child: FilterBar(),
              ),

              // Section header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    'Choose your recipes',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              ),

              // Recipe grid
              recipesAsync.when(
                data: (recipes) {
                  if (filteredRecipes.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            'No recipes match your filters',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      ),
                    );
                  }

                  return SliverPadding(
                    padding: const EdgeInsets.all(16),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.72,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final recipe = filteredRecipes[index];
                          return RecipeGridCard(recipe: recipe);
                        },
                        childCount: filteredRecipes.length,
                      ),
                    ),
                  );
                },
                loading: () => const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ),
                error: (error, stack) => SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        'Failed to load recipes',
                        style: TextStyle(color: AppColors.error600),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom padding for cart summary bar
              const SliverToBoxAdapter(
                child: SizedBox(height: 110),
              ),
            ],
          ),

          // Cart summary bar (sticky bottom)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CartSummaryBar(
              onOpenDrawer: () => showMiniCartDrawer(context, ref),
            ),
          ),
        ],
      ),
    );
  }
}
