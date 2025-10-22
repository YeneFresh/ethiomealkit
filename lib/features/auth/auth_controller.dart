import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/supabase_client.dart';

final currentUserProvider = Provider<User?>((ref) {
  final client = SupabaseConfig.client;
  return client?.auth.currentUser;
});

final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final client = SupabaseConfig.client;
  if (client == null) {
    // Return a stream that emits an unauthenticated state
    return Stream.value(const AuthState(AuthChangeEvent.signedOut, null));
  }
  return client.auth.onAuthStateChange;
});

class AuthChangeNotifier extends ChangeNotifier {
  StreamSubscription? _sub;

  AuthChangeNotifier() {
    final client = SupabaseConfig.client;
    if (client != null) {
      _sub = client.auth.onAuthStateChange.listen((_) {
        notifyListeners();
      });
    }
  }

  User? get currentUser {
    final client = SupabaseConfig.client;
    return client?.auth.currentUser;
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
