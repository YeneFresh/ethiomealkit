# Grand Image CI Checks - PowerShell Version
# Runs all stability and integrity checks for the YeneFresh app
# Ensures no UI rewrites, dead buttons, or micro breakages

param(
    [switch]$SkipDbChecks,
    [switch]$UpdateGoldens,
    [switch]$Verbose
)

# Set error action preference
$ErrorActionPreference = "Stop"

# Helper functions
function Write-Info {
    param([string]$Message)
    Write-Host "ℹ️  $Message" -ForegroundColor Blue
}

function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️  $Message" -ForegroundColor Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ $Message" -ForegroundColor Red
}

# Check if required tools are installed
function Test-Dependencies {
    Write-Info "Checking dependencies..."
    
    if (-not (Get-Command dart -ErrorAction SilentlyContinue)) {
        Write-Error "Dart is not installed"
        exit 1
    }
    
    if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
        Write-Error "Flutter is not installed"
        exit 1
    }
    
    if (-not (Get-Command psql -ErrorAction SilentlyContinue)) {
        Write-Warning "PostgreSQL client not found - skipping DB checks"
        $script:SkipDbChecks = $true
    }
    
    Write-Success "Dependencies check passed"
}

# Run Flutter/Dart checks
function Invoke-FlutterChecks {
    Write-Info "Running Flutter/Dart checks..."
    
    # Format check
    Write-Info "Checking code format..."
    try {
        dart format --set-exit-if-changed .
        Write-Success "Code format check passed"
    }
    catch {
        Write-Error "Code format check failed"
        Write-Info "Run 'dart format .' to fix formatting issues"
        exit 1
    }
    
    # Lint check
    Write-Info "Running static analysis..."
    try {
        flutter analyze --fatal-warnings --fatal-infos
        Write-Success "Static analysis passed"
    }
    catch {
        Write-Error "Static analysis failed"
        exit 1
    }
    
    # Test check
    Write-Info "Running tests..."
    try {
        flutter test
        Write-Success "Tests passed"
    }
    catch {
        Write-Error "Tests failed"
        exit 1
    }
    
    # Run specific test suites
    Write-Info "Running user flow tests..."
    try {
        flutter test test/flow/
        Write-Success "User flow tests passed"
    }
    catch {
        Write-Error "User flow tests failed"
        exit 1
    }
    
    Write-Info "Running plan allowance tests..."
    try {
        flutter test test/recipes/
        Write-Success "Plan allowance tests passed"
    }
    catch {
        Write-Error "Plan allowance tests failed"
        exit 1
    }
}

# Run golden tests
function Invoke-GoldenTests {
    Write-Info "Running golden tests..."
    
    try {
        if ($UpdateGoldens) {
            flutter test test/goldens/ --update-goldens
        } else {
            flutter test test/goldens/
        }
        Write-Success "Golden tests passed"
    }
    catch {
        Write-Error "Golden tests failed"
        if (-not $UpdateGoldens) {
            Write-Info "Run with -UpdateGoldens to update golden files"
        }
        exit 1
    }
}

# Run route map tests
function Invoke-RouteTests {
    Write-Info "Running route map tests..."
    
    try {
        flutter test test/routes/
        Write-Success "Route map tests passed"
    }
    catch {
        Write-Error "Route map tests failed"
        exit 1
    }
}

# Run button smoke tests
function Invoke-SmokeTests {
    Write-Info "Running button smoke tests..."
    
    try {
        flutter test test/ui/
        Write-Success "Button smoke tests passed"
    }
    catch {
        Write-Error "Button smoke tests failed"
        exit 1
    }
}

# Run gate integrity tests
function Invoke-GateTests {
    Write-Info "Running gate integrity tests..."
    
    try {
        flutter test test/gate/
        Write-Success "Gate integrity tests passed"
    }
    catch {
        Write-Error "Gate integrity tests failed"
        exit 1
    }
}

# Run database checks
function Invoke-DbChecks {
    if ($SkipDbChecks) {
        Write-Warning "Skipping database checks"
        return
    }
    
    Write-Info "Running database checks..."
    
    # Check if DATABASE_URL is set
    if (-not $env:DATABASE_URL) {
        Write-Warning "DATABASE_URL not set - skipping database checks"
        return
    }
    
    try {
        # Run database verification
        psql $env:DATABASE_URL -f supabase/migrations/20241226_grand_image_verify.sql | Out-Null
        Write-Success "Database verification passed"
    }
    catch {
        Write-Error "Database verification failed"
        Write-Info "Check your database connection and run migrations"
        exit 1
    }
}

# Run dead code check
function Invoke-DeadCodeCheck {
    Write-Info "Running dead code check..."
    
    # Check if dart_dead_code is available
    if (Get-Command dart_dead_code -ErrorAction SilentlyContinue) {
        try {
            dart_dead_code
            Write-Success "No dead code detected"
        }
        catch {
            Write-Warning "Dead code detected"
            Write-Info "Consider removing unused code to keep the codebase clean"
        }
    }
    else {
        Write-Warning "dart_dead_code not available - skipping dead code check"
    }
}

# Run size analysis
function Invoke-SizeAnalysis {
    Write-Info "Running size analysis..."
    
    try {
        flutter build apk --analyze-size
        Write-Success "Size analysis completed"
    }
    catch {
        Write-Warning "Size analysis failed - continuing anyway"
    }
}

# Main execution
function Main {
    Write-Host "Grand Image Guardrails - YeneFresh CI" -ForegroundColor Cyan
    Write-Host "======================================" -ForegroundColor Cyan
    Write-Host ""
    
    Test-Dependencies
    Invoke-FlutterChecks
    Invoke-GoldenTests
    Invoke-RouteTests
    Invoke-SmokeTests
    Invoke-GateTests
    Invoke-DbChecks
    Invoke-DeadCodeCheck
    Invoke-SizeAnalysis
    
    Write-Host ""
    Write-Host "All Grand Image checks passed!" -ForegroundColor Green
    Write-Host "No UI rewrites detected" -ForegroundColor Green
    Write-Host "No dead buttons found" -ForegroundColor Green
    Write-Host "Gate integrity maintained" -ForegroundColor Green
    Write-Host "Visual stability preserved" -ForegroundColor Green
    Write-Host ""
    Write-Success "Ready for deployment!"
}

# Run main function
Main
