import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/auth_notifier.dart';
import 'package:ethiomealkit/bootstrap/env.dart';
import 'package:ethiomealkit/features/admin/menu_admin_screen.dart';
import 'package:ethiomealkit/features/admin/recipes_admin_screen.dart';

// Screens
import 'package:ethiomealkit/features/welcome/welcome_screen_redesign.dart';
import 'package:ethiomealkit/features/auth/onboarding_screen.dart';
import 'package:ethiomealkit/features/box/box_plan_screen.dart';
import 'package:ethiomealkit/features/box/box_selection_screen.dart';
import 'package:ethiomealkit/features/onboarding/signup_screen.dart';
import 'package:ethiomealkit/features/onboarding/recipes_selection_screen.dart';
import 'package:ethiomealkit/features/onboarding/map_picker_screen.dart';
import 'package:ethiomealkit/features/onboarding/address_form_screen.dart';
import 'package:ethiomealkit/features/onboarding/pay_screen.dart';
import 'package:ethiomealkit/features/onboarding/order_success_screen.dart';
import 'package:ethiomealkit/features/auth/auth_screen.dart';
import 'package:ethiomealkit/features/delivery/delivery_gate_screen.dart';
import 'package:ethiomealkit/features/delivery/delivery_address_screen.dart';
import 'package:ethiomealkit/features/recipes/recipes_screen.dart';
import 'package:ethiomealkit/features/checkout/checkout_screen.dart';
import 'package:ethiomealkit/features/home/home_screen_redesign.dart';
import 'package:ethiomealkit/features/rewards/rewards_screen.dart';
import 'package:ethiomealkit/features/orders/orders_screen.dart';
import 'package:ethiomealkit/features/account/account_screen.dart';
import 'package:ethiomealkit/features/auth/login_screen.dart';
import 'package:ethiomealkit/features/auth/reset_password_screen.dart';
import 'package:ethiomealkit/features/auth/widgets/auth_error_dialog.dart';
import 'package:ethiomealkit/features/box/box_recipes_screen.dart';
import 'package:ethiomealkit/features/box/box_flow_controller.dart';
import 'package:ethiomealkit/features/ops/debug_screen.dart';
import 'package:ethiomealkit/features/orders/orders_list_screen.dart';
import 'package:ethiomealkit/features/orders/order_detail_screen.dart';

final authNotifierProvider = ChangeNotifierProvider<AuthNotifier>(
  (ref) => AuthNotifier(),
);

// New tiny screens:
class AuthCallbackScreen extends StatefulWidget {
  const AuthCallbackScreen({super.key});
  @override
  State<AuthCallbackScreen> createState() => _AuthCallbackScreenState();
}

class _AuthCallbackScreenState extends State<AuthCallbackScreen> {
  String? _error;
  bool _done = false;

  @override
  void initState() {
    super.initState();
    _handle();
  }

