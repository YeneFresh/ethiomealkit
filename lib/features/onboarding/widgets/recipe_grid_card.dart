import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';
import 'package:ethiomealkit/core/providers/box_smart_selection_provider.dart';
import 'package:ethiomealkit/core/widgets/tag_chip.dart';

/// Grid recipe card for two-column layout
/// Tappable with animated selection state
class RecipeGridCard extends ConsumerWidget {
  final Recipe recipe;

  const RecipeGridCard({super.key, required this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIds = ref.watch(selectedRecipesProvider);
    final isSelected = selectedIds.contains(recipe.id);
    final atCap = ref.watch(atCapacityProvider);
    final canAdd = ref.watch(canAddMoreProvider);
    final theme = Theme.of(context);

    // Soft dimming (not full disable) when at cap
    final isDimmed = atCap && !isSelected;

    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();

        // If at capacity and trying to add, show swap hint
        if (atCap && !isSelected) {
          ref.read(selectionNudgeProvider.notifier).nudgeSwapRequired();
        } else {
          ref.read(selectedRecipesProvider.notifier).toggle(recipe.id);
        }
      },
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: isDimmed ? 0.65 : 1.0,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.gold.withValues(alpha: 0.15)
                : Colors.white,
            borderRadius: BorderRadius.circular(Layout.cardRadius),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? AppColors.gold.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.08),
                blurRadius: isSelected ? 8 : 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with selection indicator
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(Layout.cardRadius),
                      ),
                      child: _buildImage(theme),
                    ),

                    // Selection checkmark overlay
                    if (isSelected)
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.gold,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),

                    // "Swap" hint when at capacity (unselected)
                    if (isDimmed && atCap)
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.75),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: 12,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Swap',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Content
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Title - premium typography
                    Text(
                      recipe.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14.5,
                        height: 1.2,
                        color: AppColors.darkBrown,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Meta info with icons
                    Row(
                      children: [
                        Icon(Icons.timer, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.prepMinutes + recipe.cookMinutes} min',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Icon(
                          Icons.local_fire_department,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${recipe.calories} cals',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Ethiopian tag chips (max 3)
                    Wrap(
                      children: recipe.tags
                          .take(3)
                          .map((tag) => TagChip(label: tag))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImage(ThemeData theme) {
    if (recipe.imageUrl.isEmpty) {
      return Container(
        width: double.infinity,
        color: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.restaurant_menu,
          size: 48,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
        ),
      );
    }

    // Handle both asset and network images
    if (recipe.imageUrl.startsWith('http')) {
      return Image.network(
        recipe.imageUrl,
        width: double.infinity,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: double.infinity,
            color: theme.colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.restaurant_menu,
              size: 48,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
            ),
          );
        },
      );
    }

    return Image.asset(
      recipe.imageUrl,
      width: double.infinity,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: double.infinity,
          color: theme.colorScheme.surfaceContainerHighest,
          child: Icon(
            Icons.restaurant_menu,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        );
      },
    );
  }
}
