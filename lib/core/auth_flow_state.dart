// lib/core/auth_flow_state.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthFlowState extends ChangeNotifier {
  String? _lastEmail;
  String? get lastEmail => _lastEmail;

  void setEmail(String email) {
    _lastEmail = email.trim();
    notifyListeners();
  }
}

final authFlowState = AuthFlowState();

String _resetRedirect() {
  if (kIsWeb) return '${Uri.base.origin}/reset';
  // Mobile (Android/iOS)
  return 'yenefresh://auth/reset';
}

Future<void> resetPassword(String email) async {
  try {
    await Supabase.instance.client.auth.resetPasswordForEmail(
      email,
      redirectTo: _resetRedirect(),
    );
    print('Password reset email sent to $email');
  } on AuthException catch (e) {
    print('Error: ${e.message}');
  }
}

Future<void> updatePassword(String newPassword) async {
  try {
    final res = await Supabase.instance.client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
    print("Password updated: $res");
  } catch (e) {
    print("Error: $e");
  }
}
