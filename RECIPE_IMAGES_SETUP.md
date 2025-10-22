# Recipe Images Setup Guide

## 📸 **Current Status**

**Images Found**: 0  
**Images Expected**: 15  
**Location**: `assets/recipes/`

---

## 🎯 **15 Ethiopian Recipes Ready**

I've prepared seed data for 15 traditional Ethiopian dishes:

| # | Recipe Name | Image File | Tags |
|---|-------------|------------|------|
| 1 | Doro Wat | `doro-wat.jpg` | chicken, spicy, eggs |
| 2 | Kitfo | `kitfo.jpg` | beef, raw, spicy |
| 3 | Shiro Wat | `shiro-wat.jpg` | vegetarian, chickpea |
| 4 | Tibs | `tibs.jpg` | beef, vegetables |
| 5 | Injera with Beef Stew | `injera-beef-stew.jpg` | beef, spicy |
| 6 | Gomen | `gomen.jpg` | vegetarian, greens |
| 7 | Misir Wat | `misir-wat.jpg` | vegetarian, lentils, spicy |
| 8 | Alicha | `alicha.jpg` | vegetarian, mild |
| 9 | Firfir | `firfir.jpg` | injera, spicy |
| 10 | Genfo | `genfo.jpg` | porridge, breakfast |
| 11 | Dulet | `dulet.jpg` | organ-meat, spicy |
| 12 | Zilzil Tibs | `zilzil-tibs.jpg` | beef, spicy |
| 13 | Key Wat | `key-wat.jpg` | beef, spicy |
| 14 | Atkilt | `atkilt.jpg` | vegetarian, vegetables |
| 15 | Beyaynetu | `beyaynetu.jpg` | vegetarian, combo |

---

## 📁 **Where to Add Images**

### **Step 1: Add Images to Folder**

Place your 15 recipe images here:
```
assets/recipes/doro-wat.jpg
assets/recipes/kitfo.jpg
assets/recipes/shiro-wat.jpg
assets/recipes/tibs.jpg
assets/recipes/injera-beef-stew.jpg
assets/recipes/gomen.jpg
assets/recipes/misir-wat.jpg
assets/recipes/alicha.jpg
assets/recipes/firfir.jpg
assets/recipes/genfo.jpg
assets/recipes/dulet.jpg
assets/recipes/zilzil-tibs.jpg
assets/recipes/key-wat.jpg
assets/recipes/atkilt.jpg
assets/recipes/beyaynetu.jpg
```

### **Step 2: Update Database**

Run this SQL in Supabase to replace the 5-recipe seed with 15 recipes:

**File**: `sql/seed_15_recipes.sql`

```bash
# In Supabase SQL Editor:
# 1. First delete old recipes:
DELETE FROM public.user_recipe_selections;
DELETE FROM public.recipes;

# 2. Then run: sql/seed_15_recipes.sql
```

### **Step 3: Restart App**

```bash
flutter run -d chrome
```

Images will load automatically! 🎉

---

## 🤔 **Questions for You**

### **Do you have the images?**

**Option A**: ✅ I have 15 Ethiopian recipe photos
- **Action**: Tell me where they are, I'll help move them

**Option B**: ⚠️ I don't have them yet
- **Action**: I can create placeholders or we can find free stock photos

**Option C**: 🔄 They're in a different folder
- **Action**: Tell me the path, I'll copy them over

---

## 📸 **If You Need Images**

### **Quick Options**:

1. **Use Free Stock Photos**:
   - Unsplash.com (search "Ethiopian food")
   - Pexels.com (search "Ethiopian cuisine")
   - Download 15 photos, rename to match slugs

2. **Use AI Generated**:
   - DALL-E / Midjourney
   - Prompt: "Professional photo of [recipe name], Ethiopian cuisine, food photography"

3. **Use Placeholders for Now**:
   - App works fine with icon placeholders
   - Add real photos later

---

## 🚀 **What Works Without Images**

**Currently working**:
- ✅ Recipe selection (shows recipe names)
- ✅ Order creation (doesn't need images)
- ✅ Complete flow (images optional)
- ✅ Icon fallback (looks professional)

**With images**:
- ✨ More appealing visuals
- ✨ Better user engagement
- ✨ Professional appearance

**Images are nice-to-have, not required for functionality!**

---

## 📝 **Image Requirements**

If you're adding images:

### **Format**:
- ✅ JPG or PNG
- ✅ Recommended: 800×600px
- ✅ Max size: 500KB each
- ✅ Quality: 80-90%

### **Naming** (Important!):
- ✅ Must match slug exactly
- ✅ Use kebab-case (dashes, not underscores)
- ✅ Lowercase only
- ✅ `.jpg` extension

**Example**:
- ✅ `doro-wat.jpg` ← Correct
- ❌ `Doro_Wat.JPG` ← Wrong
- ❌ `doro wat.jpg` ← Wrong (space)

---

## 🎯 **Next Steps**

**Tell me**:
1. Do you have the 15 recipe images?
2. If yes, where are they located?
3. Should I create placeholder images for testing?

**Then I'll**:
1. Move/create the images
2. Update the database seed to 15 recipes
3. Verify everything loads correctly

**Let me know what you'd like to do!** 📸




