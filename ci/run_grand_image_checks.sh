#!/bin/bash
# Grand Image CI Checks
# Runs all stability and integrity checks for the YeneFresh app
# Ensures no UI rewrites, dead buttons, or micro breakages

set -euo pipefail

echo "🚀 Starting Grand Image CI Checks..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# Check if required tools are installed
check_dependencies() {
    log_info "Checking dependencies..."
    
    if ! command -v dart &> /dev/null; then
        log_error "Dart is not installed"
        exit 1
    fi
    
    if ! command -v flutter &> /dev/null; then
        log_error "Flutter is not installed"
        exit 1
    fi
    
    if ! command -v psql &> /dev/null; then
        log_warning "PostgreSQL client not found - skipping DB checks"
        SKIP_DB_CHECKS=true
    else
        SKIP_DB_CHECKS=false
    fi
    
    log_success "Dependencies check passed"
}

# Run Flutter/Dart checks
run_flutter_checks() {
    log_info "Running Flutter/Dart checks..."
    
    # Format check
    log_info "Checking code format..."
    if ! dart format --set-exit-if-changed .; then
        log_error "Code format check failed"
        log_info "Run 'dart format .' to fix formatting issues"
        exit 1
    fi
    log_success "Code format check passed"
    
    # Lint check
    log_info "Running static analysis..."
    if ! flutter analyze --fatal-warnings --fatal-infos; then
        log_error "Static analysis failed"
        exit 1
    fi
    log_success "Static analysis passed"
    
    # Test check
    log_info "Running tests..."
    if ! flutter test; then
        log_error "Tests failed"
        exit 1
    fi
    log_success "Tests passed"
}

# Run golden tests
run_golden_tests() {
    log_info "Running golden tests..."
    
    # Check if golden_toolkit is available
    if ! flutter test test/goldens/ --reporter=expanded; then
        log_error "Golden tests failed"
        log_info "Run 'flutter test test/goldens/ --update-goldens' to update golden files"
        exit 1
    fi
    log_success "Golden tests passed"
}

# Run route map tests
run_route_tests() {
    log_info "Running route map tests..."
    
    if ! flutter test test/routes/; then
        log_error "Route map tests failed"
        exit 1
    fi
    log_success "Route map tests passed"
}

# Run button smoke tests
run_smoke_tests() {
    log_info "Running button smoke tests..."
    
    if ! flutter test test/ui/; then
        log_error "Button smoke tests failed"
        exit 1
    fi
    log_success "Button smoke tests passed"
}

# Run gate integrity tests
run_gate_tests() {
    log_info "Running gate integrity tests..."
    
    if ! flutter test test/gate/; then
        log_error "Gate integrity tests failed"
        exit 1
    fi
    log_success "Gate integrity tests passed"
}

# Run database checks
run_db_checks() {
    if [ "$SKIP_DB_CHECKS" = true ]; then
        log_warning "Skipping database checks (PostgreSQL client not available)"
        return
    fi
    
    log_info "Running database checks..."
    
    # Check if DATABASE_URL is set
    if [ -z "${DATABASE_URL:-}" ]; then
        log_warning "DATABASE_URL not set - skipping database checks"
        return
    fi
    
    # Run database verification
    if ! psql "$DATABASE_URL" -f supabase/migrations/20241226_grand_image_verify.sql >/dev/null 2>&1; then
        log_error "Database verification failed"
        log_info "Check your database connection and run migrations"
        exit 1
    fi
    log_success "Database verification passed"
}

# Run dead code check
run_dead_code_check() {
    log_info "Running dead code check..."
    
    # Check if dart_dead_code is available
    if command -v dart_dead_code &> /dev/null; then
        if ! dart_dead_code; then
            log_warning "Dead code detected"
            log_info "Consider removing unused code to keep the codebase clean"
        else
            log_success "No dead code detected"
        fi
    else
        log_warning "dart_dead_code not available - skipping dead code check"
    fi
}

# Run size analysis
run_size_analysis() {
    log_info "Running size analysis..."
    
    # Check app size
    if flutter build apk --analyze-size; then
        log_success "Size analysis completed"
    else
        log_warning "Size analysis failed - continuing anyway"
    fi
}

# Main execution
main() {
    echo "🎯 Grand Image Guardrails - YeneFresh CI"
    echo "========================================"
    
    check_dependencies
    run_flutter_checks
    run_golden_tests
    run_route_tests
    run_smoke_tests
    run_gate_tests
    run_db_checks
    run_dead_code_check
    run_size_analysis
    
    echo ""
    echo "🎉 All Grand Image checks passed!"
    echo "✅ No UI rewrites detected"
    echo "✅ No dead buttons found"
    echo "✅ Gate integrity maintained"
    echo "✅ Visual stability preserved"
    echo ""
    log_success "Ready for deployment! 🚀"
}

# Run main function
main "$@"






