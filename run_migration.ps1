# Safe Migration Runner for YeneFresh App
# This script runs the migration with proper error handling

param(
    [string]$DatabaseUrl = "postgresql://postgres:password@localhost:54322/postgres",
    [switch]$TestOnly = $false,
    [switch]$Force = $false
)

# Colors
$Red = "Red"
$Green = "Green"
$Yellow = "Yellow"
$Cyan = "Cyan"

function Write-Info {
    param([string]$Message)
    Write-Host "✅ [INFO] $Message" -ForegroundColor $Green
}

function Write-Warning {
    param([string]$Message)
    Write-Host "⚠️ [WARN] $Message" -ForegroundColor $Yellow
}

function Write-Error {
    param([string]$Message)
    Write-Host "❌ [ERROR] $Message" -ForegroundColor $Red
    exit 1
}

function Write-Step {
    param([string]$Message)
    Write-Host "➡️ $Message" -ForegroundColor $Cyan
}

function Test-DatabaseConnection {
    Write-Step "Testing database connection..."
    try {
        $testQuery = "SELECT 1 as test;"
        $result = psql $DatabaseUrl -c $testQuery -t -A
        if ($result -eq "1") {
            Write-Info "Database connection successful"
            return $true
        } else {
            Write-Error "Database connection failed - unexpected result: $result"
            return $false
        }
    } catch {
        Write-Error "Database connection failed: $($_.Exception.Message)"
        return $false
    }
}

function Backup-Database {
    if (-not $Force) {
        Write-Warning "This will DROP and recreate all tables. Use -Force to proceed."
        Write-Warning "Consider backing up your database first!"
        $confirm = Read-Host "Are you sure you want to continue? (yes/no)"
        if ($confirm -ne "yes") {
            Write-Info "Migration cancelled by user"
            exit 0
        }
    }
}

function Run-Migration {
    Write-Step "Running main migration..."
    try {
        psql $DatabaseUrl -f "sql/000_robust_migration.sql"
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Main migration completed successfully"
        } else {
            Write-Error "Main migration failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Main migration failed: $($_.Exception.Message)"
    }
}

function Test-Migration {
    Write-Step "Testing migration results..."
    try {
        psql $DatabaseUrl -f "sql/test_migration.sql"
        if ($LASTEXITCODE -eq 0) {
            Write-Info "Migration test completed successfully"
        } else {
            Write-Error "Migration test failed with exit code $LASTEXITCODE"
        }
    } catch {
        Write-Error "Migration test failed: $($_.Exception.Message)"
    }
}

function Show-Summary {
    Write-Info "=== Migration Summary ==="
    Write-Info "✅ Database connection verified"
    Write-Info "✅ Main migration completed"
    Write-Info "✅ Migration test passed"
    Write-Info ""
    Write-Info "Your YeneFresh database is ready!"
    Write-Info ""
    Write-Info "Next steps:"
    Write-Info "1. Run: flutter pub get"
    Write-Info "2. Run: flutter run"
    Write-Info "3. Test the app flow"
}

# Main execution
function Main {
    Write-Host "🚀 YeneFresh Database Migration" -ForegroundColor $Cyan
    Write-Host "================================" -ForegroundColor $Cyan
    Write-Host ""

    # Test database connection
    if (-not (Test-DatabaseConnection)) {
        Write-Error "Cannot proceed without database connection"
    }

    # Backup warning
    Backup-Database

    # Run migration
    Run-Migration

    # Test migration
    Test-Migration

    # Show summary
    Show-Summary
}

# Run main function
Main






