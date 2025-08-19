import 'package:shared_preferences/shared_preferences.dart';

class AuthPrefs {
  static const _kEmail = 'last_email';
  static const _kRemember = 'remember_me';
  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kLastActiveTime = 'last_active_time';

  static Future<void> saveEmail(String email, {bool remember = true}) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kRemember, remember);
    if (remember) await sp.setString(_kEmail, email.trim());
    else await sp.remove(_kEmail);
  }

  static Future<String?> loadEmail() async {
    final sp = await SharedPreferences.getInstance();
    final remember = sp.getBool(_kRemember) ?? true;
    if (!remember) return null;
    return sp.getString(_kEmail);
  }

  static Future<bool> loadRememberMe() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kRemember) ?? true;
  }
}
