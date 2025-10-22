import 'package:flutter/material.dart';

/// Gold gradient progress bar (brand, not blue)
/// Wraps LinearProgressIndicator in ShaderMask for gold → warm-amber gradient
/// Works with both indeterminate and determinate
class GoldGradientProgressBar extends StatelessWidget {
  const GoldGradientProgressBar({
    super.key,
    this.value, // 0..1, or null for indeterminate
    this.height = 6,
  });

  final double? value;
  final double height;

  @override
  Widget build(BuildContext context) {
    const goldLight = Color(0xFFF1C97A);
    const gold = Color(0xFFC6903B);
    const goldDark = Color(0xFF8B5E2B);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: ShaderMask(
        shaderCallback: (bounds) => const LinearGradient(
          colors: [goldLight, gold, goldDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ).createShader(bounds),
        child: LinearProgressIndicator(
          value: value,
          minHeight: height,
          backgroundColor: Colors.white.withValues(alpha: 0.10),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white), // masked by shader
        ),
      ),
    );
  }
}




