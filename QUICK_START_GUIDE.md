# YeneFresh Quick Start Guide 🚀

## What Just Got Better

### 1️⃣ Box Auto-Selection (Fixed!)
**Before**: Selected wrong values (3 people, 3 meals)  
**Now**: Properly auto-selects **2 people, 4 meals** OR keeps your saved preferences

```
📂 Kept saved selection: 2 people
📂 Kept saved selection: 4 meals
```

**How it works:**
- Waits 200ms for persistence to load first (no more race conditions)
- Only auto-selects if values are `null`
- Shows clear logs for debugging

---

### 2️⃣ Delivery Header (More Prominent!)
**Before**: Thin ListTile, felt cramped  
**Now**: Beautiful gradient card with proper spacing

**Features:**
- 🎨 Gold gradient background (8% → 4% opacity)
- 📦 Icon container with gold accent
- 📍 Location and time clearly separated
- 🟢 "RECOMMENDED" badge for best slots
- 🔘 "Change" button (outlined, gold)
- 💬 Reassurance: "Don't worry, we'll call you before every delivery"

**Visual hierarchy:**
```
┌─────────────────────────────────────┐
│ 🚚  Delivery Details      [Change]  │
│     Your order will arrive on:      │
│                                      │
│ ┌───────────────────────────────┐  │
│ │ 📍 Home – Addis Ababa         │  │
│ │ ───────────────────────────   │  │
│ │ ⏰ Thu, Oct 17 • 2–4 pm 🟢    │  │
│ └───────────────────────────────┘  │
│                                      │
│ ℹ️ Don't worry, we'll call first     │
└─────────────────────────────────────┘
```

---

### 3️⃣ Smart Recipe Selection (Helpful, Not Bossy!)

#### **Soft Auto-Pick**
- Gracefully suggests recipes based on:
  1. Chef's Choice (highest confidence)
  2. Popular (user-tested)
  3. Quick recipes (<30 min)

#### **Gentle Nudge Banner**
Instead of a modal, shows a dismissible banner:
```
┌──────────────────────────────────────┐
│ 🤲 We've handpicked 3 for you • Edit │
└──────────────────────────────────────┘
```

#### **Swap Instead of Block**
**At capacity, unselected cards show:**
```
┌──────────────┐
│  Recipe      │
│  Image       │
│              │
│    [🔄 Swap] │ ← Helpful hint overlay
└──────────────┘
```

**Snackbar on tap:**
> "Your box is full! Remove a recipe first, or tap Swap to replace one."

---

### 4️⃣ Phase 9 Hub (New!)

#### **Home Screen** (`/home`)
- Personalized greeting (Good morning/afternoon/evening)
- Weekly progress card with "Manage" button
- Next delivery summary
- Recipe carousel
- "Manage This Week" sheet:
  - Change delivery date
  - Skip this week
  - Change box size
  - Cutoff warning

#### **Rewards Screen** (`/rewards`)
- 🔥 Streak tracker (3 weeks!)
- Points & tier progress bar (Bronze → Platinum)
- Weekly challenges with rewards
- Referral program
- Badge collection (6 badges)

#### **Orders Screen** (`/orders`)
- Past and upcoming deliveries
- Gold accent for upcoming orders
- Tap to view details

#### **Account Screen** (`/account`)
- Profile with avatar
- Manage Plan, Payment Methods
- Addresses, Support
- Pause/Cancel subscription (tasteful dialogs)
- Sign Out

#### **Bottom Navigation**
```
┌────┬────┬────┬────┬────┐
│🏠  │📋  │🏆  │📦  │👤  │
│Home│Menu│Rwd │Ord │Acct│
└────┴────┴────┴────┴────┘
```

---

### 5️⃣ Onboarding Image Screen

**New entry point** (`/onboarding`)
- Full-bleed background image: `assets/scenes/onboarding.png`
- Warm overlay (15% brown-gold, not black!)
- Subtle gradient for button legibility
- Two CTAs:
  - "I'm new here" → Box selection
  - "I have an account" → Login
- Value badges: 🌱 Farm Fresh, 👨‍🍳 Chef Curated, 🚚 Delivered

**Transitions:**
- 260ms fade + slide (2% vertical)
- EaseOutCubic curve
- Applied to: onboarding → box, onboarding → login

---

### 6️⃣ Delivery Window System (Robust!)

**Rules Enforced:**
- ✅ 48-hour cutoff (no slots within 2 days)
- ✅ Capacity checks (disabled if full)
- ✅ City filtering (only Addis Ababa for now)
- ✅ Recommended badge (first valid afternoon slot)

