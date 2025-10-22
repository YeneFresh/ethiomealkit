import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/app_colors.dart';
import '../../core/widgets/app_bottom_nav.dart';
import '../../core/widgets/gold_progress_bar.dart';
import '../../core/providers/hub_providers.dart';

/// Home Screen - Post-onboarding hub
class HomeScreenRedesign extends ConsumerWidget {
  const HomeScreenRedesign({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final weeklyStatusAsync = ref.watch(weeklyStatusProvider);
    final nextDelivery = ref.watch(nextDeliveryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Greeting header
            SliverToBoxAdapter(
              child: _buildGreeting(context, user, theme),
            ),

            // Weekly progress card
            SliverToBoxAdapter(
              child: weeklyStatusAsync.when(
                data: (status) =>
                    _buildWeeklyProgressCard(context, ref, status, theme),
                loading: () => const Center(
                    child: Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                )),
                error: (e, st) => const SizedBox.shrink(),
              ),
            ),

            // Next delivery card
            SliverToBoxAdapter(
              child: _buildNextDeliveryCard(context, nextDelivery, theme),
            ),

            // Section: This Week's Recipes
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                child: Text(
                  'This Week\'s Recipes',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // Recipe carousel (horizontal scroll)
            SliverToBoxAdapter(
              child: _buildRecipeCarousel(context, theme),
            ),

            // Bottom padding for nav bar
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 0),
    );
  }

  Widget _buildGreeting(BuildContext context, User? user, ThemeData theme) {
    final firstName = user?.userMetadata?['first_name'] ?? 'there';
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Good morning';
    } else if (hour < 18) {
      greeting = 'Good afternoon';
    } else {
      greeting = 'Good evening';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting,',
            style: theme.textTheme.headlineSmall?.copyWith(
              color: AppColors.darkBrown.withOpacity(0.7),
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            firstName,
            style: theme.textTheme.headlineMedium?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyProgressCard(BuildContext context, WidgetRef ref,
      WeeklyStatus status, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.12),
            AppColors.gold.withOpacity(0.06),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.gold.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'This Week',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              OutlinedButton(
                onPressed: () {
                  _showManageWeekSheet(context, ref, status);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.gold,
                  side: const BorderSide(color: AppColors.gold, width: 1.5),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text('Manage',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GoldGradientProgressBar(
            value: status.quota > 0 ? status.selectedRecipes / status.quota : 0,
            height: 8,
          ),
          const SizedBox(height: 10),
          Text(
            status.isComplete
                ? '✅ All set! ${status.selectedRecipes} recipes selected'
                : '${status.selectedRecipes} of ${status.quota} recipes selected',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkBrown.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextDeliveryCard(
      BuildContext context, Map<String, String?> delivery, ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.local_shipping_outlined,
                color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Next Delivery',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${delivery['date']} • ${delivery['window']}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  delivery['address'] ?? 'Home • Addis Ababa',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right, color: Colors.grey[400]),
        ],
      ),
    );
  }

  Widget _buildRecipeCarousel(BuildContext context, ThemeData theme) {
    // TODO: Replace with real recipes from provider
    final recipes = List.generate(
      6,
      (i) => {
        'title': 'Recipe ${i + 1}',
        'image': '',
        'time': '${20 + i * 5} min',
        'tags': ['Chef\'s Choice', 'Popular'][i % 2],
      },
    );

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: recipes.length,
        itemBuilder: (context, i) {
          final recipe = recipes[i];
          return Container(
            width: 160,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_menu, color: Colors.grey),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        recipe['title'] as String,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe['time'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showManageWeekSheet(
      BuildContext context, WidgetRef ref, WeeklyStatus status) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.offWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ManageWeekSheet(status: status),
    );
  }
}

/// Manage Week Bottom Sheet
class _ManageWeekSheet extends StatelessWidget {
  final WeeklyStatus status;

  const _ManageWeekSheet({required this.status});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
          children: [
            // Header
            Row(
              children: [
                Text(
                  'Manage This Week',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Edit delivery date
            _buildOption(
              context,
              icon: Icons.calendar_today,
              title: 'Edit Delivery Date',
              subtitle: 'Move to a different day this week',
              onTap: () {
                // TODO: Show delivery edit modal
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Delivery date picker coming soon!')),
                );
              },
            ),

            const SizedBox(height: 12),

            // Skip this week
            _buildOption(
              context,
              icon: Icons.pause_circle_outline,
              title: 'Skip This Week',
              subtitle: 'Pause delivery, resume next week',
              onTap: () {
                // TODO: Implement skip logic
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Skip week feature coming soon!')),
                );
              },
            ),

            const SizedBox(height: 12),

            // Change box size
            _buildOption(
              context,
              icon: Icons.inventory_2_outlined,
              title: 'Change Box Size',
              subtitle: 'Adjust recipes or people count',
              onTap: () {
                Navigator.pop(context);
                context.go('/onboarding/box');
              },
            ),

            const SizedBox(height: 24),

            // Cutoff warning
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 20, color: AppColors.darkBrown),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Changes must be made by Wednesday 11:59 PM',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.darkBrown,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.darkBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }
}
