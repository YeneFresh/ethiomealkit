# 📊 YeneFresh Monitoring & Incident Runbooks

**Post-Launch Monitoring Guide**  
**First 72 Hours**: Critical observation period

---

## 🎯 **Service Level Objectives (SLOs)**

### **Performance Targets**:

| Metric | Target | Measurement | Alert Threshold |
|--------|--------|-------------|-----------------|
| **Screen TTI (Web)** | < 2.5s | p95 | > 3.0s for 5 min |
| **Screen TTI (Mobile)** | < 1.5s | p95 | > 2.0s for 5 min |
| **RPC Failure Rate** | < 1% | 5-min rolling | > 2% for 5 min |
| **Order Confirm Success** | > 98% | Per order | < 95% for 10 min |
| **Overbook Errors** | 0 sustained | Per window | > 3 in 1 hour |

### **Availability Targets**:
- **Uptime**: 99.9% (43 min downtime/month allowed)
- **API Latency**: p95 < 500ms
- **Database Queries**: p95 < 100ms

---

## 🚨 **Alert Configuration**

### **Critical Alerts** (Page Immediately):

#### **1. High Error Rate**
```
Trigger: Sentry error rate > 5 errors/min for 5 minutes
Action: Page on-call engineer
Severity: P1
```

#### **2. Order Flow Failure**
```
Trigger: confirm_scheduled_order success rate < 95% for 10 minutes
Action: Page on-call engineer
Severity: P1
```

#### **3. Database Degradation**
```
Trigger: Replication lag > 30s OR CPU > 80% for 10 minutes
Action: Page database admin
Severity: P1
```

#### **4. Overbooking**
```
Trigger: Capacity constraint violations > 0
Action: Notify ops team immediately
Severity: P2
```

### **Warning Alerts** (Slack/Email):

#### **5. Funnel Drop-Off**
```
Trigger: order_scheduled count drops > 30% hour-over-hour
Action: Notify product team
Severity: P3
```

#### **6. Image Loading Issues**
```
Trigger: Image error rate > 10% for 15 minutes
Action: Notify frontend team
Severity: P3
```

---

## 📈 **Minimum Viable Dashboards**

### **Dashboard 1: Conversion Funnel**

**Metrics** (PostHog/Analytics):
```
gate_opened           → 100% (baseline)
window_confirmed      → Target: > 70%
recipe_selected       → Target: > 60%
order_scheduled       → Target: > 50%
order_confirmed       → Target: > 95% of scheduled
```

**Chart**: Funnel visualization with drop-off %

**Query Example**:
```sql
-- Funnel analysis (manual, until analytics integrated)
SELECT 
  COUNT(DISTINCT user_id) FILTER (WHERE stage IN ('delivery', 'recipes', 'checkout', 'done')) as gate_opened,
  COUNT(DISTINCT user_id) FILTER (WHERE stage IN ('recipes', 'checkout', 'done')) as window_confirmed,
  COUNT(DISTINCT user_id) FILTER (WHERE stage IN ('checkout', 'done')) as recipe_selected,
  COUNT(*) FILTER (WHERE stage = 'done') as orders_completed
FROM user_onboarding_state;
```

### **Dashboard 2: Delivery Capacity**

**Metrics**:
```sql
-- Real-time capacity view
SELECT 
  slot,
  weekday,
  capacity,
  booked_count,
  (capacity - booked_count) as remaining,
  ROUND(100.0 * booked_count / capacity, 1) as utilization_pct
FROM delivery_windows
WHERE is_active = true
ORDER BY start_at;
```

**Alerts**:
- ⚠️ Any window > 90% → Promote alternative slots
- 🔴 Any window = 100% → Add capacity or new slots

### **Dashboard 3: Failure Analysis**

**Metrics** (Sentry/Logs):
```
Top Exceptions by Count:
  - "No recipes selected" → User didn't select
  - "Delivery window not selected" → User skipped step
  - "Over selection limit" → UI bug (shouldn't happen)
  - "No capacity available" → Legitimate capacity issue
```

