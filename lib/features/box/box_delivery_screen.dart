import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'box_flow_controller.dart';

class BoxDeliveryScreen extends ConsumerStatefulWidget {
  const BoxDeliveryScreen({super.key});

  @override
  ConsumerState<BoxDeliveryScreen> createState() => _BoxDeliveryScreenState();
}

class _BoxDeliveryScreenState extends ConsumerState<BoxDeliveryScreen> {
  DateTime? selectedDate;
  String? selectedWindowId;
  List<Map<String, dynamic>> availableWindows = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => loading = true);
    try {
      final box = ref.read(boxFlowProvider);

      // Set default to next Tuesday if no date selected
      if (box.deliveryDate1 == null) {
        final now = DateTime.now();
        final daysUntilTuesday = (DateTime.tuesday - now.weekday) % 7;
        final nextTuesday = now
            .add(Duration(days: daysUntilTuesday == 0 ? 7 : daysUntilTuesday));
        selectedDate = nextTuesday;
        box.setDelivery1(nextTuesday, '');
      } else {
        selectedDate = box.deliveryDate1;
        selectedWindowId = box.deliveryWindow1Id;
      }

      // Load available windows for the selected date
      if (selectedDate != null) {
        await _loadWindowsForDate(selectedDate!);
      }
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadWindowsForDate(DateTime date) async {
    try {
      final box = ref.read(boxFlowProvider);
      final windows = await box.loadWindowsForDate(date);
      setState(() {
        availableWindows = windows;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading delivery windows: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final box = ref.watch(boxFlowProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Details'),
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery city info
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Delivery City',
                                  style: theme.textTheme.labelMedium,
                                ),
                                Text(
                                  box.deliveryCity,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Selected date
                  Text(
                    'Delivery Date',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: Icon(
                        Icons.calendar_today,
                        color: theme.colorScheme.primary,
                      ),
                      title: Text(
                        selectedDate != null
                            ? '${selectedDate!.day}/${selectedDate!.month}/${selectedDate!.year}'
                            : 'Select a date',
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                      subtitle: selectedDate != null
                          ? Text(_getDayName(selectedDate!))
                          : null,
                      trailing: const Icon(Icons.arrow_forward_ios),
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: selectedDate ??
                              DateTime.now().add(const Duration(days: 1)),
                          firstDate:
                              DateTime.now().add(const Duration(days: 1)),
                          lastDate:
                              DateTime.now().add(const Duration(days: 30)),
                        );
                        if (date != null) {
                          setState(() {
                            selectedDate = date;
                            selectedWindowId = null;
                          });
                          box.setDelivery1(date, '');
                          await _loadWindowsForDate(date);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Delivery windows
                  Text(
                    'Available Time Slots',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (availableWindows.isEmpty)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.schedule,
                                size: 48,
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No delivery windows available',
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Please select a different date',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    ...availableWindows.map((window) => Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: RadioListTile<String>(
                            title: Text(
                              window['label'] ?? 'Delivery Window',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w500),
                            ),
                            subtitle: Text(
                              '${window['start_time']} - ${window['end_time']}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurface
                                    .withValues(alpha: 0.7),
                              ),
                            ),
                            value: window['id'],
                            groupValue: selectedWindowId,
                            onChanged: (value) {
                              setState(() {
                                selectedWindowId = value;
                              });
                              if (value != null && selectedDate != null) {
                                box.setDelivery1(selectedDate!, value);
                              }
                            },
                          ),
                        )),

                  const SizedBox(height: 32),

                  // Continue button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed:
                          selectedDate != null && selectedWindowId != null
                              ? () {
                                  box.confirmDeliveryPref();
                                  context.go('/box/recipes');
                                }
                              : null,
                      child: const Text(
                        'Continue to Recipe Selection',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  String _getDayName(DateTime date) {
    const days = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday'
    ];
    return days[date.weekday - 1];
  }
}


