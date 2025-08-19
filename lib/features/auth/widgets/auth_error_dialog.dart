import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../core/auth_prefs.dart';
import '../../../core/auth_event_logger.dart';

Future<void> showAuthErrorDialog(
  BuildContext context, {
  String? errorMessage,
}) async {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => _AuthErrorDialog(errorMessage: errorMessage),
  );
}

class _AuthErrorDialog extends StatefulWidget {
  final String? errorMessage;
  const _AuthErrorDialog({this.errorMessage});

  @override
  State<_AuthErrorDialog> createState() => _AuthErrorDialogState();
}

class _AuthErrorDialogState extends State<_AuthErrorDialog> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _showPasswordFallback = false;
  bool _loadingResend = false;
  bool _loadingPwd = false;

  @override
  void initState() {
    super.initState();
    () async {
      final saved = await AuthPrefs.loadEmail();
      if (mounted && saved != null) _emailCtrl.text = saved;
    }();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  String get _origin => Uri.base.origin;

  Future<void> _resendLink() async {
    final email = _emailCtrl.text.trim();
    if (!_validEmail(email)) {
      _snack('Enter a valid email');
      return;
    }
    setState(() => _loadingResend = true);
    try {
      final redirect =
          kIsWeb ? '$_origin/auth-callback' : 'yenefresh://auth/callback';
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirect,
      );

      // Log success
      await AuthEventLogger.logMagicLinkSent(
        route: '/auth-error-dialog',
        metadata: {
          'redirect_url': redirect,
          'context': 'error_dialog_resend',
        },
      );

      _snack('Magic link resent. Check your inbox.');
    } on AuthException catch (e) {
      _snack(e.message, error: true);

      // Log error
      await AuthEventLogger.logSignInError(
        provider: 'magic_link',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_resend',
          'supabase_error': e.message,
          'status_code': e.statusCode,
        },
      );
    } catch (e) {
      _snack('Failed to resend: $e', error: true);

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'magic_link',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_resend',
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loadingResend = false);
    }
  }

  Future<void> _emailPasswordSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loadingPwd = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
      );

      // Log success
      await AuthEventLogger.logSignInSuccess(
        provider: 'password',
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_fallback',
        },
      );

      if (!mounted) return;
      Navigator.of(context).pop(); // close dialog
      context.go('/home'); // success → home
    } on AuthException catch (e) {
      _snack(e.message, error: true);

      // Log error
      await AuthEventLogger.logSignInError(
        provider: 'password',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_fallback',
          'supabase_error': e.message,
          'status_code': e.statusCode,
        },
      );
    } catch (e) {
      _snack('Sign-in failed: $e', error: true);

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'password',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_fallback',
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loadingPwd = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (!_validEmail(email)) {
      _snack('Enter a valid email first');
      return;
    }
    setState(() => _loadingPwd = true);
    try {
      final redirect = kIsWeb ? '$_origin/reset' : 'yenefresh://auth/reset';
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirect,
      );

      // Log success
      await AuthEventLogger.logPasswordReset(
        route: '/auth-error-dialog',
        metadata: {
          'redirect_url': redirect,
          'context': 'error_dialog_forgot',
        },
      );

      _snack('Reset link sent.');
    } on AuthException catch (e) {
      _snack(e.message, error: true);

      // Log error
      await AuthEventLogger.logSignInError(
        provider: 'password_reset',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_forgot',
          'supabase_error': e.message,
          'status_code': e.statusCode,
        },
      );
    } catch (e) {
      _snack('Reset failed: $e', error: true);

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'password_reset',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/auth-error-dialog',
        metadata: {
          'context': 'error_dialog_forgot',
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loadingPwd = false);
    }
  }

  bool _validEmail(String s) => RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(s);

  void _snack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: error ? Colors.red.shade700 : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: c.error),
              const SizedBox(height: 12),
              Text(
                'We couldn\'t sign you in',
                style: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                widget.errorMessage ??
                    'The link may be expired or already used. You can resend a fresh link or use email & password.',
                style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Email entry (shared by resend + fallback)
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'you@example.com',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),

              // Primary actions row
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _loadingResend ? null : _resendLink,
                      icon: const Icon(Icons.mail_outline_rounded),
                      label: const Text('Resend magic link'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => setState(() {
                        _showPasswordFallback = !_showPasswordFallback;
                      }),
                      icon: const Icon(Icons.lock_outline_rounded),
                      label: Text(_showPasswordFallback
                          ? 'Hide password login'
                          : 'Use email & password'),
                    ),
                  ),
                ],
              ),

              // Inline password fallback (expandable)
              AnimatedCrossFade(
                duration: const Duration(milliseconds: 200),
                crossFadeState: _showPasswordFallback
                    ? CrossFadeState.showFirst
                    : CrossFadeState.showSecond,
                firstChild: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: true,
                          decoration: const InputDecoration(
                            labelText: 'Password',
                            hintText: 'Min 8 characters',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) =>
                              (v ?? '').length < 8 ? 'Min 8 characters' : null,
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed:
                                    _loadingPwd ? null : _emailPasswordSignIn,
                                child: _loadingPwd
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 2),
                                      )
                                    : const Text('Sign in'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _loadingPwd ? null : _forgotPassword,
                                child: const Text('Forgot password'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                secondChild: const SizedBox(height: 0),
              ),

              const SizedBox(height: 8),

              // Footer
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
