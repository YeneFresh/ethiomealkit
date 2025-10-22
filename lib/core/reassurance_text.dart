import 'package:flutter/material.dart';
import 'design_tokens.dart';

/// Reassurance text component for delivery-related screens
class ReassuranceText extends StatelessWidget {
  final String? customText;

  const ReassuranceText({super.key, this.customText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.only(top: Yf.g12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.phone_outlined,
            size: 14,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
          SizedBox(width: Yf.g8),
          Flexible(
            child: Text(
              customText ??
                  "Don't worry — we'll call you before every delivery.",
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}




