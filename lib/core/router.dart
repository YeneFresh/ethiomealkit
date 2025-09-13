THIS SHOULD BE A LINTER ERRORimport 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import '../features/meals/meals_list_screen.dart';
import '../features/meals/meal_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../main.dart';
import '../features/shell.dart';
import '../features/auth/sign_in_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/weekly_menu/weekly_menu_screen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/meals',
  routes: [
    GoRoute(path: '/signin', builder: (context, state) => const SignInScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingFlow()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(
          path: '/meals',
          builder: (context, state) => const MealsListScreen(),
          redirect: (context, state) {
            final user = Supabase.instance.client.auth.currentUser;
            if (user == null) return '/signin';
            return null;
          },
        ),
        GoRoute(
          path: '/meals/:id',
          builder: (context, state) => MealDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(
          path: '/cart',
          builder: (context, state) => const CartScreen(),
          redirect: (context, state) => Supabase.instance.client.auth.currentUser == null ? '/signin' : null,
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) => const CheckoutScreen(),
          redirect: (context, state) => Supabase.instance.client.auth.currentUser == null ? '/signin' : null,
        ),
        GoRoute(
          path: '/orders',
          builder: (context, state) => const OrdersScreen(),
          redirect: (context, state) => Supabase.instance.client.auth.currentUser == null ? '/signin' : null,
        ),
        GoRoute(
          path: '/weekly',
          builder: (context, state) => const WeeklyMenuScreen(),
          redirect: (context, state) => Supabase.instance.client.auth.currentUser == null ? '/signin' : null,
        ),
      ],
    ),
  ],
);


