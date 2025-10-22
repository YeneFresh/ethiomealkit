/// Address model for delivery locations
class Address {
  final String id; // 'home' | 'office' | uuid
  final String label; // 'Home' | 'Office' | custom
  final String line1;
  final String? line2;
  final String city;
  final String? notes;
  final double? lat;
  final double? lng;

  const Address({
    required this.id,
    required this.label,
    required this.line1,
    this.line2,
    required this.city,
    this.notes,
    this.lat,
    this.lng,
  });

  Address copyWith({
    String? label,
    String? line1,
    String? line2,
    String? city,
    String? notes,
    double? lat,
    double? lng,
  }) => Address(
    id: id,
    label: label ?? this.label,
    line1: line1 ?? this.line1,
    line2: line2 ?? this.line2,
    city: city ?? this.city,
    notes: notes ?? this.notes,
    lat: lat ?? this.lat,
    lng: lng ?? this.lng,
  );

  /// Display full address as single line
  String get fullAddress {
    final parts = <String>[
      if (line1.isNotEmpty) line1,
      if (line2 != null && line2!.isNotEmpty) line2!,
      city,
    ];
    return parts.join(', ');
  }

  /// Display short address (for cards/chips)
  String get shortAddress {
    return '$label • $city';
  }
}
