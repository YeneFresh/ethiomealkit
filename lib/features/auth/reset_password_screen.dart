// lib/features/auth/reset_password_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _pass1 = TextEditingController();
  final _pass2 = TextEditingController();
  bool _loading = false;
  String? _msg;

  @override
  void dispose() {
    _pass1.dispose();
    _pass2.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final p1 = _pass1.text;
    final p2 = _pass2.text;

    if (p1.length < 8) {
      setState(() => _msg = 'Password must be at least 8 characters.');
      return;
    }
    if (p1 != p2) {
      setState(() => _msg = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _msg = null;
    });
    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: p1),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated.')));

      // Optional: force a refresh of the session
      // final session = await Supabase.instance.client.auth.refreshSession();

      context.go('/home');
    } on AuthException catch (e) {
      setState(() => _msg = e.message);
    } catch (e) {
      setState(() => _msg = 'Failed to update password: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Handle web sessions for password reset
    if (kIsWeb && Supabase.instance.client.auth.currentSession == null) {
      // idempotent: will no-op if already set
      unawaited(Supabase.instance.client.auth.getSessionFromUrl(Uri.base));
    }

    final user = Supabase.instance.client.auth.currentUser;
    final hasRecoverySession = user != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Set New Password'),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Status indicator
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: hasRecoverySession
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        hasRecoverySession ? Icons.check_circle : Icons.warning,
                        color: hasRecoverySession
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          hasRecoverySession
                              ? 'Recovery session detected'
                              : 'No recovery session found',
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(
                                color: hasRecoverySession
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.error,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Password fields
                TextFormField(
                  controller: _pass1,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'New password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _pass2,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Confirm password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),

                const SizedBox(height: 24),

                // Update button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: (_loading || !hasRecoverySession)
                        ? null
                        : _update,
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Password'),
                  ),
                ),

                // Error message
                if (_msg != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Theme.of(context).colorScheme.error,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _msg!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
