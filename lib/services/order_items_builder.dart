import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/recipe_selection_providers.dart';

/// Builds order items JSON payload from selected recipes.
/// Each entry: { "meal_kit_id": <id>, "quantity": 1 }
/// NOTE: Uses recipe IDs as meal_kit_id for now; ensure backend mapping aligns.
class OrderItemsBuilder {
  static List<Map<String, dynamic>> buildItemsJson(Ref ref) {
    final selected = ref.read(selectedRecipesProvider);
    if (selected.isEmpty) return const [];
    return selected
        .map((id) => {
              'meal_kit_id': id,
              'quantity': 1,
            })
        .toList(growable: false);
  }
}


