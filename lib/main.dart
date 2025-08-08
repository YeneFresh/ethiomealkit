import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // TODO: Replace with your Supabase project URL and anon key
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');
  if (supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingFlow(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeScreen(),
        ),
      ],
    );

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
