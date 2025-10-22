/// Pricing constants for YeneFresh meal kits
class Pricing {
  Pricing._(); // Private constructor

  // Price per serving based on meals per week
  static const double pricePerServing3 = 55.0; // ETB
  static const double pricePerServing4 = 49.0; // ETB
  static const double pricePerServing5 = 45.0; // ETB

  // Tax and fees
  static const double vatRate = 0.15; // 15% VAT
  static const double deliveryFee = 0.0; // Free delivery in Addis Ababa

  // Promotions
  static const double join40Discount = 0.40; // 40% off first order with JOIN40

  /// Get price per serving based on meals per week
  static double getPricePerServing(int meals) {
    if (meals >= 5) return pricePerServing5;
    if (meals == 4) return pricePerServing4;
    return pricePerServing3;
  }
}
