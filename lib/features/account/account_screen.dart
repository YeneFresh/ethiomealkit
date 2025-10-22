import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/widgets/app_bottom_nav.dart';

class AccountScreen extends ConsumerWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = Supabase.instance.client.auth.currentUser;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User info card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.gold.withOpacity(0.2),
                  child: Text(
                    (user?.email ?? 'U')[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: AppColors.gold,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.userMetadata?['first_name'] ?? 'User',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.email ?? '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Manage Plan
          Text(
            'Subscription',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.edit_calendar_outlined,
            title: 'Manage Plan',
            subtitle: '4 meals/week • 2 people',
            onTap: () => context.go('/onboarding/box'),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.credit_card,
            title: 'Payment Methods',
            subtitle: 'Manage your cards & billing',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Payment methods coming soon!')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Personal
          Text(
            'Personal',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.person_outline,
            title: 'Profile',
            subtitle: 'Name, email, phone',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile editor coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.location_on_outlined,
            title: 'Addresses',
            subtitle: 'Manage delivery addresses',
            onTap: () => context.go('/onboarding/map-picker'),
          ),

          const SizedBox(height: 24),

          // Support
          Text(
            'Support',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.help_outline,
            title: 'Help Center',
            subtitle: 'FAQs & support articles',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Help center coming soon!')),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.chat_bubble_outline,
            title: 'Contact Us',
            subtitle: 'Chat or call our team',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support coming soon!')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Settings
          Text(
            'Settings',
            style: theme.textTheme.titleMedium?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            subtitle: 'Email & push preferences',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Notifications settings coming soon!'),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.privacy_tip_outlined,
            title: 'Privacy & Terms',
            subtitle: 'Legal documents',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Privacy policy coming soon!')),
              );
            },
          ),

          const SizedBox(height: 24),

          // Pause/Cancel
          _buildOption(
            context,
            icon: Icons.pause_circle_outline,
            title: 'Pause Subscription',
            subtitle: 'Take a break anytime',
            onTap: () => _showPauseDialog(context),
            textColor: Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildOption(
            context,
            icon: Icons.cancel_outlined,
            title: 'Cancel Subscription',
            subtitle: 'We\'ll miss you!',
            onTap: () => _showCancelDialog(context),
            textColor: Colors.red,
          ),

          const SizedBox(height: 24),

          // Logout
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () async {
                await Supabase.instance.client.auth.signOut();
                if (context.mounted) {
                  context.go('/welcome');
                }
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.darkBrown,
                side: BorderSide(color: AppColors.darkBrown.withOpacity(0.3)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Sign Out'),
            ),
          ),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 4),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? textColor,
  }) {
    final theme = Theme.of(context);
    final color = textColor ?? AppColors.darkBrown;

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
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: color,
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

  void _showPauseDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Pause Subscription'),
        content: const Text(
          'You can pause for up to 4 weeks. Your box will be automatically resumed afterward.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Subscription paused successfully'),
                ),
              );
            },
            child: const Text('Pause'),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Subscription'),
        content: const Text(
          'We\'re sorry to see you go! Your current box will be delivered, and you won\'t be charged again. Would you like to tell us why?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep Subscription'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Subscription cancelled. We hope to see you again!',
                  ),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}
