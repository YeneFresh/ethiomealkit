# 🚀 YeneFresh Go/No-Go Preflight Checklist

**Target Launch**: Production deployment  
**Estimated Time**: 10 minutes  
**Status**: Ready to verify

---

## ✅ **BACKEND VERIFICATION** (3 minutes)

### **Database Schema**

Run these queries in Supabase SQL Editor:

#### **1. Verify Recipe Count** (Expected: 15)
```sql
SELECT COUNT(*) as recipe_count FROM public.recipes;
```
- [ ] ✅ Returns: `15`

#### **2. Verify All RPCs Exist** (Expected: 8)
```sql
SELECT routine_name 
FROM information_schema.routines 
WHERE routine_schema = 'app'
ORDER BY routine_name;
```
- [ ] ✅ Returns 8 functions:
  - confirm_order_final
  - confirm_scheduled_order
  - current_addis_week
  - reserve_window_capacity
  - set_onboarding_plan
  - toggle_recipe_selection
  - upsert_user_active_window
  - user_selections

#### **3. Verify Performance Indexes** (Expected: 9)
```sql
SELECT indexname 
FROM pg_indexes 
WHERE schemaname = 'public' 
  AND indexname LIKE 'idx_%'
ORDER BY indexname;
```
- [ ] ✅ Returns 9 indexes:
  - idx_orders_status
  - idx_orders_user
  - idx_orders_week
  - idx_orders_window
  - idx_recipes_active
  - idx_recipes_slug
  - idx_recipes_week
  - idx_user_selections_user_week
  - idx_weeks_current

#### **4. Test Capacity Guard** (Should fail gracefully)
```sql
-- First, check current capacity
SELECT id, slot, capacity, booked_count 
FROM delivery_windows 
ORDER BY start_at LIMIT 1;

-- Try to overbook (manually set booked_count = capacity)
UPDATE delivery_windows 
SET booked_count = capacity 
WHERE id = (SELECT id FROM delivery_windows ORDER BY start_at LIMIT 1);

-- Now try to reserve (should fail)
SELECT app.reserve_window_capacity(
  (SELECT id FROM delivery_windows ORDER BY start_at LIMIT 1)::uuid
);

-- Reset for testing
UPDATE delivery_windows SET booked_count = 0;
```
- [ ] ✅ Throws exception: "No capacity available for this delivery window"

#### **5. Test RLS Smoke** (Anonymous cannot write)
```sql
-- As anonymous (run in incognito browser or SQL editor without auth)
INSERT INTO public.user_active_window (user_id, window_id, location_label)
VALUES (gen_random_uuid(), (SELECT id FROM delivery_windows LIMIT 1), 'Home - Addis Ababa');
```
- [ ] ✅ Fails with: "permission denied" or "violates row-level security policy"

---

## ✅ **FRONTEND VERIFICATION** (5 minutes)

### **App Startup**

```bash
flutter run -d chrome
```

#### **6. Full Flow Test** (3 browsers)

**Chrome**:
```
1. Welcome → Get Started
2. Box → 2-person, 3 meals
3. Auth → Sign up (test@example.com)
4. Delivery → Home + Sat 14-16
5. Recipes → Select 3 (see images!)
6. Address → Fill form → Submit
7. Checkout → See order ID → Finish
8. Home → Success!
```
- [ ] ✅ Chrome: Complete flow works, order created
- [ ] ✅ Safari: Same flow (if testing iOS later)
- [ ] ✅ Mobile Chrome: Same flow (responsive design)

#### **7. Dark Mode**
```
System → Switch to dark mode → Verify app switches automatically
```
- [ ] ✅ App theme changes to dark
- [ ] ✅ All screens readable in dark mode
- [ ] ✅ Colors maintain contrast

#### **8. All 15 Images Render**
```
Navigate to /meals (recipe selection screen)
```
- [ ] ✅ All 15 recipes show photos (not icons)
- [ ] ✅ Images load within 2 seconds
- [ ] ✅ No broken image icons

#### **9. Debug Screen Visibility**
```
Development build:
  Navigate to /debug → Should show health check

Production build:
  flutter build web --release
  Try /debug → Should 404 or not exist in routes
```
- [ ] ✅ `/debug` visible in debug mode
- [ ] ✅ `/debug` hidden in release builds

#### **10. Orders Screen**
```
After creating order:
  Navigate to /orders
  Tap on order
```
- [ ] ✅ Orders list shows created order
- [ ] ✅ Order detail shows items + address
- [ ] ✅ Empty state shows when no orders

---

## ✅ **INFRASTRUCTURE** (2 minutes)

### **Environment Configuration**

#### **11. Supabase URL** (Production)
```bash
# Check lib/core/env.dart
```
- [ ] ✅ Points to: `https://dtpoaskptvsabptisamp.supabase.co`
- [ ] ✅ NOT localhost/127.0.0.1

