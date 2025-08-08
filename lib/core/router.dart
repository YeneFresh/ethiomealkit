import 'package:go_router/go_router.dart';
import 'package:flutter/widgets.dart';
import '../features/meals/meals_list_screen.dart';
import '../features/meals/meal_detail_screen.dart';
import '../features/cart/cart_screen.dart';
import '../features/checkout/checkout_screen.dart';
import '../features/orders/orders_screen.dart';
import '../main.dart';
import '../features/shell.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/meals',
  routes: [
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingFlow()),
    GoRoute(path: '/home', builder: (context, state) => const HomeScreen()),
    ShellRoute(
      builder: (context, state, child) => ShellScaffold(child: child),
      routes: [
        GoRoute(path: '/meals', builder: (context, state) => const MealsListScreen()),
        GoRoute(
          path: '/meals/:id',
          builder: (context, state) => MealDetailScreen(id: state.pathParameters['id']!),
        ),
        GoRoute(path: '/cart', builder: (context, state) => const CartScreen()),
        GoRoute(path: '/checkout', builder: (context, state) => const CheckoutScreen()),
        GoRoute(path: '/orders', builder: (context, state) => const OrdersScreen()),
      ],
    ),
  ],
);


