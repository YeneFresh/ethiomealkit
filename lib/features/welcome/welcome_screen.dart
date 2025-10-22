// Welcome Screen - 2025 Edition
// Investor-ready entry point with brand hero
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/design_tokens.dart';
import '../../core/analytics.dart';
import '../../core/services/persistence_service.dart';
import '../onboarding/providers/user_onboarding_progress_provider.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen>
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
      duration: Yf.d300,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Yf.standard,
    );
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
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
    HapticFeedback.mediumImpact();
    Analytics.track('welcome_get_started');
    context.go('/onboarding/box');
  }

  void _handleResumeSetup() {
    HapticFeedback.mediumImpact();
    Analytics.track('welcome_resume_setup');
    // Resume at last step
    final currentStep = ref.read(userOnboardingProgressProvider);
    context.go(currentStep.route);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              SizedBox(height: Yf.s24),
              Text(
                'Loading...',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Yf.s24,
              vertical: Yf.s20,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),

                // =================================================================
                // BRAND HERO
                // =================================================================
                _buildBrandHero(theme),

                SizedBox(height: Yf.s32),

                // =================================================================
                // DUAL CTAs
                // =================================================================
                if (_isSignedIn || _hasOnboardingProgress) ...[
                  _buildResumeSetupCTA(theme),
                  SizedBox(height: Yf.s12),
                  _buildSecondaryAction(
                    label: _isSignedIn ? 'Sign Out' : 'Start Over',
                    onTap: () async {
                      if (_isSignedIn) {
                        await Supabase.instance.client.auth.signOut();
                        setState(() => _isSignedIn = false);
                      } else {
                        // Clear all saved progress and restart
                        await PersistenceService.clearAllOnboardingData();
                        await ref
                            .read(userOnboardingProgressProvider.notifier)
                            .reset();
                        if (mounted) {
                          setState(() => _hasOnboardingProgress = false);
                        }
                      }
                    },
                  ),
                ] else ...[
                  _buildGetStartedCTA(theme),
                  SizedBox(height: Yf.s12),
                  _buildSecondaryAction(
                    label: 'I already have an account',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      context.go('/auth');
                    },
                  ),
                ],

                const Spacer(),

                // Debug info (only on web in debug mode)
                if (kIsWeb && kDebugMode) _buildDebugInfo(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // HERO COMPONENTS
  // ===========================================================================

  Widget _buildBrandHero(ThemeData theme) {
    return Column(
      children: [
        // Icon with brand color
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            shape: BoxShape.circle,
            boxShadow: Yf.e2,
          ),
          child: Icon(
            Icons.restaurant_menu_rounded,
            size: 48,
            color: Yf.brown900,
          ),
        ),
        SizedBox(height: Yf.s24),

        // Headline
        Text(
          'YeneFresh',
          style: theme.textTheme.displaySmall?.copyWith(
            color: Yf.brown900,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: Yf.s12),

        // Subhead - Value proposition
        Text(
          'Smart Addis meal kits—select, schedule,\nwe handle the rest.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildGetStartedCTA(ThemeData theme) {
    return SizedBox(
      height: 56,
      child: FilledButton(
        onPressed: _handleGetStarted,
        style: FilledButton.styleFrom(
          backgroundColor: Yf.brown900,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: Yf.borderRadius16,
          ),
        ),
        child: const Text(
          'Get Started',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildResumeSetupCTA(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: Yf.borderRadius16,
        boxShadow: Yf.e2,
      ),
      child: Material(
        color: Yf.brown900,
        borderRadius: Yf.borderRadius16,
        child: InkWell(
          onTap: _handleResumeSetup,
          borderRadius: Yf.borderRadius16,
          child: Container(
            height: 72,
            padding: EdgeInsets.symmetric(horizontal: Yf.s20),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: Yf.borderRadius12,
                  ),
                  child: const Icon(
                    Icons.play_circle_outline_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                SizedBox(width: Yf.s16),

                // Text
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Resume Setup',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: Yf.s4),
                      Text(
                        'Pick up where you left off',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),

                // Chevron
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 32,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSecondaryAction({
    required String label,
    required VoidCallback onTap,
  }) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: Yf.brown700,
        ),
      ),
    );
  }

  Widget _buildDebugInfo(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(Yf.s12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: Yf.borderRadius12,
      ),
      child: Text(
        'Debug: ${_isSignedIn ? "Signed in" : "Not signed in"}',
        style: theme.textTheme.labelSmall?.copyWith(
          fontFamily: 'monospace',
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
