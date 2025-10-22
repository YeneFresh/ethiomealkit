// Box/Plan Size Screen
// Buttons for 2-person / 4-person, 3/4/5 meals
// On continue → call setOnboardingPlan
// Next: /auth

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/features/onboarding/onboarding_providers.dart';
import 'package:ethiomealkit/features/onboarding/onboarding_progress_header.dart';

class BoxPlanScreen extends ConsumerStatefulWidget {
  const BoxPlanScreen({super.key});

  @override
  ConsumerState<BoxPlanScreen> createState() => _BoxPlanScreenState();
}

class _BoxPlanScreenState extends ConsumerState<BoxPlanScreen> {
  int? _selectedBoxSize = 2; // Default selection
  int? _selectedMealsPerWeek = 3; // Default selection
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Your Plan'),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          // Progress Header
          const OnboardingProgressHeader(currentStep: 1),

          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Text(
                    'Select your meal plan',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose the perfect plan for your household',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Selection Summary
                  if (_canContinue())
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(
                          alpha: 0.3,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(
                            alpha: 0.3,
                          ),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.check_circle_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Selected: $_selectedBoxSize-person box, $_selectedMealsPerWeek meals per week',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),

                  // Box Size Selection
                  Text(
                    'Box Size',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildBoxSizeCard(
                          context,
                          size: 2,
                          label: '2-Person Box',
                          description: 'Perfect for couples',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildBoxSizeCard(
                          context,
                          size: 4,
                          label: '4-Person Box',
                          description: 'Ideal for families',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Meals Per Week Selection
                  Text(
                    'Meals Per Week',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [3, 4, 5].map((meals) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildMealsCard(context, meals),
                        ),
                      );
                    }).toList(),
                  ),

                  const SizedBox(height: 32),

                  // Continue Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _canContinue() && !_isLoading
                          ? [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.3,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : null,
                    ),
                    child: FilledButton(
                      onPressed: _canContinue() && !_isLoading
                          ? () => _handleContinue()
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: _canContinue()
                            ? theme.colorScheme.primary
                            : theme.colorScheme.surfaceContainerHighest,
                        foregroundColor: _canContinue()
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text('Saving...'),
                              ],
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  _canContinue()
                                      ? 'Continue to Sign Up'
                                      : 'Select your plan',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (_canContinue()) ...[
                                  const SizedBox(width: 8),
                                  const Icon(Icons.arrow_forward, size: 20),
                                ],
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxSizeCard(
    BuildContext context, {
    required int size,
    required String label,
    required String description,
  }) {
    final theme = Theme.of(context);
    final isSelected = _selectedBoxSize == size;

    return Card(
      elevation: isSelected ? 3 : 1,
      shadowColor: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBoxSize = size;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                label,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMealsCard(BuildContext context, int meals) {
    final theme = Theme.of(context);
    final isSelected = _selectedMealsPerWeek == meals;

    return Card(
      elevation: isSelected ? 3 : 1,
      shadowColor: isSelected
          ? theme.colorScheme.primary.withValues(alpha: 0.3)
          : Colors.grey.withValues(alpha: 0.2),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: theme.colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedMealsPerWeek = meals;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              Text(
                '$meals',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                'meals',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              if (isSelected)
                Icon(Icons.check, color: theme.colorScheme.primary, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  bool _canContinue() {
    return _selectedBoxSize != null && _selectedMealsPerWeek != null;
  }

  void _handleContinue() async {
    if (!_canContinue() || _isLoading) return;

    // Add haptic feedback
    HapticFeedback.mediumImpact();

    setState(() {
      _isLoading = true;
    });

    try {
      // Save locally first (pre-auth). Auth screen will persist after sign-in.
      ref.read(pendingPlanProvider.notifier).state = {
        'boxSize': _selectedBoxSize!,
        'mealsPerWeek': _selectedMealsPerWeek!,
      };

      if (mounted) context.go('/auth');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save plan: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
}
