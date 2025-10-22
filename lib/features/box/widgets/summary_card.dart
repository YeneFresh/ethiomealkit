import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/app_colors.dart';
import '../providers/box_selection_providers.dart';

/// Summary card showing servings and reassurance copy
class SummaryCard extends ConsumerWidget {
  const SummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final people = ref.watch(selectedPeopleProvider);
    final meals = ref.watch(selectedMealsProvider);
    final theme = Theme.of(context);

    if (people == null || meals == null) {
      return const SizedBox.shrink();
    }

    final totalServings = people * meals;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.peach50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.darkBrown.withOpacity(0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main summary text
          RichText(
            text: TextSpan(
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppColors.darkBrown,
                height: 1.5,
              ),
              children: [
                const TextSpan(text: 'You will receive a box with '),
                TextSpan(
                  text: '$meals recipes',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' for '),
                TextSpan(
                  text: '$people ${people == 1 ? "person" : "people"}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: '.\nThat\'s '),
                TextSpan(
                  text: '$totalServings servings',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: ' per week.'),
              ],
            ),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Reassurance tags
          _ReassuranceTag(
            icon: Icons.receipt_long_outlined,
            text: 'No commitment',
          ),
          const SizedBox(height: 8),
          _ReassuranceTag(
            icon: Icons.local_shipping_outlined,
            text: 'Free delivery in Addis Ababa',
          ),
          const SizedBox(height: 8),
          _ReassuranceTag(
            icon: Icons.favorite_border,
            text: 'Change your plan any time',
          ),
        ],
      ),
    );
  }
}

class _ReassuranceTag extends StatelessWidget {
  final IconData icon;
  final String text;

  const _ReassuranceTag({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.success600,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 14,
            color: AppColors.darkBrown.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
