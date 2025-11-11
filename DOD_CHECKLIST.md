# Definition of Done (DoD) Checklist

## ✅ Database Layer
- [x] **Views/RPCs exist and compile** (sql/999_verify.sql)
  - [x] app.available_delivery_windows
  - [x] app.user_delivery_readiness  
  - [x] app.current_weekly_recipes
  - [x] app.user_selections()
  - [x] app.upsert_user_active_window()
  - [x] app.set_onboarding_plan()
  - [x] app.toggle_recipe_selection()

- [x] **RLS enforced on base tables**
  - [x] user_active_window → user_id = auth.uid()
  - [x] user_onboarding_state → user_id = auth.uid()
  - [x] user_recipe_selections → user_id = auth.uid()
  - [x] delivery_windows, weeks, recipes → views only

- [x] **Seeds for Addis delivery slots exist**
  - [x] Thursday 10-12 (20 capacity)
  - [x] Saturday 14-16 (15 capacity)
  - [x] Monday 08-10 (15 capacity)
  - [x] Wednesday 18-20 (12 capacity)

## ✅ Flutter App Layer
- [x] **Resume setup logic works** (onboarding_state.stage)
  - [x] Welcome screen shows "Resume setup" for incomplete flows
  - [x] Welcome screen shows Login/Signup for new users
  - [x] Navigation to appropriate stage based on state

- [x] **Locked → unlocked gating works on /meals**
  - [x] Shows locked overlay when !is_ready
  - [x] Shows recipes when is_ready
  - [x] Proper error handling and loading states

- [x] **Recipe cards load one per row, lazy list**
  - [x] ListView.builder implementation
  - [x] One card per recipe (no collage/masonry)
  - [x] Proper image handling with error builders
  - [x] Tags display correctly

- [x] **Recipe selection enforced** (no over-select)
  - [x] Plan allowance enforcement via RPC
  - [x] "x of y selected" pill display
  - [x] Block over-select with proper feedback
  - [x] Toggle selection with visual feedback

## ✅ Testing
- [x] **Tests pass: golden, smoke, route registry, DB verify**
  - [x] Golden tests for all screens
  - [x] Smoke tests for button interactions
  - [x] Route registry validation
  - [x] Database verification tests
  - [x] Unit tests for providers
  - [x] Plan enforcement tests

## ✅ CI Pipeline
- [x] **CI green**
  - [x] Supabase: db reset, lint, verify
  - [x] Flutter: format, analyze, test
  - [x] Golden: require manual --update-goldens
  - [x] All test suites passing

## ✅ Architecture Compliance
- [x] **Views-only reads** - No direct base table access
- [x] **Idempotent migrations** - Safe to run multiple times
- [x] **Consistent theme** - Brown/gold Material 3 throughout
- [x] **No surprise UI rewrites** - Grand Image Guardrails enforced

## ✅ User Flow Implementation
- [x] **Welcome** - Resume setup logic
- [x] **Box/Plan** - 2/4-person, 3/4/5 meals selection
- [x] **Auth** - Supabase auth with state binding
- [x] **Delivery** - Location + recommended time selection
- [x] **Recipes** - Locked/unlocked with lazy list and selection

## ✅ Data Contracts
- [x] **Typed API methods** - SupaClient with exact field names
- [x] **Provider state management** - Riverpod for all flows
- [x] **Error handling** - Graceful error states throughout
- [x] **Loading states** - Proper loading indicators

## ✅ Quality Assurance
- [x] **No dead buttons** - All CTAs respond without exceptions
- [x] **No micro breakages** - Comprehensive test coverage
- [x] **Stable navigation** - Screen registry prevents route deletions
- [x] **Feature flags** - Experimental changes behind toggles

## 🎯 **ALL CHECKPOINTS MET - READY FOR PRODUCTION!**

### Commands to Verify
```bash
# Database
supabase db reset --force && supabase db lint && psql "$DATABASE_URL" -f sql/999_verify.sql

# Flutter
dart format . && dart analyze && flutter test

# CI Pipeline
.\ci\run_complete_checks.ps1
```

### Key Achievements
- ✅ **Complete 5-screen user flow** implemented
- ✅ **Stable data model** with proper RLS
- ✅ **Comprehensive test coverage** for all scenarios
- ✅ **Grand Image Guardrails** preventing UI rewrites
- ✅ **Plan allowance enforcement** working correctly
- ✅ **Resume setup logic** for incomplete flows
- ✅ **Material 3 theme** consistency throughout
- ✅ **Views-only data access** pattern enforced

**The YeneFresh app is now locked into a stable, predictable development mode with no surprise UI rewrites, dead buttons, or micro breakages!** 🚀








