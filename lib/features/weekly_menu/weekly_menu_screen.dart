import 'package:flutter/material.dart';
import 'delivery_window_selector.dart';

class WeeklyMenuScreen extends StatefulWidget {
  const WeeklyMenuScreen({super.key});

  @override
  State<WeeklyMenuScreen> createState() => _WeeklyMenuScreenState();
}

class _WeeklyMenuScreenState extends State<WeeklyMenuScreen> {
  String? selectedWindowId;
  String? city;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Weekly Menu')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'City (optional)'),
              onChanged: (v) => setState(() => city = v.isEmpty ? null : v),
            ),
            const SizedBox(height: 12),
            DeliveryWindowSelector(
              city: city,
              onChanged: (v) => setState(() => selectedWindowId = v),
            ),
            const SizedBox(height: 24),
            Text('Selected window: ${selectedWindowId ?? '-'}'),
          ],
        ),
      ),
    );
  }
}

