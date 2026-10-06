# scripts/check-session.ps1 - AWS Session Validation
$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " CHECKING AWS SESSION & CREDENTIAL STATUS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$expectedAccount = "913786626696"
$expectedRegion = "us-east-1"

try {
    $identityJson = aws sts get-caller-identity 2>$null
    if (-not $identityJson) {
        Write-Host "[FAIL] AWS credentials expired or invalid!" -ForegroundColor Red
        Write-Host "ACTION REQUIRED: Refresh your VocLabs credentials and retry." -ForegroundColor Yellow
        exit 1
    }

    $identity = $identityJson | ConvertFrom-Json
    $currentRegion = aws configure get region 2>$null
    if (-not $currentRegion) { $currentRegion = $expectedRegion }

    $accColor = "Red"
    if ($identity.Account -eq $expectedAccount) { $accColor = "Green" }
    $regColor = "Yellow"
    if ($currentRegion -eq $expectedRegion) { $regColor = "Green" }

    Write-Host "Account:       $($identity.Account)" -ForegroundColor $accColor
    Write-Host "Region:        $currentRegion" -ForegroundColor $regColor
    Write-Host "Identity ARN:  $($identity.Arn)" -ForegroundColor Green
    Write-Host "User ID:       $($identity.UserId)" -ForegroundColor Green

    if ($identity.Account -ne $expectedAccount) {
        Write-Host "[WARN] Detected Account ($($identity.Account)) differs from Expected ($expectedAccount)" -ForegroundColor Red
        exit 2
    }

    Write-Host "`n[PASS] AWS Session is active and authenticated to expected VocLabs account." -ForegroundColor Green
    exit 0
} catch {
    Write-Host "[ERROR] Failed to query AWS STS: $_" -ForegroundColor Red
    exit 1
}
