import 'package:flutter/material.dart';

/// Onboarding progress header showing user's position in the flow
/// Steps: 1. Box → 2. Window → 3. Recipes → 4. Address → 5. Checkout
class OnboardingProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const OnboardingProgressHeader({
    super.key,
    required this.currentStep,
    this.totalSteps = 5,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final steps = _getSteps();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Progress bar
          Row(
            children: List.generate(totalSteps * 2 - 1, (index) {
              if (index.isOdd) {
                // Connector line
                final isCompleted = (index ~/ 2) < currentStep - 1;
                return Expanded(
                  child: Container(
                    height: 2,
                    color: isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.3),
                  ),
                );
              } else {
                // Step indicator
                final stepIndex = index ~/ 2 + 1;
                final isCompleted = stepIndex < currentStep;
                final isCurrent = stepIndex == currentStep;

                return _buildStepIndicator(
                  context,
                  stepIndex,
                  isCompleted,
                  isCurrent,
                );
              }
            }),
          ),

          const SizedBox(height: 8),

          // Step labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(totalSteps, (index) {
              final stepIndex = index + 1;
              final isCurrent = stepIndex == currentStep;

              return Expanded(
                child: Text(
                  steps[index],
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                    color: isCurrent
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 11,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(
    BuildContext context,
    int stepNumber,
    bool isCompleted,
    bool isCurrent,
  ) {
    final theme = Theme.of(context);

    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted || isCurrent
            ? theme.colorScheme.primary
            : theme.colorScheme.surfaceContainer,
        border: Border.all(
          color: isCompleted || isCurrent
              ? theme.colorScheme.primary
              : theme.colorScheme.outline.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: isCurrent
            ? [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Center(
        child: isCompleted
            ? Icon(
                Icons.check,
                size: 16,
                color: theme.colorScheme.onPrimary,
              )
            : Text(
                '$stepNumber',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isCurrent
                      ? theme.colorScheme.onPrimary
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
      ),
    );
  }

  List<String> _getSteps() {
    return [
      'Box',
      'Window',
      'Recipes',
      'Address',
      'Checkout',
    ];
  }
}




