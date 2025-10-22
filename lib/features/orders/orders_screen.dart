import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/widgets/app_bottom_nav.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // TODO: Replace with real orders from Supabase
    final orders = List.generate(
      8,
      (i) => {
        'id': 'order-$i',
        'week': 'Week ${i + 1}',
        'date': i == 0 ? 'Thu, 17 Oct' : 'Week of Oct ${10 + i * 7}',
        'window': i % 3 == 0
            ? 'Morning (8–10 am)'
            : i % 3 == 1
            ? 'Afternoon (2–4 pm)'
            : 'Evening (6–8 pm)',
        'status': i == 0
            ? 'Upcoming'
            : i < 4
            ? 'Delivered'
            : 'Completed',
        'recipes': i == 0 ? 4 : 4,
      },
    );

    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.offWhite,
      appBar: AppBar(
        title: const Text('Orders'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: orders.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) {
          final order = orders[i];
          final isUpcoming = order['status'] == 'Upcoming';

          return Material(
            elevation: 0,
            borderRadius: BorderRadius.circular(14),
            color: Colors.white,
            child: InkWell(
              onTap: () {
                // TODO: Navigate to order details
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Order details for ${order['week']}')),
                );
              },
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isUpcoming
                        ? AppColors.gold.withValues(alpha: 0.3)
                        : AppColors.darkBrown.withValues(alpha: 0.1),
                    width: isUpcoming ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (isUpcoming ? AppColors.gold : Colors.grey)
                            .withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        isUpcoming ? Icons.local_shipping : Icons.check_circle,
                        color: isUpcoming ? AppColors.gold : Colors.grey[600],
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            order['week'] as String,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order['date']} • ${order['window']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${order['recipes']} recipes • ${order['status']}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isUpcoming
                                  ? AppColors.gold
                                  : Colors.grey[600],
                              fontWeight: isUpcoming
                                  ? FontWeight.w600
                                  : FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.grey[400]),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: const AppBottomNav(selectedIndex: 3),
    );
  }
}
