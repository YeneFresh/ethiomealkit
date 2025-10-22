import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/widgets/app_bottom_nav.dart';
import 'package:ethiomealkit/core/providers/hub_providers.dart';

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(userStatsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Rewards'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: statsAsync.when(
        data: (stats) => _buildContent(context, stats, theme),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error loading rewards: $e')),
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 2),
    );
  }

  Widget _buildContent(
    BuildContext context,
    Map<String, dynamic> stats,
    ThemeData theme,
  ) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Streak card
        _buildStreakCard(stats, theme),
        const SizedBox(height: 16),

        // Points & tier
        _buildPointsCard(stats, theme),
        const SizedBox(height: 24),

        // Section: Weekly Challenges
        Text(
          'Weekly Challenges',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          theme,
          icon: Icons.check_circle_outline,
          title: 'Cook 4 recipes',
          progress: stats['weeklyProgress'] ?? 0,
          goal: stats['weeklyGoal'] ?? 4,
          reward: '+100 pts',
        ),
        const SizedBox(height: 12),
        _buildChallengeCard(
          theme,
          icon: Icons.star_outline,
          title: 'Try a new cuisine',
          progress: 0,
          goal: 1,
          reward: '+50 pts',
        ),

        const SizedBox(height: 24),

        // Referrals
        Text(
          'Invite Friends',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildReferralCard(stats, theme),

        const SizedBox(height: 24),

        // Badges
        Text(
          'Your Badges',
          style: theme.textTheme.titleLarge?.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        _buildBadgesGrid(theme),

        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildStreakCard(Map<String, dynamic> stats, ThemeData theme) {
    final streak = stats['streak'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withOpacity(0.15),
            AppColors.gold.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.local_fire_department,
              color: AppColors.gold,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$streak Week Streak!',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep cooking to maintain your streak',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBrown.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsCard(Map<String, dynamic> stats, ThemeData theme) {
    final points = stats['points'] ?? 0;
    final tier = stats['tier'] ?? 'Bronze';
    final tierProgress = (points % 1000) / 1000; // Simple tier calculation

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Tier: $tier',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.darkBrown,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '$points pts',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.gold,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: tierProgress,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation(AppColors.gold),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(1000 - (points % 1000))} pts to Platinum',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChallengeCard(
    ThemeData theme, {
    required IconData icon,
    required String title,
    required int progress,
    required int goal,
    required String reward,
  }) {
    final isComplete = progress >= goal;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isComplete
              ? AppColors.success600.withOpacity(0.3)
              : AppColors.darkBrown.withOpacity(0.1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isComplete ? AppColors.success600 : AppColors.gold,
            size: 28,
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
                const SizedBox(height: 4),
                Text(
                  '$progress / $goal',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.gold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              reward,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralCard(Map<String, dynamic> stats, ThemeData theme) {
    final referrals = stats['referrals'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.people_outline, color: AppColors.gold),
              const SizedBox(width: 8),
              Text(
                'Invite friends, earn rewards',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'You\'ve referred $referrals friend${referrals == 1 ? '' : 's'}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                // TODO: Share referral code
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.gold,
                side: const BorderSide(color: AppColors.gold),
              ),
              child: const Text('Share Your Code'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesGrid(ThemeData theme) {
    final badges = [
      ('🔥', 'Streak Master', 'true'),
      ('👨‍🍳', 'Chef\'s Pick', 'true'),
      ('🌱', 'Veggie Lover', 'false'),
      ('🏆', 'Gold Tier', 'true'),
      ('📅', 'Planner', 'false'),
      ('💎', 'Platinum', 'false'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: badges.map((badge) {
        final isEarned = badge.$3 == 'true';
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isEarned ? Colors.white : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isEarned
                  ? AppColors.gold.withOpacity(0.3)
                  : Colors.grey.withOpacity(0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                badge.$1,
                style: TextStyle(
                  fontSize: 32,
                  color: isEarned ? null : Colors.grey,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                badge.$2,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isEarned ? AppColors.darkBrown : Colors.grey,
                  fontWeight: isEarned ? FontWeight.w600 : FontWeight.w400,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
