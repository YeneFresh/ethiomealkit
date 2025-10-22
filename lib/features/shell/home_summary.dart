import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';

class HomeSummary extends StatefulWidget {
  const HomeSummary({super.key});
  @override
  State<HomeSummary> createState() => _HomeSummaryState();
}

class _HomeSummaryState extends State<HomeSummary> {
  String? _addr;
  String? _window;
  int _picked = 0, _max = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    try {
      final wk = await supa.rpc('current_week_start_utc') as String;

      final prof = await supa
          .from('profiles')
          .select('meals_per_week')
          .eq('id', uid)
          .maybeSingle();
      _max = (prof?['meals_per_week'] as int?) ?? 3;

      final countSel = await supa
          .from('user_meal_selections')
          .select('id')
          .eq('user_id', uid)
          .eq('week_start', wk);
      _picked = countSel.length;

      final addr = await supa
          .from('addresses')
          .select()
          .eq('user_id', uid)
          .eq('is_default', true)
          .maybeSingle();
      _addr = addr == null
          ? null
          : '${addr['label']}: ${addr['line1']}, ${addr['city']}';

      final win = await supa
          .from('delivery_windows')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .maybeSingle();
      if (win != null) {
        const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        _window = '${names[(win['weekday'] as int) - 1]} ${win['slot']}';
      } else {
        // Fallback to locally persisted delivery window (gate-selected/autoselected)
        final saved = await PersistenceService.loadDeliveryWindow();
        if (saved != null) {
          final startAt = DateTime.tryParse(
            saved['start_at']?.toString() ?? '',
          );
          final slot = saved['slot']?.toString() ?? '';
          if (startAt != null && slot.isNotEmpty) {
            const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            _window = '${names[startAt.weekday - 1]} $slot';
          }
        }
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This week: $_picked/$_max meals selected'),
            const SizedBox(height: 8),
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => context.go('/menu'),
                  child: const Text('Choose meals'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.go('/address'),
                  child: Text(_addr == null ? 'Set address' : 'Edit address'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => context.go('/onboarding/delivery'),
                  child: Text(_window == null ? 'Set window' : 'Edit window'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (_addr != null) Text('Address: $_addr'),
            if (_window != null) Text('Delivery: $_window'),
          ],
        ),
      ),
    );
  }
}
