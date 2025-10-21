#!/usr/bin/env bash
set -euo pipefail

if ! command -v supabase >/dev/null 2>&1; then
  echo "::warning::supabase CLI not installed; skipping SQL parse check."
  exit 0
fi

echo "Starting local Supabase (DB only)…"
supabase stop || true
supabase start -x studio

DB_URL="postgresql://postgres:postgres@localhost:54322/postgres"

if command -v psql >/dev/null 2>&1; then
  if [ -f supabase/schema.sql ]; then
    echo "Applying supabase/schema.sql to local Postgres…"
    psql "$DB_URL" -v ON_ERROR_STOP=1 -f supabase/schema.sql
    echo "Schema applied successfully."
  else
    echo "::notice::No supabase/schema.sql found; skipping."
  fi
else
  echo "::warning::psql not available; skipping SQL apply."
fi


