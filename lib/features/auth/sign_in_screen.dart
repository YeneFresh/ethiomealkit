import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  Future<void> _sendMagicLink() async {
    setState(() {
      _loading = true;
      _message = null;
    });
    try {
      final email = _emailCtrl.text.trim();
      if (email.isEmpty) {
        throw const AuthException('Please enter your email');
      }
      await Supabase.instance.client.auth.signInWithOtp(email: email, emailRedirectTo: null);
      setState(() {
        _message = 'Check your email for a magic link';
      });
    } on SocketException {
      setState(() {
        _message = 'No internet connection or DNS lookup failed. Please check your network.';
      });
    } on AuthException catch (e) {
      setState(() {
        _message = e.message;
      });
    } catch (e) {
      setState(() {
        _message = 'Something went wrong';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign in')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loading ? null : _sendMagicLink,
              child: _loading ? const CircularProgressIndicator() : const Text('Send magic link'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Text(_message!),
            ]
          ],
        ),
      ),
    );
  }
}



