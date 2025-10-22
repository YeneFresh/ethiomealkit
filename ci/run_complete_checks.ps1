# Complete CI Pipeline - Supabase + Flutter + Golden Tests (PowerShell)

param(
    [switch]$UpdateGoldens
)

# Configuration
$DatabaseUrl = $env:DATABASE_URL
if (-not $DatabaseUrl) {
    $DatabaseUrl = "postgresql://postgres:password@localhost:54322/postgres"
}

$SupabaseProjectRef = $env:SUPABASE_PROJECT_REF
if (-not $SupabaseProjectRef) {
    $SupabaseProjectRef = "your-project-ref"
}

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "✅ [INFO] $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ [WARN] $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ [ERROR] $Message" -ForegroundColor Red
    exit 1
}

function Invoke-Command {
    param(
        [string]$Command,
        [string]$Description = "Running command"
    )
    Write-Host "➡️ $Description: $Command" -ForegroundColor Cyan
    try {
        Invoke-Expression $Command -ErrorAction Stop
        Write-Info "$Description completed."
    } catch {
        Write-Error "$Description failed. Error: $($_.Exception.Message)"
    }
}

# Main execution
function Main {
    Write-Info "Starting complete CI pipeline..."
    
    # 1. Supabase Database Checks
    Write-Info "=== Supabase Database Checks ==="
    Invoke-Command "supabase db reset --force" "Resetting Supabase database"
    Invoke-Command "supabase db lint" "Linting Supabase database"
    Invoke-Command "psql `"$DatabaseUrl`" -f sql/999_verify.sql" "Running SQL verification"
    
    # 2. Flutter Format and Analyze
    Write-Info "=== Flutter Format and Analyze ==="
    Invoke-Command "dart format . --set-exit-if-changed" "Formatting Dart code"
    Invoke-Command "dart analyze" "Analyzing Dart code"
    
    # 3. Flutter Tests
    Write-Info "=== Flutter Tests ==="
    Invoke-Command "flutter test" "Running Flutter tests"
    
    # 4. Specific Test Suites
    Write-Info "=== SQL Verify Tests ==="
    Invoke-Command "flutter test test/sql/" "Running SQL verify tests"
    
    Write-Info "=== Unit Tests ==="
    Invoke-Command "flutter test test/unit/" "Running unit tests"
    
    Write-Info "=== Widget Smoke Tests ==="
    Invoke-Command "flutter test test/widget/" "Running widget smoke tests"
    
    Write-Info "=== Route Registry Tests ==="
    Invoke-Command "flutter test test/routes/" "Running route registry tests"
    
    Write-Info "=== Plan Enforcement Tests ==="
    Invoke-Command "flutter test test/plan/" "Running plan enforcement tests"
    
    # 5. Golden Tests
    Write-Info "=== Golden Tests ==="
    if ($UpdateGoldens) {
        Write-Warning "Updating golden files..."
        Invoke-Command "flutter test --update-goldens test/golden/" "Updating golden files"
    } else {
        Write-Info "Running golden tests (fail if diffs found)..."
        Invoke-Command "flutter test test/golden/" "Running golden tests"
    }
    
    # 6. Final verification
    Write-Info "=== Final Verification ==="
    Write-Info "All checks passed successfully!"
    Write-Info "✅ Database views and RPCs verified"
    Write-Info "✅ RLS policies enforced"
    Write-Info "✅ Flutter code formatted and analyzed"
    Write-Info "✅ All tests passing"
    Write-Info "✅ Golden tests stable"
    Write-Info "✅ Route registry matches GoRouter"
    Write-Info "✅ Plan enforcement working"
    
    Write-Info "🚀 Ready for deployment!"
}

# Run main function
Main





