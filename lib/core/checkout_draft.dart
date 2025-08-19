import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutDraft {
  final String id;
  final String userId;
  final String weekStart;
  final int step;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  CheckoutDraft({
    required this.id,
    required this.userId,
    required this.weekStart,
    required this.step,
    required this.payload,
    required this.createdAt,
  });

  factory CheckoutDraft.fromMap(Map<String, dynamic> map) {
    return CheckoutDraft(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      weekStart: map['week_start'] as String,
      step: map['step'] as int,
      payload: Map<String, dynamic>.from(map['payload'] ?? {}),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}

class CheckoutDraftManager {
  static final _supa = Supabase.instance.client;

  /// Check if user has an existing checkout draft with step >= 2
  static Future<CheckoutDraft?> getExistingDraft() async {
    try {
      final user = _supa.auth.currentUser;
      if (user == null) return null;

      final result = await _supa.rpc('get_checkout_draft', params: {
        '_user': user.id,
      });

      if (result == null) return null;

      final draft = CheckoutDraft.fromMap(Map<String, dynamic>.from(result));

      // Only return if step >= 2 (user has progressed past initial setup)
      if (draft.step >= 2) {
        return draft;
      }

      return null;
    } catch (e) {
      print('Error checking for existing draft: $e');
      return null;
    }
  }

  /// Resume checkout from a specific step
  static Future<void> resumeCheckout(CheckoutDraft draft) async {
    // Navigate to the appropriate step based on draft.step
    // This will be handled by the calling widget
  }

  /// Update draft step
  static Future<void> updateDraftStep(String draftId, int step) async {
    try {
      await _supa.rpc('update_checkout_draft_step', params: {
        '_draft_id': draftId,
        '_step': step,
      });
    } catch (e) {
      print('Error updating draft step: $e');
    }
  }

  /// Delete draft when checkout is completed
  static Future<void> deleteDraft(String draftId) async {
    try {
      await _supa.rpc('delete_checkout_draft', params: {
        '_draft_id': draftId,
      });
    } catch (e) {
      print('Error deleting draft: $e');
    }
  }
}
