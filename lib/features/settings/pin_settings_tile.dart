import 'package:flutter/material.dart';
import '../../core/pin_vault.dart';
import '../../core/sentry_service.dart';

class PinSettingsTile extends StatefulWidget {
  const PinSettingsTile({super.key});

  @override
  State<PinSettingsTile> createState() => _PinSettingsTileState();
}

class _PinSettingsTileState extends State<PinSettingsTile> {
  bool _enabled = false;
  bool _busy = true;

  @override
  void initState() {
    super.initState();
    () async {
      final en = await PinVault.isEnabled();
      setState(() {
        _enabled = en;
        _busy = false;
      });
    }();
  }

  Future<void> _enable() async {
    final pin = await _askPin(context, title: 'Set a 4–6 digit PIN');
    if (pin == null) return;
    final confirm = await _askPin(context, title: 'Confirm PIN');
    if (confirm != pin) {
      _snack('PINs do not match', true);

      // Log PIN mismatch error
      SentryService.addAuthBreadcrumb(
        action: 'pin_setup_failed',
        provider: 'pin',
        route: '/settings',
        metadata: {
          'reason': 'pin_mismatch',
          'pin_length': pin.length,
        },
      );
      return;
    }
    setState(() => _busy = true);
    try {
      await PinVault.enableWithPin(pin);
      setState(() => _enabled = true);
      _snack('PIN enabled');

      // Log successful PIN setup
      SentryService.addAuthBreadcrumb(
        action: 'pin_setup_success',
        provider: 'pin',
        route: '/settings',
        metadata: {
          'pin_length': pin.length,
          'operation': 'enable',
        },
      );
    } catch (e) {
      _snack('Failed to enable PIN: $e', true);

      // Log PIN setup failure
      SentryService.trackAuthError(
        provider: 'pin',
        errorCode: 'setup_failed',
        errorMessage: 'Failed to enable PIN: $e',
        route: '/settings',
        metadata: {
          'pin_length': pin.length,
          'operation': 'enable',
          'exception_type': e.runtimeType.toString(),
        },
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _disable() async {
    setState(() => _busy = true);
    try {
      await PinVault.disable();
      setState(() => _enabled = false);
      _snack('PIN disabled');

      // Log successful PIN disable
      SentryService.addAuthBreadcrumb(
        action: 'pin_disabled',
        provider: 'pin',
        route: '/settings',
        metadata: {'operation': 'disable'},
      );
    } catch (e) {
      _snack('Failed to disable PIN: $e', true);

      // Log PIN disable failure
      SentryService.trackAuthError(
        provider: 'pin',
        errorCode: 'disable_failed',
        errorMessage: 'Failed to disable PIN: $e',
        route: '/settings',
        metadata: {
          'operation': 'disable',
          'exception_type': e.runtimeType.toString(),
        },
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  Future<void> _change() async {
    final has = await PinVault.hasPin();
    if (!has) return _enable();

    final old = await _askPin(context, title: 'Enter current PIN');
    if (old == null) return;

    final ok = await PinVault.verifyPin(old);
    if (!ok) {
      _snack('Incorrect PIN', true);

      // Log current PIN verification failure
      SentryService.addAuthBreadcrumb(
        action: 'pin_change_failed',
        provider: 'pin',
        route: '/settings',
        metadata: {
          'reason': 'incorrect_current_pin',
          'operation': 'change',
        },
      );
      return;
    }

    final pin = await _askPin(context, title: 'New PIN (4–6 digits)');
    if (pin == null) return;

    final confirm = await _askPin(context, title: 'Confirm new PIN');
    if (confirm != pin) {
      _snack('PINs do not match', true);

      // Log PIN mismatch error during change
      SentryService.addAuthBreadcrumb(
        action: 'pin_change_failed',
        provider: 'pin',
        route: '/settings',
        metadata: {
          'reason': 'new_pin_mismatch',
          'pin_length': pin.length,
          'operation': 'change',
        },
      );
      return;
    }

    setState(() => _busy = true);
    try {
      await PinVault.enableWithPin(pin);
      setState(() => _busy = false);
      _snack('PIN changed');

      // Log successful PIN change
      SentryService.addAuthBreadcrumb(
        action: 'pin_change_success',
        provider: 'pin',
        route: '/settings',
        metadata: {
          'pin_length': pin.length,
          'operation': 'change',
        },
      );
    } catch (e) {
      _snack('Failed to change PIN: $e', true);

      // Log PIN change failure
      SentryService.trackAuthError(
        provider: 'pin',
        errorCode: 'change_failed',
        errorMessage: 'Failed to change PIN: $e',
        route: '/settings',
        metadata: {
          'pin_length': pin.length,
          'operation': 'change',
          'exception_type': e.runtimeType.toString(),
        },
      );
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_busy) {
      return const ListTile(
        title: Text('App PIN'),
        subtitle: Text('Loading...'),
        trailing: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return Column(
      children: [
        SwitchListTile(
          title: const Text('Enable PIN fallback'),
          subtitle:
              const Text('Use a 4–6 digit PIN when biometrics are unavailable'),
          value: _enabled,
          onChanged: (v) => v ? _enable() : _disable(),
        ),
        ListTile(
          title: const Text('Change PIN'),
          enabled: _enabled,
          trailing: const Icon(Icons.chevron_right),
          onTap: _enabled ? _change : null,
        ),
      ],
    );
  }

  Future<String?> _askPin(BuildContext context, {required String title}) async {
    final ctrl = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(
            hintText: 'Digits only',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              final pin = ctrl.text.trim();
              if (pin.length < 4 ||
                  pin.length > 6 ||
                  int.tryParse(pin) == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Enter 4–6 digits')),
                );

                // Log PIN validation failure
                SentryService.addAuthBreadcrumb(
                  action: 'pin_validation_failed',
                  provider: 'pin',
                  route: '/settings',
                  metadata: {
                    'pin_length': pin.length,
                    'is_numeric': int.tryParse(pin) != null,
                    'reason': pin.length < 4
                        ? 'too_short'
                        : pin.length > 6
                            ? 'too_long'
                            : 'not_numeric',
                  },
                );
                return;
              }
              Navigator.pop(context, pin);
            },
            child: const Text('Continue'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg, [bool error = false]) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(msg),
          backgroundColor: error ? Colors.red.shade700 : null),
    );
  }
}
