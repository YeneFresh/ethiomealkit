import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddressFormScreen extends StatefulWidget {
  const AddressFormScreen({super.key});
  @override
  State<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _form = GlobalKey<FormState>();
  final _label = TextEditingController(text: 'Home');
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController(text: 'Addis Ababa');
  final _region = TextEditingController();
  final _notes = TextEditingController();
  bool _isDefault = true;
  bool _saving = false;

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() => _saving = true);
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;

    try {
      if (_isDefault) {
        await supa
            .from('addresses')
            .update({'is_default': false})
            .eq('user_id', uid);
      }
      await supa.from('addresses').insert({
        'user_id': uid,
        'label': _label.text.trim(),
        'line1': _line1.text.trim(),
        'line2': _line2.text.trim().isEmpty ? null : _line2.text.trim(),
        'city': _city.text.trim(),
        'region': _region.text.trim().isEmpty ? null : _region.text.trim(),
        'instructions': _notes.text.trim().isEmpty ? null : _notes.text.trim(),
        'is_default': _isDefault,
      });
      if (!mounted) return;
      Navigator.of(context).maybePop();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Address saved.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Save failed: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Delivery Address')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _form,
          child: ListView(
            children: [
              TextFormField(
                controller: _label,
                decoration: const InputDecoration(labelText: 'Label'),
              ),
              TextFormField(
                controller: _line1,
                decoration: const InputDecoration(labelText: 'Line 1'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _line2,
                decoration: const InputDecoration(
                  labelText: 'Line 2 (optional)',
                ),
              ),
              TextFormField(
                controller: _city,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _region,
                decoration: const InputDecoration(
                  labelText: 'Subcity / Region (optional)',
                ),
              ),
              TextFormField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Delivery notes (optional)',
                ),
              ),
              SwitchListTile(
                value: _isDefault,
                onChanged: (v) => setState(() => _isDefault = v),
                title: const Text('Make default'),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _saving ? null : _save,
                child: Text(_saving ? 'Saving…' : 'Save Address'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
