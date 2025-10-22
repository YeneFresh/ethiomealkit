import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class DeliveryWindowSelector extends StatefulWidget {
  final List<Map<String, dynamic>> windows;
  final Function(String windowId) onWindowSelected;
  final String? selectedWindowId;

  const DeliveryWindowSelector({
    super.key,
    required this.windows,
    required this.onWindowSelected,
    this.selectedWindowId,
  });

  @override
  State<DeliveryWindowSelector> createState() => _DeliveryWindowSelectorState();
}

class _DeliveryWindowSelectorState extends State<DeliveryWindowSelector> {
  String? _selectedDay;
  String? _selectedTimeSlot;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeSelection();
    });
  }

  void _initializeSelection() {
    final availableDays = _getAvailableDays();
    if (availableDays.isNotEmpty) {
      // Default to tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowDayName = _getDayName(tomorrow.weekday);

      if (availableDays.contains(tomorrowDayName)) {
        setState(() {
          _selectedDay = tomorrowDayName;
          _selectDefault();
        });
      } else {
        setState(() {
          _selectedDay = availableDays.first;
          _selectDefault();
        });
      }
    }
  }

  void _selectDefault() {
    if (_selectedDay != null) {
      final timeSlots = _getAvailableTimeSlots(_selectedDay!);
      if (timeSlots.contains('Afternoon')) {
        setState(() {
          _selectedTimeSlot = 'Afternoon';
          _updateSelection();
        });
      } else if (timeSlots.isNotEmpty) {
        setState(() {
          _selectedTimeSlot = timeSlots.first;
          _updateSelection();
        });
      }
    }
  }

  void _updateSelection() {
    if (_selectedDay != null && _selectedTimeSlot != null) {
      final windowId = _getWindowId(_selectedDay!, _selectedTimeSlot!);
      if (windowId != null) {
        widget.onWindowSelected(windowId);
      }
    }
  }

  String? _getWindowId(String day, String timeSlot) {
    final dayPrefix = day.substring(0, 3).toLowerCase();
    final slotSuffix = _getTimeSlot(timeSlot);
    return '${dayPrefix}_$slotSuffix';
  }

  String _getTimeSlot(String displaySlot) {
    switch (displaySlot) {
      case 'Morning':
        return 'morning';
      case 'Noon':
        return 'noon';
      case 'Afternoon':
        return 'afternoon';
      default:
        return displaySlot.toLowerCase();
    }
  }

  List<String> _getAvailableDays() {
    final now = DateTime.now();
    final days = <String>[];

    // Generate next 7 days starting from tomorrow
    for (int i = 1; i <= 7; i++) {
      final date = now.add(Duration(days: i));
      days.add(_getDayName(date.weekday));
    }

    return days;
  }

  String _getDayName(int weekday) {
    switch (weekday) {
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      case 7:
        return 'Sunday';
      default:
        return 'Monday';
    }
  }

  List<String> _getAvailableTimeSlots(String day) {
    // Weekend restriction: Saturday and Sunday only have Morning & Noon
    if (day == 'Saturday' || day == 'Sunday') {
      return ['Morning', 'Noon'];
    }
    return ['Morning', 'Noon', 'Afternoon'];
  }

  String _getTimeSlotDescription(String slot) {
    switch (slot) {
      case 'Morning':
        return '7:00-9:30';
      case 'Noon':
        return '12:00-14:30';
      case 'Afternoon':
        return '15:00-18:30';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final availableDays = _getAvailableDays();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Selection
          Text(
            'Select Day',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: availableDays.length,
              itemBuilder: (context, index) {
                final day = availableDays[index];
                final isSelected = _selectedDay == day;
                final now = DateTime.now();
                final dayDate = now.add(Duration(days: index + 1));

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedDay = day;
                        _selectedTimeSlot = null;
                        _selectDefault();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day.substring(0, 3),
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${dayDate.day}/${dayDate.month}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                      .withValues(alpha: 0.8)
                                  : theme.colorScheme.onSurface
                                      .withValues(alpha: 0.7),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 20),

          // Time Slot Selection
          if (_selectedDay != null) ...[
            Text(
              'Select Time',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 12),
            Flexible(
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: _getAvailableTimeSlots(_selectedDay!).map((slot) {
                  final isSelected = _selectedTimeSlot == slot;
                  final description = _getTimeSlotDescription(slot);

                  return GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _selectedTimeSlot = slot;
                        _updateSelection();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            slot,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (description.isNotEmpty)
                            Text(
                              description,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: isSelected
                                    ? theme.colorScheme.onPrimary
                                        .withValues(alpha: 0.8)
                                    : theme.colorScheme.onSurface
                                        .withValues(alpha: 0.7),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
