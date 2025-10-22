import 'package:flutter/material.dart';

/// Dismissible tooltip nudge for first-time users
class NudgeTooltip extends StatefulWidget {
  final String text;
  final VoidCallback? onDismiss;

  const NudgeTooltip({
    super.key,
    required this.text,
    this.onDismiss,
  });

  @override
  State<NudgeTooltip> createState() => _NudgeTooltipState();
}

class _NudgeTooltipState extends State<NudgeTooltip> {
  bool _visible = true;

  void _dismiss() {
    setState(() => _visible = false);
    widget.onDismiss?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            widget.text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _dismiss,
            child: const Icon(
              Icons.close,
              size: 14,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}