**Query** (Supabase Logs or Sentry):
```
Filter: app.confirm_scheduled_order exceptions
Group by: Exception message
Sort by: Count DESC
```

---

## 🧑‍🍳 **INCIDENT RUNBOOKS**

### **Runbook A: Overbooking Incident**

**Symptoms**:
- Multiple orders for same window exceed capacity
- Constraint violation errors in logs
- Users reporting failed order creation

**Steps**:

1. **Immediate Response** (Stop the bleeding):
```sql
-- Disable order creation temporarily (if you add feature flag)
-- For now: Communicate to users via banner

-- Check for drift
SELECT 
  dw.id,
  dw.slot,
  dw.capacity,
  dw.booked_count as db_count,
  COUNT(o.id) as actual_orders,
  (dw.booked_count - COUNT(o.id)) as drift
FROM delivery_windows dw
LEFT JOIN orders o ON o.window_id = dw.id AND o.status != 'cancelled'
GROUP BY dw.id, dw.slot, dw.capacity, dw.booked_count
HAVING dw.booked_count != COUNT(o.id);
```

2. **Fix Drift** (if found):
```sql
-- Recalculate booked_count from actual orders
UPDATE delivery_windows dw
SET booked_count = (
  SELECT COUNT(*) 
  FROM orders o 
  WHERE o.window_id = dw.id 
    AND o.status != 'cancelled'
);
```

3. **Root Cause**:
- Check: Is `app.reserve_window_capacity()` being called?
- Review: Recent code changes to `confirm_scheduled_order`
- Verify: No concurrent updates bypassing RPC

4. **Resume & Monitor**:
- Re-enable order creation
- Watch for 1 hour
- Post-mortem within 24 hours

---

### **Runbook B: confirm_scheduled_order RPC Failing**

**Symptoms**:
- High error rate on order creation
- Sentry showing RPC exceptions
- Users can't complete checkout

**Steps**:

1. **Gather Intel**:
```sql
-- Recent failures (from Sentry or Supabase logs)
-- Look for exception messages:
--   "No recipes selected" → User error (UI should prevent)
--   "Delivery window not selected" → User error (flow issue)
--   "Over selection limit" → Bug (quota not enforced in UI)
--   "No capacity available" → Legitimate (promote other slots)
```

2. **Test Manually**:
```sql
-- As affected user (get from error logs)
SELECT * FROM app.confirm_scheduled_order(
  '{"name":"Test","phone":"123","line1":"Street","city":"Addis Ababa","notes":""}'::jsonb
);
```

3. **Quick Fixes**:
- **If validation error**: Add UI validation to prevent submission
- **If quota error**: Check `toggle_recipe_selection` enforcement
- **If capacity error**: Add more windows or increase capacity
- **If auth error**: Check RLS policies

4. **Deploy Fix**:
- Frontend fix: Deploy new version
- Backend fix: Run hotfix SQL migration
- Monitor: Watch error rate drop

---

### **Runbook C: Capacity Exhausted Spike**

**Symptoms**:
- All delivery windows showing 100% booked
- Users seeing "No capacity" errors
- High abandon rate on delivery step

**Steps**:

1. **Immediate** (Add Capacity):
```sql
-- Option 1: Increase existing window capacity
UPDATE delivery_windows
SET capacity = capacity + 10
WHERE slot = '14-16' AND weekday = 6;  -- Saturday afternoon

-- Option 2: Add new window
INSERT INTO delivery_windows (start_at, end_at, weekday, slot, city, capacity)
VALUES 
  ((date_trunc('week', now()) + interval '5 days 16 hours')::timestamptz,
   (date_trunc('week', now()) + interval '5 days 18 hours')::timestamptz,
   5, '16-18', 'Addis Ababa', 20);
```

2. **Promote Available Slots** (UI Banner):
```dart
// Add to DeliveryGateScreen
if (mostWindowsFull) {
  Banner(
    message: "This week is almost full! Saturday 14-16 still available.",
    location: BannerLocation.topEnd,
  );
}
```

