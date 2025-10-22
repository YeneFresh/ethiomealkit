# Grand Image Guardrails — YeneFresh (Flutter + Supabase)

## Overview

The Grand Image Guardrails system prevents surprise UI rewrites, screen deletions, and micro breakages in the YeneFresh app. It ensures architectural integrity and functional consistency through:

- **Screen Registry**: Stable route IDs that cannot be silently removed
- **Feature Flags**: All experimental changes behind flags (default OFF)
- **Idempotent Migrations**: Database changes that can be run multiple times safely
- **Comprehensive Testing**: Golden tests, smoke tests, and gate integrity tests
- **CI Enforcement**: Automated checks prevent breaking changes

## Quick Start

### Running Checks

```bash
# PowerShell (Windows)
.\ci\run_grand_image_checks.ps1

# Bash (Linux/Mac)
./ci/run_grand_image_checks.sh

# With options
.\ci\run_grand_image_checks.ps1 -UpdateGoldens -SkipDbChecks
```

### Adding New Screens

1. Add to `lib/app/screen_registry.yaml`
2. Update router configuration
3. Add golden test
4. Run route map test

### Adding Feature Flags

1. Add flag to `lib/app/flags.dart`
2. Use flag in UI components
3. Default to `false` for release

## Architecture

### Screen Registry (`lib/app/screen_registry.yaml`)

The source of truth for all app screens. Never remove or rename existing route IDs without explicit deprecation.

```yaml
screens:
  - id: welcome
    path: /welcome
    description: "Welcome/funnel start screen"
  - id: weekly_menu
    path: /weekly-menu
    description: "Weekly menu selection screen"
```

### Feature Flags (`lib/app/flags.dart`)

All experimental UI changes must be behind flags:

```dart
class Flags {
  static const bool newGateFlow = false; // default off
  static const bool newMenuGrid = false; // default off
}
```

### Database Views (`supabase/migrations/`)

All app reads go through stable views:

- `app.available_delivery_windows` - Delivery windows with capacity
- `app.user_delivery_readiness` - User's delivery setup status
- `app.user_selections()` - User's recipe selections (RPC)
- `app.current_weekly_recipes` - Weekly recipes (gated by readiness)

### API Client (`lib/data/api/supa_client.dart`)

Stable contracts for all data access:

```dart
class SupaClient {
  Future<List<Map<String, dynamic>>> availableWindows();
  Future<Map<String, dynamic>> userReadiness();
  Future<List<Map<String, dynamic>>> currentWeeklyRecipes();
}
```

## Testing Strategy

### Golden Tests (`test/goldens/`)

Visual regression tests for each screen:

```dart
testGoldens('Weekly Menu - Ready State', (tester) async {
  await screenMatchesGolden(tester, 'weekly_menu_ready');
});
```

### Smoke Tests (`test/ui/smoke_buttons_test.dart`)

Ensures all buttons respond without exceptions:

```dart
testWidgets('Primary CTAs respond', (tester) async {
  await tester.tap(find.text('Select Recipe'));
  await tester.pump();
  // No exceptions should be thrown
});
```

### Gate Integrity Tests (`test/gate/gate_integrity_test.dart`)

Tests delivery readiness logic:

```dart
testWidgets('Locked when not ready; unlocked when ready', (tester) async {
  // Test locked state
  expect(find.textContaining('unlock'), findsOneWidget);
  
  // Test ready state
  expect(find.textContaining('unlock'), findsNothing);
});
```

### Route Map Tests (`test/routes/no_dangling_routes_test.dart`)

Ensures registry matches router configuration:

```dart
test('Registry matches router configuration', () async {
  final registryPaths = loadRegistryPaths();
  final routerPaths = extractRouterPaths();
  expect(routerPaths.containsAll(registryPaths), true);
});
```

## CI Pipeline

The CI script runs all checks in sequence:

1. **Dependencies** - Verify required tools
2. **Format** - Check code formatting
3. **Lint** - Static analysis
4. **Tests** - Unit and widget tests
5. **Goldens** - Visual regression tests
6. **Routes** - Route map validation
7. **Smoke** - Button interaction tests
8. **Gate** - Delivery readiness tests
9. **Database** - View/RPC verification
10. **Dead Code** - Unused code detection
11. **Size** - App size analysis

## Database Migrations

All migrations are idempotent and use safe patterns:

```sql
-- Create schema if not exists
CREATE SCHEMA IF NOT EXISTS app;

-- Create or replace view
CREATE OR REPLACE VIEW app.available_delivery_windows AS
SELECT ...;

-- Insert with conflict handling
INSERT INTO table (id, data)
SELECT 'id', 'data'
WHERE NOT EXISTS (SELECT 1 FROM table WHERE id = 'id');
```

## Error Handling

### API Client Errors

```dart
try {
  return await api.currentWeeklyRecipes();
} catch (e) {
  throw SupaClientException('Failed to fetch weekly recipes: $e');
}
```

### Provider Error States

```dart
final provider = FutureProvider.autoDispose<List<Recipe>>((ref) async {
  try {
    return await api.currentWeeklyRecipes();
  } catch (e) {
    // Return empty list on error - UI will show appropriate state
    return [];
  }
});
```

## Best Practices

### Do's

- ✅ Always use feature flags for UI changes
- ✅ Update screen registry when adding screens
- ✅ Write tests for all new functionality
- ✅ Use stable API contracts
- ✅ Make migrations idempotent
- ✅ Handle errors gracefully

### Don'ts

- ❌ Never remove route IDs without deprecation
- ❌ Never change UI without flags
- ❌ Never access base tables directly
- ❌ Never break existing tests
- ❌ Never ship without CI passing

## Troubleshooting

### Golden Test Failures

```bash
# Update golden files
flutter test test/goldens/ --update-goldens
```

### Route Map Failures

```bash
# Check registry vs router
flutter test test/routes/
```

### Database Issues

```bash
# Run verification
psql $DATABASE_URL -f supabase/migrations/20241226_grand_image_verify.sql
```

### CI Failures

```bash
# Run full check locally
.\ci\run_grand_image_checks.ps1 -Verbose
```

## Contributing

1. Follow the PR template
2. Ensure all checks pass
3. Update tests for new features
4. Use feature flags for experiments
5. Maintain backward compatibility

## Refusal Policy

If a PR attempts structural UI changes without flags or registry updates, it should be rejected with:

> "Refused structural UI change: violates Grand Image Guardrails (screen_registry.yaml / flags). Propose a design RFC instead."

This ensures the app remains stable and predictable for users.





