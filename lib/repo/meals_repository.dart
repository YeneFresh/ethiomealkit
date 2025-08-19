import '../api/api_client.dart';
import '../models/models.dart';

class MealsRepository {
  final ApiClient api;
  MealsRepository(this.api);

  Future<List<MealKit>> getMealKits() => api.fetchMealKits();
  Future<MealKit> getMealKit(String id) => api.fetchMealKitDetail(id);
}
