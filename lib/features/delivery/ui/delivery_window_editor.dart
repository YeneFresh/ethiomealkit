import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/delivery_models.dart';
import '../state/delivery_providers.dart';
import 'delivery_gradient_bg.dart';
import 'location_toggle.dart';

/// Canonical delivery window editor
/// Used in: Recipes, Checkout, Home
/// Opens as bottom sheet modal
class DeliveryWindowEditor extends ConsumerStatefulWidget {
  const DeliveryWindowEditor({super.key, required this.initial});
  final DeliveryWindow initial;

  @override
  ConsumerState<DeliveryWindowEditor> createState() =>
      _DeliveryWindowEditorState();
}

class _DeliveryWindowEditorState extends ConsumerState<DeliveryWindowEditor> {
  late DeliveryDaypart _daypart;
  late DateTime _date;
  late String _locationId;

  @override
  void initState() {
    super.initState();
    _daypart = widget.initial.daypart;
    _date = widget.initial.date;
    _locationId = widget.initial.location.id;
  }

  @override
  Widget build(BuildContext context) {
    return DeliveryGradientBg(
      daypart: _daypart,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 44,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.black26,
                borderRadius: BorderRadius.circular(999),
              ),
            ),

            // Header
            const Text(
              'Delivery Window',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),

            // Location toggle (Home/Office)
            const LocationToggle(),
            const SizedBox(height: 16),

            // Daypart selector (Morning / Afternoon)
            SegmentedButton<DeliveryDaypart>(
              segments: const [
                ButtonSegment(
                  value: DeliveryDaypart.morning,
                  label: Text('Morning'),
                  icon: Icon(Icons.wb_sunny_outlined),
                ),
                ButtonSegment(
                  value: DeliveryDaypart.afternoon,
                  label: Text('Afternoon'),
                  icon: Icon(Icons.local_shipping_outlined),
                ),
              ],
              selected: <DeliveryDaypart>{_daypart},
              onSelectionChanged: (s) => setState(() => _daypart = s.first),
            ),

            const SizedBox(height: 16),

            // Date picker
            SizedBox(
              height: 360,
              child: CalendarDatePicker(
                initialDate: _date,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 60)),
                onDateChanged: (d) => setState(() => _date = d),
              ),
            ),

            const SizedBox(height: 12),

            // Reassurance message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.phone, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Don\'t worry, we\'ll call you before every delivery',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Confirm button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () async {
                  final notifier =
                      ref.read(deliveryWindowControllerProvider.notifier);
                  await notifier.setAll(
                    locId: _locationId,
                    daypart: _daypart,
                    date: _date,
                  );
                  if (mounted) Navigator.of(context).maybePop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC6903B),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirm'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}



