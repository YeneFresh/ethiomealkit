// weekly_menu_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({super.key});

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> {
  bool _loading = true;
  String? _errorMessage;
  String weekStr = '';
  List<Map<String, dynamic>> recipes = [];
  Set<String> picked = {};
  Map<String, dynamic>? profile;
  int get maxMeals => (profile?['meals_per_week'] as int?) ?? 3;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in';

      // Get current week string
      final wk = await supa.rpc('current_week_start_utc');
      weekStr = wk as String;

      // Load profile
      profile =
          await supa.from('profiles').select().eq('id', uid).maybeSingle() ??
              {
                'meals_per_week': 3,
                'preferences': <String>[],
              };

      // Load weekly menu
      final rpc = await supa.rpc('get_weekly_menu_current');
      final list = List<Map<String, dynamic>>.from(rpc);
      recipes = list
          .map((m) => {
                'id': (m['recipe_id'] as String),
                'name': (m['name'] as String?) ?? 'Recipe',
                'categories':
                    List<String>.from(m['categories'] ?? const <String>[]),
                'cook_minutes': m['cook_minutes'] ?? 25,
                'kcal': m['kcal'] ?? 500,
                'hero_image': m['hero_image'] ??
                    'https://picsum.photos/seed/${(m['recipe_id'] as String).hashCode}/800/500',
              })
          .toList();

      // Load existing selections
      if (weekStr != null) {
        final sel = await supa
            .from('user_meal_selections')
            .select('recipe_id')
            .eq('user_id', uid)
            .eq('week_start', weekStr);
        picked = sel.isEmpty
            ? <String>{}
            : sel.map<String>((e) => e['recipe_id'] as String).toSet();
      }

      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Load error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<void> _togglePick(String recipeId) async {
    final supa = Supabase.instance.client;
    final uid = supa.auth.currentUser!.id;
    final isPicked = picked.contains(recipeId);

    if (!isPicked && picked.length >= maxMeals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limit reached: $maxMeals meals/week')),
      );
      return;
    }

    try {
      if (isPicked) {
        await supa.from('user_meal_selections').delete().match({
          'user_id': uid,
          'week_start': weekStr,
          'recipe_id': recipeId,
        });
        setState(() => picked.remove(recipeId));
      } else {
        await supa.from('user_meal_selections').insert({
          'user_id': uid,
          'week_start': weekStr,
          'recipe_id': recipeId,
        });
        setState(() => picked.add(recipeId));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save error: $e')),
      );
    }
  }

  Future<void> _continueToDelivery() async {
    if (picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one meal')),
      );
      return;
    }

    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser!.id;

      // Create/find pending order
      if (weekStr == null) throw 'Week string not available';
      final oid = await supa.rpc('place_order_from_selections', params: {
        '_user': uid,
        '_week': weekStr,
      });

      if (!mounted) return;

      // Navigate to delivery plan with order ID
      context.push('/delivery-plan?order=$oid');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to create order: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("This Week's Menu"),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('${picked.length}/$maxMeals'),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_errorMessage!),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _bootstrap,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: recipes.length,
                        itemBuilder: (_, i) {
                          final r = recipes[i];
                          final id = r['id'] as String;
                          final selected = picked.contains(id);
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(12),
                              title: Text(r['name']),
                              subtitle: Text(
                                '${(r['categories'] as List).join(' • ')}\n'
                                '${r['cook_minutes']} min • ${r['kcal']} kcal',
                              ),
                              isThreeLine: true,
                              trailing: ElevatedButton(
                                onPressed: () => _togglePick(id),
                                child: Text(selected ? 'Unselect' : 'Select'),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _continueToDelivery,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Continue to Delivery Planning'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
