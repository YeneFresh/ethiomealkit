import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Onboarding step definition
enum OnboardingStep {
  box, // Step 1: Box size selection
  signup, // Step 2: Sign up / Auth
  recipes, // Step 3: Recipe selection
  delivery, // Step 4: Delivery window
  pay, // Step 5: Payment / Checkout
}

/// Extension to get step metadata
extension OnboardingStepExt on OnboardingStep {
  int get number {
    switch (this) {
      case OnboardingStep.box:
        return 1;
      case OnboardingStep.signup:
        return 2;
      case OnboardingStep.recipes:
        return 3;
      case OnboardingStep.delivery:
        return 4;
      case OnboardingStep.pay:
        return 5;
    }
  }

  String get label {
    switch (this) {
      case OnboardingStep.box:
        return 'Box';
      case OnboardingStep.signup:
        return 'Sign Up';
      case OnboardingStep.recipes:
        return 'Recipes';
      case OnboardingStep.delivery:
        return 'Delivery';
      case OnboardingStep.pay:
        return 'Pay';
    }
  }

  String get route {
    switch (this) {
      case OnboardingStep.box:
        return '/onboarding/box';
      case OnboardingStep.signup:
        return '/onboarding/signup';
      case OnboardingStep.recipes:
        return '/onboarding/recipes';
      case OnboardingStep.delivery:
        return '/onboarding/map-picker';
      case OnboardingStep.pay:
        return '/onboarding/pay';
    }
  }
}

/// All onboarding steps in order
const List<OnboardingStep> allOnboardingSteps = [
  OnboardingStep.box,
  OnboardingStep.signup,
  OnboardingStep.recipes,
  OnboardingStep.delivery,
  OnboardingStep.pay,
];

/// State notifier for onboarding progress
class OnboardingProgressNotifier extends StateNotifier<OnboardingStep> {
  OnboardingProgressNotifier() : super(OnboardingStep.box) {
    _loadProgress();
  }

  /// Load saved progress from SharedPreferences
  Future<void> _loadProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStep = prefs.getInt('onboarding_current_step');
      if (savedStep != null && savedStep >= 1 && savedStep <= 5) {
        state = allOnboardingSteps[savedStep - 1];
        print('📂 Loaded onboarding progress: Step $savedStep');
      }
    } catch (e) {
      print('⚠️ Failed to load onboarding progress: $e');
    }
  }

  /// Save progress to SharedPreferences
  Future<void> _saveProgress() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('onboarding_current_step', state.number);
      print('💾 Saved onboarding progress: Step ${state.number}');
    } catch (e) {
      print('⚠️ Failed to save onboarding progress: $e');
    }
  }

  /// Move to a specific step
  Future<void> goToStep(OnboardingStep step) async {
    state = step;
    await _saveProgress();
  }

  /// Move to next step
  Future<void> nextStep() async {
    final currentIndex = allOnboardingSteps.indexOf(state);
    if (currentIndex < allOnboardingSteps.length - 1) {
      state = allOnboardingSteps[currentIndex + 1];
      await _saveProgress();
    }
  }

  /// Move to previous step
  Future<void> previousStep() async {
    final currentIndex = allOnboardingSteps.indexOf(state);
    if (currentIndex > 0) {
      state = allOnboardingSteps[currentIndex - 1];
      await _saveProgress();
    }
  }

  /// Reset to beginning
  Future<void> reset() async {
    state = OnboardingStep.box;
    await _saveProgress();
  }

  /// Mark step as completed and advance
  Future<void> completeStep(OnboardingStep step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('onboarding_step_${step.number}_completed', true);
      print('✅ Marked step ${step.number} as completed');

      // Auto-advance to next step
      await nextStep();
    } catch (e) {
      print('⚠️ Failed to mark step completed: $e');
    }
  }

  /// Check if a step is completed
  Future<bool> isStepCompleted(OnboardingStep step) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('onboarding_step_${step.number}_completed') ?? false;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for onboarding progress
final userOnboardingProgressProvider =
    StateNotifierProvider<OnboardingProgressNotifier, OnboardingStep>(
  (ref) => OnboardingProgressNotifier(),
);
