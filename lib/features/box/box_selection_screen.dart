import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ethiomealkit/core/app_colors.dart';
import 'package:ethiomealkit/features/onboarding/providers/user_onboarding_progress_provider.dart';
import 'package:ethiomealkit/features/onboarding/widgets/onboarding_scaffold.dart';
import 'package:ethiomealkit/features/box/providers/box_selection_providers.dart';
import 'package:ethiomealkit/features/box/widgets/people_selector.dart';
import 'package:ethiomealkit/features/box/widgets/recipes_per_week_selector.dart';
import 'package:ethiomealkit/features/box/widgets/promo_banner.dart';
import 'package:ethiomealkit/features/box/widgets/summary_card.dart';
import 'package:ethiomealkit/features/box/widgets/confirm_cta.dart';

/// Box Selection Screen - Step 1 of unified onboarding
/// Users select: number of people + meals per week
class BoxSelectionScreen extends ConsumerStatefulWidget {
  const BoxSelectionScreen({super.key});

  @override
  ConsumerState<BoxSelectionScreen> createState() => _BoxSelectionScreenState();
}

class _BoxSelectionScreenState extends ConsumerState<BoxSelectionScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-select defaults: 2 people, 4 recipes (most popular)
    // Wait for providers to finish loading persisted state first
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;

        final people = ref.read(selectedPeopleProvider);
        final meals = ref.read(selectedMealsProvider);

        if (people == null) {
          ref.read(selectedPeopleProvider.notifier).setPeople(2);
          print('🎯 Auto-selected 2 people (default)');
        } else {
          print('📂 Kept saved selection: $people people');
        }

        if (meals == null) {
          ref.read(selectedMealsProvider.notifier).setMeals(4);
          print('🎯 Auto-selected 4 meals (popular)');
        } else {
          print('📂 Kept saved selection: $meals meals');
        }
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeople = ref.watch(selectedPeopleProvider);
    final selectedMeals = ref.watch(selectedMealsProvider);
    final theme = Theme.of(context);

    final isComplete = selectedPeople != null && selectedMeals != null;

    return OnboardingScaffold(
      currentStep: OnboardingStep.box,
      showBackButton: false, // First step
      child: Container(
        color: AppColors.offWhite,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner
              _buildHeroBanner(context, theme),

              const SizedBox(height: 24),

              // People Selector
              const PeopleSelector(),

              const SizedBox(height: 32),

              // Recipes Per Week Selector
              const RecipesPerWeekSelector(),

              const SizedBox(height: 24),

              // Promo Banner
              const PromoBanner(),

              const SizedBox(height: 24),

              // Summary Card (only show when both selected)
              if (isComplete) ...[
                const SummaryCard(),
                const SizedBox(height: 32),
              ],

              // Confirm CTA
              ConfirmCTA(
                enabled: isComplete,
                onPressed: () async {
                  // Save selections and advance
                  await _saveSelections(ref, selectedPeople!, selectedMeals!);

                  // Mark step completed
                  await ref
                      .read(userOnboardingProgressProvider.notifier)
                      .completeStep(OnboardingStep.box);

                  // Navigate to next step
                  if (context.mounted) {
                    context.go('/onboarding/signup');
                  }
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'hello there,',
          style: theme.textTheme.titleMedium?.copyWith(
            color: AppColors.darkBrown.withOpacity(0.7),
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'How many people are you\ncooking for?',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.darkBrown,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'We\'ll customize your box to perfectly fit your household',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.darkBrown.withOpacity(0.6),
          ),
        ),
      ],
    );
  }

  Future<void> _saveSelections(WidgetRef ref, int people, int meals) async {
    // TODO: Save to Supabase user_onboarding_state
    // For now, just keep in providers
    print('📦 Saving box selection: $people people, $meals meals');

    // You can call your Supabase API here:
    // final api = SupaClient(Supabase.instance.client);
    // await api.upsertUserOnboardingState(
    //   boxSize: people,
    //   mealsPerWeek: meals,
    // );
  }
}
