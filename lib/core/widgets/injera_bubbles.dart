import 'dart:math';
import 'package:flutter/material.dart';

/// Animated injera bubbles (splash overlay)
/// Lightweight CustomPainter that animates soft circles "blooming" like injera bubbles
/// Looks great over warm neutral background with subtle alpha
class InjeraBubbles extends StatefulWidget {
  const InjeraBubbles({
    super.key,
    this.color = const Color(0xFFFFFFFF),
    this.maxRadius = 8,
    this.count = 36,
    this.opacity = 0.18,
    this.speed = 1.0,
  });

  final Color color;
  final double maxRadius;
  final int count;
  final double opacity; // overall intensity
  final double speed; // 0.5–1.5

  @override
  State<InjeraBubbles> createState() => _InjeraBubblesState();
}

class _InjeraBubblesState extends State<InjeraBubbles>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ac;
  late final List<_Bubble> _bubbles;
  final _rng = Random();

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _bubbles = List.generate(widget.count, (_) => _Bubble(_rng));
  }

  @override
  void dispose() {
    _ac.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _ac,
        builder: (_, __) => CustomPaint(
          painter: _InjeraPainter(
            progress: (_ac.value * widget.speed) % 1.0,
            bubbles: _bubbles,
            color: widget.color.withValues(alpha: widget.opacity),
            maxRadius: widget.maxRadius,
          ),
          size: Size.infinite,
        ),
      ),
    );
  }
}

class _Bubble {
  _Bubble(Random rng)
    : x = rng.nextDouble(),
      y = rng.nextDouble(),
      phase = rng.nextDouble(),
      rMul = rng.nextDouble() * 0.8 + 0.2;
  final double x, y; // 0..1 relative
  final double phase; // random phase
  final double rMul; // radius multiplier
}

class _InjeraPainter extends CustomPainter {
  _InjeraPainter({
    required this.progress,
    required this.bubbles,
    required this.color,
    required this.maxRadius,
  });

  final double progress;
  final List<_Bubble> bubbles;
  final Color color;
  final double maxRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    for (final b in bubbles) {
      // subtle "bloom" pulse
      final t = (progress + b.phase) % 1.0;
      final bloom = 0.5 + 0.5 * sin(2 * pi * t);
      final radius = (maxRadius * b.rMul) * (0.6 + 0.4 * bloom);

      // varied alpha per bubble
      paint.color = color.withValues(
        alpha: (0.25 + 0.75 * b.rMul) * (color.opacity),
      );

      final offset = Offset(b.x * size.width, b.y * size.height);
      canvas.drawCircle(offset, radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _InjeraPainter old) =>
      old.progress != progress ||
      old.color != color ||
      old.maxRadius != maxRadius;
}
