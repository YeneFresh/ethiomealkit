import '../../domain/entities/recipe.dart';

/// Recipe Data Transfer Object (DTO)
/// Maps between Supabase JSON and domain entity
class RecipeDto {
  final String id;
  final String title;
  final String description;
  final int prepMinutes;
  final int cookMinutes;
  final int calories;
  final List<String> tags;
  final String? heroImageUrl;
  final int shelfDays;

  const RecipeDto({
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

  factory RecipeDto.fromJson(Map<String, dynamic> json) {
    return RecipeDto(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled Recipe',
      description: json['description'] as String? ?? '',
      prepMinutes: json['prep_minutes'] as int? ?? 0,
      cookMinutes: json['cook_minutes'] as int? ?? 0,
      calories: json['calories'] as int? ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
              [],
      heroImageUrl: json['hero_image_url'] as String?,
      shelfDays: json['shelf_days'] as int? ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'prep_minutes': prepMinutes,
      'cook_minutes': cookMinutes,
      'calories': calories,
      'tags': tags,
      'hero_image_url': heroImageUrl,
      'shelf_days': shelfDays,
    };
  }

  /// Convert DTO to domain entity
  Recipe toEntity() {
    return Recipe(
      id: id,
      title: title,
      description: description,
      prepMinutes: prepMinutes,
      cookMinutes: cookMinutes,
      calories: calories,
      tags: tags,
      heroImageUrl: heroImageUrl,
      shelfDays: shelfDays,
    );
  }

  /// Create DTO from domain entity
  factory RecipeDto.fromEntity(Recipe entity) {
    return RecipeDto(
      id: entity.id,
      title: entity.title,
      description: entity.description,
      prepMinutes: entity.prepMinutes,
      cookMinutes: entity.cookMinutes,
      calories: entity.calories,
      tags: entity.tags,
      heroImageUrl: entity.heroImageUrl,
      shelfDays: entity.shelfDays,
    );
  }
}



