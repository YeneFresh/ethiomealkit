// lib/admin/routes/admin_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/menu/menu_planner_screen.dart';
import '../features/recipes/recipes_catalog_screen.dart';

final adminRouter = GoRouter(
  initialLocation: '/admin/menu',
  routes: [
    GoRoute(
      path: '/admin/menu',
      builder: (_, __) => const AdminShell(child: MenuPlannerScreen()),
    ),
    GoRoute(
      path: '/admin/recipes',
      builder: (_, __) => const AdminShell(child: RecipesCatalogScreen()),
    ),
  ],
);

class AdminShell extends StatelessWidget {
  final Widget child;
  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    int index = 0;
    if (loc.startsWith('/admin/recipes')) index = 1;

    return Scaffold(
      appBar: AppBar(title: const Text('YeneFresh Admin')),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: index,
            onDestinationSelected: (i) {
              switch (i) {
                case 0:
                  context.go('/admin/menu');
                  break;
                case 1:
                  context.go('/admin/recipes');
                  break;
              }
            },
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.calendar_today),
                label: Text('Menu'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.restaurant_menu),
                label: Text('Recipes'),
              ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: child),
        ],
      ),
    );
  }
}