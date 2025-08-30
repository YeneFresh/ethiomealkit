#!/bin/bash

# Manual deployment script for EthioMealKit migrations
# Use this if Supabase CLI is not available

echo "🍲 EthioMealKit Database Migration Deployment"
echo "============================================="
echo ""

MIGRATION_DIR="./migrations"
VERIFICATION_DIR="./verification"

if [ ! -d "$MIGRATION_DIR" ]; then
    echo "❌ Migration directory not found: $MIGRATION_DIR"
    exit 1
fi

echo "📋 Migration files to deploy (in order):"
echo ""
ls -1 "$MIGRATION_DIR"/*.sql | sort
echo ""

echo "📝 Instructions for manual deployment:"
echo ""
echo "1. Open your Supabase Dashboard"
echo "2. Go to SQL Editor"
echo "3. Copy and execute each file in this order:"
echo ""

# List files in deployment order
for file in $(ls -1 "$MIGRATION_DIR"/*.sql | sort); do
    filename=$(basename "$file")
    echo "   • $filename"
done

echo ""
echo "4. After all migrations, run development verification:"
echo ""
echo "   • scripts/dev_verification.sql (comprehensive verification)"

echo ""
echo "🔧 Alternative: Use psql if you have direct database access:"
echo ""
echo "   psql 'postgresql://postgres:[PASSWORD]@[HOST]:5432/postgres' -f migrations/[file].sql"
echo ""
echo "📊 After deployment, verify with:"
echo "   psql -f scripts/dev_verification.sql"
echo "   OR: SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public';"
echo ""
echo "✅ Expected result: At least 10 tables should be created"
echo ""

# Check if schema.sql exists and offer it as alternative
if [ -f "schema.sql" ]; then
    echo "💡 Alternative: You can also apply the complete schema.sql file"
    echo "   (but migrations provide better version control)"
fi