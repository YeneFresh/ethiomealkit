# Development Scripts

This directory contains scripts for **development and testing only** - not migrations.

## Scripts Overview

### `dev_verification.sql`
- **Purpose**: Comprehensive database verification after migration deployment
- **When to run**: After `supabase db push` or manual migration application
- **What it checks**: Schema integrity, functions, views, RLS policies, indexes
- **Usage**: `psql -f scripts/dev_verification.sql`

### `dev_seed_data.sql` 
- **Purpose**: Seeds development test data including test users
- **When to run**: After migrations and verification, for development testing
- **What it creates**: 
  - 2 test users with predefined UUIDs
  - Test addresses
  - 6 sample recipes with full metadata
  - Delivery windows
  - Sample box selections and orders
- **Usage**: `psql -f scripts/dev_seed_data.sql`
- **⚠️ WARNING**: Contains test data - DO NOT run in production

## Execution Order

1. **Deploy migrations** (pure DDL)
2. **Verify deployment**: `psql -f scripts/dev_verification.sql`
3. **Seed test data**: `psql -f scripts/dev_seed_data.sql`
4. **Seed meal kits**: `dart run tools/seed_meals.dart` (production-safe)

## Test User IDs

The dev seeding script uses these predefined test user IDs:
- Test User 1: `11111111-1111-1111-1111-111111111111`
- Test User 2: `22222222-2222-2222-2222-222222222222`

These can be used in your Flutter app for testing box selection, order flows, etc.

## Production Notes

- **Never run dev scripts in production**
- Production seeding should use `tools/seed_meals.dart` for meal kits only
- Real users come from Supabase auth registration
- Use proper environment separation for testing vs production data