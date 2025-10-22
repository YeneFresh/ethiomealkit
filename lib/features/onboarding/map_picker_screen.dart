import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/layout.dart';
import '../../core/models/address.dart';
import '../../core/providers/address_providers.dart';
import 'providers/user_onboarding_progress_provider.dart';
import 'widgets/onboarding_scaffold.dart';

/// Map Picker Screen - Step 4a of unified onboarding
/// Playful map interface for selecting delivery location
class MapPickerScreen extends ConsumerWidget {
  const MapPickerScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final city = ref.watch(selectedCityProvider);
    final lat = ref.watch(mapLatProvider);
    final lng = ref.watch(mapLngProvider);
    final theme = Theme.of(context);

    return OnboardingScaffold(
      currentStep: OnboardingStep.delivery,
      child: Column(
        children: [
          // Title section
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'almost done,',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Where should we deliver your recipes?',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: AppColors.darkBrown,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _SearchBar(city: city),
          ),
          const SizedBox(height: 12),

          // Map placeholder (will integrate real map later)
          Expanded(
            child: Stack(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.darkBrown.withOpacity(0.1),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.map_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Interactive map coming soon',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'For now, we\'ll use your selected city',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Center pin
                const _CenterPin(),

                // Tooltip
                Positioned(
                  top: 24,
                  left: 32,
                  right: 32,
                  child: _TooltipBubble(
                    text:
                        'Your order will be delivered here\nMove pin to your exact spot',
                  ),
                ),
              ],
            ),
          ),

          // Footer card
          _FooterCard(
            city: city,
            lat: lat,
            lng: lng,
            onContinue: () {
              // Persist pin coords to active address
              final id = ref.read(activeAddressIdProvider);
              final current = ref.read(activeAddressProvider);
              final updated = (current ??
                      Address(
                        id: id,
                        label: 'Home',
                        line1: city,
                        city: city,
                      ))
                  .copyWith(
                lat: lat ?? 9.0108,
                lng: lng ?? 38.7613,
              );
              ref.read(addressesProvider.notifier).upsert(updated);

              // Navigate to address form
              context.go('/onboarding/address-form');
            },
            onBack: () => context.go('/onboarding/recipes'),
          ),
        ],
      ),
    );
  }
}

/// Search bar for areas/buildings
class _SearchBar extends StatelessWidget {
  const _SearchBar({required this.city});
  final String city;

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        hintText: 'Search for area or building name…',
        prefixIcon: const Icon(Icons.search),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide(
            color: AppColors.darkBrown.withOpacity(0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      onTap: () {
        // TODO: Open place autocomplete later
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Place autocomplete coming soon!'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }
}

/// Center pin indicator
class _CenterPin extends ConsumerWidget {
  const _CenterPin();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // NOTE: With a real map, update lat/lng from camera position
    return const IgnorePointer(
      child: Center(
        child: Icon(
          Icons.location_on,
          size: 48,
          color: AppColors.gold,
          shadows: [
            Shadow(
              color: Colors.black26,
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tooltip bubble
class _TooltipBubble extends StatelessWidget {
  const _TooltipBubble({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkBrown.withOpacity(0.9),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.white,
            ),
      ),
    );
  }
}

/// Footer card with location summary and CTA
class _FooterCard extends StatelessWidget {
  const _FooterCard({
    required this.city,
    this.lat,
    this.lng,
    required this.onContinue,
    required this.onBack,
  });

  final String city;
  final double? lat;
  final double? lng;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.place, color: AppColors.gold, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        city,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.darkBrown,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (lat != null && lng != null)
                        Text(
                          '${lat!.toStringAsFixed(4)}, ${lng!.toStringAsFixed(4)}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Layout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Complete address details',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: onBack,
              child: Text(
                'Go back',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.darkBrown.withOpacity(0.7),
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
