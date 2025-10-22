import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Shared bottom navigation bar for all main app screens
class AppBottomNav extends StatelessWidget {
  final int selectedIndex;

  const AppBottomNav({super.key, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: (i) {
        switch (i) {
          case 0:
            context.go('/home');
            break;
          case 1:
            context.go('/weekly-menu');
            break;
          case 2:
            context.go('/rewards');
            break;
          case 3:
            context.go('/orders');
            break;
          case 4:
            context.go('/account');
            break;
        }
      },
      backgroundColor: Colors.white,
      indicatorColor: AppColors.gold.withOpacity(0.15),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.restaurant_menu_outlined),
          selectedIcon: Icon(Icons.restaurant_menu),
          label: 'Recipes',
        ),
        NavigationDestination(
          icon: Icon(Icons.emoji_events_outlined),
          selectedIcon: Icon(Icons.emoji_events),
          label: 'Rewards',
        ),
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Orders',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          selectedIcon: Icon(Icons.person),
          label: 'Account',
        ),
      ],
    );
  }
}
