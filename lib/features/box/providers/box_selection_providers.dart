import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';

/// Selected number of people (1-4) with persistence
class SelectedPeopleNotifier extends StateNotifier<int?> {
  SelectedPeopleNotifier() : super(null) {
    _loadState();
  }

  Future<void> _loadState() async {
    state = await PersistenceService.loadSelectedPeople();
  }

  void setPeople(int? people) {
    state = people;
    PersistenceService.saveSelectedPeople(people);
  }
}

final selectedPeopleProvider =
    StateNotifierProvider<SelectedPeopleNotifier, int?>(
      (ref) => SelectedPeopleNotifier(),
    );

/// Selected number of meals per week (3-5) with persistence
class SelectedMealsNotifier extends StateNotifier<int?> {
  SelectedMealsNotifier() : super(null) {
    _loadState();
  }

  Future<void> _loadState() async {
    state = await PersistenceService.loadSelectedMeals();
  }

  void setMeals(int? meals) {
    state = meals;
    PersistenceService.saveSelectedMeals(meals);
  }
}

final selectedMealsProvider =
    StateNotifierProvider<SelectedMealsNotifier, int?>(
      (ref) => SelectedMealsNotifier(),
    );

/// Promo state with persistence
class PromoNotifier extends StateNotifier<Map<String, dynamic>> {
  PromoNotifier() : super({'applied': true, 'code': 'JOIN40', 'discount': 40}) {
    _loadState();
  }

  Future<void> _loadState() async {
    state = await PersistenceService.loadPromo();
  }

  void setPromo(bool applied, String? code, int discount) {
    state = {'applied': applied, 'code': code, 'discount': discount};
    PersistenceService.savePromo(applied, code, discount);
  }

  void togglePromo() {
    final applied = !(state['applied'] as bool);
    setPromo(applied, state['code'] as String?, state['discount'] as int);
  }
}

final promoNotifierProvider =
    StateNotifierProvider<PromoNotifier, Map<String, dynamic>>(
      (ref) => PromoNotifier(),
    );

/// Convenience providers for backward compatibility
final promoAppliedProvider = Provider<bool>((ref) {
  return ref.watch(promoNotifierProvider)['applied'] as bool;
});

final promoCodeProvider = Provider<String?>((ref) {
  return ref.watch(promoNotifierProvider)['code'] as String?;
});

final promoDiscountProvider = Provider<int>((ref) {
  return ref.watch(promoNotifierProvider)['discount'] as int;
});

/// Calculate price per serving based on selections
final pricePerServingProvider = Provider<Map<String, dynamic>>((ref) {
  final people = ref.watch(selectedPeopleProvider);
  final meals = ref.watch(selectedMealsProvider);
  final promoApplied = ref.watch(promoAppliedProvider);
  final discountPercent = ref.watch(promoDiscountProvider);

  if (people == null || meals == null) {
    return {
      'originalPrice': 0.0,
      'discountedPrice': 0.0,
      'totalServings': 0,
      'currency': 'ETB',
    };
  }

  // Base pricing logic (example - adjust to your actual pricing)
  final basePrice = switch (meals) {
    3 => 55.0,
    4 => 49.0,
    5 => 45.0,
    _ => 50.0,
  };

  final totalServings = people * meals;
  final originalPrice = basePrice;
  final discountedPrice = promoApplied
      ? basePrice * (1 - discountPercent / 100)
      : basePrice;

  return {
    'originalPrice': originalPrice,
    'discountedPrice': discountedPrice,
    'totalServings': totalServings,
    'currency': 'ETB',
    'savings': originalPrice - discountedPrice,
  };
});

/// Box quota (meals per week selected in Step 1)
final boxQuotaProvider = Provider<int>((ref) {
  return ref.watch(selectedMealsProvider) ?? 0;
});
