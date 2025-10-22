import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'env.dart';

/// YeneFresh Feedback System
/// Prefilled email for user feedback with context
class Feedback {
  /// Build feedback email body with context
  static String buildFeedbackBody({
    required String screen,
    String? lastErrorCode,
    Map<String, dynamic>? context,
  }) {
    final lines = [
      'Feedback for YeneFresh',
      '',
      'Screen: $screen',
      if (lastErrorCode != null) 'Last error: $lastErrorCode',
      if (context != null)
        ...context.entries.map((e) => '${e.key}: ${e.value}'),
      'UTC: ${DateTime.now().toUtc().toIso8601String()}',
      '---',
      'Device: ${defaultTargetPlatform.name}',
      'App: ${Env.appVersion} (${Env.buildNumber})',
      '',
      '---',
      'Please describe your issue or suggestion:',
      '',
    ];
    return lines.join('\n');
  }

  /// Launch email client with prefilled feedback
  static Future<void> sendFeedback({
    required String screen,
    String? lastErrorCode,
    Map<String, dynamic>? context,
  }) async {
    final body = buildFeedbackBody(
      screen: screen,
      lastErrorCode: lastErrorCode,
      context: context,
    );

    final uri = Uri.parse(
      'mailto:feedback@yenefresh.co'
      '?subject=${Uri.encodeComponent('YeneFresh Beta Feedback')}'
      '&body=${Uri.encodeComponent(body)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (kDebugMode) {
        print('Could not launch email client. Mailto: ${uri.toString()}');
      }
    }
  }

  /// Show feedback dialog (alternative to email)
  /// For use with Typeform/Google Form if preferred
  static Future<void> sendFeedbackForm({
    required String formUrl,
  }) async {
    final uri = Uri.parse(formUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (kDebugMode) {
        print('Could not launch feedback form: $formUrl');
      }
    }
  }
}




