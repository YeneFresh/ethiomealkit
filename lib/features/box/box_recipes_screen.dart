import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'box_flow_controller.dart';

class BoxRecipesScreen extends ConsumerStatefulWidget {
  const BoxRecipesScreen({super.key});
  @override
  ConsumerState<BoxRecipesScreen> createState() => _BoxRecipesScreenState();
}

class _BoxRecipesScreenState extends ConsumerState<BoxRecipesScreen> {
  final _fmtDate = DateFormat('EEEE, d MMM');
  final _fmtTime = DateFormat('h a');

  @override
  void initState() {
    super.initState();
    // ensure data is there
    Future.microtask(
        () => ref.read(boxFlowProvider).loadRecipesAndSelections());
  }

  @override
  Widget build(BuildContext context) {
    final box = ref.watch(boxFlowProvider);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('This Week'),
        scrolledUnderElevation: 0,
      ),
      body: box.loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.only(
                  bottom: 120, left: 12, right: 12, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Delivery header (always visible)
                  _DeliveryHeader(
                    city: box.deliveryCity,
                    dateText: box.deliveryDate1 == null
                        ? 'Pick a date'
                        : _fmtDate.format(box.deliveryDate1!),
                    timeText: box.deliveryWindow1Id == null
                        ? 'Choose time'
                        : 'Window ${box.deliveryWindow1Id!.substring(0, 4)}',
                    onEdit: () => context.go('/box/delivery'),
                    onConfirm: box.hasDeliveryChoice
                        ? () => ref.read(boxFlowProvider).confirmDeliveryPref()
                        : null,
                    confirmed: box.deliveryPrefConfirmed,
                  ),
                  const SizedBox(height: 16),

                  // After confirm → show the full menu scaffolding
                  if (box.deliveryPrefConfirmed) ...[
                    _ChooseHeadline(
                      picked: box.selectedIds.length,
                      total: box.mealsPerWeek,
                      hoursLeftText: _hoursLeftText(),
                    ),
                    const SizedBox(height: 8),

                    _FilterBar(
                      sortKey: box.sortKey,
                      onSort: (k) => ref.read(boxFlowProvider).setSort(k),
                      onFilterPressed: () {
                        showModalBottomSheet(
                          context: context,
                          showDragHandle: true,
                          builder: (_) => const _FilterBottomSheet(),
                        );
                      },
                    ),
                    const SizedBox(height: 8),

                    // Chips (Rapid, Family, Veggie, Bestseller, New)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children:
                          ref.watch(boxFlowProvider).orderedChips().map((key) {
                        final selected = box.activeChips.contains(key);
                        return FilterChip(
                          label: Text(_chipLabel(key)),
                          selected: selected,
                          onSelected: (_) =>
                              ref.read(boxFlowProvider).toggleChip(key),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 12),

                    // List of recipes
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: box.filteredSorted.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) {
                        final r = box.filteredSorted[i];
                        final id =
                            (r['id']?.toString() ?? r['slug']?.toString())!;
                        final picked = box.selectedIds.contains(id);
                        return _RecipeTile(
                          recipe: r,
                          picked: picked,
                          onTap: () => ref.read(boxFlowProvider).togglePick(id),
                        );
                      },
                    ),
                  ],
                ],
              ),
            ),
      // Discount + Continue
      bottomNavigationBar: _BottomCtaBar(
        canContinue: box.selectedIds.isNotEmpty,
        picked: box.selectedIds.length,
        requiredCount: box.mealsPerWeek,
        onContinue: () async {
          if (box.selectedIds.length < box.mealsPerWeek) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Please choose ${box.mealsPerWeek} recipes.')),
            );
            return;
          }
          await ref.read(boxFlowProvider).persistSelections();
          if (context.mounted) context.go('/box/checkout');
        },
      ),
    );
  }

  String _chipLabel(String k) {
    switch (k) {
      case 'rapid':
        return 'Express';
      case 'family':
        return 'Family';
      case 'veggie':
        return 'Veggie';
      case 'bestseller':
        return 'Bestseller';
      case 'new':
        return 'New';
    }
    return k;
  }

  String _hoursLeftText() {
    // If you have real cutoff use it; for now show a reassuring window
    final hours = 6;
    return 'Avoid missing your selected delivery slot by placing an order within $hours hrs';
  }
}

// ===== UI pieces =====

class _DeliveryHeader extends StatelessWidget {
  final String city;
  final String dateText;
  final String timeText;
  final VoidCallback onEdit;
  final VoidCallback? onConfirm;
  final bool confirmed;

  const _DeliveryHeader({
    required this.city,
    required this.dateText,
    required this.timeText,
    required this.onEdit,
    required this.onConfirm,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      surfaceTintColor: cs.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: city,
              items: const [
                DropdownMenuItem(
                    value: 'Addis Ababa', child: Text('Addis Ababa')),
                DropdownMenuItem(value: 'Bole', child: Text('Bole')),
                DropdownMenuItem(
                    value: 'Old Airport', child: Text('Old Airport')),
              ],
              onChanged: (_) {},
              decoration: const InputDecoration(
                labelText: 'Deliver my box to',
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(dateText),
              subtitle: Text(timeText),
              trailing: OutlinedButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
            ),
            const SizedBox(height: 8),
            FilledButton(
              onPressed: confirmed ? null : onConfirm,
              child: Text(confirmed ? 'Confirmed' : 'Confirm to view recipes'),
            ),
            const SizedBox(height: 6),
            Text('39 recipes every week',
                style: Theme.of(context).textTheme.labelLarge),
          ],
        ),
      ),
    );
  }
}

