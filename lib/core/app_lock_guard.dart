import 'dart:async';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ethiomealkit/features/auth/pin_unlock_dialog.dart';
import 'package:ethiomealkit/core/pin_vault.dart';

/// Wrap your MaterialApp with this to enable biometric lock on resume/cold start.
/// - Locks after [inactivity] away from foreground when enabled in prefs.
/// - Pref key: 'biometric_lock_enabled' (bool, default true)
/// - Pref key: 'biometric_lock_last_active' (int millisSinceEpoch)
class AppLockGuard extends StatefulWidget {
  final Widget child;
  final Duration inactivity;

  const AppLockGuard({
    super.key,
    required this.child,
    this.inactivity = const Duration(minutes: 5),
  });

  @override
  State<AppLockGuard> createState() => _AppLockGuardState();
}

class _AppLockGuardState extends State<AppLockGuard>
    with WidgetsBindingObserver {
  final _la = LocalAuthentication();
  bool _locked = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // On cold start, decide whether to lock immediately.
    _maybeLockOnLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Track app lifecycle to decide lock/unlock
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    unawaited(_updateLastActiveIfNeeded(state));
    if (state == AppLifecycleState.resumed) {
      _maybeLockOnResume();
    }
  }

  Future<void> _maybeLockOnLaunch() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool('biometric_lock_enabled') ?? true;
    if (!enabled) return;
    final last = sp.getInt('biometric_lock_last_active');
    final now = DateTime.now().millisecondsSinceEpoch;

    final away = (last == null)
        ? widget.inactivity +
              const Duration(seconds: 1) // force lock on first run
        : Duration(milliseconds: now - last);

    if (away >= widget.inactivity) {
      setState(() => _locked = true);
    }
  }

  Future<void> _maybeLockOnResume() async {
    final sp = await SharedPreferences.getInstance();
    final enabled = sp.getBool('biometric_lock_enabled') ?? true;
    if (!enabled) return;

    final last = sp.getInt('biometric_lock_last_active');
    final now = DateTime.now().millisecondsSinceEpoch;

    // If we don't know, lock conservatively.
    if (last == null) {
      setState(() => _locked = true);
      return;
    }
    final away = Duration(milliseconds: now - last);
    if (away >= widget.inactivity) {
      setState(() => _locked = true);
    }
  }

  Future<void> _updateLastActiveIfNeeded(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(
        'biometric_lock_last_active',
        DateTime.now().millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _authenticate() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final pinEnabled = await PinVault.isEnabled();

      final canCheck =
          await _la.canCheckBiometrics || await _la.isDeviceSupported();
      bool unlocked = false;

      if (canCheck) {
        try {
          unlocked = await _la.authenticate(
            localizedReason: 'Unlock YeneFresh',
            options: const AuthenticationOptions(
              biometricOnly: true,
              stickyAuth: true,
              useErrorDialogs: true,
            ),
          );
        } catch (_) {
          /* fall through to PIN */
        }
      }

      if (!unlocked && pinEnabled) {
        unlocked = await showPinUnlockDialog(context);
      }

      if (!unlocked && !canCheck && !pinEnabled) {
        // As a last resort (no biometrics, no PIN) — don't trap the user.
        unlocked = true;
      }

      if (unlocked) {
        final sp = await SharedPreferences.getInstance();
        await sp.setInt(
          'biometric_lock_last_active',
          DateTime.now().millisecondsSinceEpoch,
        );
        if (mounted) setState(() => _locked = false);
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked) _LockOverlay(onUnlock: _authenticate, busy: _checking),
      ],
    );
  }
}

class _LockOverlay extends StatelessWidget {
  final VoidCallback onUnlock;
  final bool busy;
  const _LockOverlay({required this.onUnlock, required this.busy});

  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme;
    final t = Theme.of(context).textTheme;
    return Material(
      color: c.surface.withValues(alpha: 0.98),
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Card(
              elevation: 2,
              margin: const EdgeInsets.all(20),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_rounded, size: 56, color: c.primary),
                    const SizedBox(height: 12),
                    Text(
                      'Locked',
                      style: t.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use Face ID / Touch ID to continue.',
                      style: t.bodyMedium?.copyWith(color: c.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: busy ? null : onUnlock,
                      icon: busy
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.fingerprint_rounded),
                      label: const Text('Unlock'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'If biometrics are unavailable, disable App-Lock in Settings.',
                      style: t.bodySmall?.copyWith(color: c.onSurfaceVariant),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
