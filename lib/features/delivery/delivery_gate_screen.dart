// Simple Delivery Gate Screen - Clean and approachable for all users
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:ethiomealkit/features/onboarding/onboarding_progress_header.dart';
import 'package:ethiomealkit/core/analytics.dart';
import 'package:ethiomealkit/core/reassurance_text.dart';
import 'package:ethiomealkit/core/design_tokens.dart';

class DeliveryGateScreen extends ConsumerStatefulWidget {
  const DeliveryGateScreen({super.key});

  @override
  ConsumerState<DeliveryGateScreen> createState() => _DeliveryGateScreenState();
}

class _DeliveryGateScreenState extends ConsumerState<DeliveryGateScreen> {
  String? _selectedLocation;
  String? _selectedWindowId;
  bool _isLoading = false;
  bool _isSaving = false;
  List<Map<String, dynamic>> _windows = [];
  bool _isLoadingWindows = true;
  String? _errorMessage;

  final List<String> _locations = [
    'Home - Addis Ababa',
    'Office - Addis Ababa',
  ];

  @override
  void initState() {
    super.initState();
    // Auto-select "Home" as default
    _selectedLocation = 'Home - Addis Ababa';
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      print('🔄 Loading delivery windows...');
      final api = SupaClient(Supabase.instance.client);

      // Load delivery windows (works for both authenticated and unauthenticated users)
      final windows = await api.availableWindows();
      print('✅ Loaded ${windows.length} delivery windows');

      // Try to load user readiness (only works for authenticated users)
      Map<String, dynamic> readiness = {
        'user_id': null,
        'is_ready': false,
        'reasons': ['NO_USER_SESSION'],
        'active_city': null,
        'active_window_id': null,
        'window_start': null,
        'window_end': null,
        'weekday': null,
        'slot': null,
      };

      try {
        readiness = await api.userReadiness();
        print('✅ Loaded user readiness: ${readiness['is_ready']}');
      } catch (e) {
        // User not authenticated, use default values
        print('ℹ️ User not authenticated, using default readiness state: $e');
      }

      setState(() {
        _windows = windows;
        _isLoadingWindows = false;
        _isLoading = false;
      });

      // Pre-select if user already has a delivery setup
      if (readiness['is_ready'] == true) {
        _selectedLocation = readiness['active_city'];
        _selectedWindowId = readiness['active_window_id'];
      }
    } catch (e) {
      print('❌ Error loading delivery data: $e');
      if (mounted) {
        setState(() {
          _isLoadingWindows = false;
          _isLoading = false;
          _errorMessage = 'Failed to load delivery information: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return _buildLoadingScreen(theme);
    }

    if (_errorMessage != null) {
      return _buildErrorScreen(theme);
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: _buildDeliverySetup(),
    );
  }

  Widget _buildLoadingScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 24),
            Text('Loading...', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen(ThemeData theme) {
    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceContainer,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Yf.error600),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadInitialData,
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDeliverySetup() {
    return Column(
      children: [
        // Progress Header
        const OnboardingProgressHeader(currentStep: 2),

        // Content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(Yf.s24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Simple Header
                _buildSimpleHeader(),
                const SizedBox(height: Yf.s32),

                // Location Selection
                _buildLocationSection(),
                const SizedBox(height: Yf.s24),

                // Time Selection
                _buildTimeSection(),
                const SizedBox(height: Yf.s32),

                // Continue Button
                _buildUnlockButton(),

                const SizedBox(height: Yf.s16),

                // Reassurance text
                const ReassuranceText(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimpleHeader() {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(Yf.s32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Yf.peach100, Yf.peach50],
        ),
        borderRadius: Yf.borderRadius20,
        boxShadow: Yf.e2,
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(Yf.s16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.restaurant,
              size: 40,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: Yf.s20),
          Text(
            'Set up your delivery',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Yf.s12),
          Text(
            'Choose when and where to receive your meals',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Yf.s8),
            Text(
              'Delivery Location',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Yf.s20),
        ..._locations.map((location) => _buildLocationCard(location)),
      ],
    );
  }

  Widget _buildLocationCard(String location) {
    final isSelected = _selectedLocation == location;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.s16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: Yf.borderRadius16,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? Yf.brownShadow : Yf.e1,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Yf.s20,
            vertical: Yf.s8,
          ),
          leading: Container(
            padding: const EdgeInsets.all(Yf.s8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.location_on,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Text(
            location,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: theme.colorScheme.onSurface,
            ),
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(Yf.s4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                )
              : null,
          onTap: () => setState(() => _selectedLocation = location),
        ),
      ),
    );
  }

  Widget _buildTimeSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_outlined,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: Yf.s8),
            Text(
              'Delivery Time',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: Yf.s20),
        if (_isLoadingWindows)
          const Center(child: CircularProgressIndicator())
        else
          ..._windows.map((window) => _buildTimeCard(window)),
      ],
    );
  }

  Widget _buildTimeCard(Map<String, dynamic> window) {
    final isSelected = _selectedWindowId == window['id'];
    final theme = Theme.of(context);
    final startAt = DateTime.parse(window['start_at']);
    final endAt = DateTime.parse(window['end_at']);
    final isRecommended = window['slot'] == '14-16' && startAt.weekday == 6;

    return Padding(
      padding: const EdgeInsets.only(bottom: Yf.s16),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surface,
          borderRadius: Yf.borderRadius16,
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.outline.withValues(alpha: 0.5),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected ? Yf.brownShadow : Yf.e1,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: Yf.s20,
            vertical: Yf.s12,
          ),
          leading: Container(
            padding: const EdgeInsets.all(Yf.s8),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.2)
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.access_time,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Row(
            children: [
              Text(
                _formatWeekday(window['weekday']),
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (isRecommended) ...[
                const SizedBox(width: Yf.s8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: Yf.s8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Yf.success600.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Popular',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Yf.success600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Text(
            '${_formatTime(startAt)} - ${_formatTime(endAt)}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: isSelected
              ? Container(
                  padding: const EdgeInsets.all(Yf.s4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check,
                    color: theme.colorScheme.onPrimary,
                    size: 16,
                  ),
                )
              : null,
          onTap: () => setState(() => _selectedWindowId = window['id']),
        ),
      ),
    );
  }

  Widget _buildUnlockButton() {
    final canContinue = _selectedLocation != null && _selectedWindowId != null;
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton(
        onPressed: canContinue && !_isSaving ? _handleUnlock : null,
        style: FilledButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          disabledBackgroundColor: theme.colorScheme.surfaceContainerHighest,
          disabledForegroundColor: theme.colorScheme.onSurfaceVariant,
          shape: RoundedRectangleBorder(borderRadius: Yf.borderRadius16),
          elevation: canContinue ? 2 : 0,
        ),
        child: _isSaving
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    theme.colorScheme.onPrimary,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.restaurant_menu, size: 20),
                  const SizedBox(width: Yf.s8),
                  Text(
                    'View Recipes',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onPrimary,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  String _formatWeekday(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final adjustedWeekday = weekday - 1;
    return days[adjustedWeekday];
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _handleUnlock() async {
    if (_selectedLocation == null || _selectedWindowId == null || _isSaving) {
      return;
    }

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    // Track analytics
    Analytics.gateOpened(location: _selectedLocation);

    setState(() {
      _isSaving = true;
    });

    try {
      // Save delivery preferences
      final api = SupaClient(Supabase.instance.client);
      try {
        await api.upsertUserActiveWindow(
          windowId: _selectedWindowId!,
          locationLabel: _selectedLocation!,
        );

        // Track window confirmation
        final selectedWindow = _windows.firstWhere(
          (w) => w['id'] == _selectedWindowId,
          orElse: () => <String, dynamic>{},
        );
        Analytics.windowConfirmed(
          windowId: _selectedWindowId!,
          location: _selectedLocation!,
          slot: selectedWindow['slot'] ?? 'unknown',
        );
      } catch (_) {
        // User might not be authenticated, continue anyway
      }

      if (mounted) {
        setState(() {
          _isSaving = false;
        });

        // Navigate to full recipes screen with all enhancements
        // Add query param to bypass readiness check since we just set it up
        context.go('/meals?from=delivery');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Yf.error600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
