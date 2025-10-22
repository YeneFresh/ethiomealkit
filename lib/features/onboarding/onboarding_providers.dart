// Onboarding Providers - Proxies app.set_onboarding_plan

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/api/supa_client.dart';

// Data Models
class OnboardingState {
  final String? stage;
  final int? planBoxSize;
  final int? mealsPerWeek;
  final String? draftWindowId;
  final DateTime? updatedAt;

  const OnboardingState({
    this.stage,
    this.planBoxSize,
    this.mealsPerWeek,
    this.draftWindowId,
    this.updatedAt,
  });

  factory OnboardingState.fromJson(Map<String, dynamic> json) {
    return OnboardingState(
      stage: json['stage'],
      planBoxSize: json['plan_box_size'],
      mealsPerWeek: json['meals_per_week'],
      draftWindowId: json['draft_window_id'],
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'])
          : null,
    );
  }

  bool get hasPlan => planBoxSize != null && mealsPerWeek != null;
  bool get needsResume => stage != null && stage != 'done';
}

// Core Providers
final onboardingProvider =
    FutureProvider.autoDispose<OnboardingState?>((ref) async {
  final api = ref.watch(supaClientProvider);

  try {
    final data = await api.getUserOnboardingState();
    return data != null ? OnboardingState.fromJson(data) : null;
  } catch (e) {
    return null;
  }
});

// Action Provider
final setOnboardingPlanProvider = FutureProvider.family
    .autoDispose<void, Map<String, int>>((ref, plan) async {
  final api = ref.watch(supaClientProvider);

  try {
    await api.setOnboardingPlan(
      boxSize: plan['boxSize']!,
      mealsPerWeek: plan['mealsPerWeek']!,
    );

    // Invalidate to refresh
    ref.invalidate(onboardingProvider);
  } catch (e) {
    rethrow;
  }
});

// Holds a pending plan selection before the user authenticates.
// Flow: Box screen saves here → Auth screen reads and persists after sign-in.
final pendingPlanProvider = StateProvider<Map<String, int>?>(
  (ref) => null,
);
