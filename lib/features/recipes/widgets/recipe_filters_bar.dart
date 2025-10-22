import 'dart:async';
import 'package:flutter/material.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Horizontal scrollable filter chips for recipes.
/// Supports multiple active filters with debounced updates.
class RecipeFiltersBar extends StatefulWidget {
  final Set<String> activeFilters;
  final ValueChanged<Set<String>> onFiltersChanged;
  final int resultCount;

  const RecipeFiltersBar({
    super.key,
    required this.activeFilters,
    required this.onFiltersChanged,
    this.resultCount = 0,
  });

  @override
  State<RecipeFiltersBar> createState() => _RecipeFiltersBarState();
}

class _RecipeFiltersBarState extends State<RecipeFiltersBar> {
  Timer? _debounceTimer;
  late Set<String> _localFilters;

  // Available filter options
  static const _filterOptions = [
    _FilterOption(key: 'healthy', label: 'Healthy', icon: Icons.eco),
    _FilterOption(
      key: 'spicy',
      label: 'Spicy',
      icon: Icons.local_fire_department,
    ),
    _FilterOption(
      key: 'veggie',
      label: 'Veggie',
      icon: Icons.energy_savings_leaf,
    ),
    _FilterOption(key: '30-min', label: '<30 min', icon: Icons.schedule),
    _FilterOption(key: 'ethiopian', label: 'Ethiopian', icon: Icons.flag),
    _FilterOption(key: 'beef', label: 'Beef', icon: Icons.restaurant),
    _FilterOption(key: 'chicken', label: 'Chicken', icon: Icons.egg),
    _FilterOption(key: 'fish', label: 'Fish', icon: Icons.set_meal),
    _FilterOption(key: 'new', label: 'New', icon: Icons.fiber_new),
    _FilterOption(key: 'chef_choice', label: "Chef's Pick", icon: Icons.star),
  ];

  @override
  void initState() {
    super.initState();
    _localFilters = Set.from(widget.activeFilters);
  }

  @override
  void didUpdateWidget(RecipeFiltersBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeFilters != oldWidget.activeFilters) {
      _localFilters = Set.from(widget.activeFilters);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _toggleFilter(String key) {
    setState(() {
      if (_localFilters.contains(key)) {
        _localFilters.remove(key);
      } else {
        _localFilters.add(key);
      }
    });

    // Debounce the callback to avoid rebuild storms
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 150), () {
      widget.onFiltersChanged(_localFilters);
    });
  }

  void _clearAll() {
    setState(() {
      _localFilters.clear();
    });
    _debounceTimer?.cancel();
    widget.onFiltersChanged(_localFilters);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasActiveFilters = _localFilters.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Scrollable chips with Filter/Sort buttons
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: Row(
              children: [
                // Filter button (industry standard)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () {
                    // Optional: open filter modal later
                  },
                  icon: const Icon(Icons.filter_list, size: 18),
                  label: const Text('Filter'),
                ),
                const SizedBox(width: 8),

                // Sort by button (industry standard)
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  onPressed: () {
                    // Optional: open sort modal later
                  },
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort by'),
                ),
                const SizedBox(width: 12),

                // Clear all button (if any active)
                if (hasActiveFilters) ...[
                  _ClearButton(onPressed: _clearAll),
                  const SizedBox(width: Yf.s8),
                ],

                // Filter chips
                ..._filterOptions.map((option) {
                  final isActive = _localFilters.contains(option.key);
                  return Padding(
                    padding: const EdgeInsets.only(right: Yf.s8),
                    child: _FilterChip(
                      option: option,
                      isActive: isActive,
                      onTap: () => _toggleFilter(option.key),
                    ),
                  );
                }),
              ],
            ),
          ),

          // Result count indicator
          if (hasActiveFilters)
            Padding(
              padding: const EdgeInsets.only(
                left: Yf.s16,
                right: Yf.s16,
                bottom: Yf.s8,
              ),
              child: Text(
                '${widget.resultCount} ${widget.resultCount == 1 ? 'recipe' : 'recipes'} found',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterOption {
  final String key;
  final String label;
  final IconData icon;

  const _FilterOption({
    required this.key,
    required this.label,
    required this.icon,
  });
}

class _FilterChip extends StatelessWidget {
  final _FilterOption option;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.option,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: '${option.label} filter',
      button: true,
      selected: isActive,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: Yf.borderRadius20,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44), // Accessibility
            padding: const EdgeInsets.symmetric(
              horizontal: Yf.s12,
              vertical: Yf.s8,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: Yf.borderRadius20,
              border: isActive
                  ? Border.all(color: theme.colorScheme.primary, width: 2)
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  option.icon,
                  size: 18,
                  color: isActive
                      ? theme.colorScheme.onPrimaryContainer
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: Yf.s4),
                Text(
                  option.label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isActive
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ClearButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _ClearButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: 'Clear all filters',
      button: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: Yf.borderRadius20,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(
              horizontal: Yf.s12,
              vertical: Yf.s8,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: Yf.borderRadius20,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.clear,
                  size: 18,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: Yf.s4),
                Text(
                  'Clear',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
