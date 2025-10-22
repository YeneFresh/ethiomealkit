import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLockToggleTile extends StatefulWidget {
  const AppLockToggleTile({super.key});

  @override
  State<AppLockToggleTile> createState() => _AppLockToggleTileState();
}

class _AppLockToggleTileState extends State<AppLockToggleTile> {
  bool _enabled = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    () async {
      final sp = await SharedPreferences.getInstance();
      setState(() {
        _enabled = sp.getBool('biometric_lock_enabled') ?? true;
        _loading = false;
      });
    }();
  }

  Future<void> _set(bool v) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool('biometric_lock_enabled', v);
    if (mounted) setState(() => _enabled = v);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('App-Lock ${v ? 'enabled' : 'disabled'}')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const ListTile(
        title: Text('App-Lock'),
        trailing: CircularProgressIndicator(),
      );
    }
    return SwitchListTile(
      title: const Text('Require biometrics on launch / resume'),
      subtitle: const Text('Face ID / Touch ID / Android Biometrics'),
      value: _enabled,
      onChanged: _set,
    );
  }
}
