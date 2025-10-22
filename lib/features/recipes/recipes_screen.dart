// Recipes Screen - Recipe selection with plan allowance
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:ethiomealkit/data/api/supa_client.dart';
import 'package:ethiomealkit/features/onboarding/onboarding_progress_header.dart';
import 'package:ethiomealkit/core/analytics.dart';
import 'package:ethiomealkit/core/design_tokens.dart';
import 'package:ethiomealkit/core/providers/delivery_window_provider.dart';
import 'package:ethiomealkit/features/recipes/widgets/delivery_summary_bar.dart';
import 'package:ethiomealkit/features/recipes/widgets/recipe_card.dart';
import 'package:ethiomealkit/features/recipes/widgets/recipe_list_item.dart';
import 'package:ethiomealkit/features/recipes/widgets/recipe_filters_bar.dart';
import 'package:ethiomealkit/features/recipes/nudges.dart';
import 'package:ethiomealkit/features/recipes/auto_select.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen>
    with TickerProviderStateMixin {
  List<Map<String, dynamic>> _recipes = [];
  List<Map<String, dynamic>> _selections = [];
  bool _isLoading = true;
  bool _isReady = false;
  int _selectedCount = 0;
  int _allowedCount = 0;
  bool _fromDelivery = false;
  bool _hasLoadedOnce = false;
  final List<AnimationController> _animationControllers = [];
  final List<Animation<Offset>> _slideAnimations = [];
  final List<Animation<double>> _fadeAnimations = [];

  // Delivery window state
  Map<String, dynamic>? _activeDeliveryWindow;

  // Filters + nudges
  Set<String> _activeFilters = {};
  bool _showHandpickedBanner = false;
  bool _showGuestBanner = true; // Dismissible guest notice
  Set<String> _autoSelectedIds = {}; // Track which recipes were auto-picked
  List<Map<String, dynamic>> _filteredRecipes = [];

  // Debounce for filters (performance)
  Timer? _filterDebounce;

  // Idempotency for auto-select per week
  String? _autoSelectWeekKey;

  @override
  void initState() {
    super.initState();
    // Don't load here - wait for didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_hasLoadedOnce) {
      _hasLoadedOnce = true;

      // Check if coming from delivery gate
      final uri = GoRouterState.of(context).uri;
      _fromDelivery = uri.queryParameters['from'] == 'delivery';

      print('🔍 Recipe screen - from delivery: $_fromDelivery, URI: $uri');

      _loadData();
    }
  }

  @override
  void dispose() {
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _filterDebounce?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final api = SupaClient(Supabase.instance.client);

      // Check readiness (or assume ready if coming from delivery)
      bool isReady = _fromDelivery;
      Map<String, dynamic>? readinessData;

      if (!_fromDelivery) {
        try {
          readinessData = await api.userReadiness();
          isReady = readinessData['is_ready'] == true;
          print('✅ User readiness: $isReady');
        } catch (e) {
          print('❌ Error checking readiness: $e');
          isReady = false;
        }
      } else {
        print('✅ Bypassing readiness check - coming from delivery gate');
        // Still fetch readiness to get delivery window info
        try {
          readinessData = await api.userReadiness();
        } catch (e) {
          print('ℹ️ Could not fetch readiness data: $e');
        }
      }

      if (isReady) {
        print('🔄 Loading recipes...');
        // Load recipes and selections with pagination support
        final recipes = await api.currentWeeklyRecipes(
          limit: 15, // Limit to 15 recipes per page
          offset: null, // Could be used for pagination later
        );
        print('✅ Loaded ${recipes.length} recipes');

        List<Map<String, dynamic>> selections = [];
        try {
          selections = await api.userSelections();
          print('✅ Loaded ${selections.length} selections');
        } catch (e) {
          // Selections might not exist yet - that's OK for fresh users
          print('ℹ️ No selections yet (fresh user): $e');
          selections = [];
        }

        // Extract delivery window from readiness data
        Map<String, dynamic>? activeWindow;
        if (readinessData != null && readinessData['is_ready'] == true) {
          activeWindow = {
            'location': readinessData['active_city'] ?? 'Addis Ababa',
            'window_id': readinessData['active_window_id'],
            'deliver_at': readinessData['window_start'],
            'weekday': readinessData['weekday'],
            'slot': readinessData['slot'],
            'is_recommended': false, // Not provided by API yet
          };
          print('✅ Extracted active delivery window');
        }

        // For guest users without onboarding, set default allowance
        final currentUser = Supabase.instance.client.auth.currentUser;
        final isGuest = currentUser == null;
        final defaultAllowance = 4; // Default 4 meals for guests

        // For guests, load locally-stored selections
        if (isGuest && selections.isEmpty) {
          final guestSelections = await _loadGuestSelectionsLocally();
          selections = guestSelections
              .map(
                (id) => {
                  'recipe_id': id,
                  'selected': true,
                  'allowed': defaultAllowance,
                },
              )
              .toList();
          print(
            '📦 Restored ${guestSelections.length} selections from local storage',
          );
        }

        // For newly authenticated users, transfer any guest selections
        if (!isGuest && selections.isEmpty) {
          await _transferGuestSelectionsToDB();
        }

        setState(() {
          _recipes = recipes;
          _selections = selections;
          _activeDeliveryWindow = activeWindow;
          _isReady = true;
          _isLoading = false;
          _selectedCount = selections
              .where((s) => s['selected'] == true)
              .length;
          _allowedCount = selections.isNotEmpty
              ? selections.first['allowed'] ?? defaultAllowance
              : (isGuest ? defaultAllowance : 0);
        });

        // Sync delivery window to global provider for checkout screen
        if (activeWindow != null) {
          _syncDeliveryWindowToProvider(activeWindow);
        }

        print(
          '✅ State updated: ${recipes.length} recipes, $_selectedCount/$_allowedCount selected (guest: $isGuest)',
        );

        // Apply filters and initialize animations
        _applyFilters();
        _initializeAnimations();

        // Auto-select recipes if none selected yet (authenticated users only)
        if (!isGuest &&
            _selectedCount == 0 &&
            _allowedCount > 0 &&
            recipes.isNotEmpty) {
          print('🤖 Auto-selecting recipes...');
          _autoSelectRecipes();
        } else if (isGuest) {
          print('ℹ️ Guest user - skipping auto-select');
        }
      } else {
        print('❌ Not ready - showing locked view');

        setState(() {
          _isReady = false;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('❌ CRITICAL ERROR loading recipes: $e');
      print('Stack trace: ${StackTrace.current}');

      if (mounted) {
        setState(() {
          _isLoading = false;
          _isReady = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recipes: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 10),
          ),
        );
      }
    }
  }

  /// Sync delivery window from step 3 to global provider for checkout (step 5)
  void _syncDeliveryWindowToProvider(Map<String, dynamic> windowData) {
    try {
      final notifier = ref.read(deliveryWindowProvider.notifier);

      // Parse DateTime from window data
      final deliverAt = windowData['deliver_at'] ?? windowData['start_at'];
      if (deliverAt == null) {
        print('⚠️ No delivery date found in window data');
        return;
      }

      final startAt = DateTime.parse(deliverAt.toString());
      final endAt = startAt.add(const Duration(hours: 2));

      // Determine time group
      final hour = startAt.hour;
      String group;
      if (hour >= 6 && hour < 12) {
        group = 'Morning';
      } else if (hour >= 12 && hour < 17) {
        group = 'Afternoon';
      } else {
        group = 'Evening';
      }

      // Convert map to DeliveryWindow model
      final window = DeliveryWindow(
        id: windowData['window_id'] ?? '',
        startAt: startAt,
        endAt: endAt,
        city: windowData['location'] ?? 'Addis Ababa',
        label:
            '${windowData['location'] ?? 'Home'} – ${windowData['location'] ?? 'Addis Ababa'}',
        group: group,
        hasCapacity: true,
        isRecommended: windowData['is_recommended'] == true,
        slot: windowData['slot']?.toString(),
      );

      notifier.setWindow(window);
      print(
        '✅ Synced delivery window to global provider: ${window.dayLabel} • ${window.timeLabel}',
      );
    } catch (e) {
      print('⚠️ Failed to sync delivery window: $e');
    }
  }

  void _initializeAnimations() {
    // Dispose of existing controllers
    for (var controller in _animationControllers) {
      controller.dispose();
    }
    _animationControllers.clear();
    _slideAnimations.clear();
    _fadeAnimations.clear();

    // Create staggered animations for each recipe
    for (int i = 0; i < _recipes.length; i++) {
      final controller = AnimationController(duration: Yf.d300, vsync: this);

      final slideAnimation = Tween<Offset>(
        begin: const Offset(0, 0.3),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: controller, curve: Yf.emphasized));

      final fadeAnimation = Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(parent: controller, curve: Yf.standard));

      _animationControllers.add(controller);
      _slideAnimations.add(slideAnimation);
      _fadeAnimations.add(fadeAnimation);

      // Stagger the animations
      Future.delayed(Yf.stagger * i, () {
        if (mounted) {
          controller.forward();
        }
      });
    }
  }

  Future<void> _autoSelectRecipes() async {
    // Safety: needs current week_start & selections loaded
    if (_recipes.isEmpty || _allowedCount <= 0) return;

    // Get the real week_start from any recipe row
    final weekStart = _recipes.first['week_start'] != null
        ? DateTime.parse(_recipes.first['week_start'].toString())
        : DateTime.now();
    final weekKey = weekStart.toIso8601String().substring(0, 10);

    // Idempotency (run once per week per user on this device)
    if (_autoSelectWeekKey == weekKey ||
        (await _localAutoSelectAlreadyDone(weekKey))) {
      return;
    }

    await Future.delayed(const Duration(milliseconds: 400)); // let grid paint
    if (!mounted) return;

    try {
      final api = SupaClient(Supabase.instance.client);
      final already = _selections
          .where((s) => s['selected'] == true)
          .map<String>((s) => s['recipe_id'] as String)
          .toSet();

      final targetAuto = _calculateTargetAuto(_allowedCount);
      final req = AutoSelectRequest(
        recipes: _recipes,
        alreadySelectedIds: already,
        allowance: _allowedCount,
        targetAuto: targetAuto,
        userId: Supabase.instance.client.auth.currentUser?.id ?? '',
        weekStart: weekStart,
      );

      final choice = planAutoSelection(req);

      if (choice.isEmpty) {
        await _markAutoSelectDone(weekKey);
        return;
      }

      // Apply server-side (respect allowance; RPC enforces too)
      for (final id in choice.toSelect) {
        await api.toggleRecipeSelection(recipeId: id, select: true);
      }

      await _loadData(); // refresh recipes + selections

      setState(() {
        _showHandpickedBanner = true;
        _autoSelectWeekKey = weekKey;
        _autoSelectedIds = choice.toSelect.toSet(); // Track auto-picked IDs
      });

      await _markAutoSelectDone(weekKey);

      // Track analytics
      Analytics.recipesAutoSelected(count: choice.count);
      print(
        '🏷️ Auto-selected ${choice.toSelect.length} recipes: ${choice.toSelect}',
      );
    } catch (e) {
      debugPrint('Auto-selection failed: $e');
    }
  }

  // Helpers for local idempotency
  Future<bool> _localAutoSelectAlreadyDone(String weekKey) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('auto_select_applied:$weekKey') ?? false;
  }

  Future<void> _markAutoSelectDone(String weekKey) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('auto_select_applied:$weekKey', true);
  }

  int _calculateTargetAuto(int allowance) {
    // Spec: if box=2 → 1 auto; if box=4 → 3 auto
    if (allowance <= 3) return 1; // 2-3 person plans
    return 3; // 4+ person plans
  }

  void _updateFilters(Set<String> filters) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() {
        _activeFilters = filters;
        _applyFilters();
      });
      Analytics.filterToggled(
        filters: filters.toList(),
        resultCount: _filteredRecipes.length,
      );
    });
  }

  void _applyFilters() {
    if (_activeFilters.isEmpty) {
      _filteredRecipes = _recipes;
      return;
    }
    _filteredRecipes = _recipes.where((r) {
      final tags =
          (r['tags'] as List?)
              ?.map((t) => t.toString().toLowerCase())
              .toSet() ??
          {};
      return _activeFilters.any(tags.contains);
    }).toList();
  }

  String _formatTimeSlot(Map<String, dynamic> window) {
    try {
      final deliverAt = window['deliver_at'];
      if (deliverAt == null) return 'Not specified';

      final date = DateTime.parse(deliverAt.toString());
      final weekday = [
        'Mon',
        'Tue',
        'Wed',
        'Thu',
        'Fri',
        'Sat',
        'Sun',
      ][date.weekday - 1];
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');

      // Show 2-hour window
      final endHour = (date.hour + 2).toString().padLeft(2, '0');
      return '$weekday $hour:$minute–$endHour:$minute';
    } catch (e) {
      return 'Not specified';
    }
  }

  /// Save guest selections to SharedPreferences (persist across sign-in)
  Future<void> _saveGuestSelectionsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = _selections
          .where((s) => s['selected'] == true)
          .map((s) => s['recipe_id'] as String)
          .toList();
      await prefs.setStringList('guest_recipe_selections', selectedIds);
      print('💾 Saved ${selectedIds.length} guest selections locally');
    } catch (e) {
      debugPrint('Failed to save guest selections: $e');
    }
  }

  /// Load guest selections from SharedPreferences
  Future<List<String>> _loadGuestSelectionsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedIds = prefs.getStringList('guest_recipe_selections') ?? [];
      print(
        '📂 Loaded ${selectedIds.length} guest selections from local storage',
      );
      return selectedIds;
    } catch (e) {
      debugPrint('Failed to load guest selections: $e');
      return [];
    }
  }

  /// Clear guest selections from SharedPreferences (after successful transfer)
  Future<void> _clearGuestSelectionsLocally() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('guest_recipe_selections');
      print('🗑️ Cleared guest selections from local storage');
    } catch (e) {
      debugPrint('Failed to clear guest selections: $e');
    }
  }

  /// Transfer guest selections to database after sign-in
  Future<void> _transferGuestSelectionsToDB() async {
    final currentUser = Supabase.instance.client.auth.currentUser;
    if (currentUser == null) return; // Still a guest

    final guestSelections = await _loadGuestSelectionsLocally();
    if (guestSelections.isEmpty) {
      print('ℹ️ No guest selections to transfer');
      return;
    }

    print(
      '🔄 Transferring ${guestSelections.length} guest selections to database...',
    );

    try {
      final api = SupaClient(Supabase.instance.client);
      int transferred = 0;

      for (final recipeId in guestSelections) {
        try {
          await api.toggleRecipeSelection(recipeId: recipeId, select: true);
          transferred++;
        } catch (e) {
          debugPrint('Failed to transfer selection $recipeId: $e');
        }
      }

      print(
        '✅ Transferred $transferred/${guestSelections.length} selections to database',
      );

      // Clear local storage after successful transfer
      await _clearGuestSelectionsLocally();

      // Reload data to reflect database state
      await _loadData();
    } catch (e) {
      debugPrint('Failed to transfer guest selections: $e');
    }
  }

  String? _getChefNote(Map<String, dynamic> recipe) {
    final tags =
        (recipe['tags'] as List?)
            ?.map((t) => t.toString().toLowerCase())
            .toSet() ??
        {};
    if (tags.contains("chef's choice") || tags.contains('chef_choice')) {
      if (tags.contains('spicy')) return "Chef's pick · Spicy · 30-min";
      if (tags.contains('healthy') || tags.contains('light')) {
        return "Chef's pick · Light & fresh";
      }
      return "Chef's favorite";
    }
    return null;
  }

  Future<void> _toggleRecipe(String recipeId) async {
    final isSelected = _selections.any(
      (s) => s['recipe_id'] == recipeId && s['selected'] == true,
    );

    if (!isSelected && _selectedCount >= _allowedCount) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(QuotaFullSnackBar(context: context));
      return;
    }

    final currentUser = Supabase.instance.client.auth.currentUser;
    final isGuest = currentUser == null;

    // For guest users, track selections locally AND persist to SharedPreferences
    if (isGuest) {
      if (mounted) {
        setState(() {
          if (isSelected) {
            // Remove from local selections
            _selections.removeWhere((s) => s['recipe_id'] == recipeId);
            _selectedCount--;
            // Clear auto-selected flag if user manually deselects
            _autoSelectedIds.remove(recipeId);
          } else {
            // Add to local selections (explicit type to avoid IdentityMap issues)
            _selections.add(
              Map<String, dynamic>.from({
                'recipe_id': recipeId,
                'selected': true,
                'allowed': _allowedCount,
              }),
            );
            _selectedCount++;
          }
        });

        // Persist to SharedPreferences so they survive sign-in
        await _saveGuestSelectionsLocally();

        // Track analytics
        if (isSelected) {
          Analytics.recipeDeselected(
            recipeId: recipeId,
            totalSelected: _selectedCount,
          );
        } else {
          final recipe = _recipes.firstWhere(
            (r) => r['id'] == recipeId,
            orElse: () => {'title': 'Unknown'},
          );
          Analytics.recipeSelected(
            recipeId: recipeId,
            recipeTitle: recipe['title'] ?? 'Unknown',
            totalSelected: _selectedCount,
            allowed: _allowedCount,
          );
        }
      }
      return;
    }

    // For authenticated users, save to database
    try {
      final api = SupaClient(Supabase.instance.client);
      await api.toggleRecipeSelection(recipeId: recipeId, select: !isSelected);

      // Track analytics before reload
      if (isSelected) {
        Analytics.recipeDeselected(
          recipeId: recipeId,
          totalSelected: _selectedCount - 1,
        );
      } else {
        final recipe = _recipes.firstWhere(
          (r) => r['id'] == recipeId,
          orElse: () => {'title': 'Unknown'},
        );
        Analytics.recipeSelected(
          recipeId: recipeId,
          recipeTitle: recipe['title'] ?? 'Unknown',
          totalSelected: _selectedCount + 1,
          allowed: _allowedCount,
        );
      }

      await _loadData();
    } catch (e) {
      debugPrint('Toggle failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save selection: $e'),
            backgroundColor: Yf.error600,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Recipes'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isReady && !_isLoading)
            Container(
              margin: const EdgeInsets.only(right: Yf.s16),
              padding: const EdgeInsets.symmetric(
                horizontal: Yf.s12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: Yf.borderRadius16,
              ),
              child: Text(
                '$_selectedCount/$_allowedCount selected',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Progress Header - Show only when ready
          if (_isReady && !_isLoading)
            const OnboardingProgressHeader(currentStep: 3),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : !_isReady
                ? _buildLockedView(context, theme)
                : _buildRecipesView(context, theme),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedView(BuildContext context, ThemeData theme) {
    return Padding(
      padding: Yf.screenPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(height: Yf.s24),
          Text(
            'Delivery Required',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: Yf.s12),
          Text(
            'Please set up your delivery details before choosing recipes',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: Yf.s32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: () => context.go('/delivery'),
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: Yf.borderRadius16),
              ),
              child: const Text(
                'Set Up Delivery',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipesView(BuildContext context, ThemeData theme) {
    if (_recipes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 64,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(height: Yf.s24),
            Text(
              'No Recipes Available',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: Yf.s12),
            Text(
              'Check back later for new recipes',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    final recipesToShow = _activeFilters.isEmpty ? _recipes : _filteredRecipes;

    final currentUser = Supabase.instance.client.auth.currentUser;
    final isGuest = currentUser == null;

    return Column(
      children: [
        // 0. Delivery Summary Bar (if delivery window exists)
        if (_activeDeliveryWindow != null)
          DeliverySummaryBar(
            location: _activeDeliveryWindow!['location'] ?? 'Addis Ababa',
            timeSlot: _formatTimeSlot(_activeDeliveryWindow!),
            recommended: _activeDeliveryWindow!['is_recommended'] == true,
            onEdit: () => context.go('/delivery'),
          ),

        // 0.5. Guest Notice Banner (dismissible, less prominent)
        if (isGuest && _showGuestBanner)
          Container(
            margin: const EdgeInsets.fromLTRB(Yf.s16, Yf.s8, Yf.s16, Yf.s8),
            padding: const EdgeInsets.all(Yf.s12),
            decoration: BoxDecoration(
              color: Yf.peach50,
              borderRadius: Yf.borderRadius12,
              border: Border.all(color: theme.colorScheme.outlineVariant),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Yf.brown700, size: 18),
                const SizedBox(width: Yf.s8),
                Expanded(
                  child: Text(
                    'Selections saved locally • Sign in at checkout to complete order',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Yf.brown900,
                      fontSize: 12,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 18, color: Yf.brown700),
                  onPressed: () => setState(() => _showGuestBanner = false),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
          ),

        // 1. Selection Progress
        Padding(
          padding: const EdgeInsets.symmetric(vertical: Yf.s16),
          child: SelectionProgress(
            selected: _selectedCount,
            total: _allowedCount,
            showSocialProof: true,
          ),
        ),

        // 2. Handpicked Banner (dismissible)
        if (_showHandpickedBanner)
          HandpickedBanner(
            onDismiss: () => setState(() => _showHandpickedBanner = false),
          ),

        // 2.5. Section Header (industry standard)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _allowedCount > 0
                    ? 'Choose $_allowedCount recipes'
                    : 'Choose your recipes',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _allowedCount > 0
                    ? 'Complete your choices soon to secure your selected delivery slot.'
                    : 'Most customers choose 3–4 meals per week.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.black54,
                ),
              ),
            ],
          ),
        ),

        // 3. Filters Bar
        RecipeFiltersBar(
          activeFilters: _activeFilters,
          onFiltersChanged: _updateFilters,
          resultCount: recipesToShow.length,
        ),

        const SizedBox(height: Yf.s8),

        // 4. Responsive Recipe Feed (single-column on mobile, text+image rows on wide)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Switch layout based on screen width
              final isWideScreen = constraints.maxWidth >= 600;

              return ListView.builder(
                padding: const EdgeInsets.only(bottom: 120, top: Yf.s8),
                cacheExtent: 1200, // Performance optimization
                itemCount: recipesToShow.length,
                itemBuilder: (context, index) {
                  final recipe = recipesToShow[index];
                  final isSelected = _selections.any(
                    (s) =>
                        s['recipe_id'] == recipe['id'] && s['selected'] == true,
                  );

                  // Check if this recipe was auto-selected
                  final isAutoSelected = _autoSelectedIds.contains(
                    recipe['id'],
                  );

                  // Wide screen: use text+image row layout
                  if (isWideScreen) {
                    return RecipeListItem(
                      id: recipe['id'],
                      title: recipe['title'],
                      subtitle:
                          null, // Can extract from recipe data if available
                      category:
                          null, // Can extract from recipe data if available
                      imageUrl: recipe['image_url'],
                      tags: List<String>.from(recipe['tags'] ?? const []),
                      selected: isSelected,
                      autoSelected: isAutoSelected,
                      onToggle: () => _toggleRecipe(recipe['id']),
                    );
                  }

                  // Mobile: use single-column card (current design)
                  final card = RecipeCard(
                    id: recipe['id'],
                    title: recipe['title'],
                    imageUrl: recipe['image_url'],
                    tags: List<String>.from(recipe['tags'] ?? const []),
                    isSelected: isSelected,
                    autoSelected: isAutoSelected,
                    chefNote: _getChefNote(recipe),
                    selectedCount: _selectedCount,
                    allowedCount: _allowedCount,
                    onTap: () => _toggleRecipe(recipe['id']),
                  );

                  // Apply staggered animation only on mobile (single-column)
                  if (index < _animationControllers.length &&
                      index < _fadeAnimations.length &&
                      index < _slideAnimations.length) {
                    return SlideTransition(
                      position: _slideAnimations[index],
                      child: FadeTransition(
                        opacity: _fadeAnimations[index],
                        child: card,
                      ),
                    );
                  }

                  return card;
                },
              );
            },
          ),
        ),

        // 5. Sticky Bottom Bar (industry standard - cleaner)
        SafeArea(
          top: false,
          child: Material(
            elevation: 8,
            color: Colors.white,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: const StadiumBorder(),
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: theme.colorScheme.onPrimary,
                        disabledBackgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        disabledForegroundColor:
                            theme.colorScheme.onSurfaceVariant,
                        elevation: _selectedCount > 0 ? 2 : 0,
                      ),
                      onPressed: _allowedCount == 0
                          ? null
                          : _selectedCount > 0
                          ? () {
                              HapticFeedback.mediumImpact();
                              Analytics.track('recipes_continue_clicked', {
                                'selected_count': _selectedCount,
                                'allowed_count': _allowedCount,
                                'is_complete': _selectedCount == _allowedCount,
                              });
                              context.go('/address');
                            }
                          : null,
                      child: Text(
                        _allowedCount == 0
                            ? 'Select your box size'
                            : _selectedCount == _allowedCount
                            ? 'Continue'
                            : 'Selected $_selectedCount / $_allowedCount',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
