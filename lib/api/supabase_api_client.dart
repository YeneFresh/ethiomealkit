import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseApiClient {
  final SupabaseClient _client;

  SupabaseApiClient(this._client);

  SupabaseClient get client => _client;

  // Add API methods as needed
  Future<List<Map<String, dynamic>>> getWeeklyMenu(String weekStart) async {
    final response = await _client
        .from('weekly_menu_with_flags')
        .select()
        .eq('week_start', weekStart);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>?> getCurrentAddisWeek() async {
    final response = await _client.rpc('current_addis_week');
    return response as Map<String, dynamic>?;
  }

  Future<List<Map<String, dynamic>>> getRecipes() async {
    final response = await _client.from('recipes').select().order('sort_order');
    return List<Map<String, dynamic>>.from(response);
  }
}

