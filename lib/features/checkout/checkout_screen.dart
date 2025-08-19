import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  bool _loading = true;
  bool _confirming = false;
  String? _errorMessage;
  String? orderId;
  Map<String, dynamic>? orderSummary;
  Map<String, dynamic>? pricing;

  @override
  void initState() {
    super.initState();
    _extractOrderId();
    _loadOrderData();
  }

  void _extractOrderId() {
    final uri = Uri.parse(GoRouterState.of(context).uri.toString());
    orderId = uri.queryParameters['order'];
  }

  Future<void> _loadOrderData() async {
    try {
      final supa = Supabase.instance.client;
      final uid = supa.auth.currentUser?.id;
      if (uid == null) throw 'Not signed in';

      if (orderId == null) throw 'Order ID not available';

      // Load order summary
      final summary =
          await supa.rpc('get_order_summary', params: {'_order': orderId});
      orderSummary = Map<String, dynamic>.from(summary);

      // Load pricing data
      final pricingData =
          await supa.rpc('pricing_for_order', params: {'_order': orderId});
      pricing = Map<String, dynamic>.from(pricingData);

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

  Future<void> _confirmOrder() async {
    if (orderId == null) return;

    setState(() => _confirming = true);

    try {
      final supa = Supabase.instance.client;

      // Confirm the scheduled order
      await supa.rpc('confirm_scheduled_order', params: {'_order': orderId});

      if (!mounted) return;

      // Show success and navigate back to home
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Order confirmed successfully!')),
      );

      context.go('/home');
    } catch (e) {
      if (mounted) {
        setState(() => _confirming = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to confirm order: $e')),
        );
      }
    }
  }

  String _formatCurrency(num amount) {
    return 'ETB ${amount.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Checkout'),
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
                        onPressed: _loadOrderData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          // Order Summary Card
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order Summary',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall,
                                  ),
                                  const SizedBox(height: 16),
                                  if (orderSummary != null) ...[
                                    Text(
                                        'Order ID: ${orderSummary!['order_id'] ?? 'N/A'}'),
                                    Text(
                                        'Status: ${orderSummary!['status'] ?? 'N/A'}'),
                                    Text(
                                        'Week: ${orderSummary!['week_start'] ?? 'N/A'}'),
                                  ],
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Pricing Card
                          if (pricing != null) ...[
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pricing Breakdown',
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall,
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Meals'),
                                        Text('${pricing!['meals_count'] ?? 0}'),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Subtotal'),
                                        Text(_formatCurrency(
                                            pricing!['subtotal_etb'] ?? 0)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Delivery Fee'),
                                        Text(_formatCurrency(
                                            pricing!['delivery_fee_etb'] ?? 0)),
                                      ],
                                    ),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text('Discount'),
                                        Text(
                                            '-${_formatCurrency(pricing!['discount_etb'] ?? 0)}'),
                                      ],
                                    ),
                                    const Divider(),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Total',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                        Text(
                                          _formatCurrency(
                                              pricing!['total_etb'] ?? 0),
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Terms and Conditions
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Terms & Conditions',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 8),
                                  const Text(
                                    'By confirming this order, you agree to our delivery terms and cancellation policy. '
                                    'Orders can be modified up to 24 hours before delivery.',
                                    style: TextStyle(
                                        fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Confirm Order Button
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: ElevatedButton(
                          onPressed: _confirming ? null : _confirmOrder,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          child: _confirming
                              ? const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: 12),
                                    Text('Confirming...'),
                                  ],
                                )
                              : const Text('Confirm Order'),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}
