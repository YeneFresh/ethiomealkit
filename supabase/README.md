# EthioMealKit Database Migrations

This directory contains the database schema and migrations for the EthioMealKit application.

## Migration Files (Execute in Order)

1. **`20241201000002_slug_hardening_complete.sql`**
   - Creates `app` schema
   - Adds slug column to recipes with unique constraints
   - Implements slug format validation and immutability
   - Creates slug generation functions and triggers

2. **`20241201000003_create_user_week_status.sql`**
   - Creates user week status tracking table
   - Implements week-based meal planning logic
   - Includes current week helper function

3. **`20241201000004_create_recipe_public_view.sql`**
   - Creates optimized public recipe view
   - Implements recipe search and filtering functions
   - Adds recommendation logic based on user preferences

4. **`20241201000005_create_box_summary_functions.sql`**
   - Creates box selection tracking table
   - Implements box summary, lock integrity, and checkout functions
   - Core business logic for meal box management

5. **`20241201000006_create_base_tables.sql`**
   - Creates all core tables (users, addresses, recipes, meal_kits, orders, etc.)
   - Sets up basic RLS policies
   - Foundation schema for the application

6. **`20241201000008_update_recipe_schema.sql`**
   - Enhances recipes table with detailed attributes
   - Adds price_cents, kcal, tags, chef_note, nutrition info
   - Creates recipe utility functions

## Development Scripts

**Not migrations** - run manually for development and verification:

- `scripts/dev_verification.sql` - Comprehensive database verification and testing
- `scripts/dev_seed_data.sql` - Development data seeding with test users and sample data

## Schema Overview

### Core Tables
- `users` - User profiles linked to auth.users
- `recipes` - Enhanced recipe data with tags, nutrition, pricing
- `meal_kits` - MVP meal kit offerings
- `box_selections` - User meal selections per week
- `user_week_status` - Weekly planning and locking status
- `orders` / `order_items` - Order management
- `addresses` - User delivery addresses
- `delivery_windows` - Available delivery slots

### Key Features
- **Slug Management**: Auto-generated, immutable recipe slugs
- **Box Locking**: Week-based meal selection with checkout locks
- **Recipe Search**: Full-text search with filtering and recommendations  
- **RLS Security**: Row-level security on all tables
- **Week Planning**: Monday-based week planning system

## Usage

### Deploy to Supabase
```bash
supabase db push
```

### Manual Application (if CLI unavailable)
1. Copy each migration file content
2. Execute in order in Supabase SQL Editor
3. Run verification scripts to confirm setup

### Verification
After migrations, run development verification:
```bash
psql -f scripts/dev_verification.sql
```

## Development Notes

- **Migrations are pure DDL and idempotent** - only schema changes, no verification code
- Migrations execute in filename order (timestamps)
- `app` schema contains internal functions
- Public functions are accessible to authenticated users  
- **Verification scripts are separate** - run manually to test functionality
- RLS policies restrict data access to appropriate users

## Next Steps

1. **Deploy migrations**: `supabase db push` or manual SQL execution
2. **Verify deployment**: `psql -f scripts/dev_verification.sql`
3. **Seed development data**: `psql -f scripts/dev_seed_data.sql` (includes test users)
4. **Seed meal kits**: `dart run tools/seed_meals.dart` (production-safe)
5. **Configure Flutter app**: Set up `.env` with Supabase credentials
6. **Implement API client**: Replace mock data with Supabase queries
7. **Test end-to-end**: Full app functionality with real backend