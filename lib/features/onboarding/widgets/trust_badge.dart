import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Small trust/reassurance badge with emoji and text
/// Used in sign-up and other conversion-critical screens
class TrustBadge extends StatelessWidget {
  final String emoji;
  final String text;

  const TrustBadge({super.key, required this.emoji, required this.text});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.offWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.darkBrown.withValues(alpha: 0.1)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 4),
            Text(
              text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.darkBrown.withValues(alpha: 0.8),
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
