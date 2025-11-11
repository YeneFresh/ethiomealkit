# 🧪 YeneFresh Beta Testing Guide

**Welcome, Beta Testers!**  
Thank you for helping us make YeneFresh better. This guide will help you test the app effectively.

---

## 📱 **How to Join Beta**

### **iPhone (TestFlight)**:

1. **Install TestFlight** (if you don't have it):
   - App Store → Search "TestFlight" → Install

2. **Join YeneFresh Beta**:
   - Open beta invite link (sent via email/message)
   - Tap "Accept" in TestFlight
   - Tap "Install" to download YeneFresh

3. **Launch & Test**:
   - Open YeneFresh from TestFlight
   - Follow test scenarios below

### **Android (Play Console Internal Testing)**:

1. **Join Beta Program**:
   - Open beta opt-in link (sent via email/message)
   - Tap "Become a tester"
   - Wait for approval (usually instant)

2. **Install from Play Store**:
   - Play Store → Search "YeneFresh"
   - You'll see "Beta" label
   - Tap "Install"

3. **Launch & Test**:
   - Open YeneFresh
   - Follow test scenarios below

---

## ✅ **What to Test** (15-20 minutes)

### **Scenario 1: First-Time User** (10 min)

**Goal**: Complete your first order

1. **Launch** → Tap "Get Started"
2. **Choose Plan**:
   - Select "2-person" box
   - Choose "3 meals/week"
   - Tap "Continue"
3. **Sign Up** (or skip if already signed up)
4. **Pick Delivery**:
   - Choose "Home Addis" or "Office Addis"
   - Select a delivery window (e.g., "Saturday 14-16")
   - Tap "Unlock Recipes"
5. **Select Recipes**:
   - Browse 15 Ethiopian recipes
   - Tap 3 cards to select (watch quota: "3/3 selected")
   - Try selecting a 4th (should be blocked with friendly message)
   - Tap "Continue to Address"
6. **Enter Address**:
   - Phone: Your phone number
   - Street: "123 Bole Road"
   - City: "Addis Ababa"
   - Notes: (optional)
   - Tap "Continue to Checkout"
7. **Checkout Success**:
   - See gold checkmark ✅
   - Order ID displayed
   - Tap "Finish & Go Home"

**Expected**: Smooth flow, no crashes, order created successfully

---

### **Scenario 2: Returning User** (5 min)

**Goal**: Test resume functionality

1. **Close app** (force quit)
2. **Reopen app**
3. **Tap "Resume Setup"** (if you see it)
4. **Continue from where you left off**

**Expected**: App remembers your progress, no data lost

---

### **Scenario 3: Edge Cases** (5 min)

**Goal**: Find bugs

**Try These**:
- Toggle dark mode (system settings) → App should switch themes
- Select recipes, then deselect one, then select another → Should work smoothly
- Leave address fields empty → Should show validation errors
- Go offline (airplane mode) mid-flow → Should show friendly error + retry button
- Increase font size (+1 or +2) → Text should be readable

**Expected**: Graceful handling, no crashes

---

## 🐛 **How to Report Issues**

### **In-App Feedback** (Preferred):

1. **After placing an order**:
   - Tap "Report an Issue" button on success screen

2. **Or from Settings**:
   - (If Settings screen exists) → "Report an Issue"

3. **Email prefills automatically** with:
   - Screen name
   - Device info (Android/iOS)
   - App version
   - Timestamp

4. **Describe your issue**:
   - What happened?
   - What did you expect?
   - Steps to reproduce?

5. **Send**

### **Manual Email** (If button doesn't work):

**To**: `feedback@yenefresh.co`  
**Subject**: `YeneFresh Beta Feedback`

**Template**:
```
Device: [iPhone 14 / Pixel 7 / etc.]
OS: [iOS 17 / Android 14 / etc.]
App Version: [See About screen or TestFlight]

Issue:
[Describe what happened]

Steps to Reproduce:
1. [First step]
2. [Second step]
3. [What went wrong]

Expected:
[What you expected to happen]

Screenshot: [Attach if helpful]
```

---

## 📊 **What We're Looking For**

### **Critical Bugs** (Report ASAP):
- App crashes
- Can't complete order
- Data loss (selections disappear)
- Login/signup fails
- Payment issues (when enabled)

### **UX Issues** (Also helpful):
- Confusing flow
- Unclear copy/labels
- Button too small
- Slow loading
- Visual glitches in dark mode

### **Nice Feedback** (Appreciated):
- Feature suggestions
- Design improvements
- Copy/microcopy tweaks
- Performance observations

---

## 🎯 **Test Coverage Goals**

We need to test on:

### **Devices**:
- [ ] iPhone (iOS 17+)
- [ ] iPhone (iOS 18)
- [ ] Android (Pixel/Samsung, Android 13+)
- [ ] Android (older device, Android 12 or Go)

### **Scenarios**:
- [ ] First-time signup
- [ ] Returning user resume
- [ ] Password reset (if applicable)
- [ ] Select different delivery slots
- [ ] Select different recipe combinations
- [ ] Dark mode on/off
- [ ] Large font size
- [ ] Offline/poor connection

### **Platforms**:
- [ ] Phone (primary)
- [ ] Tablet (if available)
- [ ] Web (if applicable)

---

## ⏱️ **Expected Timings** (What's Normal)

| Action | Expected Time | Flag if Slower |
|--------|---------------|----------------|
| App launch | < 2 seconds | > 5 seconds |
| Load recipes | < 1 second | > 3 seconds |
| Create order | < 2 seconds | > 5 seconds |
| Screen transitions | Instant | Janky/laggy |

---

## 🎊 **Thank You!**

Your feedback is invaluable. Every bug you find, every suggestion you make helps us ship a better product.

**What happens next**:
1. We collect all feedback (first week)
2. Prioritize fixes & improvements
3. Ship updated beta (week 2)
4. Repeat until ready for public launch
5. You get early access + special perks! 🎁

---

## 📞 **Need Help?**

**Email**: `support@yenefresh.co`  
**Expected Response**: Within 24 hours (usually faster)

**Common Questions**:

**Q: Can I share this with friends?**  
A: Yes! Share the TestFlight/Play link. Capacity: 100 beta testers.

**Q: Will my test orders be real?**  
A: No, this is test mode. No actual delivery (yet!).

**Q: How long is the beta?**  
A: 2-4 weeks, then public launch.

**Q: Do I need to pay?**  
A: No, beta is completely free. Payment will be added later.

**Q: My app crashed, what do I do?**  
A: It's automatically reported to us. But please also send feedback with steps to reproduce!

---

**Happy Testing! 🧪**  
**— The YeneFresh Team**








