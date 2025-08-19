import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_notifier.dart';

// Screens
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/menu/menu_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/widgets/auth_error_dialog.dart';
import '../features/box/box_recipes_screen.dart';
import '../features/box/box_flow_controller.dart';

final authNotifierProvider =
    ChangeNotifierProvider<AuthNotifier>((ref) => AuthNotifier());

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
        body: Center(
          child: Text('Redirecting to error dialog...'),
        ),
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
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withOpacity(0.7),
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

final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/login',
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
        final msg = state.uri.queryParameters['error_description'] ??
            state.uri.queryParameters['error'];
        return '/auth-error?msg=${Uri.encodeComponent(msg ?? 'Login error')}';
      }

      final loc = state.matchedLocation;
      final needsAuth = ['/home', '/weekly-menu', '/checkout', '/box']
          .any((p) => loc.startsWith(p));
      final isAuthRoute = loc == '/login' ||
          loc == '/auth-callback' ||
          loc == '/reset' ||
          loc == '/auth-error';

      if (!signedIn && needsAuth) return '/login';
      if (signedIn && loc == '/login') return '/home';
      if (signedIn && loc == '/auth-callback') return '/home';

      // Box flow routing guards
      if (signedIn && loc.startsWith('/box')) {
        final box = ref.read(boxFlowProvider);

        // users must confirm delivery before recipes are visible
        if (loc.startsWith('/box/recipes') && !box.deliveryPrefConfirmed) {
          return '/box/delivery';
        }

        if (loc.startsWith('/box/checkout')) {
          if (box.selectedIds.isEmpty && !box.serverHasSelections)
            return '/box/recipes';
          if (!box.hasDeliveryChoice) return '/box/delivery';
        }
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/auth-callback',
          builder: (_, __) => const AuthCallbackScreen()),
      GoRoute(
          path: '/auth-error',
          builder: (_, s) =>
              AuthErrorScreen(message: s.uri.queryParameters['msg'])),
      GoRoute(path: '/reset', builder: (_, __) => const ResetPasswordScreen()),
      GoRoute(path: '/home', builder: (_, __) => const HomeScreen()),
      GoRoute(path: '/weekly-menu', builder: (_, __) => const MenuScreen()),
      GoRoute(path: '/checkout', builder: (_, __) => const CheckoutScreen()),
      GoRoute(
          path: '/box/recipes', builder: (_, __) => const BoxRecipesScreen()),
    ],
    errorBuilder: (_, state) =>
        AuthErrorScreen(message: state.error.toString()),
  );
});
