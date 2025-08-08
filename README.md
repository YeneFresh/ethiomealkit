# EthioMealKit MVP

Contracts-first app with mock mode and Supabase mode.

## Setup
1. Copy `env.example` to `.env` and fill values:
```
SUPABASE_URL=
SUPABASE_ANON_KEY=
USE_MOCKS=true
```
2. Fetch deps: `flutter pub get`
3. Run: `flutter run -d windows` (enable Developer Mode for plugins).

## Modes
- Mock mode: `USE_MOCKS=true` or no Supabase env; uses `MockApiClient` with hardcoded kits.
- Supabase mode: set env keys; uses `SupabaseApiClient` (implement queries).

## Backend
- Apply `supabase/schema.sql` in your Supabase project (SQL editor).
- Seed meals: `dart run tools/seed_meals.dart` (requires `.env`).

## Scripts
- Codegen: `dart run build_runner build --delete-conflicting-outputs`


A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
