# YeneFresh Migration Commands

## 🚀 **Complete Migration (Recommended)**

### Option 1: PowerShell Script (Windows)
```powershell
.\run_migration.ps1
```

### Option 2: Direct SQL (Any OS)
```bash
# Run the robust migration
psql "postgresql://postgres:password@localhost:54322/postgres" -f sql/000_robust_migration.sql

# Test the migration
psql "postgresql://postgres:password@localhost:54322/postgres" -f sql/test_migration.sql
```

### Option 3: Supabase CLI
```bash
# Reset database
supabase db reset --force

# Run migration
psql "$(supabase status | grep 'DB URL' | awk '{print $3}')" -f sql/000_robust_migration.sql

# Test migration
psql "$(supabase status | grep 'DB URL' | awk '{print $3}')" -f sql/test_migration.sql
```

## 🔧 **What the Migration Does**

### **Error Prevention:**
- ✅ **Drops existing objects** in reverse dependency order
- ✅ **Handles all constraint conflicts** with proper CASCADE
- ✅ **Uses IF NOT EXISTS** where appropriate
- ✅ **Includes comprehensive error handling**

### **Database Structure:**
- ✅ **6 Base Tables** with proper relationships
- ✅ **4 App Views** for stable data access
- ✅ **5 RPC Functions** for business logic
- ✅ **Strict RLS** policies on all tables
- ✅ **Seed Data** for Addis Ababa delivery slots

### **Verification:**
- ✅ **Tests all views** return data
- ✅ **Tests all RPCs** execute successfully
- ✅ **Verifies RLS** policies are enabled
- ✅ **Checks permissions** are granted correctly

## 🛡️ **Safety Features**

1. **Idempotent**: Can be run multiple times safely
2. **Clean Slate**: Drops existing objects to prevent conflicts
3. **Comprehensive Testing**: Verifies everything works
4. **Error Handling**: Stops on first error with clear messages
5. **Backup Warning**: Prompts before destructive operations

## 📋 **After Migration**

1. **Start Supabase** (if not running):
   ```bash
   supabase start
   ```

2. **Run Flutter App**:
   ```bash
   flutter pub get
   flutter run
   ```

3. **Test the Flow**:
   - Welcome → Box → Auth → Delivery → Recipes
   - Verify locked/unlocked states
   - Test recipe selection with plan allowance

## 🚨 **Troubleshooting**

### If migration fails:
1. Check database connection
2. Ensure Supabase is running
3. Check for existing conflicting objects
4. Run with `-Force` flag to skip confirmations

### If tests fail:
1. Check that all tables were created
2. Verify RLS policies are enabled
3. Check that views return data
4. Ensure functions execute without errors

## ✅ **Success Indicators**

You'll know the migration succeeded when you see:
- ✅ "All migrations completed successfully!"
- ✅ "Migration test completed successfully!"
- ✅ All table/view/function counts > 0
- ✅ No error messages in the output

**The migration is designed to be bulletproof and handle all edge cases!** 🎯








