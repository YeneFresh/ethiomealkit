// features/box/box_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/draft_cache.dart';
import 'package:ethiomealkit/core/checkout_draft.dart';

class BoxScreen extends StatefulWidget {
  const BoxScreen({super.key});
  @override
  State<BoxScreen> createState() => _BoxScreenState();
}

class _BoxScreenState extends State<BoxScreen> {
  int people = 2;
  int recipes = 4;
  String prefSeed = 'bit_of_everything'; // 'family'|'quick'|'low_cal'
  CheckoutDraft? _existingDraft;
  bool _checkingDraft = true;

  // Simple pricing table (placeholder): ETB per serving by people/recipes
  int pricePerServing(int people, int recipes) {
    // tweak as you like—descending with bigger box
    if (people >= 3 && recipes >= 5) return 145;
    if (people >= 3) return 155;
    if (recipes >= 5) return 165;
    return 175;
  }

  int get servingsPerWeek => people * recipes;
  int get weeklyBefore => servingsPerWeek * pricePerServing(people, recipes);
  int get discount => (weeklyBefore * 0.30).round(); // 30% off first box
  int get weeklyAfter => weeklyBefore - discount;

  @override
  void initState() {
    super.initState();
    _checkExistingDraft();
  }

  Future<void> _checkExistingDraft() async {
    try {
      final draft = await CheckoutDraftManager.getExistingDraft();
      if (mounted) {
        setState(() {
          _existingDraft = draft;
          _checkingDraft = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _checkingDraft = false);
      }
    }
  }

  void _resumeCheckout(CheckoutDraft draft) {
    // Navigate to the appropriate step based on draft.step
    switch (draft.step) {
      case 2:
        context.go('/signup');
        break;
      case 3:
        context.go('/recipes');
        break;
      case 4:
        context.go('/delivery');
        break;
      case 5:
        context.go('/pay');
        break;
      default:
        context.go('/signup');
    }
  }

  void _startNewCheckout() {
    setState(() {
      _existingDraft = null;
    });
    // Clear any existing draft data
    DraftCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('1 • Box')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Resume checkout banner (if draft exists)
          if (_existingDraft != null && !_checkingDraft)
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.schedule, color: Colors.blue.shade700),
                        const SizedBox(width: 8),
                        Text(
                          'Resume checkout',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You have an incomplete order from ${_existingDraft!.weekStart}',
                      style: TextStyle(color: Colors.blue.shade700),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _resumeCheckout(_existingDraft!),
                            child: const Text('Resume'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _startNewCheckout(),
                            child: const Text('Start New'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          if (_checkingDraft)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 12),
                    Text('Checking for existing orders...'),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          Text(
            'How many people are you cooking for?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          ToggleButtons(
            isSelected: [1, 2, 3, 4].map((p) => p == people).toList(),
            onPressed: (i) => setState(() => people = i + 1),
            children: const [Text('1'), Text('2'), Text('3'), Text('4')],
          ),
          const SizedBox(height: 24),
          Text(
            'How many recipes would you like?',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Column(
            children: [3, 4, 5].map((r) {
              final selected = recipes == r;
              final pps = pricePerServing(people, r);
              final before = (people * r * (pps * 1.3))
                  .round(); // fake crossed-out
              final now = people * r * pps;
              return Card(
                child: ListTile(
                  title: Text('$r recipes'),
                  subtitle: Text('price/serving: ETB $pps'),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'ETB $before',
                        style: const TextStyle(
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                      Text(
                        'ETB $now',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  selected: selected,
                  onTap: () => setState(() => recipes = r),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(
              'You will receive $recipes recipes for $people people = $servingsPerWeek servings/week',
            ),
            subtitle: const Text('no commitment • free delivery'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.local_offer_outlined),
            title: const Text('30% off your first box'),
            subtitle: Text(
              'Weekly total after discount: ETB $weeklyAfter (was ETB $weeklyBefore)',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'What kind of recipes are you looking for? (optional)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip('bit_of_everything', 'A bit of everything'),
              _chip('family', 'Family friendly'),
              _chip('quick', 'Quick dinners'),
              _chip('low_cal', 'Low calorie'),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await DraftCache.saveBox(
                people: people,
                recipes: recipes,
                prefSeed: prefSeed,
              );
              await DraftCache.setStep(2);
              if (context.mounted) context.go('/signup');
            },
            child: const Text('Confirm selection'),
          ),
        ],
      ),
    );
  }

  Widget _chip(String key, String label) {
    final selected = prefSeed == key;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => prefSeed = key),
    );
  }
}