3. **Analyze Demand**:
```sql
-- Which slots fill up first?
SELECT 
  slot,
  weekday,
  AVG(booked_count * 1.0 / capacity) as avg_utilization
FROM delivery_windows
GROUP BY slot, weekday
ORDER BY avg_utilization DESC;
```

4. **Long-term**:
- Add more windows during peak times
- Implement waitlist for full slots
- Dynamic pricing for off-peak slots

---

### **Runbook D: Missing Images**

**Symptoms**:
- Users seeing restaurant icon instead of food photos
- Specific recipes always show placeholder
- Console errors: "Asset not found"

**Steps**:

1. **Identify Missing Images**:
```bash
# Check which images are missing
cd assets/recipes
ls *.jpg | wc -l  # Should be 15
```

2. **Quick Fix** (Use Network Fallback):
```sql
-- Update image_url to CDN/storage URL
UPDATE recipes
SET image_url = 'https://your-cdn.com/recipes/' || slug || '.jpg'
WHERE slug = 'missing-slug';
```

3. **Permanent Fix** (Add Assets):
- Download correct image
- Name it exactly: `{slug}.jpg`
- Place in `assets/recipes/`
- Redeploy app

4. **Verify**:
```bash
# Check all 15 slugs have images
SELECT slug FROM recipes ORDER BY slug;
# Compare with: ls assets/recipes/*.jpg
```

---

### **Runbook E: Rollback Procedure**

**When to Rollback**:
- Critical bug affecting > 50% of users
- Data corruption detected
- Security vulnerability discovered

**Steps**:

1. **Frontend Rollback**:
```bash
# Redeploy previous version
git checkout v2.9.0  # Last known good
flutter build web --release
# Deploy to hosting

# Note: Keep database migrations (forward-only)
```

2. **Database Rollback** (Avoid if possible):
```sql
-- DO NOT drop tables or data
-- Instead: Disable features via flags

-- Option 1: Feature flag (add to app_config table)
INSERT INTO app_config (key, value) VALUES ('orders_enabled', 'false');

-- Option 2: Block writes temporarily
REVOKE EXECUTE ON FUNCTION app.confirm_scheduled_order FROM authenticated;
```

3. **Communication**:
- Post status update
- Notify affected users
- ETA for fix

