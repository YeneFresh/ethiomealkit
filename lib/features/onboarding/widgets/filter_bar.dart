import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';

/// Horizontal scrollable filter bar for recipe tags
class FilterBar extends ConsumerWidget {
  const FilterBar({super.key});

  static const _filterOptions = [
    "Chef's Choice",
    'Gourmet',
    'Express',
    'Veggie',
    'Family',
    'Spicy',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeFilters = ref.watch(activeFiltersProvider);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _filterOptions.map((filter) {
            final isActive = activeFilters.contains(filter);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: Text(filter),
                selected: isActive,
                onSelected: (selected) {
                  final updated = Set<String>.from(activeFilters);
                  if (selected) {
                    updated.add(filter);
                  } else {
                    updated.remove(filter);
                  }
                  ref.read(activeFiltersProvider.notifier).state = updated;
                },
                selectedColor: AppColors.gold.withValues(alpha: 0.2),
                checkmarkColor: AppColors.darkBrown,
                backgroundColor: Colors.white,
                side: BorderSide(
                  color: isActive
                      ? AppColors.gold
                      : AppColors.darkBrown.withValues(alpha: 0.2),
                  width: isActive ? 2 : 1,
                ),
                labelStyle: TextStyle(
                  color: isActive ? AppColors.darkBrown : Colors.grey[700],
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  fontSize: 13,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
