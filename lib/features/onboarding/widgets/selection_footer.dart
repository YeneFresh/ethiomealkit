import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:confetti/confetti.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/core/layout.dart';
import 'package:ethiomealkit/core/providers/recipe_selection_providers.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';

/// Sticky footer showing selection progress and continue button
/// Triggers confetti when quota is reached
class SelectionFooter extends ConsumerStatefulWidget {
  const SelectionFooter({super.key});

  @override
  ConsumerState<SelectionFooter> createState() => _SelectionFooterState();
}

class _SelectionFooterState extends ConsumerState<SelectionFooter> {
  late ConfettiController _confettiController;
  bool _hasTriggeredConfetti = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 3),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _handleContinue() async {
    HapticFeedback.mediumImpact();

    // Mark recipes step complete
    await ref
        .read(userOnboardingProgressProvider.notifier)
        .completeStep(OnboardingStep.recipes);

    if (mounted) {
      context.go('/onboarding/delivery');
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds = ref.watch(selectedRecipesProvider);
    final quota = ref.watch(boxQuotaProvider);
    final remaining = ref.watch(remainingSelectionsProvider);
    final selectedCount = selectedIds.length;
    final isComplete = quota > 0 && selectedCount == quota;
    final showFooter = selectedCount > 0 || quota > 0;

    // Trigger confetti when quota reached (once)
    if (isComplete && !_hasTriggeredConfetti) {
      _hasTriggeredConfetti = true;
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) {
          _confettiController.play();
        }
      });
    }

    // Reset confetti flag if user deselects
    if (!isComplete && _hasTriggeredConfetti) {
      _hasTriggeredConfetti = false;
    }

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        // Confetti
        Positioned(
          top: -100,
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: 3.14 / 2, // Down
            emissionFrequency: 0.05,
            numberOfParticles: 20,
            gravity: 0.3,
            colors: [
              AppColors.gold,
              AppColors.success600,
              AppColors.darkBrown,
              AppColors.peach100,
            ],
          ),
        ),

        // Footer with remaining banner
        AnimatedSlide(
          offset: showFooter ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Remaining banner
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: remaining > 0
                    ? Container(
                        key: const ValueKey('remaining'),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: Layout.gutter,
                          vertical: 10,
                        ),
                        color: Colors.amber.shade50,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: AppColors.darkBrown.withValues(alpha: 0.7),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Add $remaining more to your box',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: AppColors.darkBrown,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(key: ValueKey('no-remaining')),
              ),

              // Main footer
              Container(
                padding: const EdgeInsets.all(Layout.gutter),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Selection count
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$selectedCount of $quota selected',
                            style: const TextStyle(
                              color: AppColors.darkBrown,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          if (!isComplete)
                            Text(
                              'Select ${quota - selectedCount} more',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            )
                          else
                            const Row(
                              children: [
                                Icon(
                                  Icons.celebration,
                                  size: 14,
                                  color: AppColors.success600,
                                ),
                                SizedBox(width: 4),
                                Text(
                                  'Perfect!',
                                  style: TextStyle(
                                    color: AppColors.success600,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),

                      // Buttons
                      Row(
                        children: [
                          // Auto-complete button (shown when remaining > 0)
                          if (remaining > 0) ...[
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(autoSelectControllerProvider)
                                    .fillRemaining();
                              },
                              child: const Text(
                                'Auto-complete',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          // Continue button
                          ElevatedButton(
                            onPressed: isComplete ? _handleContinue : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.gold,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 14,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  Layout.cardRadius,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Continue to Delivery',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
