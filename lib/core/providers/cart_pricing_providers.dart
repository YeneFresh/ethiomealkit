import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/pricing.dart';
import '../../features/box/providers/box_selection_providers.dart';
import 'recipe_selection_providers.dart';

/// Cart totals breakdown model
class CartTotals {
  final int people;
  final int meals;
  final int servings;
  final double pricePerServing;
  final double subtotal;
  final double discount;
  final double vat;
  final double delivery;
  final double total;

  const CartTotals({
    required this.people,
    required this.meals,
    required this.servings,
    required this.pricePerServing,
    required this.subtotal,
    required this.discount,
    required this.vat,
    required this.delivery,
    required this.total,
  });

  /// Empty cart totals
  static const empty = CartTotals(
    people: 0,
    meals: 0,
    servings: 0,
    pricePerServing: 0.0,
    subtotal: 0.0,
    discount: 0.0,
    vat: 0.0,
    delivery: 0.0,
    total: 0.0,
  );
}

/// Cart totals provider - calculates pricing based on selections
final cartTotalsProvider = Provider<CartTotals>((ref) {
  final meals = ref.watch(selectedMealsProvider) ?? 0;
  final people = ref.watch(selectedPeopleProvider) ?? 2;
  final selectedCount = ref.watch(selectedRecipesProvider).length;
  final promoApplied = ref.watch(promoAppliedProvider);

  // If nothing selected, return empty
  if (meals == 0 || selectedCount == 0) {
    return CartTotals.empty;
  }

  // Calculate servings (people × selected recipes)
  final servings = people * selectedCount;
  final pricePerServing = Pricing.getPricePerServing(meals);

  // Subtotal
  final subtotal = servings * pricePerServing;

  // Discount (JOIN40 = 40% off)
  final discount = promoApplied ? subtotal * Pricing.join40Discount : 0.0;

  // Taxable amount (after discount)
  final taxable = subtotal - discount;

  // VAT (15% on taxable)
  final vat = taxable * Pricing.vatRate;

  // Delivery (free)
  final delivery = Pricing.deliveryFee;

  // Total
  final total = taxable + vat + delivery;

  return CartTotals(
    people: people,
    meals: meals,
    servings: servings,
    pricePerServing: pricePerServing,
    subtotal: subtotal,
    discount: discount,
    vat: vat,
    delivery: delivery,
    total: total,
  );
});



