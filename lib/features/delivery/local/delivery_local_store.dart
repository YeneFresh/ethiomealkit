import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/delivery_models.dart';

class DeliveryLocalStore {
  static const _kWindowJson = 'ynf_delivery_window';
  static const _kReceiptJson = 'ynf_receipt_json';

  // Save delivery window
  static Future<void> saveWindow(DeliveryWindow window) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kWindowJson, jsonEncode(window.toJson()));
    print('💾 Saved delivery window locally');
  }

  // Load delivery window
  static Future<DeliveryWindow?> loadWindow() async {
    try {
      final sp = await SharedPreferences.getInstance();
      final jsonStr = sp.getString(_kWindowJson);
      if (jsonStr == null) return null;

      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      return DeliveryWindow.fromJson(json);
    } catch (e) {
      print('⚠️ Error loading window from local store: $e');
      return null;
    }
  }

  // Save receipt JSON (post-checkout)
  static Future<void> saveReceiptJson(String json) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setString(_kReceiptJson, json);
    print('💾 Saved receipt locally');
  }

  // Read receipt JSON
  static Future<String?> readReceiptJson() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getString(_kReceiptJson);
  }
}



