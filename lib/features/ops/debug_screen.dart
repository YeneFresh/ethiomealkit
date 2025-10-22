import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/env.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Debug screen (only visible in debug mode)
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> {
  Map<String, bool>? _healthCheck;
  int? _pingMs;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      _runHealthCheck();
    }
  }

  Future<void> _runHealthCheck() async {
    setState(() => _loading = true);

    try {
      final api = ref.read(supaClientProvider);

      final stopwatch = Stopwatch()..start();
      final health = await api.healthCheck();
      stopwatch.stop();

      setState(() {
        _healthCheck = health;
        _pingMs = stopwatch.elapsedMilliseconds;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _healthCheck = null;
        _pingMs = null;
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('Debug screen only available in debug mode')),
      );
    }

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('🐛 Debug Info'), centerTitle: true),
      body: RefreshIndicator(
        onRefresh: _runHealthCheck,
        child: ListView(
          padding: Yf.screenPadding,
          children: [
            // Environment Info
            _buildSection(theme, 'Environment', Icons.cloud_outlined, [
              _buildInfoRow('Supabase URL', Env.supabaseUrl),
              _buildInfoRow(
                'Environment',
                Env.supabaseUrl.startsWith('http://') ? 'Local' : 'Production',
              ),
              _buildInfoRow('Use Mocks', Env.useMocks ? 'Yes' : 'No'),
              _buildInfoRow('Config Status', Env.getConfigStatus()),
            ]),

            const SizedBox(height: Yf.g24),

            // Build Info
            _buildSection(theme, 'Build Info', Icons.info_outlined, [
              _buildInfoRow('Flutter', 'Debug Mode'),
              _buildInfoRow('Platform', kIsWeb ? 'Web' : 'Native'),
              _buildInfoRow('Package', 'ethiomealkit 3.0.0'),
            ]),

            const SizedBox(height: Yf.g24),

            // Health Check
            _buildSection(theme, 'API Health', Icons.favorite_outlined, [
              if (_loading)
                const Center(child: CircularProgressIndicator())
              else if (_healthCheck != null) ...[
                _buildHealthRow(
                  'Delivery Windows',
                  _healthCheck!['delivery_windows'],
                ),
                _buildHealthRow(
                  'User Readiness',
                  _healthCheck!['user_readiness'],
                ),
                _buildHealthRow(
                  'User Selections',
                  _healthCheck!['user_selections'],
                ),
                _buildHealthRow(
                  'Weekly Recipes',
                  _healthCheck!['weekly_recipes'],
                ),
                const SizedBox(height: Yf.g16),
                _buildInfoRow('Response Time', '${_pingMs}ms'),
              ] else
                const Text('Pull to refresh'),
            ]),

            const SizedBox(height: Yf.g24),

            // Actions
            _buildSection(theme, 'Quick Actions', Icons.build_outlined, [
              ElevatedButton.icon(
                onPressed: _runHealthCheck,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Health Check'),
              ),
              const SizedBox(height: Yf.g8),
              ElevatedButton.icon(
                onPressed: () async {
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Signed out')));
                  }
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: Yf.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: Yf.g8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Yf.g16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.g8),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontFamily: 'monospace',
                color: Colors.grey[700],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthRow(String service, bool? healthy) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.g8),
      child: Row(
        children: [
          Icon(
            healthy == true ? Icons.check_circle : Icons.error,
            color: healthy == true ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: Yf.g8),
          Expanded(child: Text(service, style: const TextStyle(fontSize: 13))),
          Text(
            healthy == true ? 'OK' : 'FAIL',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: healthy == true ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}
