# scripts/bootstrap.ps1 - Environment Bootstrapper
$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEVSECOPS ENVIRONMENT BOOTSTRAP" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Verify Session
& "$PSScriptRoot\check-session.ps1"
if ($LASTEXITCODE -ne 0) {
    Write-Host "[FAIL] Cannot bootstrap without an active AWS session." -ForegroundColor Red
    exit 1
}

# 2. Check Local Dependencies
Write-Host "`n--- Checking Local Tools ---" -ForegroundColor Yellow
$tools = @("aws", "terraform", "git", "python", "docker", "kubectl")
foreach ($tool in $tools) {
    $cmd = Get-Command $tool -ErrorAction SilentlyContinue
    if ($cmd) {
        Write-Host "[OK] Found $tool at $($cmd.Source)" -ForegroundColor Green
    } else {
        Write-Host "[WARN] Tool '$tool' not found on PATH" -ForegroundColor Yellow
    }
}

# 3. Initialize State Tracking
$stateDir = Join-Path (Split-Path $PSScriptRoot -Parent) "state"
if (-not (Test-Path $stateDir)) {
    New-Item -ItemType Directory -Path $stateDir -Force | Out-Null
}

$stateFile = Join-Path $stateDir "deployment-state.json"
if (-not (Test-Path $stateFile)) {
    $initialState = @{
        Account = "913786626696"
        Region = "us-east-1"
        InitializedAt = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssZ")
        CurrentPhase = "PHASE 0: Discovery"
        Phases = @{
            Phase0_Discovery = "COMPLETED"
            Phase1_ShiftLeftIaC = "PENDING"
            Phase2_ContainerSecurity = "PENDING"
            Phase3_NetworkAndSSM = "PENDING"
            Phase4_RuntimeThreatRemediation = "PENDING"
        }
        Resources = @{}
        LastVerifiedAt = $null
    }
    $initialState | ConvertTo-Json -Depth 5 | Set-Content -Path $stateFile -Encoding UTF8
    Write-Host "`n[OK] Initialized state file: $stateFile" -ForegroundColor Green
} else {
    Write-Host "`n[INFO] Found existing state file: $stateFile" -ForegroundColor Cyan
}

Write-Host "`n[DONE] Bootstrap completed successfully." -ForegroundColor Green
