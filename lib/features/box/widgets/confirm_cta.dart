import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ethiomealkit/core/app_colors.dart';

/// Large confirm button for box selection
class ConfirmCTA extends StatelessWidget {
  final bool enabled;
  final VoidCallback onPressed;
  final String text;

  const ConfirmCTA({
    super.key,
    required this.enabled,
    required this.onPressed,
    this.text = 'Confirm Selection',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? AppColors.gold : Colors.grey[300],
          foregroundColor: enabled ? Colors.white : Colors.grey[500],
          disabledBackgroundColor: Colors.grey[300],
          disabledForegroundColor: Colors.grey[500],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: enabled ? 2 : 0,
          shadowColor: AppColors.gold.withOpacity(0.3),
        ),
        onPressed: enabled
            ? () {
                HapticFeedback.mediumImpact();
                onPressed();
              }
            : null,
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}
