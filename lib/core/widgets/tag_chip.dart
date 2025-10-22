import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/theme/tag_tokens.dart';

/// A colored chip displaying a recipe tag with Ethiopian-inspired colors
class TagChip extends StatelessWidget {
  final String label;
  const TagChip({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      margin: const EdgeInsets.only(right: 6, bottom: 6),
      decoration: BoxDecoration(
        color: TagTokens.bgFor(label),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: TagTokens.fgFor(label),
        ),
      ),
    );
  }
}
