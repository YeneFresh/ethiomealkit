import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DeliveryWindowScreen extends StatefulWidget {
  const DeliveryWindowScreen({super.key});
  @override
  State<DeliveryWindowScreen> createState() => _DeliveryWindowScreenState();
}

class _DeliveryWindowScreenState extends State<DeliveryWindowScreen> {
  int _weekday = DateTime.monday; // 1..7
  String _slot = 'morning'; // 'morning' | 'afternoon' | 'evening'
  bool _loading = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    try {
      final existing = await supa
          .from('delivery_windows')
          .select()
          .eq('user_id', uid)
          .eq('is_active', true)
          .maybeSingle();
      if (existing != null) {
        _weekday = existing['weekday'] as int;
        _slot = (existing['slot'] as String);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _save() async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    setState(() => _saving = true);
    try {
      await supa
          .from('delivery_windows')
          .update({'is_active': false}).eq('user_id', uid);
      await supa.from('delivery_windows').insert({
        'user_id': uid,
        'weekday': _weekday,
        'slot': _slot,
        'is_active': true,
      });
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Delivery window saved.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final slots = const ['morning', 'afternoon', 'evening'];

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Window')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<int>(
              value: _weekday,
              items: List.generate(
                  7,
                  (i) =>
                      DropdownMenuItem(value: i + 1, child: Text(dayNames[i]))),
              onChanged: (v) => setState(() => _weekday = v ?? DateTime.monday),
              decoration: const InputDecoration(labelText: 'Weekday'),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _slot,
              items: slots
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _slot = v ?? 'morning'),
              decoration: const InputDecoration(labelText: 'Slot'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? 'Saving…' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }
}
