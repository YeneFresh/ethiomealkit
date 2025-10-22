import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Persistent stepper header showing 5-step onboarding progress
/// Box → Sign up → Recipes → Delivery → Pay
class StepperHeader extends StatelessWidget {
  final int currentStep; // 0-based index (0-4)

  const StepperHeader({super.key, required this.currentStep});

  @override
  Widget build(BuildContext context) {
    final steps = ['Box', 'Sign up', 'Recipes', 'Delivery', 'Pay'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= 600;

    return Container(
      color: AppColors.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: isWideScreen
          ? _buildEvenlyDistributed(steps)
          : _buildScrollable(steps),
    );
  }

  /// Desktop/tablet: evenly distributed across width
  Widget _buildEvenlyDistributed(List<String> steps) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(
        steps.length,
        (i) => _StepItem(
          stepNumber: i + 1,
          label: steps[i],
          isActive: i == currentStep,
          isCompleted: i < currentStep,
        ),
      ),
    );
  }

  /// Mobile: horizontally scrollable
  Widget _buildScrollable(List<String> steps) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: List.generate(
          steps.length,
          (i) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: _StepItem(
              stepNumber: i + 1,
              label: steps[i],
              isActive: i == currentStep,
              isCompleted: i < currentStep,
            ),
          ),
        ),
      ),
    );
  }
}

/// Individual step item in the stepper
class _StepItem extends StatelessWidget {
  final int stepNumber;
  final String label;
  final bool isActive;
  final bool isCompleted;

  const _StepItem({
    required this.stepNumber,
    required this.label,
    required this.isActive,
    required this.isCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final numberColor = isActive
        ? AppColors.gold
        : isCompleted
        ? AppColors.success600
        : Colors.grey[500];

    final labelColor = isActive
        ? AppColors.darkBrown
        : isCompleted
        ? AppColors.darkBrown.withOpacity(0.7)
        : Colors.grey[600];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Step number with checkmark if completed
        if (isCompleted)
          const Icon(Icons.check_circle, color: AppColors.success600, size: 20)
        else
          Text(
            '$stepNumber',
            style: TextStyle(
              color: numberColor,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

        const SizedBox(height: 2),

        // Active underline
        Container(
          height: 2,
          width: 22,
          decoration: BoxDecoration(
            color: isActive ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        const SizedBox(height: 4),

        // Step label
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: labelColor,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ],
    );
  }
}