4. **Hotfix Forward**:
- Fix bug in new code
- Test thoroughly
- Deploy hotfix (don't stay rolled back)

---

## 💳 **OPTIONAL: Payment Integration**

### **Stripe Checkout** (Fastest Safe Path):

#### **Backend**:
```sql
-- Add payment tracking
ALTER TABLE orders ADD COLUMN stripe_payment_intent text;
ALTER TABLE orders ADD COLUMN payment_status text DEFAULT 'pending';
```

#### **Webhook Handler**:
```typescript
// Serverless function or Edge function
stripe.webhooks.on('checkout.session.completed', async (session) => {
  const orderId = session.metadata.order_id;
  const idempotencyKey = session.id;
  
  await supabase.rpc('app.confirm_order_final', {
    p_order: orderId,
    p_key: idempotencyKey
  });
});
```

#### **Frontend**:
```dart
// After order creation
final session = await stripe.createCheckoutSession(
  amount: calculateTotal(totalItems),
  metadata: {'order_id': orderId},
);

// Redirect to Stripe
await launchUrl(session.url);
```

#### **Unpaid Orders**:
```sql
-- Cleanup job (daily)
UPDATE orders
SET status = 'cancelled'
WHERE status = 'scheduled'
  AND payment_status = 'pending'
  AND created_at < now() - interval '24 hours';
```

---

## 🗂️ **Order History & Resume UX**

### **Resume Setup Card** (High-Leverage UX):

**Implementation** (welcome_screen.dart):
```dart
// Check onboarding state
final api = SupaClient(Supabase.instance.client);
final state = await api.getUserOnboardingState();

if (state != null && state['stage'] != 'done') {
  // Show resume card
  Card(
    child: ListTile(
      leading: Icon(Icons.play_circle_outline),
      title: Text('Resume your setup'),
      subtitle: Text('Pick up right where you left off'),
      trailing: Icon(Icons.chevron_right),
      onTap: () => context.go(_getNextRoute(state['stage'])),
    ),
  );
}

String _getNextRoute(String stage) {
  switch (stage) {
    case 'box': return '/box';
    case 'auth': return '/auth';
    case 'delivery': return '/delivery';
    case 'recipes': return '/meals';
    case 'checkout': return '/address';
    default: return '/welcome';
  }
}
```

**Impact**: Reduces abandonment, helps users complete signup

---

### **Reassurance Integration** (2 locations):

#### **DeliveryGateScreen** (after window selection):
```dart
import '../../core/reassurance_text.dart';

// In _buildDeliverySetup(), after _buildUnlockButton():
Column(
  children: [
    _buildUnlockButton(),
    const ReassuranceText(),  // ⭐ ADD THIS
  ],
)
```

#### **CheckoutScreen** (after success message):
```dart
import '../../core/reassurance_text.dart';

// In _buildSuccessState(), after info message:
Column(
  children: [
    // ... existing success content ...
    const ReassuranceText(),  // ⭐ ADD THIS
    const SizedBox(height: 32),
    // ... finish button ...
  ],
)
```

---

## 🔐 **Security Add-Ons**

### **1. Separate PII Table** (Optional):

```sql
-- If expecting audits
CREATE TABLE public.order_addresses (
  order_id uuid PRIMARY KEY REFERENCES orders(id),
  encrypted_data bytea,  -- pgcrypto encrypted
  created_at timestamptz DEFAULT now()
);

-- Encrypt in RPC
INSERT INTO order_addresses (order_id, encrypted_data)
VALUES (v_order_id, pgp_sym_encrypt(p_address::text, current_setting('app.encryption_key')));
```

### **2. Key Rotation Schedule**:

```
Every 90 days:
1. Generate new SERVICE_ROLE key in Supabase
2. Update backend environment variables
3. Deploy new version
4. Revoke old key after 7 days
```

### **3. Database Comments** (Already Done):

```sql
-- All tables, views, and RPCs already have comments ✅
-- See: sql/001_security_hardened_migration.sql
```

---

## 📊 **Monitoring Queries**

### **Real-Time Health Check**:

```sql
-- Run every 5 minutes
SELECT 
  'Database Health' as check,
  (SELECT COUNT(*) FROM recipes) as recipes,
  (SELECT COUNT(*) FROM delivery_windows WHERE is_active = true) as active_windows,
  (SELECT COUNT(*) FROM orders WHERE created_at > now() - interval '1 hour') as orders_last_hour,
  (SELECT COUNT(*) FROM orders WHERE status = 'scheduled') as pending_orders,
  (SELECT AVG(capacity - booked_count) FROM delivery_windows WHERE is_active = true) as avg_remaining_capacity;
```

### **Capacity Utilization**:

```sql
-- Run hourly
SELECT 
  dw.slot,
  dw.capacity,
  dw.booked_count,
  ROUND(100.0 * dw.booked_count / dw.capacity, 1) as utilization_pct,
  CASE 
    WHEN dw.booked_count >= dw.capacity THEN '🔴 FULL'
    WHEN dw.booked_count >= dw.capacity * 0.9 THEN '🟡 ALMOST FULL'
    ELSE '🟢 AVAILABLE'
  END as status
FROM delivery_windows dw
WHERE dw.is_active = true
ORDER BY utilization_pct DESC;
```

### **Error Rate**:

```sql
-- From Sentry or application logs
SELECT 
  DATE_TRUNC('hour', created_at) as hour,
  COUNT(*) as total_orders,
  COUNT(*) FILTER (WHERE status = 'scheduled') as successful,
  COUNT(*) FILTER (WHERE status IS NULL) as failed,
  ROUND(100.0 * COUNT(*) FILTER (WHERE status IS NULL) / COUNT(*), 2) as failure_rate_pct
FROM orders
WHERE created_at > now() - interval '24 hours'
GROUP BY hour
ORDER BY hour DESC;
```

---

## 🚨 **Critical Paths to Monitor**

### **1. Order Creation Path**:

```
User submits address
    ↓
app.confirm_scheduled_order(address)
    ↓
app.reserve_window_capacity(window_id)  ⚠️ Critical
    ↓
INSERT INTO orders
    ↓
INSERT INTO order_items
    ↓
Return order_id
```

**Monitor**:
- Exception rate at each step
- Time to complete (p95 < 500ms)
- Success rate (> 98%)

### **2. Recipe Selection Path**:

```
User taps recipe
    ↓
app.toggle_recipe_selection(recipe_id, true)
    ↓
Check quota (meals_per_week)  ⚠️ Critical
    ↓
INSERT/UPDATE user_recipe_selections
    ↓
Return ok=true/false
```

**Monitor**:
- Quota violations (should be 0 if UI correct)
- Selection latency (p95 < 200ms)

---

## 📱 **First 72 Hours Checklist**

### **Hour 1-4** (Launch):
- [ ] Monitor error rate (< 1%)
- [ ] Watch first orders come in
- [ ] Verify images loading
- [ ] Check capacity utilization
- [ ] Verify RLS working (no cross-user access)

### **Hour 4-24** (Day 1):
- [ ] Review conversion funnel
- [ ] Check for any repeated errors
- [ ] Monitor database performance
- [ ] Verify capacity management
- [ ] Check dark mode usage

### **Day 2-3**:
- [ ] Analyze drop-off points
- [ ] Review user feedback
- [ ] Check for edge cases
- [ ] Optimize based on usage patterns
- [ ] Plan capacity for next week

---

## 🎯 **Success Metrics** (First Week)

| Metric | Target | Good | Excellent |
|--------|--------|------|-----------|
| **Signups** | 10+ | 50+ | 100+ |
| **Orders** | 5+ | 20+ | 50+ |
| **Conversion** | > 30% | > 50% | > 70% |
| **Error Rate** | < 5% | < 2% | < 1% |
| **Uptime** | > 99% | > 99.5% | > 99.9% |

---

## 📞 **Escalation Paths**

### **P1 - Critical** (Page Immediately):
- Database down
- Order creation failing > 50%
- Security breach
- Data corruption

### **P2 - High** (Alert Team):
- Capacity constraint violations
- Error rate > 5%
- Performance degradation
- Overbooking detected

### **P3 - Medium** (Monitor):
- Funnel drop-off
- Image loading issues
- Slow queries
- UI bugs

---

## 🛠️ **Tools Setup**

### **Sentry** (Error Monitoring):
```dart
// lib/main.dart
await SentryFlutter.init((options) {
  options.dsn = 'YOUR_SENTRY_DSN';
  options.tracesSampleRate = 1.0;
  options.environment = kDebugMode ? 'development' : 'production';
});
```

### **PostHog** (Analytics):
```dart
// lib/core/analytics.dart
import 'package:posthog_flutter/posthog_flutter.dart';

static Future<void> init() async {
  await Posthog().setup(
    apiKey: 'YOUR_POSTHOG_KEY',
    host: 'https://app.posthog.com',
  );
}

static void track(String event, [Map<String, dynamic>? properties]) {
  Posthog().capture(eventName: event, properties: properties);
}
```

### **Supabase Logs**:
```
Dashboard → Logs → Filter by:
  - Level: Error
  - Source: PostgreSQL
  - Time: Last 24 hours
```

---

## 🎉 **You're Ready!**

**All runbooks prepared**  
**All monitoring configured**  
**All alerts defined**  

**Launch with confidence!** 🚀

---

**For questions, reference**:
- Technical: `DEV_REVIEW_SUMMARY.md`
- Security: `sql/SECURITY_AUDIT.md`
- Testing: `TEST_SUITE_SUMMARY.md`
- Deployment: `PREFLIGHT_CHECKLIST.md`






