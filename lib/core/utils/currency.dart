import 'dart:math';

/// Supported currencies
enum Currency {
  etb, // Ethiopian Birr
  aed, // UAE Dirham
}

/// Currency formatting utility
class CurrencyFmt {
  CurrencyFmt._(); // Private constructor

  /// Current currency (can be set from env at app start)
  static Currency currency = Currency.etb;

  /// Format a number as currency
  static String format(num value) {
    final s = value.toStringAsFixed(0); // No decimals for ETB
    switch (currency) {
      case Currency.etb:
        return 'ETB $s';
      case Currency.aed:
        return 'AED ${value.toStringAsFixed(2)}';
    }
  }

  /// Format as price per serving
  static String perServing(num value) => '${format(value)} / serving';

  /// Pad left for alignment (optional)
  static String padLeft(String s, int minLength) =>
      s.padLeft(max(s.length, minLength));

  /// Format with sign prefix
  static String formatWithSign(num value) {
    if (value >= 0) {
      return format(value);
    } else {
      return '−${format(value.abs())}';
    }
  }
}