  Future<void> _handle() async {
    final uri = Uri.base;
    final qp = uri.queryParameters;

    // 1) Surface Supabase error if present
    if (qp['error'] != null) {
      setState(() {
        _error = qp['error_description'] ?? qp['error'];
        _done = true;
      });
      return;
    }

    // 2) On web, exchange URL for session (idempotent)
    try {
      await Supabase.instance.client.auth.getSessionFromUrl(uri);
    } catch (e) {
      setState(() {
        _error = 'Auth callback failed: $e';
        _done = true;
      });
      return;
    }

    // 3) Route by session
    try {
      if (Supabase.instance.client.auth.currentSession != null && mounted) {
        context.go('/home');
      } else if (mounted) {
        context.go('/login?msg=sign_in_required');
      }
    } catch (e) {
      // Supabase not ready yet, redirect to login
      if (mounted) {
        context.go('/login?msg=sign_in_required');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // Show the comprehensive auth error dialog
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showAuthErrorDialog(context, errorMessage: _error);
      });
      return const Scaffold(
        body: Center(child: Text('Redirecting to error dialog...')),
      );
    }
    if (!_done) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 24),
              Text(
                'Setting up your session...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

class AuthErrorScreen extends StatelessWidget {
  final String? message;
  const AuthErrorScreen({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    final msg = message ?? 'Email link is invalid or expired.';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login Error'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Error icon
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),

                const SizedBox(height: 24),

                // Error message
                Text(
                  msg,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),

                const SizedBox(height: 32),

                // Action buttons
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => context.go('/login'),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Back to Login'),
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

// Helper: Fade + Slide transition for smooth navigation
CustomTransitionPage<T> _fadeSlidePageBuilder<T>({
  required Widget child,
  Duration duration = const Duration(milliseconds: 260),
}) {
  return CustomTransitionPage<T>(
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    child: child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/onboarding',
    refreshListenable: ref.watch(authNotifierProvider),
    redirect: (context, state) {
      bool signedIn = false;
      try {
        signedIn = Supabase.instance.client.auth.currentSession != null;
      } catch (e) {
        // Supabase not ready yet, treat as not signed in
        signedIn = false;
      }

      // Error in URL → friendly page
      if (state.uri.queryParameters.containsKey('error')) {
        final msg =
            state.uri.queryParameters['error_description'] ??
            state.uri.queryParameters['error'];
        return '/auth-error?msg=${Uri.encodeComponent(msg ?? 'Login error')}';
      }

      final loc = state.matchedLocation;

      // TEMPORARY: Skip auth for development/testing
      // if (!signedIn && needsAuth) return '/login';
      // if (signedIn && (loc == '/welcome' || loc == '/login')) return '/home';
      // if (signedIn && loc == '/auth-callback') return '/home';

      // Handle welcome screen routing
      if (loc == '/welcome') {
        return null; // Let welcome screen handle its own logic
      }

      // Redirect to box selection for new users
      if (loc == '/login') return '/box';

      // Box flow routing guards
      if (signedIn && loc.startsWith('/box')) {
        final box = ref.read(boxFlowProvider);

        // users must confirm delivery before recipes are visible
        if (loc.startsWith('/box/recipes') && !box.deliveryPrefConfirmed) {
          return '/box/delivery';
        }

        if (loc.startsWith('/box/checkout')) {
          if (box.selectedIds.isEmpty && !box.serverHasSelections) {
            return '/box/recipes';
          }
          if (!box.hasDeliveryChoice) return '/box/delivery';
        }
      }

      // Weekly menu delivery gate check
      // For now, allow navigation and let the UI handle the delivery gate
      // The WeeklyMenuScreen will show the appropriate state based on confirmation status

      return null;
    },
    routes: [
      // Onboarding entry (with image)
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) =>
            _fadeSlidePageBuilder(child: const OnboardingScreen()),
      ),

      // Welcome screen (legacy)
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) =>
            _fadeSlidePageBuilder(child: const WelcomeScreenRedesign()),
      ),

      // Unified Onboarding Flow with ShellRoute (persistent scaffold)
      ShellRoute(
        builder: (context, state, child) {
          // Each screen wraps itself with OnboardingScaffold
          // for individual step configuration
          return child;
        },
        routes: [
          GoRoute(
            path: '/onboarding/box',
            pageBuilder: (context, state) =>
                _fadeSlidePageBuilder(child: const BoxSelectionScreen()),
          ),
          GoRoute(
            path: '/onboarding/signup',
            builder: (_, __) => const SignUpScreen(), // NEW redesigned screen
          ),
          GoRoute(
            path: '/onboarding/recipes',
            builder: (_, __) =>
                const RecipesSelectionScreen(), // NEW redesigned screen
          ),
          GoRoute(
            path: '/onboarding/map-picker',
            builder: (_, __) => const MapPickerScreen(),
          ),
          GoRoute(
            path: '/onboarding/address-form',
            builder: (_, __) => const AddressFormScreen(),
          ),
          GoRoute(
            path: '/onboarding/delivery',
            builder: (_, __) => const DeliveryGateScreen(),
          ),
          GoRoute(
            path: '/onboarding/pay',
            builder: (_, __) => const PayScreen(), // NEW redesigned screen
          ),
        ],
      ),

      // Legacy Onboarding Routes (for backward compatibility)
      GoRoute(path: '/box', builder: (_, __) => const BoxPlanScreen()),
      GoRoute(path: '/auth', builder: (_, __) => const AuthScreen()),
      GoRoute(
        path: '/delivery',
        builder: (_, __) => const DeliveryGateScreen(),
      ),
      GoRoute(path: '/meals', builder: (_, __) => const RecipesScreen()),
      GoRoute(
        path: '/address',
        builder: (_, __) => const DeliveryAddressScreen(),
      ),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),

      // Auth flow (with fade transitions)
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) =>
            _fadeSlidePageBuilder(child: const LoginScreen()),
      ),
      GoRoute(
        path: '/auth-callback',
        builder: (_, __) => const AuthCallbackScreen(),
      ),
      GoRoute(
        path: '/auth-error',
        builder: (_, s) =>
            AuthErrorScreen(message: s.uri.queryParameters['msg']),
      ),
      GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordScreen()),

      // ===== Main App Hub (Phase 9) =====
      GoRoute(path: '/home', builder: (_, __) => const HomeScreenRedesign()),
      GoRoute(
        path: '/weekly-menu',
        builder: (_, __) => const RecipesSelectionScreen(),
      ),
      GoRoute(path: '/rewards', builder: (_, __) => const RewardsScreen()),
      GoRoute(path: '/orders', builder: (_, __) => const OrdersScreen()),
      GoRoute(path: '/account', builder: (_, __) => const AccountScreen()),

      // Order success
      GoRoute(
        path: '/order-success',
        builder: (_, __) => const OrderSuccessScreen(),
      ),

      // Legacy orders (for backward compatibility)
      GoRoute(
        path: '/orders-legacy',
        builder: (_, __) => const OrdersListScreen(),
      ),
      GoRoute(
        path: '/orders-detail/:id',
        builder: (_, state) =>
            OrderDetailScreen(orderId: state.pathParameters['id']!),
      ),

      // Legacy routes (for backward compatibility)
      GoRoute(
        path: '/box/recipes',
        builder: (_, __) => const BoxRecipesScreen(),
      ),

      // Debug (only in debug mode)
      if (kDebugMode)
        GoRoute(path: '/debug', builder: (_, __) => const DebugScreen()),

      // Admin routes (gated by ADMIN_ENABLED)
      if (Env.adminEnabled) ...[
        GoRoute(
          path: '/admin/menu',
          builder: (_, __) => const MenuAdminScreen(),
        ),
        GoRoute(
          path: '/admin/recipes',
          builder: (_, __) => const RecipesAdminScreen(),
        ),
      ],
    ],
    errorBuilder: (_, state) =>
        AuthErrorScreen(message: state.error.toString()),
  );
});
