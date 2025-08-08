import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repo/meals_repository.dart';
import '../../repo/cart_repository.dart';
import '../../models/models.dart';

class MealDetailScreen extends ConsumerWidget {
  final String id;
  const MealDetailScreen({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<MealKit>(
      future: ref.read(mealsRepositoryProvider).getMealKit(id),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        final kit = snapshot.data!;
        return Scaffold(
          appBar: AppBar(title: Text(kit.title)),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (kit.imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(kit.imageUrl!, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(kit.description ?? ''),
              const SizedBox(height: 16),
              Text('ETB ${(kit.priceCents / 100).toStringAsFixed(2)}', style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(cartRepositoryProvider).add(kit.id, 1);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Added to cart')));
                  }
                },
                child: const Text('Add to Cart'),
              ),
            ),
          ),
        );
      },
    );
  }
}



