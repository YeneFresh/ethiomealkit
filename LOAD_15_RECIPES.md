# ✅ Load 15 Recipe Images - Action Required

## 🎉 **Good News: All 15 Images Found!**

**Location**: `assets/recipes/`  
**Count**: 15 images ✅  
**Size**: ~3.1 MB total  
**Extensions**: All `.jpg` now (standardized)

---

## 📸 **Your 15 Recipe Images**

| Recipe | Filename | Slug | Status |
|--------|----------|------|--------|
| 1. Alicha | `alicha.jpg` | alicha | ✅ |
| 2. Atkilt | `atkilt.jpg` | atkilt | ✅ |
| 3. Beyaynetu | `beyaynetu.jpg` | beyaynetu | ✅ |
| 4. Doro Wat | `doro-wat.jpg` | doro-wat | ✅ |
| 5. Dulet | `dulet.jpg` | dulet | ✅ |
| 6. Firfir | `firfir.jpg` | firfir | ✅ |
| 7. Genfo | `genfo.jpg` | genfo | ✅ |
| 8. Gomen | `gomen.jpg` | gomen | ✅ |
| 9. Injera with Beef Stew | `injera-with-beef-stew.jpg` | injera-with-beef-stew | ✅ |
| 10. Key Wat | `key-wat.jpg` | key-wat | ✅ |
| 11. Kitfo | `kitfo.jpg` | kitfo | ✅ |
| 12. Misir Wat | `misir-wat.jpg` | misir-wat | ✅ |
| 13. Shiro Wat | `shiro-wat.jpg` | shiro-wat | ✅ |
| 14. Tibs | `tibs.jpg` | tibs | ✅ |
| 15. Zilzil Tibs | `zilzil-tibs.jpg` | zilzil-tibs | ✅ |

---

## 🎯 **Current Database Has Only 5**

Your database currently has:
1. Injera with Beef Stew
2. Doro Wat
3. Kitfo
4. Shiro Wat
5. Tibs

**You have 10 more images ready to use!**

---

## 🚀 **Load All 15 Recipes**

### **Step 1: Update Database**

Run this in Supabase SQL Editor:

```sql
-- Delete old selections first
DELETE FROM public.user_recipe_selections;

-- Delete old 5 recipes
DELETE FROM public.recipes;

-- Insert all 15 recipes
-- (Copy from sql/seed_15_recipes.sql)
```

**Or just run**: `sql/seed_15_recipes.sql` (entire file)

### **Step 2: Restart App**

```bash
flutter run -d chrome
```

### **Step 3: See All 15 Recipes**

Navigate to recipe selection screen → You'll see all 15 with real photos! 📸

---

## ✅ **What I Fixed**

1. ✅ Renamed 4 files from `.jpeg` → `.jpg` (standardized)
2. ✅ Updated seed data to match exact filenames
3. ✅ All 15 recipes ready to load

**Your images are ready to use!** 🎉





