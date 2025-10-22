import 'package:flutter/material.dart';

class YfButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool primary;
  const YfButton({
    super.key,
    required this.label,
    this.onPressed,
    this.primary = true,
  });

  @override
  Widget build(BuildContext context) {
    final style = primary
        ? ElevatedButton.styleFrom()
        : OutlinedButton.styleFrom();
    return primary
        ? ElevatedButton(onPressed: onPressed, style: style, child: Text(label))
        : OutlinedButton(
            onPressed: onPressed,
            style: style,
            child: Text(label),
          );
  }
}
