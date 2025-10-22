import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/env.dart';
import 'core/router.dart';
import 'package:go_router/go_router.dart';
import 'features/dev/debug_route_menu.dart';

// If you have AppLockGuard in your project:
class AppLockGuard extends StatelessWidget {
  const AppLockGuard({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => child; // no-op stub for now
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await Env.load();

  // Initialize Supabase only if not already initialized
  try {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      anonKey: Env.supabaseAnonKey,
    );
  } catch (e) {
    // Supabase already initialized, continue
    debugPrint('Supabase already initialized: $e');
  }

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload onboarding image for instant warm visuals
    _preloadOnboardingAssets(context);
  }

  void _preloadOnboardingAssets(BuildContext context) {
    // Preload background image
    precacheImage(
      const AssetImage('assets/scenes/onboarding.png'),
      context,
    ).catchError((e) {
      debugPrint('⚠️ Could not preload onboarding image: $e');
    });
  }

  @override
  Widget build(BuildContext context) {
    final GoRouter router = ref.watch(goRouterProvider);

    // NOTHING should wrap MaterialApp.router.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EthiomealKit',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: ThemeMode.system,
      routerConfig: router,

      // Put guards/overlays HERE (under MaterialApp so Directionality exists)
      builder: (context, child) {
        final app = child ?? const SizedBox.shrink();

        // If you need AppLockGuard, wrap the child here:
        return AppLockGuard(
          child: Stack(
            children: [
              app,
              // Example: global loader
              // if (ref.watch(globalLoadingProvider)) const _DimLoading(),

              // Debug route menu (only in debug mode)
              if (kDebugMode) const DebugRouteMenu(),
            ],
          ),
        );
      },
    );
  }
}

// removed unused _DimLoading helper
