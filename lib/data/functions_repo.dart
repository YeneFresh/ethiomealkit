import 'package:supabase_flutter/supabase_flutter.dart';

class FunctionsRepo {
  final SupabaseClient _client;
  FunctionsRepo(this._client);

  Future<Map<String, dynamic>> createPaymentIntent(Map<String, dynamic> payload) async {
    final res = await _client.functions.invoke('payments-intent', body: payload);
    return Map<String, dynamic>.from(res.data as Map);
  }
}


