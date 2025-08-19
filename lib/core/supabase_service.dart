// lib/core/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

/// Centralized Supabase client service
/// Provides a clean 'db' reference for database operations
class SupabaseService {
  static SupabaseClient get db => Supabase.instance.client;

  /// Get the current authenticated user
  static User? get currentUser => db.auth.currentUser;

  /// Get the current session
  static Session? get currentSession => db.auth.currentSession;

  /// Check if user is authenticated
  static bool get isAuthenticated => currentSession != null;

  /// Get user ID (throws if not authenticated)
  static String get userId =>
      currentUser?.id ?? (throw Exception('User not authenticated'));
}

/// Convenience alias for database operations
final db = SupabaseService.db;
