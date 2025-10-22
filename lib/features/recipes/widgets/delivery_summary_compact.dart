import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Slimmed header after window is confirmed; still editable but visually secondary
class DeliverySummaryCompact extends StatelessWidget {
  final String location;
  final String dateLabel; // e.g., "Tue, 19 Aug"
  final String timeLabel; // e.g., "Between 5am to 6am" or slot
  final VoidCallback onEdit;

  const DeliverySummaryCompact({
    super.key,
    required this.location,
    required this.dateLabel,
    required this.timeLabel,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.white,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(color: theme.colorScheme.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.location_on_outlined,
              size: 18,
              color: Yf.brown700,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    location,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateLabel • $timeLabel',
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
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
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
