// lib/core/deep_link_service.dart
import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class DeepLinkService {
  StreamSubscription? _sub;
  final _appLinks = AppLinks();

  Future<void> init(GoRouter router) async {
    // Web: Supabase handles via getSessionFromUrl(Uri.base) in your /auth-callback or reset route.
    if (kIsWeb) return;

    // Handle app opened from a link (cold start)
    try {
      final initial = await _appLinks.getInitialLink();
      if (initial != null) {
        await _handleUri(initial, router);
      }
    } on PlatformException {/* ignore */}

    // Handle links while app is running
    _sub = _appLinks.uriLinkStream.listen((uri) async {
      await _handleUri(uri, router);
        }, onError: (_) {});
  }

  Future<void> _handleUri(Uri uri, GoRouter router) async {
    // Handle reset password deep links
    if (uri.scheme == 'yenefresh' && uri.host == 'auth' && uri.path == '/reset') {
      // Let Supabase exchange the recovery tokens in the URL
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {/* ignore; Supabase may have already consumed it */}
      
      // Route to reset screen
      router.go('/reset');
    }
    
    // Handle auth callback deep links (if you want mobile magic links too)
    if (uri.scheme == 'yenefresh' && uri.host == 'auth' && uri.path == '/callback') {
      // Let Supabase handle the magic link session
      try {
        await Supabase.instance.client.auth.getSessionFromUrl(uri);
      } catch (_) {/* ignore */}
      
      // Router will handle redirect based on auth state
    }
  }

  void dispose() => _sub?.cancel();
}
