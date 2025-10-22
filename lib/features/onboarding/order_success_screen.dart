import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/layout.dart';

/// Order Success Screen
/// Shown after successful order placement
class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.success600.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 72,
                    color: AppColors.success600,
                  ),
                ),

                const SizedBox(height: 24),

                // Title
                Text(
                  'Order placed!',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // Message
                Text(
                  'We\'ll see you on your chosen delivery window.\nOur driver will call you before arrival.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkBrown.withOpacity(0.8),
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 32),

                // Reassurance card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.peach50,
                    borderRadius: BorderRadius.circular(Layout.cardRadius),
                    border: Border.all(
                      color: AppColors.darkBrown.withOpacity(0.1),
                    ),
                  ),
                  child: Column(
                    children: [
                      _InfoRow(Icons.email_outlined,
                          'Order confirmation sent to your email'),
                      const SizedBox(height: 8),
                      _InfoRow(
                          Icons.phone_outlined, 'We\'ll call before delivery'),
                      const SizedBox(height: 8),
                      _InfoRow(
                          Icons.calendar_today, 'Track your order in the app'),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // CTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => context.go('/home'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.gold,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(Layout.cardRadius),
                      ),
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Secondary action
                TextButton(
                  onPressed: () => context.go('/orders'),
                  child: Text(
                    'View My Orders',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkBrown.withOpacity(0.7),
                      decoration: TextDecoration.underline,
                    ),
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

/// Info row with icon
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow(this.icon, this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.darkBrown.withOpacity(0.6)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.darkBrown.withOpacity(0.7),
                ),
          ),
        ),
      ],
    );
  }
}



