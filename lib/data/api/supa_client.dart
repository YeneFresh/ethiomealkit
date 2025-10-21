// SupaClient - Typed API Client
// Contract rule: All methods return typed Maps/Lists with exact field names as defined in SQL

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupaClient {
  final SupabaseClient _client;

  SupaClient(this._client);

  // 1. Available Windows
  Future<List<Map<String, dynamic>>> availableWindows() async {
    try {
      print('🔍 Querying delivery_windows table...');
      final response = await _client
          .from('delivery_windows')
          .select()
          .eq('is_active', true)
          .order('start_at');

      print('📊 Raw response: $response');
      final result = List<Map<String, dynamic>>.from(response);
      print('✅ Parsed ${result.length} delivery windows');
      return result;
    } catch (e) {
      print('❌ Error in availableWindows: $e');
      throw SupaClientException('Failed to fetch delivery windows: $e');
    }
  }

  // 2. User Readiness
  Future<Map<String, dynamic>> userReadiness() async {
    try {
      // Check if user has an active window
      final response = await _client.from('user_active_window').select('''
            user_id,
            window_id,
            location_label,
            delivery_windows!inner(
              start_at,
              end_at,
              weekday,
              slot,
              city
            )
          ''').limit(1).maybeSingle();

      if (response == null) {
        return {
          'user_id': null,
          'is_ready': false,
          'reasons': ['NO_ACTIVE_WINDOW'],
          'active_city': null,
          'active_window_id': null,
          'window_start': null,
          'window_end': null,
          'weekday': null,
          'slot': null,
        };
      }

      final window = response['delivery_windows'] as Map<String, dynamic>;
      return {
        'user_id': response['user_id'],
        'is_ready': true,
        'reasons': <String>[],
        'active_city': response['location_label'],
        'active_window_id': response['window_id'],
        'window_start': window['start_at'],
        'window_end': window['end_at'],
        'weekday': window['weekday'],
        'slot': window['slot'],
      };
    } catch (e) {
      // Return default not-ready state
      return {
        'user_id': null,
        'is_ready': false,
        'reasons': ['NO_USER_SESSION'],
        'active_city': null,
        'active_window_id': null,
        'window_start': null,
        'window_end': null,
        'weekday': null,
        'slot': null,
      };
    }
  }

  // 3. User Selections
  Future<List<Map<String, dynamic>>> userSelections() async {
    try {
      final response = await _client.rpc('app.user_selections');
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      throw SupaClientException('Failed to fetch user selections: $e');
    }
  }

  // 4. Current Weekly Recipes (Direct table query - no view dependencies)
  Future<List<Map<String, dynamic>>> currentWeeklyRecipes({
    int? limit,
    int? offset,
  }) async {
    try {
      // Query recipes directly from public.recipes table with join to weeks
      // This bypasses all view and readiness gate issues
      var query = _client
          .from('recipes')
          .select(
              'id, title, slug, image_url, tags, sort_order, weeks!inner(week_start, is_current)')
          .eq('is_active', true)
          .eq('weeks.is_current', true)
          .order('sort_order');

      if (limit != null) {
        query = query.limit(limit);
      }
      if (offset != null) {
        query = query.range(offset, offset + (limit ?? 15) - 1);
      }

      final response = await query;

      // Flatten the nested weeks data
      return List<Map<String, dynamic>>.from(response.map((item) {
        return {
          'id': item['id'],
          'title': item['title'],
          'slug': item['slug'],
          'image_url': item['image_url'],
          'tags': item['tags'],
          'sort_order': item['sort_order'],
          'week_start': item['weeks']['week_start'],
        };
      }));
    } catch (e) {
      throw SupaClientException('Failed to fetch weekly recipes: $e');
    }
  }

  // 5. Upsert User Active Window
  Future<void> upsertUserActiveWindow({
    required String windowId,
    required String locationLabel,
  }) async {
    try {
      // Use the delivery preference RPC that is already wired for onboarding
      final currentUser = _client.auth.currentUser;
      if (currentUser == null) {
        throw SupaClientException('No user session');
      }
      final addressId =
          locationLabel.toLowerCase().contains('office') ? 'office' : 'home';
      await _client.rpc(
        'upsert_user_delivery_preference',
        params: {
          'p_user_id': currentUser.id,
          'p_window_id': windowId,
          'p_address_id': addressId,
        },
      );
    } catch (e) {
      throw SupaClientException('Failed to set active window: $e');
    }
  }

  // 6. Set Onboarding Plan
  Future<void> setOnboardingPlan({
    required int boxSize,
    required int mealsPerWeek,
  }) async {
    try {
      await _client.rpc(
        'app.set_onboarding_plan',
        params: {'box_size': boxSize, 'meals_per_week': mealsPerWeek},
      );
    } catch (e) {
      throw SupaClientException('Failed to set onboarding plan: $e');
    }
  }

  // 7. Toggle Recipe Selection
  Future<Map<String, dynamic>> toggleRecipeSelection({
    required String recipeId,
    required bool select,
  }) async {
    try {
      final response = await _client.rpc(
        'app.toggle_recipe_selection',
        params: {'recipe_id': recipeId, 'select': select},
      );
      return Map<String, dynamic>.from(response);
    } catch (e) {
      throw SupaClientException('Failed to toggle recipe selection: $e');
    }
  }

  // 8. Get User Onboarding State
  Future<Map<String, dynamic>?> getUserOnboardingState() async {
    try {
      final response = await _client
          .from('public.user_onboarding_state')
          .select()
          .limit(1)
          .maybeSingle();

      return response != null ? Map<String, dynamic>.from(response) : null;
    } catch (e) {
      return null;
    }
  }

  // 9. Confirm Scheduled Order
  Future<(String orderId, int totalItems)> confirmScheduledOrder({
    required Map<String, dynamic> address,
  }) async {
    try {
      final response = await _client.rpc(
        'app.confirm_scheduled_order',
        params: {'p_address': address},
      );

      // RPC returns single row as map
      final orderId = response['order_id'] as String;
      final totalItems = response['total_items'] as int;

      return (orderId, totalItems);
    } catch (e) {
      throw SupaClientException('Failed to confirm order: $e');
    }
  }

  // 10. Health Check
  Future<Map<String, bool>> healthCheck() async {
    final results = <String, bool>{};

    try {
      await availableWindows();
      results['delivery_windows'] = true;
    } catch (e) {
      results['delivery_windows'] = false;
    }

    try {
      await userReadiness();
      results['user_readiness'] = true;
    } catch (e) {
      results['user_readiness'] = false;
    }

    try {
      await userSelections();
      results['user_selections'] = true;
    } catch (e) {
      results['user_selections'] = false;
    }

    try {
      await currentWeeklyRecipes();
      results['weekly_recipes'] = true;
    } catch (e) {
      results['weekly_recipes'] = false;
    }

    return results;
  }
}

// Custom exception
class SupaClientException implements Exception {
  final String message;
  SupaClientException(this.message);

  @override
  String toString() => 'SupaClientException: $message';
}

// Provider for dependency injection
final supaClientProvider = Provider<SupaClient>((ref) {
  final client = Supabase.instance.client;
  return SupaClient(client);
});
