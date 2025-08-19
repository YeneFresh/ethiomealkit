import 'package:flutter/material.dart';
import '../../core/pin_vault.dart';
import '../../core/sentry_service.dart';

Future<bool> showPinUnlockDialog(BuildContext context) async {
  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const _PinUnlockDialog(),
      ) ??
      false;
}

class _PinUnlockDialog extends StatefulWidget {
  const _PinUnlockDialog();

  @override
  State<_PinUnlockDialog> createState() => _PinUnlockDialogState();
}

class _PinUnlockDialogState extends State<_PinUnlockDialog> {
  final _ctrl = TextEditingController();
  bool _busy = false;
  String? _err;
  int _lockRem = 0;

  @override
  void initState() {
    super.initState();
    _checkLock();
  }

  Future<void> _checkLock() async {
    final rem = await PinVault.lockRemainingSeconds();
    if (mounted) setState(() => _lockRem = rem);
  }

  Future<void> _verify() async {
    setState(() {
      _busy = true;
      _err = null;
    });
    final rem = await PinVault.lockRemainingSeconds();
    if (rem > 0) {
      setState(() {
        _busy = false;
        _err = 'Locked. Try again in ${rem}s';
      });
      return;
    }
    final pin = _ctrl.text.trim();
    final ok = await PinVault.verifyPin(pin);
    if (ok) {
      // Log successful PIN unlock
      SentryService.addAuthBreadcrumb(
        action: 'pin_unlock_success',
        provider: 'pin',
        route: '/pin-unlock-dialog',
        metadata: {'pin_length': pin.length},
      );

      if (mounted) Navigator.pop(context, true);
    } else {
      await _checkLock();

      // Log failed PIN unlock attempt
      SentryService.addAuthBreadcrumb(
        action: 'pin_unlock_failed',
        provider: 'pin',
        route: '/pin-unlock-dialog',
        metadata: {
          'pin_length': pin.length,
          'locked': _lockRem > 0,
          'lock_remaining': _lockRem,
        },
      );

      setState(() {
        _busy = false;
        _err = _lockRem > 0
            ? 'Too many attempts. Try again in ${_lockRem}s'
            : 'Incorrect PIN';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    return AlertDialog(
      title: const Text('Enter PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Use your 4–6 digit PIN to unlock.', style: t.bodyMedium),
          const SizedBox(height: 12),
          TextField(
            controller: _ctrl,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            decoration: const InputDecoration(
              labelText: 'PIN',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _busy ? null : _verify(),
          ),
          if (_err != null) ...[
            const SizedBox(height: 8),
            Text(_err!, style: TextStyle(color: Colors.red.shade700)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _verify,
          child: _busy
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Unlock'),
        ),
      ],
    );
  }
}
