import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../api/api_client.dart';
import '../models/models.dart';

final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return MealsRepository(api);
});

class MealsRepository {
  final ApiClient api;
  MealsRepository(this.api);

  Future<List<MealKit>> getMealKits() => api.fetchMealKits();
  Future<MealKit> getMealKit(String id) => api.fetchMealKitDetail(id);
}

final apiClientProvider = Provider<ApiClient>((ref) {
  // Placeholder, overridden in main via ProviderScope overrides
  throw UnimplementedError('apiClientProvider not configured');
});