#### **12. Analytics Keys** (Optional)
```dart
// lib/core/analytics.dart
```
- [ ] ⚠️ Sentry DSN: Not set (using console logs)
- [ ] ⚠️ PostHog key: Not set (using console logs)
- [ ] ✅ Analytics abstraction ready (can add keys later)

#### **13. CORS Configuration** (If using CDN)
```
Supabase Storage CORS:
  - Allow origin: your-domain.com
  - If using assets/ folder: N/A (bundled with app)
```
- [ ] ✅ Using local assets (no CORS needed)
- [ ] N/A CDN (images bundled in app)

---

## 📊 **GO/NO-GO DECISION MATRIX**

| Check | Status | Blocker | Action |
|-------|--------|---------|--------|
| Recipe count = 15 | [ ] | 🔴 YES | Run sql/update_to_15_recipes.sql |
| 8 RPCs exist | [ ] | 🔴 YES | Run sql/002_production_upgrades.sql |
| 9 indexes exist | [ ] | 🟡 NO | Run sql/002_production_upgrades.sql (recommended) |
| Capacity guard works | [ ] | 🟡 NO | Capacity will work, test validates |
| RLS blocks anon writes | [ ] | 🔴 YES | Verify in SQL editor |
| Chrome flow works | [ ] | 🔴 YES | Test manually |
| Images load | [ ] | 🔴 YES | Test in app |
| Dark mode works | [ ] | 🟡 NO | Test (nice-to-have) |
| Debug hidden in release | [ ] | 🟡 NO | Verify (security) |
| Prod Supabase URL | [ ] | 🔴 YES | Check lib/core/env.dart |

**Legend**:
- 🔴 **Blocker**: Must pass to launch
- 🟡 **Important**: Should pass (can fix quickly if not)
- [ ] **Checkbox**: Mark when verified

---

## 🎯 **GO/NO-GO CRITERIA**

### **GO** ✅ (Ready to Launch):
- ✅ All 🔴 blockers passed
- ✅ 8/10 checks passing
- ✅ Tests green (31/31)
- ✅ No critical errors

### **NO-GO** ⚠️ (Not Ready):
- ❌ Any 🔴 blocker failing
- ❌ < 7/10 checks passing
- ❌ Tests failing
- ❌ Critical errors in flow

---

## 🚨 **Quick Fixes** (If Issues Found)

### **If Recipe Count ≠ 15**:
```sql
-- In Supabase SQL Editor:
-- Copy/paste: sql/update_to_15_recipes.sql
-- Run
-- Verify: SELECT COUNT(*) FROM recipes;
```

### **If RPCs ≠ 8**:
```sql
-- In Supabase SQL Editor:
-- Copy/paste: sql/002_production_upgrades.sql
-- Run
-- Verify: SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='app';
```

### **If Images Don't Load**:
```bash
# Check files exist
ls assets/recipes/*.jpg

# Verify pubspec.yaml has:
# assets:
#   - assets/recipes/

# Restart app
flutter run -d chrome
```

### **If Flow Breaks**:
```bash
# Check console for errors
# Common issues:
#   - Supabase URL wrong → Check lib/core/env.dart
#   - Migration not run → Run migrations
#   - Network error → Check internet connection
```

---

## 📋 **Post-Verification Actions**

### **If All Checks Pass** ✅:
1. ✅ Mark this checklist complete
2. ✅ Proceed to deployment
3. ✅ Monitor first 72 hours (see MONITORING.md)
4. ✅ Celebrate! 🎉

### **If Any Check Fails** ⚠️:
1. ⚠️ Review failure
2. ⚠️ Apply quick fix (see above)
3. ⚠️ Re-run verification
4. ⚠️ Delay launch until green

---

## 🎊 **Expected Results**

**All checks passing means**:
- ✅ Database: Fully operational
- ✅ Backend: All RPCs working
- ✅ Frontend: Complete flow functional
- ✅ Security: Hardened and tested
- ✅ Performance: Optimized
- ✅ UX: Polished with images

**Ready to serve real customers!** 🚀

---

## 📞 **Quick Commands**

```bash
# Run all verifications at once:

# 1. Database (in Supabase SQL Editor)
SELECT 
  (SELECT COUNT(*) FROM recipes) as recipes,
  (SELECT COUNT(*) FROM information_schema.routines WHERE routine_schema='app') as rpcs,
  (SELECT COUNT(*) FROM pg_indexes WHERE indexname LIKE 'idx_%') as indexes;

# 2. Frontend
flutter test && flutter run -d chrome

# 3. Review
# Complete manual flow test
# Switch to dark mode
# Check /orders and /debug
```

---

**Estimated Completion Time**: 10 minutes  
**Confidence Level**: High (all features tested)  
**Ready to Launch**: After verification ✅

---

**Complete this checklist, then GO!** 🚀





