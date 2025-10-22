import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Subtle gold ribbon overlay indicating a recipe was auto-selected by the algorithm
class AutoSelectedRibbon extends StatelessWidget {
  final bool visible;

  const AutoSelectedRibbon({super.key, required this.visible});

  @override
  Widget build(BuildContext context) {
    if (!visible) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topLeft,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Yf.gold600.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, size: 12, color: Colors.white),
            SizedBox(width: 4),
            Text(
              'Auto-selected',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
