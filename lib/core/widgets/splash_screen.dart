import 'package:flutter/material.dart';
import 'injera_bubbles.dart';
import 'gold_progress_bar.dart';
import '../app_colors.dart';

/// YeneFresh splash screen with animated injera bubbles
/// Shows while app initializes
class YeneFreshSplash extends StatelessWidget {
  const YeneFreshSplash({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6EEE1), // warm neutral base
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Animated background
          const InjeraBubbles(
            opacity: 0.14,
            maxRadius: 9,
            count: 42,
          ),

          // Content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand icon
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.gold.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.restaurant_menu,
                    size: 64,
                    color: AppColors.gold,
                  ),
                ),

                const SizedBox(height: 24),

                // Brand name
                Text(
                  'YeneFresh',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkBrown,
                    letterSpacing: 0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                Text(
                  'Fresh ingredients, Ethiopian soul.',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkBrown.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),

                const SizedBox(height: 32),

                // Gold progress bar
                const SizedBox(
                  width: 200,
                  child: GoldGradientProgressBar(height: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}




