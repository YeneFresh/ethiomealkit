import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Persistent delivery window summary bar with edit capability
class DeliverySummaryBar extends StatelessWidget {
  final String location;
  final String timeSlot;
  final bool recommended;
  final VoidCallback onEdit;

  const DeliverySummaryBar({
    super.key,
    required this.location,
    required this.timeSlot,
    this.recommended = false,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Yf.peach50,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: Yf.s16,
          vertical: Yf.s12,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.colorScheme.outlineVariant,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_shipping_outlined,
              color: Yf.brown700,
              size: 20,
            ),
            const SizedBox(width: Yf.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery: $location',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Yf.brown900,
                    ),
                  ),
                  Row(
                    children: [
                      Text(
                        timeSlot,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: Yf.ink600,
                        ),
                      ),
                      if (recommended) ...[
                        const SizedBox(width: Yf.s8),
                        const Icon(Icons.star, size: 14, color: Yf.gold600),
                        const SizedBox(width: Yf.s4),
                        Text(
                          'Recommended',
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: Yf.gold600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            TextButton.icon(
              onPressed: onEdit,
              icon: const Icon(
                Icons.edit_outlined,
                size: 16,
                color: Yf.brown700,
              ),
              label: const Text('Edit', style: TextStyle(color: Yf.brown700)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: Yf.s12,
                  vertical: Yf.s8,
                ),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
