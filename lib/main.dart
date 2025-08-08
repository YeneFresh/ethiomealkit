import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'core/env.dart';
import 'api/mock_api_client.dart';
import 'api/supabase_api_client.dart';
import 'repo/meals_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  // TODO: Replace with your Supabase project URL and anon key
  final supabaseUrl = Env.supabaseUrl;
  final supabaseAnonKey = Env.supabaseAnonKey;
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  final useMocks = Env.useMocks || supabaseUrl.isEmpty;
  final apiClient = useMocks ? MockApiClient() : SupabaseApiClient(Supabase.instance.client);

  runApp(ProviderScope(overrides: [
    apiClientProvider.overrideWithValue(apiClient),
  ], child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(initialLocation: '/meals', routes: [
      GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingFlow()),
      GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
      GoRoute(path: '/meals', builder: (context, state) => const MealsListScreen()),
      GoRoute(path: '/meals/:id', builder: (context, state) => MealDetailScreen(id: state.pathParameters['id']!)),
      GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
      GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
      GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
    ]);

    return MaterialApp.router(
      title: 'Ethio Meal Kit',
      theme: ThemeData(colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple)),
      routerConfig: router,
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ethio Meal Kit')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Welcome'),
            ElevatedButton(
              onPressed: () => context.go('/onboarding'),
              child: const Text('Start Onboarding'),
            ),
          ],
        ),
      ),
    );
  }
}

class OnboardingFlow extends StatefulWidget {
  const OnboardingFlow({super.key});

  @override
  State<OnboardingFlow> createState() => _OnboardingFlowState();
}

class _OnboardingFlowState extends State<OnboardingFlow> {
  int mealsPerWeek = 3;
  final Set<String> prefs = {
    'Quick & Easy',
    'Veggie',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Setup your plan')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            const Text('Meals per week'),
            DropdownButton<int>(
              value: mealsPerWeek,
              items: const [3, 5, 7]
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
              onChanged: (v) => setState(() => mealsPerWeek = v ?? 3),
            ),
            const SizedBox(height: 16),
            const Text('Preferences'),
            Wrap(
              spacing: 8,
              children: [
                'Quick & Easy',
                'Veggie',
                'Family-Friendly',
                'Calorie Smart',
                'Carb Smart',
                'No Beef',
                'No Seafood',
                'No Fish',
                'No Shellfish',
                'Pescatarian',
                'High Protein',
              ].map((p) {
                final selected = prefs.contains(p);
                return FilterChip(
                  label: Text(p),
                  selected: selected,
                  onSelected: (s) => setState(() {
                    if (s) {
                      prefs.add(p);
                    } else {
                      prefs.remove(p);
                    }
                  }),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: const Text('Continue'),
            ),
          ],
        ),
      ),
    );
  }
}
