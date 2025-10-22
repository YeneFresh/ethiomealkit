import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/analytics.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';

/// Welcome Screen - Premium Redesign
/// Matches the brown/gold aesthetic of the onboarding flow
class WelcomeScreenRedesign extends ConsumerStatefulWidget {
  const WelcomeScreenRedesign({super.key});

  @override
  ConsumerState<WelcomeScreenRedesign> createState() =>
      _WelcomeScreenRedesignState();
}

class _WelcomeScreenRedesignState extends ConsumerState<WelcomeScreenRedesign>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  bool _isSignedIn = false;
  bool _hasOnboardingProgress = false;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _checkStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkStatus() async {
    try {
      final session = Supabase.instance.client.auth.currentSession;
      final hasProgress = await PersistenceService.hasOnboardingProgress();

      setState(() {
        _isSignedIn = session != null;
        _hasOnboardingProgress = hasProgress;
        _isLoading = false;
      });
      _fadeController.forward();

      if (hasProgress) {
        print('📂 Onboarding progress detected - showing Resume button');
      }
    } catch (e) {
      setState(() {
        _isSignedIn = false;
        _hasOnboardingProgress = false;
        _isLoading = false;
      });
      _fadeController.forward();
    }
  }

  void _handleGetStarted() {
    Analytics.track('welcome_get_started');
    context.go('/onboarding/box');
  }

  void _handleResume() {
    Analytics.track('welcome_resume_setup');
    final currentStep = ref.read(userOnboardingProgressProvider);
    context.go(currentStep.route);
  }

  Future<void> _handleStartOver() async {
    await PersistenceService.clearAllOnboardingData();
    await ref.read(userOnboardingProgressProvider.notifier).reset();
    if (mounted) {
      setState(() => _hasOnboardingProgress = false);
      context.go('/onboarding/box');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.offWhite,
        body: Center(child: CircularProgressIndicator(color: AppColors.gold)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 40),

                  // Brand Hero
                  _buildBrandHero(theme),

                  const SizedBox(height: 48),

                  // Value Props
                  _buildValueProps(theme),

                  const SizedBox(height: 48),

                  // CTAs
                  if (_hasOnboardingProgress || _isSignedIn)
                    _buildResumeCTAs(theme)
                  else
                    _buildGetStartedCTAs(theme),

                  const SizedBox(height: 32),

                  // Trust badges
                  _buildTrustBadges(theme),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrandHero(ThemeData theme) {
    return Column(
      children: [
        // Logo/Icon (replace with your asset if you have one)
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: AppColors.gold,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Center(
            child: Icon(Icons.restaurant_menu, size: 40, color: Colors.white),
          ),
        ),

        const SizedBox(height: 24),

        // Brand name
        Text(
          'YeneFresh',
          style: theme.textTheme.displaySmall?.copyWith(
            color: AppColors.darkBrown,
            fontWeight: FontWeight.w700,
            height: 1.1,
          ),
          textAlign: TextAlign.center,
        ),

        const SizedBox(height: 12),

        // Tagline
        Text(
          'Fresh ingredients & recipes\ndelivered to your door',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.darkBrown.withOpacity(0.7),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildValueProps(ThemeData theme) {
    return const Column(
      children: [
        _ValuePropCard(
          icon: Icons.restaurant,
          title: 'Chef-curated recipes',
          subtitle: 'Delicious Ethiopian-inspired meals every week',
        ),
        SizedBox(height: 12),
        _ValuePropCard(
          icon: Icons.local_shipping_outlined,
          title: 'Free delivery in Addis',
          subtitle: 'We bring everything you need, fresh to your door',
        ),
        SizedBox(height: 12),
        _ValuePropCard(
          icon: Icons.schedule_outlined,
          title: 'Save time, eat well',
          subtitle: 'No grocery shopping, no meal planning',
        ),
      ],
    );
  }

  Widget _buildGetStartedCTAs(ThemeData theme) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _handleGetStarted,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.gold,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: AppColors.gold.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Layout.cardRadius),
              ),
            ),
            child: const Text(
              'Get Started',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => context.go('/login'),
          child: Text(
            'I already have an account',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.darkBrown.withOpacity(0.7),
              decoration: TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResumeCTAs(ThemeData theme) {
    final currentStep = ref.watch(userOnboardingProgressProvider);
    final stepName = currentStep.label;

    return Column(
      children: [
        // Resume button (large, prominent)
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              colors: [AppColors.gold, AppColors.gold.withOpacity(0.9)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.gold.withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _handleResume,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.play_arrow,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resume Your Setup',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Continue from: $stepName',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Secondary actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
              onPressed: _handleStartOver,
              child: Text(
                'Start Over',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkBrown.withOpacity(0.7),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            if (_isSignedIn) ...[
              const SizedBox(width: 16),
              Text('•', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(width: 16),
              TextButton(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  setState(() => _isSignedIn = false);
                },
                child: Text(
                  'Sign Out',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.darkBrown.withOpacity(0.7),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTrustBadges(ThemeData theme) {
    return const Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: [
        _TrustChip(icon: '🧾', text: 'No commitment'),
        _TrustChip(icon: '🚚', text: 'Free delivery'),
        _TrustChip(icon: '❤️', text: 'Skip any week'),
      ],
    );
  }
}

/// Value proposition card
class _ValuePropCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ValuePropCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(Layout.cardRadius),
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
            child: Icon(icon, color: AppColors.gold, size: 24),
          ),
          const SizedBox(width: 16),
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
                    color: AppColors.darkBrown.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust chip widget
class _TrustChip extends StatelessWidget {
  final String icon;
  final String text;

  const _TrustChip({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.peach50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.darkBrown.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 6),
          Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.darkBrown,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
