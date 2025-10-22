import 'package:flutter/material.dart';

class YfCard extends StatelessWidget {
  final Widget child;
  const YfCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 1,
      child: child,
    );
  }
}
