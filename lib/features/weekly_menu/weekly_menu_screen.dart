import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/features/weekly_menu/widgets/gate_card.dart';
import 'package:ethiomealkit/features/delivery/delivery_gate_banner.dart';
import 'package:ethiomealkit/features/weekly_menu/weekly_menu_providers.dart';

class WeeklyMenuScreen extends ConsumerStatefulWidget {
  const WeeklyMenuScreen({super.key});

  @override
  ConsumerState<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends ConsumerState<WeeklyMenuScreen> {
  @override
  Widget build(BuildContext context) {
    final deliveryGate = ref.watch(deliveryGateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: theme.colorScheme.surface,
            foregroundColor: theme.colorScheme.onSurface,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                "This Week's Menu",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
            ),
          ),

          // Delivery Gate Banner (shows when not confirmed)
          SliverToBoxAdapter(
            child: deliveryGate.when(
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
              data: (gateData) {
                final isConfirmed = gateData?['is_delivery_confirmed'] == true;
                if (isConfirmed) return const SizedBox.shrink();
                return const DeliveryGateBanner();
              },
            ),
          ),

          // Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: deliveryGate.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (error, stack) => _buildErrorState(theme, error),
                data: (gateData) {
                  final isConfirmed =
                      gateData?['is_delivery_confirmed'] == true;

                  if (!isConfirmed) {
                    // Show delivery gate setup
                    return Column(
                      children: [
                        const GateCard(),
                        const SizedBox(height: 24),
                        _buildLockedRecipesPlaceholder(theme),
                      ],
                    );
                  } else {
                    // Show confirmed delivery info and recipes
                    return Column(
                      children: [
                        const GateCard(),
                        const SizedBox(height: 24),
                        _buildRecipesList(theme),
                      ],
                    );
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(ThemeData theme, Object error) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.error.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 48, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(
            'Failed to load weekly menu',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            error.toString(),
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onErrorContainer.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () {
              ref.invalidate(deliveryGateProvider);
              ref.invalidate(weeklyMenuProvider);
            },
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedRecipesPlaceholder(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Icon(
              Icons.lock_outline,
              size: 32,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Recipes Locked',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete your delivery setup above to unlock this week\'s delicious Ethiopian recipes.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),

          // Preview cards (blurred/placeholder)
          Row(
            children: [
              Expanded(child: _buildRecipePreviewCard(theme, 'Misir Wat')),
              const SizedBox(width: 12),
              Expanded(child: _buildRecipePreviewCard(theme, 'Gomen')),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildRecipePreviewCard(theme, 'Kitfo')),
              const SizedBox(width: 12),
              Expanded(child: _buildRecipePreviewCard(theme, 'Atkilt Alicha')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipePreviewCard(ThemeData theme, String name) {
    return Container(
      height: 80,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 14,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Row(
            children: [
              Icon(
                Icons.lock,
                size: 12,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 4),
              Text(
                'Locked',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesList(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.restaurant_menu,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Recipes',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Choose your meals for this week',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Mock recipe cards - in a real app, these would come from the weeklyMenuProvider
          _buildRecipeCard(
            theme,
            'Misir Wat',
            'Spiced red lentils with berbere spice blend',
            '25 min',
            '450 kcal',
          ),
          const SizedBox(height: 12),
          _buildRecipeCard(
            theme,
            'Gomen',
            'Collard greens sautéed with garlic and ginger',
            '20 min',
            '320 kcal',
          ),
          const SizedBox(height: 12),
          _buildRecipeCard(
            theme,
            'Kitfo',
            'Ethiopian beef tartare with spices',
            '15 min',
            '520 kcal',
          ),
          const SizedBox(height: 12),
          _buildRecipeCard(
            theme,
            'Atkilt Alicha',
            'Mild turmeric-spiced vegetables',
            '30 min',
            '280 kcal',
          ),

          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                // TODO: Navigate to meal selection or checkout
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 20),
                        SizedBox(width: 12),
                        Text('Ready to continue to checkout!'),
                      ],
                    ),
                    backgroundColor: theme.colorScheme.primary,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Continue to Checkout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(
    ThemeData theme,
    String name,
    String description,
    String time,
    String calories,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Recipe image placeholder
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.restaurant,
              color: theme.colorScheme.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Recipe info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(
                      Icons.local_fire_department,
                      size: 14,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      calories,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Selection button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              'Select',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
