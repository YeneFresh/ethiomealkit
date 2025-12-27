import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repo/delivery_windows_repository.dart';

class DeliveryWindowSelector extends ConsumerStatefulWidget {
  final String? city;
  final ValueChanged<String?> onChanged; // selected window id
  const DeliveryWindowSelector({super.key, this.city, required this.onChanged});

  @override
  ConsumerState<DeliveryWindowSelector> createState() => _DeliveryWindowSelectorState();
}

class _DeliveryWindowSelectorState extends ConsumerState<DeliveryWindowSelector> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final repo = ref.read(deliveryWindowsRepositoryProvider);
    return FutureBuilder<WeekWindows>(
      future: repo.fetchWindowsWithFallback(city: widget.city),
      builder: (ctx, snap) {
        if (!snap.hasData) return const CircularProgressIndicator();
        final ww = snap.data!;
        if (ww.rows.isEmpty) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('No delivery windows available. Try another city or check back soon.'),
              TextButton(onPressed: () => setState(() {}), child: const Text('Refresh')),
            ],
          );
        }

        final labelDate = '${ww.weekStart.year}-${ww.weekStart.month.toString().padLeft(2,'0')}-${ww.weekStart.day.toString().padLeft(2,'0')}';
        final banner = ww.isFallback
            ? Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Showing next available week ($labelDate)',
                    style: Theme.of(context).textTheme.bodySmall),
              )
            : const SizedBox.shrink();

        final items = ww.rows.map<DropdownMenuItem<String>>((w) {
          final disabled = (w['has_capacity'] == false) || (w['is_active'] == false);
          return DropdownMenuItem<String>(
            value: w['id'] as String,
            enabled: !disabled,
            child: Text(w['label'] as String),
          );
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            banner,
            DropdownButtonFormField<String>(
              value: _selected,
              items: items,
              onChanged: (v) {
                setState(() => _selected = v);
                widget.onChanged(v);
              },
              decoration: const InputDecoration(labelText: 'Delivery window'),
            ),
          ],
        );
      },
    );
  }
}

