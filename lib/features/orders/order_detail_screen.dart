import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

/// Order detail screen - Shows order items and delivery info
class OrderDetailScreen extends ConsumerStatefulWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  ConsumerState<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends ConsumerState<OrderDetailScreen> {
  Map<String, dynamic>? _order;
  List<Map<String, dynamic>> _items = [];
  Map<String, dynamic>? _window;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrderDetails();
  }

  Future<void> _loadOrderDetails() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final client = Supabase.instance.client;

      // Load order (with address - user's own order)
      final orderData = await client
          .from('public.orders')
          .select()
          .eq('id', widget.orderId)
          .single();

      // Load order items with recipe details
      final itemsData = await client
          .from('public.order_items')
          .select('*, recipes(*)')
          .eq('order_id', widget.orderId);

      // Load delivery window
      final windowId = orderData['window_id'];
      final windowData = await client
          .from('public.delivery_windows')
          .select()
          .eq('id', windowId)
          .maybeSingle();

      setState(() {
        _order = orderData;
        _items = List<Map<String, dynamic>>.from(itemsData);
        _window = windowData;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load order details: $e';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Order Details'), centerTitle: true),
      body: _loading
          ? _buildLoadingSkeleton()
          : _error != null
          ? _buildErrorState(theme)
          : _buildOrderDetails(theme),
    );
  }

  Widget _buildLoadingSkeleton() {
    return ListView(
      padding: Yf.screenPadding,
      children: List.generate(3, (index) {
        return Container(
          margin: const EdgeInsets.only(bottom: Yf.g16),
          height: 100,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: Yf.borderRadius16,
          ),
        );
      }),
    );
  }

  Widget _buildErrorState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: Yf.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
            const SizedBox(height: Yf.g16),
            Text('Error', style: theme.textTheme.titleLarge),
            const SizedBox(height: Yf.g8),
            Text(_error!, textAlign: TextAlign.center),
            const SizedBox(height: Yf.g24),
            ElevatedButton.icon(
              onPressed: _loadOrderDetails,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(ThemeData theme) {
    return ListView(
      padding: Yf.screenPadding,
      children: [
        // Order Summary
        _buildSection(theme, 'Order Summary', Icons.receipt_long, [
          _buildDetailRow(
            theme,
            'Order ID',
            widget.orderId.substring(0, 8).toUpperCase(),
          ),
          _buildDetailRow(theme, 'Status', _order!['status']),
          _buildDetailRow(
            theme,
            'Total Items',
            '${_order!['total_items']} recipes',
          ),
          _buildDetailRow(theme, 'Week', _order!['week_start'] ?? 'N/A'),
        ]),

        const SizedBox(height: Yf.g24),

        // Delivery Info
        if (_window != null)
          _buildSection(theme, 'Delivery Window', Icons.local_shipping, [
            _buildDetailRow(theme, 'Day', _formatWeekday(_window!['weekday'])),
            _buildDetailRow(theme, 'Time', _window!['slot']),
            _buildDetailRow(theme, 'Location', _window!['city']),
          ]),

        const SizedBox(height: Yf.g24),

        // Order Items
        _buildSection(
          theme,
          'Your Recipes (${_items.length})',
          Icons.restaurant_menu,
          _items.map((item) {
            final recipe = item['recipes'] as Map<String, dynamic>?;
            return _buildRecipeItem(theme, recipe);
          }).toList(),
        ),

        const SizedBox(height: Yf.g24),

        // Delivery Address
        if (_order!['address'] != null) _buildAddressSection(theme),
      ],
    );
  }

  Widget _buildSection(
    ThemeData theme,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Card(
      child: Padding(
        padding: Yf.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: theme.colorScheme.primary),
                const SizedBox(width: Yf.g8),
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Yf.g16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.g8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(ThemeData theme, Map<String, dynamic>? recipe) {
    if (recipe == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.g12),
      child: Row(
        children: [
          Icon(Icons.restaurant, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: Yf.g8),
          Expanded(
            child: Text(
              recipe['title'] ?? 'Recipe',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection(ThemeData theme) {
    final address = _order!['address'] as Map<String, dynamic>;

    return Card(
      child: Padding(
        padding: Yf.cardPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: Yf.g8),
                Text(
                  'Delivery Address',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: Yf.g16),
            _buildDetailRow(theme, 'Phone', address['phone'] ?? 'N/A'),
            _buildDetailRow(theme, 'Address', address['line1'] ?? 'N/A'),
            if (address['line2'] != null &&
                address['line2'].toString().isNotEmpty)
              _buildDetailRow(theme, 'Line 2', address['line2']),
            _buildDetailRow(theme, 'City', address['city'] ?? 'N/A'),
            if (address['notes'] != null &&
                address['notes'].toString().isNotEmpty)
              _buildDetailRow(theme, 'Notes', address['notes']),
          ],
        ),
      ),
    );
  }

  String _formatWeekday(int weekday) {
    const days = [
      'Sunday',
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
    ];
    return days[weekday];
  }
}