**State Flow:**
1. User selects slot → Optimistic update
2. Call `upsert_user_delivery_preference` RPC
3. Refetch from server → Source of truth
4. Invalidate dependent providers (cart, summary)
5. On error → Rollback + toast

**No More Stale UI:**
- Hard refetch after every write
- Provider invalidation cascade
- Optional realtime subscriptions

---

## 🎯 How to Test

### 1. Fresh Onboarding Flow
```
1. Navigate to /onboarding
2. See full-screen image background
3. Tap "I'm new here"
4. Box screen auto-selects 2 people, 4 meals
5. Tap Continue → Sign-Up
6. Enter email/password → Recipes
7. See handpicked recipes with nudge
8. Tap recipe → Smooth selection
9. Try tapping unselected when at cap → See "Swap" hint
10. Complete → Map Picker → Address → Pay → Success
11. Tap "Go to Home" → See Hub home screen
```

### 2. Navigation Testing
```
Bottom Nav:
- Home → Weekly progress + manage sheet
- Recipes → Recipe selection grid
- Rewards → Streaks, points, badges
- Orders → Past deliveries
- Account → Settings + subscription
```

### 3. Persistence Testing
```
1. Go through onboarding halfway
2. Refresh browser
3. Should restore: people, meals, recipes, delivery, address
4. Continue from where you left off
```

---

## 📦 Required Assets

**Add these files manually:**

1. **`assets/scenes/onboarding.png`**
   - Suggested: Hero food photo (Ethiopian tray, chef, fresh ingredients)
   - Size: 1920x1080 or 2048x1366 (high DPI)
   - Focus: Center-weighted (safe space for text overlay)

2. **Recipe images** (optional)
   - 15 images for seed recipes
   - Path: `assets/recipes/recipe-{id}.jpg`
   - Size: 800x600 minimum

---

## 🔍 Debugging Tips

### Check Provider States
```dart
// In DevTools console
ref.read(selectedPeopleProvider)
ref.read(selectedMealsProvider)
ref.read(boxQuotaProvider)
ref.read(selectedRecipesProvider)
ref.read(remainingSlotsProvider)
ref.read(atCapacityProvider)
```

### Common Issues

**"Box is auto-selecting wrong values"**
- Check logs: `📂 Kept saved selection` or `🎯 Auto-selected`
- Clear SharedPreferences: DevTools → Storage → Clear
- Restart app

**"Delivery window won't update"**
- Check RPC exists: `upsert_user_delivery_preference`
- Look for: `✅ Auto-selected and saved delivery window`
- If error: `ℹ️ Could not save delivery window` (guest mode OK)

**"Recipes not appearing"**
- Check: `📦 Loaded 15 recipes for selection`
- Verify seed data in Supabase
- Check auth: Guest users see all recipes

---

## 🎨 Customization Points

### Change Auto-Selection Defaults
```dart
// lib/features/box/box_selection_screen.dart:37-45
ref.read(selectedPeopleProvider.notifier).setPeople(2); // ← Change this
ref.read(selectedMealsProvider.notifier).setMeals(4);  // ← Change this
```

### Adjust Delivery Header Spacing
```dart
// lib/features/onboarding/recipes_selection_screen.dart:233
margin: const EdgeInsets.fromLTRB(16, 12, 16, 8), // ← Adjust margins
padding: const EdgeInsets.all(18),                // ← Adjust padding
```

### Tune Recipe Auto-Pick Logic
```dart
// lib/core/providers/box_smart_selection_provider.dart:59
int _getRecipeScore(Recipe recipe) {
  int score = 0;
  if (recipe.tags.contains("Chef's Choice")) score += 100; // ← Tune weights
  if (recipe.tags.contains('Popular')) score += 50;
  // ...
}
```

---

## 🚢 Deployment Checklist

Before production:
- [ ] Add real `onboarding.png` image
- [ ] Remove all `print()` statements or wrap in `kDebugMode`
- [ ] Fix `withOpacity` → `withValues(alpha:)` deprecation warnings
- [ ] Test on iOS/Android (not just web)
- [ ] Add error tracking (Sentry/Firebase Crashlytics)
- [ ] Enable Supabase RLS policies
- [ ] Add rate limiting for auto-selection
- [ ] Test payment integration (Chapa/Telebirr)
- [ ] Add privacy policy & terms links
- [ ] Test accessibility with screen readers
- [ ] Performance audit (Lighthouse score >90)

---

**Happy Coding! 🍳✨**

For questions or issues, check the main `IMPLEMENTATION_SUMMARY.md` file.







