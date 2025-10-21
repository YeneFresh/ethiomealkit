#!/usr/bin/env bash
set -euo pipefail

dart run build_runner build --delete-conflicting-outputs >/dev/null

if ! git diff --quiet; then
  echo "::error::Codegen drift detected. Run build_runner and commit changes."
  git status --porcelain
  exit 1
fi
echo "Codegen is clean."


