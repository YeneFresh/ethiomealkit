import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiomealkit/core/sentry_service.dart';

class PinVault {
  static const _kHash = 'pin_hash';
  static const _kSalt = 'pin_salt';
  static const _kEnabled = 'pin_enabled';
  static const _kAttempts = 'pin_failed_attempts';
  static const _kLockUntil = 'pin_lock_until_ms';

  static const _storage = FlutterSecureStorage();

  /// Hash PIN with salt using SHA-256
  static String _hash(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }

  static Future<bool> isEnabled() async {
    final sp = await SharedPreferences.getInstance();
    return sp.getBool(_kEnabled) ?? false;
  }

  static Future<void> disable() async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_kEnabled, false);
    await _storage.delete(key: _kHash);
    await _storage.delete(key: _kSalt);
    await sp.remove(_kAttempts);
    await sp.remove(_kLockUntil);
  }

  static Future<void> enableWithPin(String pin) async {
    if (pin.length < 4 || pin.length > 6) {
      throw ArgumentError('PIN must be 4–6 digits');
    }

    try {
      final sp = await SharedPreferences.getInstance();
      final salt = DateTime.now().millisecondsSinceEpoch.toString();
      final hash = _hash(pin, salt);
      await _storage.write(key: _kSalt, value: salt, aOptions: _androidOpts());
      await _storage.write(key: _kHash, value: hash, aOptions: _androidOpts());
      await sp.setBool(_kEnabled, true);
      await sp.setInt(_kAttempts, 0);
      await sp.remove(_kLockUntil);

      // Log successful PIN setup
      SentryService.addAuthBreadcrumb(
        action: 'pin_enabled',
        provider: 'pin',
        metadata: {'pin_length': pin.length},
      );
    } catch (e) {
      // Log PIN setup failure
      SentryService.trackAuthError(
        provider: 'pin',
        errorCode: 'setup_failed',
        errorMessage: 'Failed to enable PIN: $e',
        metadata: {'pin_length': pin.length},
      );
      rethrow;
    }
  }

  static Future<bool> hasPin() async {
    final h = await _storage.read(key: _kHash, aOptions: _androidOpts());
    return h != null && h.isNotEmpty;
  }

  /// Returns remaining lock duration in seconds (0 if not locked)
  static Future<int> lockRemainingSeconds() async {
    final sp = await SharedPreferences.getInstance();
    final until = sp.getInt(_kLockUntil);
    if (until == null) return 0;
    final now = DateTime.now().millisecondsSinceEpoch;
    final rem = until - now;
    return rem > 0 ? (rem / 1000).ceil() : 0;
  }

  /// Verify a pin. Applies exponential backoff lockout after 5+ failed attempts.
  static Future<bool> verifyPin(String pin) async {
    final sp = await SharedPreferences.getInstance();

    // Locked?
    final rem = await lockRemainingSeconds();
    if (rem > 0) return false;

    final salt = await _storage.read(key: _kSalt, aOptions: _androidOpts());
    final h = await _storage.read(key: _kHash, aOptions: _androidOpts());
    if (salt == null || h == null) return false;

    final ok = _hash(pin, salt) == h;

    if (ok) {
      await sp.setInt(_kAttempts, 0);
      await sp.remove(_kLockUntil);

      // Log successful PIN verification
      SentryService.addAuthBreadcrumb(
        action: 'pin_verified',
        provider: 'pin',
        metadata: {'pin_length': pin.length},
      );

      return true;
    } else {
      final attempts = (sp.getInt(_kAttempts) ?? 0) + 1;
      await sp.setInt(_kAttempts, attempts);

      // Log failed PIN attempt
      SentryService.addAuthBreadcrumb(
        action: 'pin_failed',
        provider: 'pin',
        metadata: {
          'pin_length': pin.length,
          'failed_attempts': attempts,
          'locked': attempts >= 5,
        },
      );

      if (attempts >= 5) {
        // lock: 30s * 2^blocks, cap 15 min
        final blocks = (attempts - 5); // 0,1,2,...
        final seconds = (30 * (1 << blocks)).clamp(30, 900);
        final until = DateTime.now()
            .add(Duration(seconds: seconds))
            .millisecondsSinceEpoch;
        await sp.setInt(_kLockUntil, until);

        // Log lockout
        SentryService.trackAuthError(
          provider: 'pin',
          errorCode: 'lockout_triggered',
          errorMessage: 'PIN lockout triggered after $attempts failed attempts',
          metadata: {'failed_attempts': attempts, 'lockout_seconds': seconds},
        );
      }
      return false;
    }
  }

  static AndroidOptions _androidOpts() =>
      const AndroidOptions(encryptedSharedPreferences: true);
}
