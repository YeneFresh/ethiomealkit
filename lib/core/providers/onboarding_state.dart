import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';

/// Consolidated onboarding state - aggregates all step data
class OnboardingState {
  final OnboardingStep currentStep;
  final int? selectedPeople;
  final int? selectedMeals;
  final bool promoApplied;
  final String? promoCode;
  final int promoDiscount;
  final bool isBoxStepComplete;
  final bool isSignupStepComplete;
  final bool isRecipesStepComplete;
  final bool isDeliveryStepComplete;

  OnboardingState({
    required this.currentStep,
    this.selectedPeople,
    this.selectedMeals,
    this.promoApplied = false,
    this.promoCode,
    this.promoDiscount = 0,
    this.isBoxStepComplete = false,
    this.isSignupStepComplete = false,
    this.isRecipesStepComplete = false,
    this.isDeliveryStepComplete = false,
  });

  /// Check if user can proceed to next step
  bool get canProceed {
    switch (currentStep) {
      case OnboardingStep.box:
        return selectedPeople != null && selectedMeals != null;
      case OnboardingStep.signup:
        return isSignupStepComplete;
      case OnboardingStep.recipes:
        return isRecipesStepComplete;
      case OnboardingStep.delivery:
        return isDeliveryStepComplete;
      case OnboardingStep.pay:
        return true;
    }
  }

  /// Get progress percentage (0-100)
  int get progressPercentage {
    return ((currentStep.number / 5) * 100).round();
  }

  /// Calculate total servings
  int get totalServings {
    if (selectedPeople == null || selectedMeals == null) return 0;
    return selectedPeople! * selectedMeals!;
  }
}

/// Master provider combining all onboarding state
final onboardingStateProvider = Provider<OnboardingState>((ref) {
  final currentStep = ref.watch(userOnboardingProgressProvider);
  final people = ref.watch(selectedPeopleProvider);
  final meals = ref.watch(selectedMealsProvider);
  final promoApplied = ref.watch(promoAppliedProvider);
  final promoCode = ref.watch(promoCodeProvider);
  final promoDiscount = ref.watch(promoDiscountProvider);

  return OnboardingState(
    currentStep: currentStep,
    selectedPeople: people,
    selectedMeals: meals,
    promoApplied: promoApplied,
    promoCode: promoCode,
    promoDiscount: promoDiscount,
    isBoxStepComplete: people != null && meals != null,
  );
});
