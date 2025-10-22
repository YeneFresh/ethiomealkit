import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/providers/delivery_window_provider.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Bottom sheet modal for editing delivery window
/// Opens from the DeliveryHeaderCard "Edit" button
Future<void> showDeliveryEditModal(BuildContext context, WidgetRef ref) async {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => const DeliveryEditModal(),
  );
}

class DeliveryEditModal extends ConsumerStatefulWidget {
  const DeliveryEditModal({super.key});

  @override
  ConsumerState<DeliveryEditModal> createState() => _DeliveryEditModalState();
}

class _DeliveryEditModalState extends ConsumerState<DeliveryEditModal> {
  String _selectedLocation = 'Home';
  String? _selectedWindowId;
  List<Map<String, dynamic>> _windows = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadWindows();
  }

  Future<void> _loadWindows() async {
    try {
      final api = SupaClient(Supabase.instance.client);
      final windows = await api.availableWindows();

      setState(() {
        _windows = windows;
        _isLoading = false;

        // Pre-select current window if exists
        final current = ref.read(deliveryWindowProvider);
        if (current != null) {
          _selectedWindowId = current.id;
        } else if (windows.isNotEmpty) {
          // Pre-select recommended afternoon slot
          final recommended = windows.firstWhere(
            (w) => w['slot']?.toString().contains('14-16') == true,
            orElse: () => windows.first,
          );
          _selectedWindowId = recommended['id'];
        }
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('❌ Failed to load delivery windows: $e');
    }
  }

  Future<void> _handleConfirm() async {
    if (_selectedWindowId == null) return;

    HapticFeedback.mediumImpact();

    final selectedWindow = _windows.firstWhere(
      (w) => w['id'] == _selectedWindowId,
    );

    final window = DeliveryWindow.fromMap(selectedWindow);
    ref.read(deliveryWindowProvider.notifier).setWindow(window);

    // Save to backend if authenticated
    try {
      final api = SupaClient(Supabase.instance.client);
      await api.upsertUserActiveWindow(
        windowId: window.id,
        locationLabel: '$_selectedLocation – ${window.label}',
      );
      print('✅ Updated delivery window: ${window.label}');
    } catch (e) {
      print('ℹ️ Could not save delivery window: $e');
    }

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    'Delivery Window',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkBrown,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Flexible(
              child: _isLoading
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Location selector
                          Text(
                            'Deliver to',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _LocationChip(
                                label: 'Home',
                                isSelected: _selectedLocation == 'Home',
                                onTap: () =>
                                    setState(() => _selectedLocation = 'Home'),
                              ),
                              const SizedBox(width: 8),
                              _LocationChip(
                                label: 'Office',
                                isSelected: _selectedLocation == 'Office',
                                onTap: () => setState(
                                  () => _selectedLocation = 'Office',
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Time slots
                          Text(
                            'Select delivery time',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ..._windows.map((window) {
                            final isSelected =
                                window['id'] == _selectedWindowId;
                            final isRecommended =
                                window['slot']?.toString().contains('14-16') ==
                                true;

                            return _TimeSlotCard(
                              window: window,
                              isSelected: isSelected,
                              isRecommended: isRecommended,
                              onTap: () => setState(
                                () => _selectedWindowId = window['id'],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
            ),

            // Confirm button
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: Layout.buttonHeight,
                child: ElevatedButton(
                  onPressed: _selectedWindowId != null ? _handleConfirm : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                  ),
                  child: const Text(
                    'Confirm Delivery',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _LocationChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppColors.gold : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.darkBrown,
            ),
          ),
        ),
      ),
    );
  }
}

class _TimeSlotCard extends StatelessWidget {
  final Map<String, dynamic> window;
  final bool isSelected;
  final bool isRecommended;
  final VoidCallback onTap;

  const _TimeSlotCard({
    required this.window,
    required this.isSelected,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final slot = window['slot']?.toString() ?? '';
    final weekday = _getWeekdayName(window['weekday'] ?? 1);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.gold : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        '$weekday $slot',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkBrown,
                        ),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success600,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Available spots',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.gold : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  String _getWeekdayName(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    if (weekday < 1 || weekday > 7) return 'Mon';
    return days[weekday - 1];
  }
}
