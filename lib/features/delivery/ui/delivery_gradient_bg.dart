import 'package:flutter/material.dart';
import 'package:ethiomealkit/features/delivery/models/delivery_models.dart';

/// Dynamic gradient background based on time of day
/// Morning → bright, airy blues
/// Afternoon → golden, warm ambers
class DeliveryGradientBg extends StatelessWidget {
  const DeliveryGradientBg({super.key, required this.daypart, this.child});

  final DeliveryDaypart daypart;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = daypart == DeliveryDaypart.morning
        ? const [
            Color(0xFFEFF7FB), // bright, airy
            Color(0xFFD7ECFF),
          ]
        : const [
            Color(0xFFFFEDD5), // golden, warm
            Color(0xFFFBD38D),
          ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors.map((c) => c.withValues(alpha: 0.55)).toList(),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }
}
