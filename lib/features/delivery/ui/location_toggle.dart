import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/delivery_providers.dart';

/// Quick Home/Office toggle (outside the editor modal)
class LocationToggle extends ConsumerWidget {
  const LocationToggle({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dwAsync = ref.watch(deliveryWindowControllerProvider);
    final dw = dwAsync.value;

    if (dw == null) return const SizedBox.shrink();

    final isHome = dw.location.id == 'home';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _pill(
          context,
          label: 'Home',
          icon: Icons.home_rounded,
          selected: isHome,
          onTap: () {
            ref
                .read(deliveryWindowControllerProvider.notifier)
                .quickSetLocation('home');
          },
        ),
        const SizedBox(width: 8),
        _pill(
          context,
          label: 'Office',
          icon: Icons.apartment_rounded,
          selected: !isHome,
          onTap: () {
            ref
                .read(deliveryWindowControllerProvider.notifier)
                .quickSetLocation('office');
          },
        ),
      ],
    );
  }

  Widget _pill(
    BuildContext context, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFFC6903B)
              : Colors.black.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



