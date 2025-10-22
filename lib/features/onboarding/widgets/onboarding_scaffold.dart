import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';
import 'package:ethiomealkit/features/onboarding/widgets/stepper_header.dart';

/// Shared scaffold wrapper for all onboarding screens
/// Provides persistent stepper header and animated page transitions
class OnboardingScaffold extends ConsumerWidget {
  final Widget child;
  final OnboardingStep currentStep;
  final bool showBackButton;
  final VoidCallback? onBack;

  const OnboardingScaffold({
    super.key,
    required this.child,
    required this.currentStep,
    this.showBackButton = false,
    this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Update provider when step changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentProviderStep = ref.read(userOnboardingProgressProvider);
      if (currentProviderStep != currentStep) {
        ref.read(userOnboardingProgressProvider.notifier).goToStep(currentStep);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: showBackButton
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed:
                    onBack ??
                    () {
                      ref
                          .read(userOnboardingProgressProvider.notifier)
                          .previousStep();
                      Navigator.of(context).maybePop();
                    },
              )
            : null,
        title: Text('Step ${currentStep.number} of 5'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Persistent stepper header
          StepperHeader(currentStep: currentStep.number - 1),

          // Animated page content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              switchInCurve: Curves.easeInOut,
              switchOutCurve: Curves.easeInOut,
              transitionBuilder: (child, animation) {
                // Determine slide direction based on navigation
                final offset = Tween<Offset>(
                  begin: const Offset(0.1, 0), // Slide in from right
                  end: Offset.zero,
                ).animate(animation);

                return SlideTransition(
                  position: offset,
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: KeyedSubtree(key: ValueKey(currentStep), child: child),
            ),
          ),
        ],
      ),
    );
  }
}
