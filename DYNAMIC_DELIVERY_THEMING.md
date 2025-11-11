# Dynamic Delivery Window Theming 🌅

## Time-of-Day Visual Themes

### **Morning (6am - 12pm)** ☀️
**Mood**: Bright, fresh, energizing

```
┌─────────────────────────────────────────┐
│  ☀️  Delivery Details     [Edit ✏️]     │
│      Your order will arrive on:        │
│                                         │
│  [Background: Bright cream #FFF9E6]    │
│  [Border: Sunrise gold #FDB44B]        │
│  [Icon: Bright sun]                    │
│                                         │
│  📅 Thu, Oct 17                         │
│  ⏰ 8-10 • Morning (8–10 am)            │
└─────────────────────────────────────────┘
```

**Colors**:
- Gradient: `#FFF9E6` → `#FFF3D0` (40% → 20% alpha)
- Border: `#FDB44B` (35% alpha)
- Icon: `#E09200` (bright orange)
- Icon BG: `#FDB44B` (20% alpha)

---

### **Afternoon (12pm - 5pm)** 🌤️
**Mood**: Golden, warm, inviting (DEFAULT)

```
┌─────────────────────────────────────────┐
│  🚚  Delivery Details     [Edit ✏️]     │
│      Your order will arrive on:        │
│                                         │
│  [Background: Soft gold #C8A15A]       │
│  [Border: YeneFresh gold]              │
│  [Icon: Delivery truck]                │
│                                         │
│  📅 Thu, Oct 17                         │
│  ⏰ 14-16 • Afternoon (2–4 pm) [REC]   │
└─────────────────────────────────────────┘
```

**Colors**:
- Gradient: `#C8A15A` (12% → 6% alpha)
- Border: `#C8A15A` (35% alpha)
- Icon: `#C8A15A` (YeneFresh gold)
- Icon BG: `#C8A15A` (18% alpha)

---

### **Evening (5pm - 12am)** 🌆
**Mood**: Deeper, cozy, amber

```
┌─────────────────────────────────────────┐
│  🌙  Delivery Details     [Edit ✏️]     │
│      Your order will arrive on:        │
│                                         │
│  [Background: Deep amber #FFE0B2]      │
│  [Border: Sunset orange #F57C00]       │
│  [Icon: Moon/Night]                    │
│                                         │
│  📅 Thu, Oct 17                         │
│  ⏰ 18-20 • Evening (6–8 pm)            │
└─────────────────────────────────────────┘
```

**Colors**:
- Gradient: `#FFE0B2` → `#FFCC80` (25% → 15% alpha)
- Border: `#F57C00` (35% alpha)
- Icon: `#F57C00` (deep orange)
- Icon BG: `#F57C00` (18% alpha)

---

## How It Works

### Auto-Detection
```dart
// Based on window.startAt.hour
if (hour >= 6 && hour < 12) {
  return MorningTheme(); // ☀️
} else if (hour >= 12 && hour < 17) {
  return AfternoonTheme(); // 🌤️
} else {
  return EveningTheme(); // 🌆
}
```

### Theme Properties
Each time theme includes:
- `gradientColors` - Background gradient
- `borderColor` - Card outline
- `shadowColor` - Drop shadow
- `iconBgColor` - Icon container background
- `iconColor` - Icon tint
- `accentColor` - Edit button, toggles, accents
- `icon` - Contextual icon (sun/truck/moon)

---

## Apple Wallet-Style Mini Receipt 🎫

### Visual Design

```
┌────────────────────────────────────────┐
│ [Gold Gradient Header]                 │
│ 🧾 Week #42          [CONFIRMED]       │
│    Order #4791548b                     │
├────────────────────────────────────────┤
│ [White Card Body]                      │
│                                        │
│ 🚚  Thu, Oct 17                        │
│     Afternoon (2–4 pm)                 │
│                                        │
│ ─────────────────                      │
│                                        │
│ 🍽️  4 Recipes            ETB 270.48   │
│                                        │
│ ✓ Doro Wat                             │
│ ✓ Kitfo                                │
│ ✓ Shiro                                │
│ + 1 more                               │
│                                        │
│ 📞 We'll call you before delivery      │
│                                        │
│ [Modify Delivery Window]  ✏️           │
└────────────────────────────────────────┘
```

