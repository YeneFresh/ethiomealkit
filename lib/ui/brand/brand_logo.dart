import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum BrandMark { monogram, full }

class BrandLogo extends StatelessWidget {
  final BrandMark mark;
  final double size;
  final String? semanticsLabel;

  const BrandLogo({
    super.key,
    this.mark = BrandMark.full,
    this.size = 32,
    this.semanticsLabel,
  });

  String _svgPath() => switch (mark) {
    BrandMark.monogram => 'assets/brand/monogram_gold.svg',
    BrandMark.full => 'assets/brand/logo_primary.svg',
  };

  String _pngFallback() => switch (mark) {
    BrandMark.monogram => 'assets/brand/monogram_gold.png',
    BrandMark.full => 'assets/brand/logo_primary.png',
  };

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticsLabel ?? 'YeneFresh',
      image: true,
      child: SvgPicture.asset(
        _svgPath(),
        width: size,
        height: size,
        fit: BoxFit.contain,
        placeholderBuilder: (_) => Image.asset(
          _pngFallback(),
          width: size,
          height: size,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}

class BrandTitle extends StatelessWidget {
  final double iconSize;
  final String title;
  const BrandTitle({super.key, this.iconSize = 24, this.title = 'YeneFresh'});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    final style = Theme.of(context).textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w600,
      letterSpacing: 0.3,
      color: color,
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandLogo(
          mark: BrandMark.monogram,
          size: 24,
          semanticsLabel: 'YeneFresh',
        ),
        const SizedBox(width: 8),
        Text(title, style: style),
      ],
    );
  }
}
