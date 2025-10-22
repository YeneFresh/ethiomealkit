#!/usr/bin/env bash
set -euo pipefail
if grep -R -n --include='*.dart' 'withOpacity\(' lib test; then
  echo "❌ Disallowed: withOpacity(). Use Color.withValues(alpha: …)."
  exit 1
fi
echo "✅ OK: no withOpacity() found."


