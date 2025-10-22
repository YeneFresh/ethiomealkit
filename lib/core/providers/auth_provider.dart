import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/onboarding/providers/user_onboarding_progress_provider.dart';

/// Supabase client provider
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

/// Auth state provider
final authProvider =
    StateNotifierProvider<AuthController, AsyncValue<User?>>((ref) {
  return AuthController(ref);
});

/// Auth controller for sign-up and sign-in
class AuthController extends StateNotifier<AsyncValue<User?>> {
  final Ref _ref;

  AuthController(this._ref) : super(const AsyncValue.data(null)) {
    // Initialize with current user
    _initCurrentUser();
  }

  void _initCurrentUser() {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      state = AsyncValue.data(user);
    } catch (e) {
      state = const AsyncValue.data(null);
    }
  }

  /// Sign up with email and password
  Future<void> signUpWithEmail(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AsyncValue.data(response.user);

        // Mark sign-up step complete
        await _ref
            .read(userOnboardingProgressProvider.notifier)
            .completeStep(OnboardingStep.signup);

        print('✅ Sign-up successful: ${response.user!.email}');
        return;
      } else {
        throw Exception('Sign-up failed: No user returned');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print('❌ Sign-up failed: $e');
      rethrow;
    }
  }

  /// Sign in with email and password
  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = AsyncValue.data(response.user);
        print('✅ Sign-in successful: ${response.user!.email}');
        return;
      } else {
        throw Exception('Sign-in failed: No user returned');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print('❌ Sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign in with Google OAuth
  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      final response = await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: '${Uri.base.origin}/auth-callback',
      );

      if (response) {
        print('✅ Google OAuth initiated');
        // User will be redirected, session handled in callback
      } else {
        throw Exception('Google sign-in failed');
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print('❌ Google sign-in failed: $e');
      rethrow;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      state = const AsyncValue.data(null);
      print('✅ Sign-out successful');
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      print('❌ Sign-out failed: $e');
    }
  }
}



