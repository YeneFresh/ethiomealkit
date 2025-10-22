// menu_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/supabase_service.dart';
import 'menu_providers.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});
  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  bool _loading = true;
  bool applyPrefsFilter = true;
  String? _errorMessage;

  late String weekStr; // 'YYYY-MM-DD'
  Map<String, dynamic>? profile;
  List<Map<String, dynamic>> recipes = [];
  Set<String> picked = {};
  Set<String> consumed = {}; // recipe_ids user has marked consumed this week
  bool fullAccessThisWeek = false; // weekly easter-egg gate
  int get maxMeals => (profile?['meals_per_week'] as int?) ?? 3;

  // A) Add chip state
  final Map<String, String> _chipLabels = const {
    'rapid': 'Rapid Weeknight',
    'family': 'Family Favorites',
    'veggie': 'Veggie Delights',
  };
  // Active chip filters (also persisted to Supabase via RPC)
  Set<String> _activeChips =
      {'rapid', 'family', 'veggie'}.where((_) => false).toSet(); // start empty

  Map<String, num>? _pricing; // {meals_count, subtotal_etb, total_etb, ...}

  @override
  void initState() {
    super.initState();

    // Keep your existing initState logic here
    weekStr = _mondayUtcStr(DateTime.now());
    _bootstrap().then((_) => _refreshPricing());

    // Debug check in parallel
    // Debug check completely removed to avoid permission issues
  }

  String _mondayUtcStr(DateTime d) {
    final local = DateTime(d.year, d.month, d.day);
    final delta = local.weekday - DateTime.monday; // 0..6
    final monLocal = local.subtract(Duration(days: delta));
    final monUtc = DateTime.utc(monLocal.year, monLocal.month, monLocal.day);
    return DateFormat('yyyy-MM-dd').format(monUtc);
  }

  Future<void> _bootstrap() async {
    try {
      final uid = db.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in';

      // 1) week string from server (YYYY-MM-DD)
      final wk = await db.rpc('current_week_start_utc_str');
      final weekStrFromServer = wk as String;
      weekStr = weekStrFromServer; // keep your field for selections

      // 2) profile
      profile =
          await db.from('profiles').select().eq('id', uid).maybeSingle() ??
              {
                'meals_per_week': 3,
                'preferences': <String>[],
              };

      // B) Load chips from user_chip_boosts table
      await _loadChipBoosts();

      // Auto-select default chip if none are active
      if (_activeChips.isEmpty) {
        // peek at learned prefs to pick a default chip
        final uid = db.auth.currentUser!.id;
        final rows = await Supabase.instance.client
            .from('user_category_prefs')
            .select('category, weight')
            .eq('user_id', uid)
            .order('weight', ascending: false)
            .limit(10);

        final cats = {
          for (final r in rows)
            r['category'] as String: (r['weight'] as num).toDouble()
        };

        String? defaultChip;
        if ((cats['veggie'] ?? 0) > 0.8) {
          defaultChip = 'veggie';
        } else if ((cats['family'] ?? 0) > 0.8)
          defaultChip = 'family';
        else if ((cats['quick_easy'] ?? 0) > 0.8) defaultChip = 'rapid';

        if (defaultChip != null) {
          setState(() => _activeChips = {defaultChip!});
          await _setChipActive(defaultChip, true);
        }
      }

      // 3) menu via direct meals query
      final rpc = await db.from('meals').select();
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

      // 4) existing selections for this same week
      final sel = await Supabase.instance.client
          .from('user_meal_selections')
          .select('recipe_id')
          .eq('user_id', uid)
          .eq('week_start', weekStrFromServer);

      picked = sel.isEmpty
          ? <String>{}
          : sel.map<String>((e) => e['recipe_id'] as String).toSet();

      // consumed for this week
      final consumedRows = await Supabase.instance.client
          .from('user_meal_selections')
          .select('recipe_id, consumed_at')
          .eq('user_id', uid)
          .eq('week_start', weekStrFromServer);

      consumed = consumedRows
          .where((e) => e['consumed_at'] != null)
          .map<String>((e) => e['recipe_id'] as String)
          .toSet();

      // is this week already unlocked?
      final unlockedRow = await Supabase.instance.client
          .from('edu_unlocked_weeks')
          .select('user_id')
          .eq('user_id', uid)
          .eq('week_start', weekStrFromServer)
          .maybeSingle();
      fullAccessThisWeek = unlockedRow != null;

      // Debug
      print('APP USER ID => $uid');
      print(
          'WEEK => $weekStrFromServer  MENU COUNT => ${recipes.length}  PICKED => ${picked.length}');

      if (_errorMessage != null) {
        setState(() => _errorMessage = null);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Load error: $e';
          _loading = false;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _nameFromSlug(dynamic slug) {
    final s = (slug ?? '').toString().replaceAll('-', ' ');
    return s.isEmpty ? 'Recipe' : s[0].toUpperCase() + s.substring(1);
  }

  // Badge generation for recipe tiles
  List<String> _badgesFor(Map<String, dynamic> r) {
    final chips = _chipsFor(r);
    final cats = List<String>.from(r['categories'] ?? const []);
    final List<String> out = [];

    // Add chip-based badges
    if (chips.contains('rapid')) out.add('⏱️ Rapid');
    if (chips.contains('family')) out.add('👨‍👩‍👧 Family');
    if (chips.contains('veggie')) out.add('🥦 Veggie');

    // Add other category badges
    if (cats.contains('high_protein')) out.add('💪 Protein');
    if (cats.contains('calorie_smart')) out.add('🩺 Fit');

    // keep 2–3 max
    return out.take(3).toList();
  }

  IconData _chipIcon(String chip) {
    switch (chip) {
      case 'rapid':
        return Icons.flash_on; // ≤ 30 min
      case 'family':
        return Icons.family_restroom; // family category
      case 'veggie':
        return Icons.eco; // veggie category
      default:
        return Icons.label_outline;
    }
  }

  // derive chips for a recipe row
  List<String> _chipsFor(Map<String, dynamic> r) {
    final cats = List<String>.from(r['categories'] ?? const <String>[]);
    final minutes = (r['cook_minutes'] ?? 999) as int;
    final list = <String>[];
    if (minutes <= 30) list.add('rapid');
    if (cats.contains('family')) list.add('family');
    if (cats.contains('veggie')) list.add('veggie');
    return list;
  }

  // filter recipes by top chips (AND = show if matches any active chip)
  bool _passesChipFilter(Map<String, dynamic> r) {
    if (_activeChips.isEmpty) return true;
    final rc = _chipsFor(r).toSet();
    return rc.intersection(_activeChips).isNotEmpty;
  }

  Future<void> _loadChipBoosts() async {
    final uid = db.auth.currentUser!.id;
    try {
      final rows = await db.rpc('get_user_chip_boosts', params: {'_user': uid});
      _activeChips
        ..clear()
        ..addAll(List<Map<String, dynamic>>.from(rows)
            .where((m) => (m['is_active'] as bool? ?? false))
            .map((m) => m['chip'] as String));
      if (mounted) setState(() {});
    } catch (_) {/* ignore */}
  }

  Future<void> _setChipActive(String chip, bool active) async {
    final uid = db.auth.currentUser!.id;
    setState(() {
      if (active) {
        _activeChips.add(chip);
      } else {
        _activeChips.remove(chip);
      }
    });
    // persist (influences recommender weights immediately)
    try {
      await db.rpc('toggle_user_chip',
          params: {'_user': uid, '_chip': chip, '_active': active});
    } catch (e) {
      // revert on error
      setState(() {
        if (active) {
          _activeChips.remove(chip);
        } else {
          _activeChips.add(chip);
        }
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Chip save failed: $e')));
    }
  }

  Future<void> _refreshPricing() async {
    final uid = db.auth.currentUser!.id;
    try {
      final rows =
          await db.rpc('pricing_for_current_week', params: {'_user': uid});
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isNotEmpty) {
        setState(() => _pricing = Map<String, num>.from(list.first));
      }
    } catch (e) {
      // optional: surface errors
    }
  }

  Future<Map<String, dynamic>?> _fetchOrderSummary() async {
    final uid = db.auth.currentUser!.id;
    try {
      final rows =
          await db.rpc('get_order_summary_current', params: {'_user': uid});
      final list = List<Map<String, dynamic>>.from(rows);
      if (list.isNotEmpty) {
        return list.first;
      }
    } catch (e) {
      // optional: surface errors
    }
    return null;
  }

  void _showReceiptSheet(BuildContext context, Map<String, dynamic> summary) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Receipt',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Text('Order ID: ${summary['order_id'] ?? 'N/A'}'),
              Text('Status: ${summary['status'] ?? 'N/A'}'),
              Text(
                  'Total: ETB ${(summary['total_etb'] ?? 0).toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipBar() {
    final chips = const ['rapid', 'family', 'veggie'];
    final labels = {'rapid': 'Rapid', 'family': 'Family', 'veggie': 'Veggie'};
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: chips.map((c) {
          final on = _activeChips.contains(c);
          return FilterChip(
            selected: on,
            avatar: Icon(_chipIcon(c), size: 18),
            label: Text(labels[c]!),
            onSelected: (v) => _setChipActive(c, v),
          );
        }).toList(),
      ),
    );
  }

  Widget _pricingBar() {
    if (_pricing == null) return const SizedBox.shrink();
    final meals = (_pricing!['meals_count'] ?? 0).toInt();
    final subtotal = _pricing!['subtotal_etb'] ?? 0;
    final delivery = _pricing!['delivery_fee_etb'] ?? 0;
    final discount = _pricing!['discount_etb'] ?? 0;
    final total = _pricing!['total_etb'] ?? 0;

    String etb(num v) => 'ETB ${v.toStringAsFixed(2)}';

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border:
                Border(top: BorderSide(color: Theme.of(context).dividerColor))),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$meals meals • ${etb(subtotal)} subtotal',
                      style: Theme.of(context).textTheme.bodyMedium),
                  Text('Delivery ${etb(delivery)} • Discount -${etb(discount)}',
                      style: Theme.of(context).textTheme.bodySmall),
                  Text('Total ${etb(total)}',
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
            Column(
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    final uid = db.auth.currentUser!.id;
                    try {
                      final res =
                          await db.rpc('add_himbasha_to_order', params: {
                        '_user': uid,
                      });
                      if (res.error == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Himbasha added to your order!')),
                        );
                        // Refresh pricing to show updated total
                        await _refreshPricing();
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text('Error: ${res.error!.message}')),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  },
                  icon: Icon(Icons.add_circle_outline),
                  label: Text('Add Himbasha (150 ETB)'),
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    context.go(
                        '/menu'); // Navigate to meal selection instead of calling RPC directly
                  },
                  child: const Text('Place Order'),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Cancel Order'),
                  onPressed: () async {
                    final uid = db.auth.currentUser!.id;
                    try {
                      await db
                          .rpc('cancel_current_order', params: {'_user': uid});
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Order canceled & capacity released')),
                      );
                      // Refresh pricing to show updated state
                      await _refreshPricing();
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Cancel failed: $e')),
                      );
                    }
                  },
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  List<Map<String, dynamic>> get _visibleRecipes {
    var list = recipes;

    if (applyPrefsFilter) {
      final prefs =
          List<String>.from(profile?['preferences'] ?? const <String>[]);
      if (prefs.isNotEmpty) {
        list = list.where((r) {
          final cats = List<String>.from(r['categories'] ?? const <String>[]);
          return cats.any(prefs.contains);
        }).toList();
      }
    }

    if (_activeChips.isNotEmpty) {
      list = list.where(_passesChipFilter).toList();
    }

    return list.isEmpty ? recipes : list;
  }

  Future<void> _togglePick(String recipeKey) async {
    final uid = db.auth.currentUser!.id;
    final isPicked = picked.contains(recipeKey);

    if (!isPicked && picked.length >= maxMeals) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Limit reached: $maxMeals meals/week')),
      );
      return;
    }

    try {
      if (isPicked) {
        await db.from('user_meal_selections').delete().match({
          'user_id': uid,
          'week_start': weekStr,
          'recipe_id': recipeKey,
        });
        setState(() => picked.remove(recipeKey));
      } else {
        await db.from('user_meal_selections').insert({
          'user_id': uid,
          'week_start': weekStr,
          'recipe_id': recipeKey,
        });
        setState(() => picked.add(recipeKey));
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Save error: $e')));
    }
  }

  Future<void> _autoSelect() async {
    final uid = db.auth.currentUser!.id;
    try {
      final rec = await db.rpc('recommend_recipes', params: {
        '_user': uid,
        '_week': weekStr, // you already set this from the server RPC
        '_limit': maxMeals,
      });

      final rows = List<Map<String, dynamic>>.from(rec);
      final ids = rows.map<String>((e) => e['recipe_id'] as String).toList();

      if (ids.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No matches for your preferences.')),
        );
        return;
      }

      // Clear then insert new picks
      await Supabase.instance.client
          .from('user_meal_selections')
          .delete()
          .match({'user_id': uid, 'week_start': weekStr});

      await db.from('user_meal_selections').insert(ids
          .take(maxMeals)
          .map((id) => {
                'user_id': uid,
                'week_start': weekStr,
                'recipe_id': id,
              })
          .toList());

      setState(() => picked = ids.take(maxMeals).toSet());
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-selected ${picked.length} meals.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto-select failed: $e')),
      );
    }
  }

  Future<void> autoFillNextWeeks() async {
    final uid = db.auth.currentUser!.id;
    try {
      final rows =
          await db.rpc('rpc_auto_select_5_weeks', params: {'_user': uid});
      final inserted = List<Map<String, dynamic>>.from(rows);
      if (!mounted) return;

      // Refresh current week's data to show updated selections
      await _bootstrap();

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              'Auto Plan Generated! ${inserted.length} meals selected across upcoming weeks.')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Auto Plan failed: $e')),
      );
    }
  }

  Future<void> _rateRecipe(String recipeId, String name) async {
    final controller = TextEditingController();
    int stars = 5;

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Rate $name'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<int>(
              value: stars,
              items: [1, 2, 3, 4, 5]
                  .map((i) => DropdownMenuItem(value: i, child: Text('$i ★')))
                  .toList(),
              onChanged: (v) => setState(() => stars = v ?? 5),
            ),
            TextField(
              controller: controller,
              decoration:
                  const InputDecoration(labelText: 'Comment (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final uid = db.auth.currentUser!.id;
              try {
                await db.from('meal_ratings').upsert({
                  'user_id': uid,
                  'recipe_id': recipeId,
                  'rating': stars,
                  'comment': controller.text.trim().isEmpty
                      ? null
                      : controller.text.trim(),
                }, onConflict: 'user_id,recipe_id');
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Thanks for rating! +10 pts')));
                }
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Rating failed: $e')));
              }
            },
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _markConsumed(String recipeId) async {
    final uid = db.auth.currentUser!.id;
    try {
      // RPC updates consumed_at; unlocks week if all picked are consumed and shipment is shipped
      final unlocked = await db.rpc('mark_consumed_and_maybe_unlock', params: {
        '_user': uid,
        '_week':
            weekStr, // the YYYY-MM-DD you got from current_week_start_utc()
        '_recipe': recipeId,
      });

      setState(() {
        consumed.add(recipeId); // update UI state
        fullAccessThisWeek = (unlocked as bool?) == true || fullAccessThisWeek;
      });

      // tiny, non-promotional nudge
      if ((unlocked as bool?) == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Content unlocked.')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Check-in failed: $e')),
      );
    }
  }

  Future<void> _showEdu(String recipeId, String name) async {
    try {
      final rows = await Supabase.instance.client
          .from('recipe_edu_content') // <- changed table
          .select('title, body, media_url')
          .eq('recipe_id', recipeId);

      final items = List<Map<String, dynamic>>.from(rows);
      if (!context.mounted) return;

      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        builder: (_) => SafeArea(
          child: items.isEmpty
              ? const Padding(
                  padding: EdgeInsets.all(16), child: Text('No content yet.'))
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (_, i) {
                    final it = items[i];
                    return ListTile(
                      title: Text(it['title'] ?? 'Untitled'),
                      subtitle: Text('${it['body'] ?? ''}'),
                      isThreeLine: true,
                    );
                  },
                ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not load content: $e')));
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
          )),
          IconButton(
            tooltip: 'Auto-select this week',
            onPressed: _autoSelect,
            icon: const Icon(Icons.auto_mode),
          ),
          IconButton(
            tooltip: 'Auto Plan - Generate 5 weeks',
            onPressed: autoFillNextWeeks,
            icon: const Icon(Icons.calendar_month),
          ),
          Switch(
              value: applyPrefsFilter,
              onChanged: (v) => setState(() => applyPrefsFilter = v)),
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
                        onPressed: () {
                          setState(() {
                            _errorMessage = null;
                            _loading = true;
                          });
                          _bootstrap();
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    _chipBar(),
                    // Filter and Sort Bar
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 10,
                        runSpacing: 8,
                        children: [
                          // Filter button opens bottom sheet
                          OutlinedButton.icon(
                            icon: const Icon(Icons.tune),
                            label: const Text('Filter'),
                            onPressed: () => _openFilters(context),
                          ),
                          // Sort by dropdown
                          DropdownButton<String>(
                            value: ref.watch(sortByProvider),
                            items: const [
                              DropdownMenuItem(
                                  value: 'default', child: Text('Sort by')),
                              DropdownMenuItem(
                                  value: 'cal_low_high',
                                  child: Text('Calories: Low → High')),
                              DropdownMenuItem(
                                  value: 'time_low_high',
                                  child: Text('Cooking Time: Low → High')),
                              DropdownMenuItem(
                                  value: 'protein_high_low',
                                  child: Text('Protein: High → Low')),
                            ],
                            onChanged: (v) => ref
                                .read(sortByProvider.notifier)
                                .state = v ?? 'default',
                          ),
                          // Quick chips (keep your existing categories)
                          ChoiceChip(
                            label: const Text('Rapid'),
                            selected:
                                ref.watch(quickChipProvider).contains('rapid'),
                            onSelected: (_) => ref
                                .read(quickChipProvider.notifier)
                                .toggle('rapid'),
                          ),
                          ChoiceChip(
                            label: const Text('Family'),
                            selected:
                                ref.watch(quickChipProvider).contains('family'),
                            onSelected: (_) => ref
                                .read(quickChipProvider.notifier)
                                .toggle('family'),
                          ),
                          ChoiceChip(
                            label: const Text('Veggie'),
                            selected:
                                ref.watch(quickChipProvider).contains('veggie'),
                            onSelected: (_) => ref
                                .read(quickChipProvider.notifier)
                                .toggle('veggie'),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _visibleRecipes.where(_passesChipFilter).isEmpty
                          ? const Center(child: Text('No recipes match.'))
                          : ListView.builder(
                              padding: const EdgeInsets.all(12),
                              itemCount: _visibleRecipes
                                  .where(_passesChipFilter)
                                  .length,
                              itemBuilder: (_, i) {
                                final filtered = _visibleRecipes
                                    .where(_passesChipFilter)
                                    .toList();
                                final r = filtered[i];
                                final id = r['id'] as String;
                                final selected = picked.contains(id);
                                final chips = _chipsFor(r);

                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 8),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.all(12),
                                    title: Text(r['name']),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${(r['categories'] as List).join(' • ')}\n'
                                          '${r['cook_minutes']} min • ${r['kcal']} kcal',
                                        ),
                                        const SizedBox(height: 6),
                                        Wrap(
                                          spacing: 6,
                                          children: chips
                                              .map((c) => Chip(
                                                    label: Text(c == 'rapid'
                                                        ? 'Rapid'
                                                        : c == 'family'
                                                            ? 'Family'
                                                            : 'Veggie'),
                                                    avatar: Icon(_chipIcon(c),
                                                        size: 16),
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                    materialTapTargetSize:
                                                        MaterialTapTargetSize
                                                            .shrinkWrap,
                                                  ))
                                              .toList(),
                                        ),
                                      ],
                                    ),
                                    isThreeLine: true,
                                    trailing: ElevatedButton(
                                      onPressed: () => _togglePick(id),
                                      child: Text(
                                          selected ? 'Unselect' : 'Select'),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
      bottomNavigationBar: _loading ? null : _pricingBar(),
    );
  }

  void _openFilters(BuildContext ctx) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final f = ref.watch(filterStateProvider);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: .85,
      builder: (_, ctl) => Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          controller: ctl,
          children: [
            const Text('Filter by',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            const Text('Main Protein',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _tag(ref, 'fish', 'Fish'),
              _tag(ref, 'poultry', 'Poultry'),
              _tag(ref, 'meat', 'Meat'),
              _tag(ref, 'veg', 'Veg/Vegan'),
            ]),
            const SizedBox(height: 16),
            const Text('Recipe Features',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, runSpacing: 8, children: [
              _tag(ref, 'calorie_smart', 'Calorie Smart'),
              _tag(ref, 'global_eats', 'Global Eats'),
              _tag(ref, 'low_carb', 'Low Carb'),
              _tag(ref, 'family', 'Family Friendly'),
              _tag(ref, 'express', 'Express'),
              _tag(ref, 'gourmet', 'Gourmet'),
              _tag(ref, 'chefs_choice', "Chef's Choice"),
            ]),
            const SizedBox(height: 24),
            Row(
              children: [
                OutlinedButton(
                  onPressed: () =>
                      ref.read(filterStateProvider.notifier).clear(),
                  child: const Text('Clear all'),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Apply filters'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _tag(WidgetRef ref, String key, String label) {
    final sel = ref.watch(filterStateProvider).tags.contains(key);
    return FilterChip(
      selected: sel,
      label: Text(label),
      onSelected: (_) => ref.read(filterStateProvider.notifier).toggle(key),
    );
  }
}
