// lib/core/auth_notifier.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

class AuthNotifier extends ChangeNotifier {
  AuthNotifier();

  StreamSubscription<AuthState>? _sub;
  bool _initialized = false;

  void _initialize() {
    if (_initialized) return;
    try {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        // Any sign-in/out/session refresh will trigger router reevaluation
        notifyListeners();
      });
      _initialized = true;
    } catch (e) {
      // Supabase not ready yet, will retry later
      debugPrint('AuthNotifier: Supabase not ready yet: $e');
    }
  }

  bool get isSignedIn {
    try {
      _initialize(); // Try to initialize if not done yet
      return Supabase.instance.client.auth.currentSession != null;
    } catch (e) {
      return false; // Return false if Supabase not ready
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
