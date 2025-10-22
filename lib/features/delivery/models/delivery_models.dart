/// Delivery models - clean entities for the delivery window system
enum DeliveryDaypart { morning, afternoon }

class DeliveryLocation {
  final String id; // 'home' | 'office'
  final String label;
  final String icon; // optional asset/lucide name
  const DeliveryLocation(this.id, this.label, this.icon);

  static const home = DeliveryLocation('home', 'Home', 'house');
  static const office = DeliveryLocation('office', 'Office', 'building');
}

class DeliveryWindow {
  final DateTime date; // canonical day
  final DeliveryDaypart daypart; // morning / afternoon
  final DeliveryLocation location; // home/office

  const DeliveryWindow({
    required this.date,
    required this.daypart,
    required this.location,
  });

  String get humanDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return "${days[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}";
  }

  String get humanRange =>
      daypart == DeliveryDaypart.morning ? "9–12 am" : "2–4 pm";

  String get humanSummary =>
      "$humanDate • ${daypart.name._capitalize()} • ${location.label}";

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'daypart': daypart.name,
    'location_id': location.id,
  };

  factory DeliveryWindow.fromJson(Map<String, dynamic> json) {
    final dp = (json['daypart'] as String) == 'morning'
        ? DeliveryDaypart.morning
        : DeliveryDaypart.afternoon;
    final locId = json['location_id'] as String;
    final loc = locId == 'home'
        ? DeliveryLocation.home
        : DeliveryLocation.office;
    final date = DateTime.parse(json['date'] as String);
    return DeliveryWindow(date: date, daypart: dp, location: loc);
  }
}

extension _Cap on String {
  String _capitalize() => isEmpty ? this : this[0].toUpperCase() + substring(1);
}