class _ChooseHeadline extends StatelessWidget {
  final int picked;
  final int total;
  final String hoursLeftText;
  const _ChooseHeadline(
      {required this.picked, required this.total, required this.hoursLeftText});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Choose $total recipes',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(hoursLeftText, style: theme.textTheme.bodyMedium),
      ],
    );
  }
}

class _FilterBar extends StatelessWidget {
  final String sortKey;
  final ValueChanged<String> onSort;
  final VoidCallback onFilterPressed;
  const _FilterBar(
      {required this.sortKey,
      required this.onSort,
      required this.onFilterPressed});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        OutlinedButton.icon(
          onPressed: onFilterPressed,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Filter'),
        ),
        const SizedBox(width: 8),
        _SortMenu(sortKey: sortKey, onSort: onSort),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {}, // quick flag for "Express" if you want
          icon: const Icon(Icons.bolt_outlined),
          label: const Text('Express'),
        ),
        const SizedBox(width: 8),
        OutlinedButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.local_fire_department_outlined),
          label: const Text('Calorie smart'),
        ),
      ],
    );
  }
}

class _SortMenu extends StatelessWidget {
  final String sortKey;
  final ValueChanged<String> onSort;
  const _SortMenu({required this.sortKey, required this.onSort});
  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      builder: (context, controller, child) => OutlinedButton.icon(
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
        icon: const Icon(Icons.sort),
        label: const Text('Sort by'),
      ),
      menuChildren: [
        MenuItemButton(
            onPressed: () => onSort('kcal_asc'),
            child: const Text('Calories: low → high')),
        MenuItemButton(
            onPressed: () => onSort('kcal_desc'),
            child: const Text('Calories: high → low')),
        MenuItemButton(
            onPressed: () => onSort('cook_asc'),
            child: const Text('Cook time')),
      ],
    );
  }
}

class _FilterBottomSheet extends StatelessWidget {
  const _FilterBottomSheet();
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text('Filter',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        SizedBox(height: 12),
        Text('Main protein'),
        Wrap(spacing: 8, children: [
          Chip(label: Text('Beef')),
          Chip(label: Text('Chicken')),
          Chip(label: Text('Fish')),
          Chip(label: Text('Seafood')),
          Chip(label: Text('Veggie')),
        ]),
        SizedBox(height: 16),
        Text('Features'),
        Wrap(spacing: 8, children: [
          Chip(label: Text('Gourmet')),
          Chip(label: Text('Global eats')),
          Chip(label: Text('Air fryer')),
          Chip(label: Text('For the kids')),
          Chip(label: Text('Injera-based')),
        ]),
        SizedBox(height: 16),
        Text('…more coming soon'),
        SizedBox(height: 8),
      ],
    );
  }
}

class _RecipeTile extends StatelessWidget {
  final Map<String, dynamic> recipe;
  final bool picked;
  final VoidCallback onTap;

  const _RecipeTile(
      {required this.recipe, required this.picked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = recipe['name'] ?? 'Recipe';
    final subtitle = recipe['cuisine'] ?? '—';
    final img = recipe['hero_image'] ??
        'https://picsum.photos/seed/${name.hashCode}/800/600';
    final cats = List<String>.from(recipe['categories'] ?? const <String>[]);

    // map to label above image like "FISH", "MEAT", "VEGAN"
    final topLabel = _topLabelFromCats(cats);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (topLabel != null)
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                child: Text(topLabel,
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6)),
              ),
            ),
          ListTile(
            title:
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('with $subtitle'),
          ),
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(img, fit: BoxFit.cover),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                _miniBadge(cats.contains('quick_easy') ? 'Express' : '45'),
                const SizedBox(width: 12),
                _miniBadge('${recipe['kcal'] ?? 500} cals'),
                const Spacer(),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: const StadiumBorder(),
                  ),
                  onPressed: onTap,
                  child: Text(picked ? 'Unselect' : '+ ADD'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.black12),
      ),
      child: Text(text),
    );
  }

  String? _topLabelFromCats(List<String> cats) {
    if (cats.any((c) => c.contains('vegan'))) return 'VEGAN';
    if (cats.any((c) => c.contains('veggie'))) return 'VEGGIE';
    if (cats.any((c) => c.contains('fish'))) return 'FISH';
    if (cats.any((c) => c.contains('seafood'))) return 'SEAFOOD';
    if (cats.any((c) => c.contains('beef') || c.contains('meat')))
      return 'MEAT';
    return null;
  }
}

class _BottomCtaBar extends StatelessWidget {
  final bool canContinue;
  final int picked;
  final int requiredCount;
  final VoidCallback onContinue;
  const _BottomCtaBar({
    required this.canContinue,
    required this.picked,
    required this.requiredCount,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      elevation: 8,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer.withOpacity(.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('40% off on your first order',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: canContinue ? onContinue : null,
                  child: Text('Continue • $picked/$requiredCount'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
