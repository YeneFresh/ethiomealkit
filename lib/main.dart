import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme.dart';
import 'core/env.dart';
import 'core/router.dart';
import 'package:go_router/go_router.dart';

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

  // Initialize Supabase
  await Supabase.initialize(
    url: Env.supabaseUrl,
    anonKey: Env.supabaseAnonKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final GoRouter router = ref.watch(goRouterProvider);

    // NOTHING should wrap MaterialApp.router.
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'EthiomealKit',
      theme: buildTheme(),
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
            ],
          ),
        );
      },
    );
  }
}

class _DimLoading extends StatelessWidget {
  const _DimLoading();
  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Container(
          color: Colors.black12,
          alignment: Alignment.center,
          child: const CircularProgressIndicator(),
        ),
      );
}
