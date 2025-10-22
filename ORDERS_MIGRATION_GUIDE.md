# Orders Schema Migration Guide

## ✅ What Was Added

### **New Tables** (2)

#### 1. `public.orders`
**Purpose**: Stores user orders with delivery details and status

| Column | Type | Description |
|--------|------|-------------|
| `id` | uuid | Primary key |
| `user_id` | uuid | FK → auth.users |
| `week_start` | date | Order week |
| `window_id` | uuid | FK → delivery_windows |
| `address` | jsonb | Delivery address `{name, phone, line1, line2, city, notes}` |
| `meals_per_week` | int | User's plan size |
| `total_items` | int | Number of recipes in order |
| `status` | text | `scheduled`, `confirmed`, or `cancelled` |
| `created_at` | timestamptz | Order creation time |

**RLS**: ✅ Users can only access their own orders

#### 2. `public.order_items`
**Purpose**: Line items for each order (selected recipes)

| Column | Type | Description |
|--------|------|-------------|
| `order_id` | uuid | FK → orders (PK) |
| `recipe_id` | uuid | FK → recipes (PK) |
| `qty` | int | Quantity (default: 1) |

**RLS**: ✅ Users can only access items from their own orders

### **New RPC** (1)

#### `app.confirm_scheduled_order(p_address jsonb)`
**Purpose**: Creates order from current selections with validation

**Returns**: `TABLE(order_id uuid, total_items int)`

**Validations**:
1. ✅ User must be authenticated
2. ✅ Delivery window must be selected
3. ✅ At least one recipe must be selected
4. ✅ Selection count must not exceed plan limit (`meals_per_week`)

**Process**:
1. Gets current week, user's window, and plan
2. Counts selected recipes for current week
3. Validates selections against limits
4. Creates order with status `'scheduled'`
5. Inserts order items from selections
6. Returns order ID and total items

---

## 🚀 How to Run the Migration

### **Option 1: Supabase Dashboard (Recommended)**

1. Go to your Supabase project: https://supabase.com/dashboard/project/dtpoaskptvsabptisamp
2. Navigate to **SQL Editor** (left sidebar)
3. Click **New Query**
4. Copy the entire contents of `sql/000_robust_migration.sql`
5. Paste into the SQL editor
6. Click **Run** (or press Ctrl+Enter)
7. Wait for completion (should see "All migrations completed successfully!")

### **Option 2: Supabase CLI**

```bash
# If you have Supabase CLI installed and configured
supabase db reset --db-url "postgresql://postgres:[YOUR-PASSWORD]@db.dtpoaskptvsabptisamp.supabase.co:5432/postgres"
```

---

## ✓ Verification Queries

### **1. Check Tables Exist**

```sql
-- Should return 8 tables including orders and order_items
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
  AND table_name IN (
    'delivery_windows',
    'user_active_window', 
    'user_onboarding_state',
    'weeks',
    'recipes',
    'user_recipe_selections',
    'orders',
    'order_items'
  )
ORDER BY table_name;
```

**Expected Output**: 8 rows

### **2. Check RPC Exists**

```sql
-- Should return 6 functions including confirm_scheduled_order
SELECT routine_name, routine_type
FROM information_schema.routines 
WHERE routine_schema = 'app'
ORDER BY routine_name;
```

**Expected Output**:
```
confirm_scheduled_order | FUNCTION
current_addis_week      | FUNCTION
set_onboarding_plan     | FUNCTION
toggle_recipe_selection | FUNCTION
upsert_user_active_window | FUNCTION
user_selections         | FUNCTION
```

### **3. Verify RLS Policies**

```sql
-- Should show policies for orders and order_items
SELECT schemaname, tablename, policyname
FROM pg_policies
WHERE tablename IN ('orders', 'order_items')
ORDER BY tablename;
```

**Expected Output**:
```
public | orders      | orders self access
public | order_items | order_items self access
```

### **4. Test Order Creation (Manual Test)**

```sql
-- Prerequisites: Must have authenticated user with:
-- 1. Onboarding plan set
-- 2. Delivery window selected
-- 3. At least one recipe selected

-- Test order creation
SELECT * FROM app.confirm_scheduled_order(
  '{"name": "Test User", "phone": "+251911234567", "line1": "Bole Road", "city": "Addis Ababa"}'::jsonb
);
```

### **5. View Sample Order**

```sql
-- View created orders (requires authenticated session)
SELECT 
  o.id,
  o.week_start,
  o.status,
  o.total_items,
  o.address->>'name' as customer_name,
  o.created_at
FROM public.orders o
WHERE o.user_id = auth.uid()
ORDER BY o.created_at DESC
LIMIT 5;
```

---

## 📋 Migration Summary

**File**: `sql/000_robust_migration.sql`  
**New Lines**: ~190 (orders schema + RPC)  
**Total Lines**: ~673

### **Updated Sections**:
1. **Line 10-18**: Added order tables to cleanup
2. **Line 489-538**: Orders schema (tables + RLS)
3. **Line 540-613**: Orders RPC (confirm_scheduled_order)
4. **Line 635**: Grant execute permission on new RPC
5. **Line 667-669**: Verification for orders tables

### **Schema Version**: Complete with Orders
- ✅ 8 base tables
- ✅ 3 views
- ✅ 6 RPCs
- ✅ All RLS policies
- ✅ Seed data
- ✅ Orders support

---

## 🔗 Frontend Integration

### **Update SupaClient**

Add to `lib/data/api/supa_client.dart`:

```dart
// Order confirmation
Future<Map<String, dynamic>> confirmOrder({
  required Map<String, dynamic> address,
}) async {
  try {
    final response = await _client.rpc(
      'app.confirm_scheduled_order',
      params: {'p_address': address},
    );
    return Map<String, dynamic>.from(response);
  } catch (e) {
    throw SupaClientException('Failed to confirm order: $e');
  }
}
```

### **Update Checkout Screen**

In `lib/features/checkout/checkout_screen.dart`:

```dart
Future<void> _confirmOrder() async {
  // ... existing code ...
  
  final address = {
    'name': _nameController.text,
    'phone': _phoneController.text,
    'line1': _streetController.text,
    'line2': '',
    'city': _cityController.text,
    'notes': _notesController.text,
  };
  
  final result = await api.confirmOrder(address: address);
  final orderId = result['order_id'];
  
  // Navigate to success or order detail
  context.go('/order/$orderId');
}
```

---

## 🎯 Next Steps

1. ✅ **Run Migration** - Execute in Supabase SQL Editor
2. ✅ **Verify RPC** - Run verification queries above
3. ✅ **Update SupaClient** - Add `confirmOrder()` method
4. ✅ **Wire Checkout** - Connect address form to RPC
5. ✅ **Test Flow** - Complete onboarding → checkout → order creation
6. ✅ **Add Orders Screen** - Display user's order history

---

## 🚨 Troubleshooting

### **Error: "relation 'public.orders' does not exist"**
→ Migration hasn't run. Execute `sql/000_robust_migration.sql` in Supabase.

### **Error: "function app.confirm_scheduled_order does not exist"**
→ RPC creation failed. Check permissions and run migration again.

### **Error: "No recipes selected"**
→ User hasn't selected any recipes. Ensure recipe selection step is complete.

### **Error: "Delivery window not selected"**
→ User hasn't confirmed delivery. Ensure delivery step is complete.

### **Error: "Over selection limit"**
→ User selected more recipes than their plan allows. Frontend should prevent this.

---

**Status**: ✅ Ready to run migration
**File Modified**: `sql/000_robust_migration.sql`
**Action Required**: Execute migration in Supabase SQL Editor





