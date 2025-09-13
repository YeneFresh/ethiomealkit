import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_client.dart';

final deliveryWindowsRepositoryProvider = Provider<DeliveryWindowsRepository>((ref) {
  final client = SupabaseConfig.client;
  return DeliveryWindowsRepository(client);
});

class WeekWindows {
  WeekWindows({required this.weekStart, required this.rows, required this.isFallback});
  final DateTime weekStart;
  final List<Map<String, dynamic>> rows;
  final bool isFallback;
}

class DeliveryWindowsRepository {
  DeliveryWindowsRepository(this.client);
  final SupabaseClient client;

  String _isoDate(DateTime d) => d.toIso8601String().substring(0, 10);

  DateTime _parseDate(dynamic value) {
    if (value is DateTime) return value;
    if (value is String) return DateTime.parse(value);
    throw StateError('Unexpected date value from RPC: $value');
  }

  Future<DateTime> fetchCurrentAddisWeek() async {
    final dynamic curWeekAny = await client.rpc('app.current_addis_week');
    return _parseDate(curWeekAny);
  }

  Future<WeekWindows> fetchWindowsForWeek(DateTime weekStart, {String? city}) async {
    final Map<String, dynamic> params = {
      'p_week': _isoDate(weekStart),
      if (city != null && city.isNotEmpty) 'p_city': city,
    };

    final dynamic rowsAny = await client.rpc(
      'app.delivery_windows_for_week',
      params: params,
    );

    final List<Map<String, dynamic>> rows = (rowsAny as List?)?.cast<Map<String, dynamic>>() ?? const [];
    return WeekWindows(weekStart: weekStart, rows: rows, isFallback: false);
  }

  Future<WeekWindows> fetchWindowsWithFallback({String? city}) async {
    final curWeekAny = await client.rpc('app.current_addis_week');
    final DateTime curWeek = _parseDate(curWeekAny);

    final Map<String, dynamic> paramsCurrent = {
      'p_week': _isoDate(curWeek),
      if (city != null && city.isNotEmpty) 'p_city': city,
    };

    final dynamic rowsAnyCurrent = await client.rpc(
      'app.delivery_windows_for_week',
      params: paramsCurrent,
    );

    final List<Map<String, dynamic>> rowsCurrent =
        (rowsAnyCurrent as List?)?.cast<Map<String, dynamic>>() ?? const [];

    if (rowsCurrent.isNotEmpty) {
      return WeekWindows(weekStart: curWeek, rows: rowsCurrent, isFallback: false);
    }

    final Map<String, dynamic> nextParams = {
      if (city != null && city.isNotEmpty) 'p_city': city,
    };

    final dynamic nextWeekAny = await client.rpc('app.next_available_week', params: nextParams);
    if (nextWeekAny == null) {
      return WeekWindows(weekStart: curWeek, rows: const [], isFallback: false);
    }

    final DateTime nextWeek = _parseDate(nextWeekAny);

    final Map<String, dynamic> paramsNext = {
      'p_week': _isoDate(nextWeek),
      if (city != null && city.isNotEmpty) 'p_city': city,
    };

    final dynamic rowsAnyNext = await client.rpc(
      'app.delivery_windows_for_week',
      params: paramsNext,
    );

    final List<Map<String, dynamic>> rowsNext =
        (rowsAnyNext as List?)?.cast<Map<String, dynamic>>() ?? const [];

    return WeekWindows(weekStart: nextWeek, rows: rowsNext, isFallback: true);
  }
}

