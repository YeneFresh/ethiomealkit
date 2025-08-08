import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  await dotenv.load(fileName: '.env', isOptional: true);
  final url = dotenv.env['SUPABASE_URL'];
  final key = dotenv.env['SUPABASE_ANON_KEY'];
  if (url == null || url.isEmpty || key == null || key.isEmpty) {
    stdout.writeln('Supabase env not configured; seed skipped.');
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