### Features
- ✅ Week number (calculated from year start)
- ✅ Order ID (first 8 chars)
- ✅ "CONFIRMED" badge (white on semi-transparent)
- ✅ Delivery window summary
- ✅ Total meals + amount
- ✅ Top 3 recipes with checkmarks
- ✅ "+N more" if >3 recipes
- ✅ Reassurance message
- ✅ "Modify Delivery Window" CTA
- ✅ Saved offline (via SharedPreferences)

### Apple Wallet Aesthetic
1. **Gold stripe header** - Premium feel
2. **White body** - Clean, readable
3. **Subtle shadows** - Card depth (8px blur, 16px offset)
4. **Icon badges** - Visual hierarchy
5. **Inline CTAs** - Immediate actions
6. **Rounded corners** - Modern (16px)

---

## Implementation Details

### File Structure
```
lib/core/widgets/
├── dynamic_delivery_card.dart      ← Time-of-day theming
├── gold_progress_bar.dart          ← Brand gradient
└── injera_bubbles.dart             ← Ethiopian animation

lib/features/post_checkout/
├── delivery_confirmation_screen.dart
└── widgets/
    └── order_mini_receipt.dart     ← Apple Wallet style
```

### State Management
- `smartDeliveryProvider` - Auto-selects with 1s delay
- Persists to SharedPreferences
- Updates across all screens (Step 3, 5, Home)

---

## Usage Examples

### 1. Recipes Screen (Step 3)
```dart
// Dynamic card with Home/Office toggle
DynamicDeliveryCard(
  compact: false,
  showAddressToggle: true, // Show Home/Office chips
)
```

### 2. Pay Screen (Step 5)
```dart
// Compact version, no toggle
DynamicDeliveryCard(
  compact: true,
  showAddressToggle: false,
)
```

### 3. Home Screen
```dart
// Next delivery summary
DynamicDeliveryCard(
  compact: true,
  showAddressToggle: false,
)
```

### 4. Post-Checkout
```dart
// Mini receipt with modify option
OrderMiniReceipt(
  orderId: orderId,
  weekNumber: 42,
  totalMeals: 4,
  totalAmount: 270.48,
  recipeTitles: ['Doro Wat', 'Kitfo', 'Shiro', 'Tibs'],
)
```

---

## Visual Comparison

### Before (Static)
```
┌─────────────────────────┐
│ 🚚 Delivery             │ ← Always same gold
│     Home • 2–4 pm       │
│     [Change]            │
└─────────────────────────┘
```

### After (Dynamic)
```
Morning:
┌─────────────────────────┐
│ ☀️ Delivery   [Edit ✏️] │ ← Bright cream background
│     8–10 • Morning      │
│     [🏠 Home] [Office]  │
└─────────────────────────┘

Afternoon:
┌─────────────────────────┐
│ 🚚 Delivery   [Edit ✏️] │ ← Golden background
│     14–16 • Afternoon   │
│     [🏠 Home] [Office]  │
└─────────────────────────┘

Evening:
┌─────────────────────────┐
│ 🌙 Delivery   [Edit ✏️] │ ← Deep amber background
│     18–20 • Evening     │
│     [🏠 Home] [Office]  │
└─────────────────────────┘
```

---

## Benefits

### User Experience
- **Visual storytelling**: Time-of-day feels immediate
- **Contextual icons**: Sun/truck/moon reinforce time
- **Warm gradients**: Feels more personal than flat
- **Consistent editing**: Same "Edit ✏️" everywhere

### Brand Identity
- **Ethiopian warmth**: Gold tones throughout
- **Premium feel**: Apple Wallet aesthetic
- **Cultural authenticity**: Warm colors match cuisine
- **Memorable**: Unique compared to competitors

### Technical
- **Zero dependencies**: Pure Flutter CustomPainter
- **Performance**: ShaderMask is GPU-accelerated
- **Reusable**: Same component, different themes
- **Maintainable**: Themes centralized in one method

---

## Next Enhancements

### Seasonal Theming
```dart
// Future: Adjust for Ethiopian holidays/seasons
if (isMessekel) {
  return MessekelTheme(); // Yellow flowers
} else if (isTimkat) {
  return TimkatTheme(); // Water/baptism blue
}
```

### Weather Integration
```dart
// Future: Sync with weather API
if (isRainy) {
  return RainyTheme(); // Umbrella icon, blue tint
}
```

---

**Visual polish complete! Dynamic theming makes delivery windows feel alive.** 🎨✨







