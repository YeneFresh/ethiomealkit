// delivery_plan_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final supa = Supabase.instance.client;

String mondayUtcStr(DateTime now) {
  final local = DateTime(now.year, now.month, now.day);
  final delta = local.weekday - DateTime.monday;
  final monLocal = local.subtract(Duration(days: delta));
  final monUtc = DateTime.utc(monLocal.year, monLocal.month, monLocal.day);
  return DateFormat('yyyy-MM-dd').format(monUtc);
}

Future<List<Map<String, dynamic>>> loadWindowsForWeek(String weekStr) async {
  final rows = await supa
      .rpc('delivery_windows_for_week', params: {'_week_start': weekStr});
  return List<Map<String, dynamic>>.from(rows);
}

Future<Map<String, dynamic>> saveDeliverySelection({
  required String userId,
  required String weekStr,
  required String windowId,
}) async {
  final res = await supa.rpc('save_delivery_selection', params: {
    '_user': userId,
    '_week_start': weekStr,
    '_window_id': windowId,
  });
  return Map<String, dynamic>.from(res as Map);
}

class DeliveryPlanScreen extends StatefulWidget {
  const DeliveryPlanScreen({super.key});

  @override
  State<DeliveryPlanScreen> createState() => _DeliveryPlanScreenState();
}

class _DeliveryPlanScreenState extends State<DeliveryPlanScreen> {
  bool _loading = true;
  String? _errorMessage;
  String? orderId;
  List<Map<String, dynamic>> weekWindows = [];
  Set<String> selectedWindows = {}; // set of selected window_ids
  int maxSelections = 2;

  @override
  void initState() {
    super.initState();
    _extractOrderId();
    _loadWeekWindows();
  }

  void _extractOrderId() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    orderId = uri.queryParameters['order'];
  }

  Future<void> _loadWeekWindows() async {
    try {
      final uid = supa.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in';

      // Get current week
      final week = await supa.rpc('current_week_start_utc');

      // Fetch delivery windows for the week with capacity info
      weekWindows = await loadWindowsForWeek(week);

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

  void _toggleWindow(String windowId) {
    setState(() {
      if (selectedWindows.contains(windowId)) {
        // Remove the window from selectedWindows
        selectedWindows.remove(windowId);
      } else if (selectedWindows.length < maxSelections) {
        // Add the window
        selectedWindows.add(windowId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Maximum $maxSelections delivery windows allowed')),
        );
      }
    });
  }

  Future<void> _saveSchedule() async {
    if (selectedWindows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select at least one delivery window')),
      );
      return;
    }

    try {
      final supa = Supabase.instance.client;

      // Convert to drops format
      final drops = selectedWindows
          .map((windowId) => {
                'window_id': windowId,
              })
          .toList();

      // Set order schedule
      await supa.rpc('set_order_schedule', params: {
        '_order': orderId,
        '_drops': drops,
      });

      if (!mounted) return;

      // Navigate to checkout
      context.push('/checkout?order=$orderId');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save schedule: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delivery Planning'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text('${selectedWindows.length}/$maxSelections'),
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
                        onPressed: _loadWeekWindows,
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
                        itemCount: weekWindows.length,
                        itemBuilder: (_, i) {
                          final window = weekWindows[i];
                          final label =
                              window['label'] as String? ?? 'Delivery Window';
                          final remaining = window['remaining'] as int? ?? 0;
                          final isVip =
                              window['is_concierge'] as bool? ?? false;
                          final windowId = window['id'] as String;
                          final isSelected = selectedWindows.contains(windowId);
                          final isDisabled = remaining == 0;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            child: ListTile(
                              title: Row(
                                children: [
                                  Expanded(child: Text(label)),
                                  if (isVip)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Text(
                                        'VIP',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Delivery Window'),
                                  if (remaining > 0)
                                    Text(
                                      '$remaining slots remaining',
                                      style: TextStyle(
                                        color: remaining < 5
                                            ? Colors.orange
                                            : Colors.green,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    )
                                  else
                                    const Text(
                                      'No slots available',
                                      style: TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (isSelected)
                                    const Icon(Icons.check_circle,
                                        color: Colors.green),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: isDisabled
                                        ? null
                                        : () => _toggleWindow(windowId),
                                    child: Text(
                                        isSelected ? 'Selected' : 'Select'),
                                  ),
                                ],
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
                          onPressed: _saveSchedule,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: const Text('Continue to Checkout'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('EEE, MMM d').format(date);
    } catch (e) {
      return dateStr;
    }
  }
}

class DeliverThenRecipes extends StatefulWidget {
  const DeliverThenRecipes({super.key});
  @override
  State<DeliverThenRecipes> createState() => _DeliverThenRecipesState();
}

class _DeliverThenRecipesState extends State<DeliverThenRecipes> {
  String? _windowId;
  String _addressHint = 'Home';
  List<Map<String, dynamic>> _wins = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final weekStr = mondayUtcStr(DateTime.now());
    final wins = await loadWindowsForWeek(weekStr);
    setState(() {
      _wins = wins;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('3 • Delivery → Recipes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('Deliver my box to',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: ['Home', 'Work', 'Pickup']
                .map((address) => ChoiceChip(
                      label: Text(address),
                      selected: _addressHint == address,
                      onSelected: (_) => setState(() => _addressHint = address),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          const Text('My first delivery is on',
              style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._wins.map((w) => RadioListTile<String>(
                value: w['id'] as String,
                groupValue: _windowId,
                onChanged: (v) => setState(() => _windowId = v),
                title: Text(w['label']),
                subtitle: Text(
                  (w['remaining'] as int) > 0
                      ? 'Spots left: ${w['remaining']}'
                      : 'Fully booked',
                ),
                secondary: (w['is_concierge'] as bool)
                    ? const Icon(Icons.star, color: Colors.amber)
                    : null,
              )),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _windowId == null
                ? null
                : () async {
                    final uid = supa.auth.currentUser!.id;
                    final weekStr = mondayUtcStr(DateTime.now());
                    final res = await saveDeliverySelection(
                      userId: uid,
                      weekStr: weekStr,
                      windowId: _windowId!,
                    );

                    // Update the checkout draft with delivery info
                    await supa.rpc('update_checkout_draft', params: {
                      '_user': uid,
                      '_step': 4,
                      '_payload': {
                        'delivery_window_id': _windowId!,
                        'address_hint': _addressHint,
                      }
                    });
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Delivery saved for ${(res['delivery_at'] as String)}.')),
                    );
                    // Expand page into recipes view (your MenuScreen) or navigate:
                    context.go('/recipes');
                  },
            child: const Text('Confirm & view recipes'),
          ),
          const SizedBox(height: 8),
          Row(
            children: const [
              Icon(Icons.check_circle, color: Colors.green, size: 18),
              SizedBox(width: 6),
              Text('Fresh Ethiopian choices every week'),
            ],
          ),
        ],
      ),
    );
  }
}
