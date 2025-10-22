// login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ethiomealkit/core/auth_prefs.dart';
import 'package:ethiomealkit/core/auth_flow_state.dart';
import 'package:ethiomealkit/core/auth_event_logger.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  late final TabController _tab;
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _rememberMe = true;
  String? _err;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    () async {
      final saved = await AuthPrefs.loadEmail();
      final remember = await AuthPrefs.loadRememberMe();
      if (mounted && saved != null) _emailCtrl.text = saved;
      if (mounted) setState(() => _rememberMe = remember);
    }();
  }

  @override
  void dispose() {
    _tab.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendMagicLink() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _err = 'Enter your email');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      authFlowState.setEmail(email);
      await AuthPrefs.saveEmail(email, remember: _rememberMe);

      final redirect = kIsWeb
          ? '${Uri.base.origin}/auth-callback'
          : 'yenefresh://auth/callback';
      await Supabase.instance.client.auth.signInWithOtp(
        email: email,
        emailRedirectTo: redirect,
      );

      // Log success
      await AuthEventLogger.logMagicLinkSent(
        route: '/login',
        metadata: {'redirect_url': redirect, 'remember_me': _rememberMe},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Magic link sent. Check your email.')),
        );
      }
    } on AuthException catch (e) {
      final errorMessage = _getUserFriendlyMessage(
        e.message ?? 'Unknown error',
      );
      setState(() => _err = errorMessage);

      // Log error with specific details
      await AuthEventLogger.logSignInError(
        provider: 'magic_link',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/login',
        metadata: {'supabase_error': e.message, 'status_code': e.statusCode},
      );
    } catch (e) {
      setState(() => _err = 'Something went wrong. Please try again.');

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'magic_link',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/login',
        metadata: {
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Convert technical error messages to user-friendly ones
  String _getUserFriendlyMessage(String errorMessage) {
    final lowerError = errorMessage.toLowerCase();

    if (lowerError.contains('invalid email')) {
      return 'Please enter a valid email address.';
    } else if (lowerError.contains('rate limit')) {
      return 'Too many attempts. Please wait a moment and try again.';
    } else if (lowerError.contains('network')) {
      return 'Network error. Please check your connection and try again.';
    } else if (lowerError.contains('timeout')) {
      return 'Request timed out. Please try again.';
    } else if (lowerError.contains('server')) {
      return 'Server error. Please try again later.';
    } else if (lowerError.contains('email not confirmed')) {
      return 'Please check your email and confirm your account first.';
    } else if (lowerError.contains('user not found')) {
      return 'No account found with this email. Please sign up instead.';
    } else if (lowerError.contains('already registered')) {
      return 'An account with this email already exists. Please sign in instead.';
    }

    // Default fallback - keep it calm and helpful
    return 'Something went wrong. Please try again.';
  }

  Future<void> _signInWithPassword() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _err = 'Enter email and password');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      authFlowState.setEmail(email);
      await AuthPrefs.saveEmail(email, remember: _rememberMe);
      await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: pass,
      );

      // Log success
      await AuthEventLogger.logSignInSuccess(
        provider: 'password',
        route: '/login',
        metadata: {'remember_me': _rememberMe},
      );

      if (mounted) context.go('/home');
    } on AuthException catch (e) {
      final errorMessage = _getUserFriendlyMessage(
        e.message ?? 'Unknown error',
      );
      setState(() => _err = errorMessage);

      // Log error
      await AuthEventLogger.logSignInError(
        provider: 'password',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/login',
        metadata: {'supabase_error': e.message, 'status_code': e.statusCode},
      );
    } catch (e) {
      setState(() => _err = 'Something went wrong. Please try again.');

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'password',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/login',
        metadata: {
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _forgotPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _err = 'Enter your email first');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });

    try {
      final redirect = kIsWeb
          ? '${Uri.base.origin}/reset'
          : 'yenefresh://auth/reset';
      await Supabase.instance.client.auth.resetPasswordForEmail(
        email,
        redirectTo: redirect,
      );

      // Log success
      await AuthEventLogger.logPasswordReset(
        route: '/login',
        metadata: {'redirect_url': redirect},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password reset link sent. Check your email.'),
          ),
        );
      }
    } on AuthException catch (e) {
      final errorMessage = _getUserFriendlyMessage(
        e.message ?? 'Unknown error',
      );
      setState(() => _err = errorMessage);

      // Log error
      await AuthEventLogger.logSignInError(
        provider: 'password_reset',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/login',
        metadata: {'supabase_error': e.message, 'status_code': e.statusCode},
      );
    } catch (e) {
      setState(() => _err = 'Something went wrong. Please try again.');

      // Log unexpected error
      await AuthEventLogger.logSignInError(
        provider: 'password_reset',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/login',
        metadata: {
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signUpWithPassword() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    if (email.isEmpty || pass.isEmpty) {
      setState(() => _err = 'Enter email and password');
      return;
    }
    setState(() {
      _loading = true;
      _err = null;
    });
    try {
      authFlowState.setEmail(email);
      await AuthPrefs.saveEmail(email, remember: _rememberMe);

      final redirect = kIsWeb
          ? '${Uri.base.origin}/auth-callback'
          : 'yenefresh://auth/callback';
      await Supabase.instance.client.auth.signUp(
        email: email,
        password: pass,
        emailRedirectTo: redirect,
      );

      // Log success
      await AuthEventLogger.logSignUpSuccess(
        provider: 'password',
        route: '/login',
        metadata: {'redirect_url': redirect, 'remember_me': _rememberMe},
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Account created. Check email to confirm (if enabled).',
            ),
          ),
        );
      }
    } on AuthException catch (e) {
      final errorMessage = _getUserFriendlyMessage(
        e.message ?? 'Unknown error',
      );
      setState(() => _err = errorMessage);

      // Log error
      await AuthEventLogger.logSignUpError(
        provider: 'password',
        errorCode: e.statusCode?.toString() ?? 'unknown',
        errorMessage: e.message ?? 'Unknown error',
        route: '/login',
        metadata: {'supabase_error': e.message, 'status_code': e.statusCode},
      );
    } catch (e) {
      setState(() => _err = 'Something went wrong. Please try again.');

      // Log unexpected error
      await AuthEventLogger.logSignUpError(
        provider: 'password',
        errorCode: 'unexpected_error',
        errorMessage: e.toString(),
        route: '/login',
        metadata: {
          'exception_type': e.runtimeType.toString(),
          'exception_message': e.toString(),
        },
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Column(
        children: [
          TabBar(
            controller: _tab,
            tabs: const [
              Tab(text: 'Magic Link'),
              Tab(text: 'Email & Password'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tab,
              children: [
                _MagicLinkTab(
                  emailCtrl: _emailCtrl,
                  loading: _loading,
                  onSend: _sendMagicLink,
                ),
                _PasswordTab(
                  emailCtrl: _emailCtrl,
                  passCtrl: _passCtrl,
                  loading: _loading,
                  rememberMe: _rememberMe,
                  onRememberMeChanged: (value) =>
                      setState(() => _rememberMe = value),
                  onSignIn: _signInWithPassword,
                  onSignUp: _signUpWithPassword,
                  onForgotPassword: _forgotPassword,
                ),
              ],
            ),
          ),
          if (_err != null)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(_err!, style: const TextStyle(color: Colors.red)),
            ),
        ],
      ),
    );
  }
}

