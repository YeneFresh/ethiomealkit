import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Onboarding/flow progress stages
enum ProgressStage {
  box, // Box size selection
  delivery, // Delivery window selection
  recipes, // Recipe selection
  address, // Address input
}

/// Current progress stage provider
final progressStageProvider = StateProvider<ProgressStage>(
  (_) => ProgressStage.delivery,
);

/// Helper to get step number (1-based) from stage
int getStepNumber(ProgressStage stage) {
  switch (stage) {
    case ProgressStage.box:
      return 1;
    case ProgressStage.delivery:
      return 2;
    case ProgressStage.recipes:
      return 3;
    case ProgressStage.address:
      return 4;
  }
}

/// Total number of steps
const int totalSteps = 4;
