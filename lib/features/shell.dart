import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/profile/profile_menu.dart';

class ShellScaffold extends StatelessWidget {
  final Widget child;
  const ShellScaffold({super.key, required this.child});

  int _indexForLocation(String location) {
    if (location.startsWith('/meals')) return 0;
    if (location.startsWith('/cart')) return 1;
    if (location.startsWith('/orders')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _indexForLocation(location);
    return Scaffold(
      appBar: AppBar(title: const Text('Ethio Meal Kit'), actions: [
        IconButton(
          tooltip: 'Weekly menu',
          icon: const Icon(Icons.event_available),
          onPressed: () => context.go('/weekly'),
        ),
        const ProfileMenu(),
      ]),
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.restaurant), label: 'Meals'),
          NavigationDestination(icon: Icon(Icons.shopping_cart), label: 'Cart'),
          NavigationDestination(icon: Icon(Icons.receipt_long), label: 'Orders'),
        ],
        onDestinationSelected: (i) {
          switch (i) {
            case 0:
              context.go('/meals');
              break;
            case 1:
              context.go('/cart');
              break;
            case 2:
              context.go('/orders');
              break;
          }
        },
      ),
    );
  }
}


