import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';

/// Horizontal selector for number of people (1-4)
class PeopleSelector extends ConsumerWidget {
  const PeopleSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedPeopleProvider);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Number of people',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.darkBrown,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) {
            final value = index + 1;
            final isSelected = selected == value;

            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: index < 3 ? 8 : 0),
                child: _PeopleChip(
                  value: value,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(selectedPeopleProvider.notifier).state = value;
                  },
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _PeopleChip extends StatelessWidget {
  final int value;
  final bool isSelected;
  final VoidCallback onTap;

  const _PeopleChip({
    required this.value,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.gold : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected
                    ? AppColors.gold
                    : AppColors.darkBrown.withOpacity(0.2),
                width: 2,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.person,
                  size: 32,
                  color: isSelected ? AppColors.darkBrown : Colors.grey[600],
                ),
                const SizedBox(height: 4),
                Text(
                  '$value',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isSelected ? AppColors.darkBrown : Colors.grey[700],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value == 1 ? 'person' : 'people',
                  style: TextStyle(
                    fontSize: 12,
                    color: isSelected
                        ? AppColors.darkBrown.withOpacity(0.8)
                        : Colors.grey[600],
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