class _MagicLinkTab extends StatelessWidget {
  final TextEditingController emailCtrl;
  final bool loading;
  final VoidCallback onSend;
  const _MagicLinkTab({
    required this.emailCtrl,
    required this.loading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: loading ? null : onSend,
            child: const Text('Send magic link'),
          ),
        ],
      ),
    );
  }
}

class _PasswordTab extends StatefulWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool rememberMe;
  final ValueChanged<bool> onRememberMeChanged;
  final VoidCallback onSignIn;
  final VoidCallback onSignUp;
  final VoidCallback onForgotPassword;

  const _PasswordTab({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.rememberMe,
    required this.onRememberMeChanged,
    required this.onSignIn,
    required this.onSignUp,
    required this.onForgotPassword,
  });

  @override
  State<_PasswordTab> createState() => _PasswordTabState();
}

class _PasswordTabState extends State<_PasswordTab> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: widget.emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.passCtrl,
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: widget.loading ? null : widget.onSignIn,
                  child: const Text('Sign in'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: widget.loading ? null : widget.onSignUp,
                  child: const Text('Create account'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Checkbox(
                value: widget.rememberMe,
                onChanged: (v) => widget.onRememberMeChanged(v ?? true),
              ),
              const Text('Remember me'),
              const Spacer(),
              TextButton(
                onPressed: widget.loading ? null : widget.onForgotPassword,
                child: const Text('Forgot password?'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
