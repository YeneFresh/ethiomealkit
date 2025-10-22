import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/delivery_providers.dart';
import 'delivery_window_editor.dart';

/// Apple Wallet-style order confirmation mini-receipt
/// Shows after successful checkout
/// Can be saved offline for reference
class ReceiptCard extends ConsumerWidget {
  const ReceiptCard({
    super.key,
    required this.weekNumber,
    required this.totalMeals,
    this.badgeIcons = const [],
  });

  final int weekNumber;
  final int totalMeals;
  final List<IconData> badgeIcons;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dwAsync = ref.watch(deliveryWindowControllerProvider);
    final dw = dwAsync.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFC6903B).withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Gold header stripe
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFC6903B), Color(0xFFD4AF37)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Week $weekNumber',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'CONFIRMED',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Delivery summary
                Row(
                  children: [
                    const Icon(Icons.local_shipping,
                        size: 18, color: Color(0xFFC6903B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dw?.humanSummary ?? 'Delivery window pending',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Reassurance
                Text(
                  'We\'ll call you before every delivery',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.black.withValues(alpha: 0.65),
                  ),
                ),

                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),

                // Meals count with badges
                Row(
                  children: [
                    Text(
                      'Meals: $totalMeals',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ...badgeIcons.map(
                      (i) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child:
                            Icon(i, size: 16, color: const Color(0xFFC6903B)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Modify CTA
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: dw == null
                        ? null
                        : () => showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useSafeArea: true,
                              shape: const RoundedRectangleBorder(
                                borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(24),
                                ),
                              ),
                              builder: (_) => DeliveryWindowEditor(initial: dw),
                            ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text('Modify Delivery'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                        color: const Color(0xFFC6903B).withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



