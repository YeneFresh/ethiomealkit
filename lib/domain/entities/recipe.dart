/// Recipe entity (domain model)
/// Pure business logic, no framework dependencies
class Recipe {
  final String id;
  final String title;
  final String description;
  final int prepMinutes;
  final int cookMinutes;
  final int calories;
  final List<String> tags;
  final String? heroImageUrl;
  final int shelfDays; // Perishability for smart auto-picks

  const Recipe({
    required this.id,
    required this.title,
    required this.description,
    required this.prepMinutes,
    required this.cookMinutes,
    required this.calories,
    required this.tags,
    this.heroImageUrl,
    this.shelfDays = 3,
  });

  int get totalMinutes => prepMinutes + cookMinutes;

  bool get isQuick => totalMinutes <= 30;

  bool get isChefChoice => tags.any((t) => t.toLowerCase().contains("chef"));

  bool get isPopular => tags.contains('Popular');

  /// Calculate pick priority for auto-selection
  /// Higher score = higher priority
  int get pickScore {
    int score = 0;

    // Chef's Choice = highest confidence
    if (isChefChoice) score += 100;

    // Popular = user-tested
    if (isPopular) score += 50;

    // Quick = low friction
    if (isQuick) score += 30;

    // Express = fast
    if (tags.contains('Express')) score += 20;

    // Fresh ingredients last longer = easier to deliver
    score += shelfDays * 5;

    // Prefer shorter cook times
    score -= cookMinutes ~/ 5;

    return score;
  }

  Recipe copyWith({
    String? id,
    String? title,
    String? description,
    int? prepMinutes,
    int? cookMinutes,
    int? calories,
    List<String>? tags,
    String? heroImageUrl,
    int? shelfDays,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      prepMinutes: prepMinutes ?? this.prepMinutes,
      cookMinutes: cookMinutes ?? this.cookMinutes,
      calories: calories ?? this.calories,
      tags: tags ?? this.tags,
      heroImageUrl: heroImageUrl ?? this.heroImageUrl,
      shelfDays: shelfDays ?? this.shelfDays,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Recipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
