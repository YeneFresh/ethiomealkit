import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repo/meals_repository.dart';
import '../../models/models.dart';
import 'package:go_router/go_router.dart';

class MealsListScreen extends ConsumerWidget {
  const MealsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<MealKit>>(
      future: ref.read(mealsRepositoryProvider).getMealKits(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final kits = snapshot.data!;
        return ListView.separated(
          itemCount: kits.length,
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final kit = kits[index];
            return ListTile(
              leading: kit.imageUrl != null ? Image.network(kit.imageUrl!, width: 64, height: 64, fit: BoxFit.cover) : null,
              title: Text(kit.title),
              subtitle: Text('ETB ${(kit.priceCents / 100).toStringAsFixed(2)}'),
              onTap: () => context.go('/meals/${kit.id}'),
            );
          },
        );
      },
    );
  }
}


