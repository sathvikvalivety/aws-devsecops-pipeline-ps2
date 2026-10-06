# scripts/resume.ps1 - Session Resumption & State Synchronizer
$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEVSECOPS SESSION RESUME & STATE SYNC" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Verify caller identity
$identityJson = aws sts get-caller-identity 2>$null
if (-not $identityJson) {
    Write-Host "[FAIL] No valid AWS credentials found." -ForegroundColor Red
    Write-Host "Please refresh your AWS VocLabs credentials and retry." -ForegroundColor Yellow
    exit 1
}

$identity = $identityJson | ConvertFrom-Json
$expectedAccount = "913786626696"
$expectedRegion = "us-east-1"
$currentRegion = aws configure get region 2>$null
if (-not $currentRegion) { $currentRegion = $expectedRegion }

if ($identity.Account -ne $expectedAccount) {
    Write-Host "[FAIL] Wrong AWS Account! Expected $expectedAccount, got $($identity.Account)" -ForegroundColor Red
    exit 1
}

Write-Host "[PASS] Re-authenticated to Account: $($identity.Account)" -ForegroundColor Green
Write-Host "[PASS] Region: $currentRegion" -ForegroundColor Green
Write-Host "[PASS] Role ARN: $($identity.Arn)" -ForegroundColor Green

# 2. Check State File
$stateFile = Join-Path (Split-Path $PSScriptRoot -Parent) "state\deployment-state.json"
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    Write-Host "`n--- Current Deployment Status ---" -ForegroundColor Yellow
    Write-Host "Current Phase: $($state.CurrentPhase)" -ForegroundColor Cyan
    foreach ($prop in $state.Phases.PSObject.Properties) {
        $pColor = "Yellow"
        if ($prop.Value -eq "COMPLETED") { $pColor = "Green" }
        Write-Host "  $($prop.Name): $($prop.Value)" -ForegroundColor $pColor
    }
} else {
    Write-Host "[INFO] No existing deployment-state.json found. Run bootstrap.ps1 first." -ForegroundColor Yellow
}

# 3. Detect Terraform State
$tfStateFiles = Get-ChildItem -Path (Split-Path $PSScriptRoot -Parent) -Recurse -Filter "terraform.tfstate" -ErrorAction SilentlyContinue
if ($tfStateFiles) {
    Write-Host "`n--- Discovered Terraform State ---" -ForegroundColor Yellow
    foreach ($tf in $tfStateFiles) {
        Write-Host "  Found state: $($tf.FullName) ($($tf.Length) bytes)" -ForegroundColor Green
    }
} else {
    Write-Host "`n[INFO] No local terraform.tfstate detected yet." -ForegroundColor DarkGray
}

Write-Host "`n[READY] Session resumed successfully. You can continue safely." -ForegroundColor Green
