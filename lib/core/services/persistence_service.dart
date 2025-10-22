import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/address.dart';

/// Centralized persistence service for all onboarding state
class PersistenceService {
  PersistenceService._();

  // Keys
  static const _keySelectedPeople = 'onboarding_selected_people';
  static const _keySelectedMeals = 'onboarding_selected_meals';
  static const _keySelectedRecipes = 'onboarding_selected_recipes';
  static const _keyPromoApplied = 'onboarding_promo_applied';
  static const _keyPromoCode = 'onboarding_promo_code';
  static const _keyPromoDiscount = 'onboarding_promo_discount';
  static const _keyActiveAddressId = 'onboarding_active_address_id';
  static const _keyAddresses = 'onboarding_addresses';
  static const _keyDeliveryWindowId = 'onboarding_delivery_window_id';
  static const _keyDeliveryWindowLabel = 'onboarding_delivery_window_label';
  static const _keyDeliveryWindowStartAt = 'onboarding_delivery_window_start';
  static const _keyDeliveryWindowEndAt = 'onboarding_delivery_window_end';
  static const _keyDeliveryWindowCity = 'onboarding_delivery_window_city';
  static const _keyCurrentStep = 'onboarding_current_step';

  // ========== BOX SELECTION ==========

  static Future<void> saveSelectedPeople(int? people) async {
    final prefs = await SharedPreferences.getInstance();
    if (people == null) {
      await prefs.remove(_keySelectedPeople);
    } else {
      await prefs.setInt(_keySelectedPeople, people);
    }
    print('💾 Saved selected people: $people');
  }

  static Future<int?> loadSelectedPeople() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedPeople);
  }

  static Future<void> saveSelectedMeals(int? meals) async {
    final prefs = await SharedPreferences.getInstance();
    if (meals == null) {
      await prefs.remove(_keySelectedMeals);
    } else {
      await prefs.setInt(_keySelectedMeals, meals);
    }
    print('💾 Saved selected meals: $meals');
  }

  static Future<int?> loadSelectedMeals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySelectedMeals);
  }

  static Future<void> savePromo(
      bool applied, String? code, int discount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyPromoApplied, applied);
    if (code != null) {
      await prefs.setString(_keyPromoCode, code);
    }
    await prefs.setInt(_keyPromoDiscount, discount);
    print('💾 Saved promo: $code ($discount%)');
  }

  static Future<Map<String, dynamic>> loadPromo() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'applied': prefs.getBool(_keyPromoApplied) ?? true,
      'code': prefs.getString(_keyPromoCode) ?? 'JOIN40',
      'discount': prefs.getInt(_keyPromoDiscount) ?? 40,
    };
  }

  // ========== RECIPE SELECTION ==========

  static Future<void> saveSelectedRecipes(Set<String> recipeIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_keySelectedRecipes, recipeIds.toList());
    print('💾 Saved ${recipeIds.length} selected recipes');
  }

  static Future<Set<String>> loadSelectedRecipes() async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keySelectedRecipes) ?? [];
    return list.toSet();
  }

  // ========== ADDRESS ==========

  static Future<void> saveActiveAddressId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyActiveAddressId, id);
    print('💾 Saved active address ID: $id');
  }

  static Future<String?> loadActiveAddressId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyActiveAddressId);
  }

  static Future<void> saveAddresses(List<Address> addresses) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = addresses.map((a) => _addressToMap(a)).toList();
    await prefs.setString(_keyAddresses, jsonEncode(encoded));
    print('💾 Saved ${addresses.length} addresses');
  }

  static Future<List<Address>> loadAddresses() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_keyAddresses);
    if (json == null) return [];

    try {
      final List<dynamic> decoded = jsonDecode(json);
      return decoded.map((a) => _addressFromMap(a)).toList();
    } catch (e) {
      print('⚠️ Failed to load addresses: $e');
      return [];
    }
  }

  static Map<String, dynamic> _addressToMap(Address a) => {
        'id': a.id,
        'label': a.label,
        'line1': a.line1,
        'line2': a.line2,
        'city': a.city,
        'notes': a.notes,
        'lat': a.lat,
        'lng': a.lng,
      };

  static Address _addressFromMap(Map<String, dynamic> map) => Address(
        id: map['id'] ?? '',
        label: map['label'] ?? 'Home',
        line1: map['line1'] ?? '',
        line2: map['line2'],
        city: map['city'] ?? 'Addis Ababa',
        notes: map['notes'],
        lat: map['lat'],
        lng: map['lng'],
      );

  // ========== DELIVERY WINDOW ==========

  static Future<void> saveDeliveryWindow(
    String id,
    String label,
    DateTime startAt,
    DateTime endAt,
    String city,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDeliveryWindowId, id);
    await prefs.setString(_keyDeliveryWindowLabel, label);
    await prefs.setString(_keyDeliveryWindowStartAt, startAt.toIso8601String());
    await prefs.setString(_keyDeliveryWindowEndAt, endAt.toIso8601String());
    await prefs.setString(_keyDeliveryWindowCity, city);
    print('💾 Saved delivery window: $label');
  }

  static Future<Map<String, dynamic>?> loadDeliveryWindow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final id = prefs.getString(_keyDeliveryWindowId);
      if (id == null) return null;

      return {
        'id': id,
        'label': prefs.getString(_keyDeliveryWindowLabel) ?? '',
        'start_at': prefs.getString(_keyDeliveryWindowStartAt) ?? '',
        'end_at': prefs.getString(_keyDeliveryWindowEndAt) ?? '',
        'city': prefs.getString(_keyDeliveryWindowCity) ?? 'Addis Ababa',
        'slot': _extractSlotFromTimes(
          prefs.getString(_keyDeliveryWindowStartAt),
          prefs.getString(_keyDeliveryWindowEndAt),
        ),
      };
    } catch (e) {
      print('⚠️ Error loading delivery window: $e');
      return null;
    }
  }

  static String _extractSlotFromTimes(String? startAt, String? endAt) {
    if (startAt == null || endAt == null) return '14-16';

    try {
      final start = DateTime.parse(startAt);
      final end = DateTime.parse(endAt);
      return '${start.hour.toString().padLeft(2, '0')}-${end.hour.toString().padLeft(2, '0')}';
    } catch (e) {
      return '14-16';
    }
  }

  // ========== CLEAR ALL ==========

  static Future<void> clearAllOnboardingData() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = [
      _keySelectedPeople,
      _keySelectedMeals,
      _keySelectedRecipes,
      _keyPromoApplied,
      _keyPromoCode,
      _keyPromoDiscount,
      _keyActiveAddressId,
      _keyAddresses,
      _keyDeliveryWindowId,
      _keyDeliveryWindowLabel,
      _keyDeliveryWindowStartAt,
      _keyDeliveryWindowEndAt,
      _keyDeliveryWindowCity,
      _keyCurrentStep,
    ];

    for (final key in keys) {
      await prefs.remove(key);
    }

    print('🗑️ Cleared all onboarding data');
  }

  /// Check if user has any saved onboarding progress
  static Future<bool> hasOnboardingProgress() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_keySelectedPeople) ||
        prefs.containsKey(_keySelectedMeals) ||
        prefs.containsKey(_keySelectedRecipes) ||
        prefs.containsKey(_keyCurrentStep);
  }
}
