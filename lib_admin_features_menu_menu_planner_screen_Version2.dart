// lib/admin/features/menu/menu_planner_screen.dart
import 'package:flutter/material.dart';

class MenuPlannerScreen extends StatefulWidget {
  const MenuPlannerScreen({super.key});

  @override
  State<MenuPlannerScreen> createState() => _MenuPlannerScreenState();
}

class _MenuPlannerScreenState extends State<MenuPlannerScreen> {
  DateTime _weekStart = _mondayOf(DateTime.now());

  static DateTime _mondayOf(DateTime d) {
    final diff = d.weekday == DateTime.monday ? 0 : d.weekday - DateTime.monday;
    return DateTime(d.year, d.month, d.day).subtract(Duration(days: diff));
  }

  void _shiftWeek(int delta) {
    setState(() => _weekStart = _weekStart.add(Duration(days: 7 * delta)));
  }

  @override
  Widget build(BuildContext context) {
    final end = _weekStart.add(const Duration(days: 6));
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              IconButton(onPressed: () => _shiftWeek(-1), icon: const Icon(Icons.chevron_left)),
              Text(
                '${_weekStart.toIso8601String().substring(0, 10)} – ${end.toIso8601String().substring(0, 10)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              IconButton(onPressed: () => _shiftWeek(1), icon: const Icon(Icons.chevron_right)),
              const Spacer(),
              FilledButton(onPressed: () {/* TODO: publish */}, child: const Text('Publish')),
              const SizedBox(width: 8),
              OutlinedButton(onPressed: () {/* TODO: clone */}, child: const Text('Clone from…')),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Card(
              child: Center(
                child: Text('Weekly menu grid goes here (draft ➜ preview ➜ publish)'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}