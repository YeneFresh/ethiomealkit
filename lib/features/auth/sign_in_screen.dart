import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:io';
import '../../supabase_client.dart';
import '../../core/env.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _emailCtrl = TextEditingController();
  bool _loading = false;
  String? _message;

  String? _validateSupabaseUrl() {
    final client = SupabaseConfig.client;
    if (client == null) return 'Supabase client not initialized';
    
    final url = client.supabaseUrl;
    if (url.isEmpty) return 'Supabase URL is empty';
    if (!url.startsWith('https://')) return 'Supabase URL must start with https://';
    if (!url.contains('.supabase.co')) return 'Invalid Supabase URL format';
    if (url.contains('<your-ref>')) return 'Please replace <your-ref> with your actual Supabase project reference';
    
    return null; // URL is valid
  }

  Future<String> _testNetworkConnectivity() async {
    try {
      // Test basic internet connectivity
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        return 'Internet connection: ✅ Working';
      } else {
        return 'Internet connection: ❌ Failed';
      }
    } catch (e) {
      return 'Internet connection: ❌ Failed - ${e.toString()}';
    }
  }

  String _getDnsErrorTroubleshootingGuide(String connectivity) {
    return '''DNS Error: Cannot resolve server address

$connectivity

🔧 Troubleshooting Steps:

1. Check your .env configuration:
   ${Env.getConfigStatus()}

2. Verify your Supabase URL format:
   • Should be: https://your-project-ref.supabase.co
   • Current: ${SupabaseConfig.client?.supabaseUrl ?? "Not configured"}

3. Network checks:
   • Try accessing your Supabase URL in a web browser
   • Check if you're behind a corporate firewall/proxy
   • Try using a different network (mobile hotspot)

4. DNS troubleshooting:
   • Try flushing DNS cache (restart your device)
   • Check if DNS server is working
   • Try different DNS servers (8.8.8.8, 1.1.1.1)

5. Development environment:
   • Restart your Flutter app
   • Run 'flutter clean' then 'flutter pub get'
   • Check if other apps can access the internet

If problem persists, your Supabase project might be down or URL is incorrect.''';
  }

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
      
      final client = SupabaseConfig.client;
      if (client == null) {
        throw const AuthException('Authentication service is not available. Please check your configuration.');
      }
      
      // Validate URL before attempting connection
      final urlError = _validateSupabaseUrl();
      if (urlError != null) {
        throw AuthException('Configuration error: $urlError');
      }
      
      await client.auth.signInWithOtp(email: email, emailRedirectTo: null);
      setState(() {
        _message = 'Check your email for a magic link';
      });
    } on SocketException catch (e) {
      final connectivity = await _testNetworkConnectivity();
      setState(() {
        if (e.message.toLowerCase().contains('no such host') || 
            e.message.toLowerCase().contains('host lookup failed') ||
            e.osError?.message.toLowerCase().contains('no such host') == true) {
          _message = _getDnsErrorTroubleshootingGuide(connectivity);
        } else {
          _message = 'Network error: ${e.message}.\n\n$connectivity';
        }
      });
    } on AuthException catch (e) {
      setState(() {
        _message = e.message;
      });
    } catch (e) {
      final connectivity = await _testNetworkConnectivity();
      setState(() {
        // Check if the error message contains DNS-related issues
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('no such host') || 
            errorMsg.contains('host lookup') ||
            errorMsg.contains('dns') ||
            errorMsg.contains('name resolution')) {
          _message = _getDnsErrorTroubleshootingGuide(connectivity);
        } else {
          _message = 'Error: ${e.toString()}\n\n$connectivity';
        }
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final client = SupabaseConfig.client;
      if (client == null) {
        throw const AuthException('Supabase client not initialized. Using mock backend.');
      }

      final urlError = _validateSupabaseUrl();
      if (urlError != null) {
        throw AuthException('Configuration error: $urlError');
      }

      // Test basic connectivity to Supabase
      final connectivity = await _testNetworkConnectivity();
      
      // Try a simple request to test the connection
      await client.from('test_connection').select().limit(1);
      
      setState(() {
        _message = 'Connection test successful! ✅\n\n$connectivity\n\nSupabase is properly configured.';
      });
    } on SocketException catch (e) {
      final connectivity = await _testNetworkConnectivity();
      setState(() {
        if (e.message.toLowerCase().contains('no such host') || 
            e.message.toLowerCase().contains('host lookup failed') ||
            e.osError?.message.toLowerCase().contains('no such host') == true) {
          _message = _getDnsErrorTroubleshootingGuide(connectivity);
        } else {
          _message = 'Network error during connection test: ${e.message}.\n\n$connectivity';
        }
      });
    } catch (e) {
      final connectivity = await _testNetworkConnectivity();
      setState(() {
        final errorMsg = e.toString().toLowerCase();
        if (errorMsg.contains('no such host') || 
            errorMsg.contains('host lookup') ||
            errorMsg.contains('dns') ||
            errorMsg.contains('name resolution')) {
          _message = _getDnsErrorTroubleshootingGuide(connectivity);
        } else {
          _message = 'Connection test details:\n\n$connectivity\n\nError: ${e.toString()}';
        }
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
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : _testConnection,
              child: const Text('Test Connection'),
            ),
            if (_message != null) ...[
              const SizedBox(height: 16),
              Container(
                height: 200, // Fixed height to make scrollable
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _message!.startsWith('Check your email') || _message!.contains('✅')
                      ? Colors.green.shade50 
                      : Colors.red.shade50,
                  border: Border.all(
                    color: _message!.startsWith('Check your email') || _message!.contains('✅')
                        ? Colors.green 
                        : Colors.red,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _message!,
                    style: TextStyle(
                      color: _message!.startsWith('Check your email') || _message!.contains('✅')
                          ? Colors.green.shade800 
                          : Colors.red.shade800,
                    ),
                  ),
                ),
              ),
            ],
            const Spacer(),
            // Debug info section
            const Divider(),
            const Text(
              'Debug Info',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Configuration: ${Env.getConfigStatus()}\n'
              'Backend: ${SupabaseConfig.isConfigured ? "Supabase" : "Mock"}\n'
              '${SupabaseConfig.isConfigured ? "URL: ${SupabaseConfig.client?.supabaseUrl ?? "Not available"}" : "To use Supabase: Update .env with real credentials"}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}



