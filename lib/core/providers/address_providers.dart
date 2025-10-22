import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ethiomealkit/core/models/address.dart';
import 'package:ethiomealkit/core/services/persistence_service.dart';

/// Manages the list of user addresses (Home, Office, etc.) with persistence
class AddressesController extends StateNotifier<List<Address>> {
  AddressesController() : super([]) {
    _loadState();
  }

  Future<void> _loadState() async {
    final loaded = await PersistenceService.loadAddresses();
    if (loaded.isNotEmpty) {
      state = loaded;
      print('📂 Restored ${loaded.length} addresses');
    } else {
      // Default addresses if none saved
      state = [
        const Address(
          id: 'home',
          label: 'Home',
          line1: 'Addis Ababa',
          city: 'Addis Ababa',
          lat: 9.0108,
          lng: 38.7613,
        ),
        const Address(
          id: 'office',
          label: 'Office',
          line1: 'Addis Ababa',
          city: 'Addis Ababa',
          lat: 9.0108,
          lng: 38.7613,
        ),
      ];
    }
  }

  void _persist() {
    PersistenceService.saveAddresses(state);
  }

  void upsert(Address address) {
    final index = state.indexWhere((x) => x.id == address.id);
    if (index >= 0) {
      state = [...state]..[index] = address;
      print('✏️ Updated address: ${address.label}');
    } else {
      state = [...state, address];
      print('➕ Added new address: ${address.label}');
    }
    _persist();
  }

  void remove(String id) {
    state = state.where((a) => a.id != id).toList();
    _persist();
    print('🗑️ Removed address: $id');
  }
}

final addressesProvider =
    StateNotifierProvider<AddressesController, List<Address>>(
      (ref) => AddressesController(),
    );

/// Currently active address ID with persistence
class ActiveAddressIdNotifier extends StateNotifier<String> {
  ActiveAddressIdNotifier() : super('home') {
    _loadState();
  }

  Future<void> _loadState() async {
    final loaded = await PersistenceService.loadActiveAddressId();
    if (loaded != null) {
      state = loaded;
      print('📂 Restored active address: $loaded');
    }
  }

  void setActiveId(String id) {
    state = id;
    PersistenceService.saveActiveAddressId(id);
  }
}

final activeAddressIdProvider =
    StateNotifierProvider<ActiveAddressIdNotifier, String>(
      (ref) => ActiveAddressIdNotifier(),
    );

/// Active address (derived from ID)
final activeAddressProvider = Provider<Address?>((ref) {
  final id = ref.watch(activeAddressIdProvider);
  final addresses = ref.watch(addressesProvider);
  return addresses.firstWhere(
    (a) => a.id == id,
    orElse: () => Address(
      id: id,
      label: 'Home',
      line1: 'Addis Ababa',
      city: 'Addis Ababa',
      lat: 9.0108,
      lng: 38.7613,
    ),
  );
});

/// Map picker transient state (step 1)
final mapLatProvider = StateProvider<double?>((ref) {
  // Default to active address lat or Addis Ababa
  final address = ref.watch(activeAddressProvider);
  return address?.lat ?? 9.0108;
});

final mapLngProvider = StateProvider<double?>((ref) {
  // Default to active address lng or Addis Ababa
  final address = ref.watch(activeAddressProvider);
  return address?.lng ?? 38.7613;
});

/// Selected city
final selectedCityProvider = StateProvider<String>((_) => 'Addis Ababa');
