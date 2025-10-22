// ops_dashboard_screen.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OpsDashboardScreen extends StatefulWidget {
  const OpsDashboardScreen({super.key});

  @override
  State<OpsDashboardScreen> createState() => _OpsDashboardScreenState();
}

class _OpsDashboardScreenState extends State<OpsDashboardScreen> {
  bool _loading = true;
  Map<String, dynamic>? _opsData;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadOpsData();
  }

  final supa = Supabase.instance.client;

  Future<File> downloadVatCsv({int monthOffset = 0}) async {
    final res = await supa.rpc(
      'vat_return_csv_month',
      params: {'_month_offset': monthOffset},
    );
    final csv =
        (res as String?) ?? 'invoice_number,invoice_date,base_etb,vat_etb\n';
    final dir = await getTemporaryDirectory();
    final file = File(
      '${dir.path}/vat_export_${DateTime.now().millisecondsSinceEpoch}.csv',
    );
    return file.writeAsBytes(utf8.encode(csv), flush: true);
  }

  Future<void> _loadOpsData() async {
    try {
      setState(() => _loading = true);
      final data = await loadOpsData();
      if (mounted) {
        setState(() {
          _opsData = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Load error: $e';
          _loading = false;
        });
      }
    }
  }

  Future<Map<String, dynamic>> loadOpsData() async {
    final cap = await supa.from('v_delivery_capacity').select();
    final sum = await supa.from('v_orders_summary_today').select().single();
    final kpis = await supa
        .from('v_messaging_kpis')
        .select()
        .order('day', ascending: false)
        .limit(14);
    final tasks = await supa
        .from('ops_tasks')
        .select()
        .eq('status', 'open')
        .order('created_at', ascending: false)
        .limit(50);
    final msgs = await supa
        .from('message_log')
        .select()
        .order('created_at', ascending: false)
        .limit(100);
    return {
      'capacity': cap,
      'summary': sum,
      'kpis': kpis,
      'tasks': tasks,
      'messages': msgs,
    };
  }

  // UI sketch: three cards + list
  Widget opsDashboard(Map<String, dynamic> data) {
    final cap = List<Map<String, dynamic>>.from(data['capacity']);
    final sum = Map<String, dynamic>.from(data['summary']);
    final kpis = List<Map<String, dynamic>>.from(data['kpis']);
    final tasks = List<Map<String, dynamic>>.from(data['tasks']);
    final msgs = List<Map<String, dynamic>>.from(data['messages']);

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          child: ListTile(
            title: const Text('Orders Today'),
            subtitle: Text(
              'Pending ${sum['pending']} • Confirmed ${sum['confirmed']} • Shipped ${sum['shipped']} • Canceled ${sum['canceled']}',
            ),
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(title: Text('Delivery Capacity')),
              ...cap.map(
                (w) => ListTile(
                  title: Text(w['slot'] ?? 'Window'),
                  subtitle: Text(
                    '${w['booked_count']}/${w['capacity'] ?? '∞'}'
                    '${w['is_concierge'] == true ? ' • Concierge' : ''}',
                  ),
                  trailing: Text(
                    w['utilization_pct'] == null
                        ? '—'
                        : '${w['utilization_pct']}%',
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(title: Text('Messaging (14 days)')),
              ...kpis.map(
                (r) => ListTile(
                  dense: true,
                  title: Text((r['day'] as String).substring(0, 10)),
                  subtitle: Text(
                    'out: ${r['out_total']} (sent ${r['out_sent']}, deliv ${r['out_delivered']}, fail ${r['out_failed']}) • in: ${r['inbound_total']}',
                  ),
                ),
              ),
            ],
          ),
        ),
        Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ListTile(title: Text('VAT Export')),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final file = await downloadVatCsv(
                                  monthOffset: 0,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'VAT CSV downloaded: ${file.path}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('VAT export failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Current Month'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              try {
                                final file = await downloadVatCsv(
                                  monthOffset: -1,
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'VAT CSV downloaded: ${file.path}',
                                      ),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('VAT export failed: $e'),
                                    ),
                                  );
                                }
                              }
                            },
                            icon: const Icon(Icons.download),
                            label: const Text('Last Month'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Download VAT return CSV files for accounting',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        const Text('Open Tasks', style: TextStyle(fontWeight: FontWeight.bold)),
        ...tasks.map(
          (t) => Card(
            child: ListTile(
              title: Text('${t['kind']} • ${t['status']}'),
              subtitle: Text((t['payload'] ?? {}).toString()),
              trailing: ElevatedButton(
                onPressed: () async {
                  try {
                    await supa
                        .from('ops_tasks')
                        .update({'status': 'done'})
                        .eq('id', t['id']);
                    // Refresh data after resolving task
                    await _loadOpsData();
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to resolve task: $e')),
                      );
                    }
                  }
                },
                child: const Text('Resolve'),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Recent Messages',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        ...msgs.map(
          (m) => ListTile(
            dense: true,
            title: Text('${m['channel']} • ${m['direction']} • ${m['status']}'),
            subtitle: Text(
              (m['body'] ?? '').toString(),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Operations Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOpsData,
            tooltip: 'Refresh Data',
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
                    onPressed: _loadOpsData,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _opsData != null
          ? opsDashboard(_opsData!)
          : const Center(child: Text('No data available')),
    );
  }
}
