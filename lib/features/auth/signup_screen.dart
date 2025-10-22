// features/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'package:ethiomealkit/core/draft_cache.dart';
import 'dart:async';

String mondayUtcStr(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  final delta = local.weekday - DateTime.monday;
  final monLocal = local.subtract(Duration(days: delta));
  final monUtc = DateTime.utc(monLocal.year, monLocal.month, monLocal.day);
  return DateFormat('yyyy-MM-dd').format(monUtc);
}

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  StreamSubscription<AuthState>? _sub;

  @override
  void initState() {
    super.initState();
    // If already logged in, skip to draft save
    final u = Supabase.instance.client.auth.currentUser;
    if (u != null) {
      _afterLogin();
    } else {
      _sub = Supabase.instance.client.auth.onAuthStateChange.listen((event) {
        if (event.event == AuthChangeEvent.signedIn) {
          _afterLogin();
        }
      });
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _afterLogin() async {
    try {
      final result = await DraftCache.load();
      final p = result.$1;
      final r = result.$2;
      final pref = result.$3;
      if (p != null && r != null) {
        await Supabase.instance.client.rpc(
          'save_checkout_draft',
          params: {
            '_user': Supabase.instance.client.auth.currentUser!.id,
            '_week_start': mondayUtcStr(DateTime.now()),
            '_step': 3,
            '_payload': {
              'people': p,
              'recipes': r,
              'pref': pref ?? 'bit_of_everything',
              'address_hint': 'Home', // optional
            },
          },
        );
      }
      await DraftCache.setStep(3);
      if (!mounted) return;
      context.go('/recipes'); // S3 next
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _sendMagicLink() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _emailCtrl.text.trim(),
        emailRedirectTo: null, // deep link if you want
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Check your email to continue')),
      );
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('2 • Sign up')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              'Let\'s get started',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emailCtrl,
              decoration: const InputDecoration(labelText: 'Email address'),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loading ? null : _sendMagicLink,
              child: _loading
                  ? const CircularProgressIndicator()
                  : const Text('Continue to view recipes'),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(_error!, style: const TextStyle(color: Colors.red)),
              ),
            const Spacer(),
            const ListTile(
              leading: Icon(Icons.info_outline),
              title: Text('No commitment. Skip or cancel any time.'),
              subtitle: Text(
                'Easily skip any delivery week or cancel your subscription any time.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
