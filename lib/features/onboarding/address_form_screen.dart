import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/app_colors.dart';
import '../../core/layout.dart';
import '../../core/models/address.dart';
import '../../core/providers/address_providers.dart';
import 'providers/user_onboarding_progress_provider.dart';
import 'widgets/onboarding_scaffold.dart';

/// Address Form Screen - Step 4b of unified onboarding
/// Precise form for completing delivery address details
class AddressFormScreen extends ConsumerStatefulWidget {
  const AddressFormScreen({super.key});

  @override
  ConsumerState<AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends ConsumerState<AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _street = TextEditingController();
  final _notes = TextEditingController();
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _phone = TextEditingController(text: '+251 ');

  bool _sameAsBilling = true;
  String _selectedInstructions = 'None';

  @override
  void initState() {
    super.initState();
    // Pre-fill form with existing address data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final active = ref.read(activeAddressProvider);
      if (active != null) {
        _line1.text = active.line1;
        _line2.text = active.line2 ?? '';
        _notes.text = active.notes ?? '';
      }
    });
  }

  @override
  void dispose() {
    _line1.dispose();
    _line2.dispose();
    _street.dispose();
    _notes.dispose();
    _first.dispose();
    _last.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    if (!value.startsWith('+251') && !value.startsWith('09')) {
      return 'Enter a valid Ethiopian phone number';
    }
    return null;
  }

  void _onContinue() {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all required fields'),
          backgroundColor: AppColors.error600,
        ),
      );
      return;
    }

    final id = ref.read(activeAddressIdProvider);
    final base = ref.read(activeAddressProvider);
    final city = ref.read(selectedCityProvider);

    final updated = (base ??
            Address(
              id: id,
              label: 'Home',
              line1: _line1.text,
              city: city,
            ))
        .copyWith(
      line1: _line1.text,
      line2: _line2.text.isEmpty ? null : _line2.text,
      city: city,
      notes: _notes.text.isEmpty ? null : _notes.text,
    );

    ref.read(addressesProvider.notifier).upsert(updated);

    // Mark delivery step as complete
    ref
        .read(userOnboardingProgressProvider.notifier)
        .completeStep(OnboardingStep.delivery);

    print('✅ Address saved: ${updated.fullAddress}');
    print('📞 Contact: ${_first.text} ${_last.text} - ${_phone.text}');

    // Navigate to Pay step
    context.go('/onboarding/pay');
  }

  @override
  Widget build(BuildContext context) {
    final city = ref.watch(selectedCityProvider);
    final active = ref.watch(activeAddressProvider);
    final theme = Theme.of(context);

    return OnboardingScaffold(
      currentStep: OnboardingStep.delivery,
      child: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Title
            Text(
              'Deliver my recipes to',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Selected city: $city',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),

            const SizedBox(height: 16),

            // Mini map preview
            GestureDetector(
              onTap: () => context.go('/onboarding/map-picker'),
              child: Container(
                height: 140,
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
                      Icon(Icons.map, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(
                        'Tap to view map',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Location summary row
            Row(
              children: [
                const Icon(Icons.place, color: AppColors.gold, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${active?.label ?? 'Home'} • ${active?.city ?? city}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => context.go('/onboarding/map-picker'),
                  child: const Text('Change'),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Address fields
            _TwoCol(
              left: _Input(
                label: 'Flat/Villa no. *',
                controller: _line1,
                validator: _validateRequired,
              ),
              right: _Input(
                label: 'Building/Community',
                controller: _line2,
              ),
            ),
            _Input(
              label: 'Street name *',
              controller: _street,
              validator: _validateRequired,
            ),

            const SizedBox(height: 12),

            // Delivery instructions dropdown
            _Dropdown(
              label: 'Delivery instructions',
              items: const [
                'None',
                'Call on arrival',
                'Leave at reception',
                'Doorstep drop',
              ],
              value: _selectedInstructions,
              onChanged: (v) {
                setState(() {
                  _selectedInstructions = v!;
                  _notes.text = v == 'None' ? '' : v;
                });
              },
            ),

            const SizedBox(height: 12),

            // Same as billing checkbox
            Row(
              children: [
                Switch(
                  value: _sameAsBilling,
                  onChanged: (v) => setState(() => _sameAsBilling = v),
                  activeColor: AppColors.gold,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use the same for billing address',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkBrown,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Contact details section
            Text(
              'My contact details',
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.darkBrown,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            _TwoCol(
              left: _Input(
                label: 'First Name *',
                controller: _first,
                validator: _validateRequired,
              ),
              right: _Input(
                label: 'Last Name *',
                controller: _last,
                validator: _validateRequired,
              ),
            ),
            _Input(
              label: 'Phone Number *',
              controller: _phone,
              keyboard: TextInputType.phone,
              validator: _validatePhone,
              hint: '+251 9xx xxx xxx',
            ),

            const SizedBox(height: 24),

            // Continue button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _onContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(Layout.cardRadius),
                  ),
                ),
                child: const Text(
                  'Continue to Payment',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Reassurance message
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                '📍 Pin your exact spot during delivery — our driver will call first.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Two-column layout helper
class _TwoCol extends StatelessWidget {
  const _TwoCol({required this.left, required this.right});
  final Widget left;
  final Widget right;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: 12),
        Expanded(child: right),
      ],
    );
  }
}

/// Input field widget
class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboard,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboard;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Layout.cardRadius),
            borderSide: BorderSide(
              color: AppColors.darkBrown.withOpacity(0.2),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Layout.cardRadius),
            borderSide: BorderSide(
              color: AppColors.darkBrown.withOpacity(0.2),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Layout.cardRadius),
            borderSide: const BorderSide(
              color: AppColors.gold,
              width: 2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(Layout.cardRadius),
            borderSide: const BorderSide(
              color: AppColors.error600,
              width: 2,
            ),
          ),
        ),
      ),
    );
  }
}

/// Dropdown widget
class _Dropdown extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.items,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final List<String> items;
  final String value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: value,
      items:
          items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Layout.cardRadius),
          borderSide: BorderSide(
            color: AppColors.darkBrown.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Layout.cardRadius),
          borderSide: BorderSide(
            color: AppColors.darkBrown.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(Layout.cardRadius),
          borderSide: const BorderSide(
            color: AppColors.gold,
            width: 2,
          ),
        ),
      ),
    );
  }
}
