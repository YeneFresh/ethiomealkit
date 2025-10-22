import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/delivery_providers.dart';
import 'delivery_window_editor.dart';
import '../../../core/widgets/gold_progress_bar.dart';

/// Delivery window summary chip with edit launcher
/// Shows "Selecting recommended delivery time..." while loading
/// Then shows the selected window summary
class DeliveryWindowChip extends ConsumerWidget {
  const DeliveryWindowChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(deliveryWindowControllerProvider);

    return state.when(
      loading: () => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: GoldGradientProgressBar(),
            ),
            const SizedBox(width: 8),
            Text(
              'Selecting recommended delivery time…',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
      error: (e, _) => Text(
        'Delivery window unavailable',
        style: TextStyle(color: Colors.red[700]),
      ),
      data: (dw) {
        if (dw == null) return const Text('Set delivery window');

        return InkWell(
          borderRadius: BorderRadius.circular(999),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            builder: (_) => DeliveryWindowEditor(initial: dw),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: const Color(0xFFC6903B).withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.local_shipping_outlined,
                  size: 18,
                  color: const Color(0xFFC6903B),
                ),
                const SizedBox(width: 8),
                Text(
                  dw.humanSummary,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.edit,
                  size: 14,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}



