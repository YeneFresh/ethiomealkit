import 'package:flutter/material.dart';
import '../../core/design_tokens.dart';

/// Retention nudges and progress indicators for recipe selection.
/// Includes auto-select banner, progress bar, and social proof.
class HandpickedBanner extends StatelessWidget {
  final VoidCallback onDismiss;

  const HandpickedBanner({
    super.key,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.all(Yf.s16),
      padding: EdgeInsets.all(Yf.s16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: Yf.borderRadius20,
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            padding: EdgeInsets.all(Yf.s8),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.auto_awesome,
              size: 20,
              color: theme.colorScheme.onPrimary,
            ),
          ),

          SizedBox(width: Yf.s12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Handpicked for you',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: Yf.s4),
                Text(
                  'We selected recipes based on your preferences. Swap any time!',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onPrimaryContainer
                        .withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: Yf.s8),

          // Dismiss button
          IconButton(
            icon: const Icon(Icons.close),
            iconSize: 20,
            color: theme.colorScheme.onPrimaryContainer,
            onPressed: onDismiss,
            tooltip: 'Dismiss',
          ),
        ],
      ),
    );
  }
}

/// Progress indicator showing recipe selection status.
class SelectionProgress extends StatelessWidget {
  final int selected;
  final int total;
  final bool showSocialProof;

  const SelectionProgress({
    super.key,
    required this.selected,
    required this.total,
    this.showSocialProof = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total > 0 ? selected / total : 0.0;
    final isComplete = selected >= total && total > 0;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: Yf.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with count
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isComplete
                    ? '✅ Selection Complete!'
                    : total > 0
                        ? 'Selected $selected / $total Recipes'
                        : 'Select recipes for this week',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: Yf.s8,
                  vertical: Yf.s4,
                ),
                decoration: BoxDecoration(
                  color: isComplete
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: Yf.borderRadius12,
                ),
                child: Text(
                  '$selected/$total',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isComplete
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          SizedBox(height: Yf.s8),

          // Progress bar
          ClipRRect(
            borderRadius: Yf.borderRadius12,
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                isComplete
                    ? theme.colorScheme.primary
                    : theme.colorScheme.secondary,
              ),
            ),
          ),

          // Social proof (if enabled and not complete)
          if (showSocialProof && !isComplete) ...[
            SizedBox(height: Yf.s8),
            Row(
              children: [
                Icon(
                  Icons.people_outline,
                  size: 16,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                SizedBox(width: Yf.s4),
                Text(
                  'Most choose 3–4 meals per week',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// Quota full indicator shown when user tries to exceed allowance.
class QuotaFullSnackBar extends SnackBar {
  QuotaFullSnackBar({
    super.key,
    required BuildContext context,
  }) : super(
          content: const Row(
            children: [
              Icon(Icons.info_outline, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Max reached — swap one to add',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        );
}
