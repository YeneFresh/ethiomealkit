import 'package:flutter/material.dart';
import 'design_tokens.dart';
import 'analytics.dart';

/// YeneFresh UI States - 2025 Edition
/// Investor-grade loading, empty, and error states

// =============================================================================
// SKELETON LOADERS - Shimmer effect for loading states
// =============================================================================

/// Skeleton loader for recipe cards
class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: Yf.recipeCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image skeleton
          _SkeletonBox(
            width: double.infinity,
            height: 200,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(Yf.r20),
              topRight: Radius.circular(Yf.r20),
            ),
          ),
          Padding(
            padding: Yf.cardPadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title skeleton
                const _SkeletonBox(width: 180, height: 20),
                SizedBox(height: Yf.s8),
                // Tags skeleton
                Row(
                  children: [
                    _SkeletonBox(
                        width: 60, height: 24, borderRadius: Yf.borderRadius12),
                    SizedBox(width: Yf.s8),
                    _SkeletonBox(
                        width: 80, height: 24, borderRadius: Yf.borderRadius12),
                  ],
                ),
                SizedBox(height: Yf.s12),
                // Button skeleton
                const _SkeletonBox(width: double.infinity, height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Skeleton loader for order list items
class OrderListSkeleton extends StatelessWidget {
  const OrderListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: Yf.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SkeletonBox(
                    width: 40, height: 40, borderRadius: Yf.borderRadius12),
                SizedBox(width: Yf.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SkeletonBox(width: 150, height: 18),
                      SizedBox(height: Yf.s4),
                      const _SkeletonBox(width: 100, height: 14),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: Yf.s12),
            const _SkeletonBox(width: double.infinity, height: 14),
          ],
        ),
      ),
    );
  }
}

/// Basic shimmer skeleton box
class _SkeletonBox extends StatefulWidget {
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const _SkeletonBox({
    required this.width,
    required this.height,
    this.borderRadius,
  });

  @override
  State<_SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<_SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
    _animation = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? Colors.white.withValues(alpha: 0.08)
        : Yf.ink600.withValues(alpha: 0.1);
    final highlightColor = isDark
        ? Colors.white.withValues(alpha: 0.12)
        : Yf.ink600.withValues(alpha: 0.15);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          width: widget.width == double.infinity ? null : widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: [
                _animation.value - 0.3,
                _animation.value,
                _animation.value + 0.3,
              ].map((e) => e.clamp(0.0, 1.0)).toList(),
              colors: [baseColor, highlightColor, baseColor],
            ),
          ),
        );
      },
    );
  }
}

// =============================================================================
// EMPTY STATES - Delightful empty state illustrations
// =============================================================================

/// Generic empty state with illustration, message, and CTA
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: Yf.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon illustration
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 64,
                color: theme.colorScheme.primary.withValues(alpha: 0.5),
              ),
            ),
            SizedBox(height: Yf.s24),

            // Title
            Text(
              title,
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Yf.s8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            // Action button
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: Yf.s24),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add_rounded),
                label: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined empty state for orders
class EmptyOrders extends StatelessWidget {
  final VoidCallback? onStartOrder;

  const EmptyOrders({super.key, this.onStartOrder});

  @override
  Widget build(BuildContext context) {
    return EmptyState(
      icon: Icons.receipt_long_outlined,
      title: 'No Orders Yet',
      message:
          'Your order history will appear here once you place your first order.',
      actionLabel: 'Start Your First Order',
      onAction: onStartOrder,
    );
  }
}

/// Predefined empty state for recipes
class EmptyRecipes extends StatelessWidget {
  const EmptyRecipes({super.key});

  @override
  Widget build(BuildContext context) {
    return const EmptyState(
      icon: Icons.restaurant_menu_rounded,
      title: 'No Recipes Available',
      message: 'New recipes are added every week. Check back soon!',
    );
  }
}

// =============================================================================
// ERROR STATES - Investor-grade error handling
// =============================================================================

/// Generic error state with retry capability
class ErrorState extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback? onRetry;
  final String? errorCode;

  const ErrorState({
    super.key,
    required this.title,
    required this.message,
    this.onRetry,
    this.errorCode,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Log error to analytics
    if (errorCode != null) {
      Analytics.error(
        error: errorCode!,
        context: {'title': title, 'message': message},
      );
    }

    return Center(
      child: Padding(
        padding: Yf.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Error icon
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Yf.error600.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Yf.error600,
              ),
            ),
            SizedBox(height: Yf.s24),

            // Title
            Text(
              title,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Yf.s8),

            // Message
            Text(
              message,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),

            // Error code (if available)
            if (errorCode != null) ...[
              SizedBox(height: Yf.s8),
              Text(
                'Error: $errorCode',
                style: theme.textTheme.labelSmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ],

            // Retry button
            if (onRetry != null) ...[
              SizedBox(height: Yf.s24),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Try Again'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Predefined error for network issues
class NetworkError extends StatelessWidget {
  final VoidCallback? onRetry;

  const NetworkError({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Connection Issue',
      message: 'Please check your internet connection and try again.',
      onRetry: onRetry,
      errorCode: 'NETWORK_ERROR',
    );
  }
}

/// Predefined error for data loading failures
class LoadingError extends StatelessWidget {
  final VoidCallback? onRetry;
  final String? details;

  const LoadingError({super.key, this.onRetry, this.details});

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      title: 'Failed to Load',
      message: details ?? 'Something went wrong. Please try again.',
      onRetry: onRetry,
      errorCode: 'LOADING_ERROR',
    );
  }
}




