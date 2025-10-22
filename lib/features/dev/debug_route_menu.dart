import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Debug menu for quick navigation between routes
/// Only shows in debug mode
class DebugRouteMenu extends StatefulWidget {
  const DebugRouteMenu({super.key});

  @override
  State<DebugRouteMenu> createState() => _DebugRouteMenuState();
}

class _DebugRouteMenuState extends State<DebugRouteMenu> {
  bool _isExpanded = false;

  final _routes = [
    _RouteItem('Welcome', '/welcome', Icons.home),
    _RouteItem('Onboarding Flow', '/onboarding', Icons.start),
    _RouteItem('', '', null), // Divider
    _RouteItem('  Step 1: Box', '/onboarding/box', Icons.inventory_2),
    _RouteItem('  Step 2: Sign Up', '/onboarding/signup', Icons.person_add),
    _RouteItem(
      '  Step 3: Recipes',
      '/onboarding/recipes',
      Icons.restaurant_menu,
    ),
    _RouteItem('  Step 4a: Map Picker', '/onboarding/map-picker', Icons.map),
    _RouteItem(
      '  Step 4b: Address Form',
      '/onboarding/address-form',
      Icons.home,
    ),
    _RouteItem('  Step 5: Pay', '/onboarding/pay', Icons.payment),
    _RouteItem('  ✅ Success', '/order-success', Icons.check_circle),
    _RouteItem('', '', null), // Divider
    _RouteItem('Legacy: Box Plan', '/box', Icons.shopping_bag),
    _RouteItem('Legacy: Auth', '/auth', Icons.login),
    _RouteItem('Legacy: Delivery', '/delivery', Icons.location_on),
    _RouteItem('Legacy: Recipes', '/meals', Icons.fastfood),
    _RouteItem('Legacy: Checkout', '/checkout', Icons.shopping_cart),
    _RouteItem('', '', null), // Divider
    _RouteItem('Home', '/home', Icons.dashboard),
    _RouteItem('Orders', '/orders', Icons.receipt_long),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 80,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Expanded menu
          if (_isExpanded)
            Container(
              constraints: const BoxConstraints(maxHeight: 500),
              width: 280,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bug_report, color: Colors.white, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Debug Navigation',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Routes list
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: _routes.length,
                      itemBuilder: (context, index) {
                        final route = _routes[index];

                        // Divider
                        if (route.icon == null) {
                          return const Divider(height: 1);
                        }

                        // Route item
                        return Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              context.go(route.path);
                              setState(() => _isExpanded = false);
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    route.icon,
                                    size: 18,
                                    color: AppColors.darkBrown,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      route.label,
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: AppColors.darkBrown,
                                        fontWeight: route.label.startsWith('  ')
                                            ? FontWeight.w400
                                            : FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  Icon(
                                    Icons.arrow_forward_ios,
                                    size: 12,
                                    color: Colors.grey[400],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

          // Toggle button
          FloatingActionButton(
            mini: true,
            backgroundColor: AppColors.gold,
            foregroundColor: Colors.white,
            onPressed: () {
              setState(() => _isExpanded = !_isExpanded);
            },
            child: Icon(_isExpanded ? Icons.close : Icons.bug_report),
          ),
        ],
      ),
    );
  }
}

class _RouteItem {
  final String label;
  final String path;
  final IconData? icon;

  _RouteItem(this.label, this.path, this.icon);
}
