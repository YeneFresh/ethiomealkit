import 'package:url_launcher/url_launcher.dart';

class WebviewService {
  /// For now, open external; swap to in-app webview if desired later.
  static Future<void> open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
