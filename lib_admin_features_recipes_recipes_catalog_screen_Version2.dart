// lib/admin/features/recipes/recipes_catalog_screen.dart
import 'package:flutter/material.dart';

class RecipesCatalogScreen extends StatelessWidget {
  const RecipesCatalogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Expanded(
                child: TextField(decoration: InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search recipes…')),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(onPressed: () {/* TODO: create */}, icon: const Icon(Icons.add), label: const Text('New Recipe')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: ListView.separated(
                padding: const EdgeInsets.all(8),
                itemCount: 8,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) => ListTile(
                  leading: const CircleAvatar(child: Icon(Icons.image)),
                  title: Text('Recipe #$i'),
                  subtitle: const Text('tags: vegan, quick • allergens: nuts'),
                  trailing: IconButton(icon: const Icon(Icons.edit), onPressed: () {/* TODO: edit */}),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}