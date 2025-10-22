#!/bin/bash
# Complete CI Pipeline - Supabase + Flutter + Golden Tests

set -euo pipefail

# Configuration
DATABASE_URL="${DATABASE_URL:-postgresql://postgres:password@localhost:54322/postgres}"
SUPABASE_PROJECT_REF="${SUPABASE_PROJECT_REF:-your-project-ref}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

run_command() {
    local cmd="$@"
    log_info "Running: $cmd"
    if ! eval "$cmd"; then
        log_error "Command failed: $cmd"
        exit 1
    fi
}

# Main execution
main() {
    log_info "Starting complete CI pipeline..."
    
    # 1. Supabase Database Checks
    log_info "=== Supabase Database Checks ==="
    run_command "supabase db reset --force"
    run_command "supabase db lint"
    run_command "psql \"$DATABASE_URL\" -f sql/999_verify.sql"
    
    # 2. Flutter Format and Analyze
    log_info "=== Flutter Format and Analyze ==="
    run_command "dart format . --set-exit-if-changed"
    run_command "dart analyze"
    
    # 3. Flutter Tests
    log_info "=== Flutter Tests ==="
    run_command "flutter test"
    
    # 4. Specific Test Suites
    log_info "=== SQL Verify Tests ==="
    run_command "flutter test test/sql/"
    
    log_info "=== Unit Tests ==="
    run_command "flutter test test/unit/"
    
    log_info "=== Widget Smoke Tests ==="
    run_command "flutter test test/widget/"
    
    log_info "=== Route Registry Tests ==="
    run_command "flutter test test/routes/"
    
    log_info "=== Plan Enforcement Tests ==="
    run_command "flutter test test/plan/"
    
    # 5. Golden Tests (require manual update)
    log_info "=== Golden Tests ==="
    if [[ "${1:-}" == "--update-goldens" ]]; then
        log_warn "Updating golden files..."
        run_command "flutter test --update-goldens test/golden/"
    else
        log_info "Running golden tests (fail if diffs found)..."
        run_command "flutter test test/golden/"
    fi
    
    # 6. Final verification
    log_info "=== Final Verification ==="
    log_info "All checks passed successfully!"
    log_info "✅ Database views and RPCs verified"
    log_info "✅ RLS policies enforced"
    log_info "✅ Flutter code formatted and analyzed"
    log_info "✅ All tests passing"
    log_info "✅ Golden tests stable"
    log_info "✅ Route registry matches GoRouter"
    log_info "✅ Plan enforcement working"
    
    log_info "🚀 Ready for deployment!"
}

# Run main function
main "$@"






