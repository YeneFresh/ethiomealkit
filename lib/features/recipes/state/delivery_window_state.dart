import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Delivery window model
class DeliveryWindow {
  final String id;
  final String label; // e.g., "Thu 14:00–16:00"
  final String location; // e.g., "Home - Addis Ababa"
  final String? dateLabel; // e.g., "Tue, 19 Aug"
  final String? timeLabel; // e.g., "Between 5am to 6am"
  final bool recommended;

  const DeliveryWindow({
    required this.id,
    required this.label,
    required this.location,
    this.dateLabel,
    this.timeLabel,
    this.recommended = false,
  });

  factory DeliveryWindow.fromMap(Map<String, dynamic> data) {
    // Parse from API response
    final startAt = data['deliver_at'] ?? data['start_at'];
    final location = data['location_label'] ?? data['city'] ?? 'Addis Ababa';
    
    String label = 'Not specified';
    if (startAt != null) {
      try {
        final date = DateTime.parse(startAt.toString());
        final weekday = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'][date.weekday - 1];
        final hour = date.hour.toString().padLeft(2, '0');
        final minute = date.minute.toString().padLeft(2, '0');
        final endHour = (date.hour + 2).toString().padLeft(2, '0');
        label = '$weekday $hour:$minute–$endHour:$minute';
      } catch (e) {
        print('Error parsing date: $e');
      }
    }

    return DeliveryWindow(
      id: data['window_id'] ?? data['id'] ?? '',
      label: label,
      location: location,
      recommended: data['is_recommended'] == true,
    );
  }
}

/// Selected delivery window provider
final selectedWindowProvider = StateProvider<DeliveryWindow?>((ref) => null);




