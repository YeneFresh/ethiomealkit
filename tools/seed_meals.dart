import 'dart:convert';
import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

// Note: This script expects SUPABASE_URL and SUPABASE_ANON_KEY to be passed via --dart-define
// Usage: dart run tools/seed_meals.dart --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>

Future<void> main() async {
  const url = String.fromEnvironment('SUPABASE_URL', defaultValue: '');
  const key = String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

  if (url.isEmpty || key.isEmpty) {
    stdout.writeln(
      'Supabase env not configured. Pass via --dart-define flags.',
    );
    stdout.writeln(
      'Usage: dart run tools/seed_meals.dart --dart-define=SUPABASE_URL=<url> --dart-define=SUPABASE_ANON_KEY=<key>',
    );
    return;
  }
  await Supabase.initialize(url: url, anonKey: key);
  final client = Supabase.instance.client;
  final file = File('tools/seed_meals.json');
  final data = jsonDecode(await file.readAsString()) as List<dynamic>;
  for (final item in data.cast<Map<String, dynamic>>()) {
    await client.from('meal_kits').upsert(item, onConflict: 'id');
  }
  stdout.writeln('Seed completed: ${data.length} meal kits upserted.');
}
