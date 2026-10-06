# scripts/status.ps1 - Deployment Status Viewer
$ErrorActionPreference = "Continue"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEVSECOPS PIPELINE & INFRASTRUCTURE STATUS" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$stateFile = Join-Path (Split-Path $PSScriptRoot -Parent) "state\deployment-state.json"
if (Test-Path $stateFile) {
    $state = Get-Content $stateFile -Raw | ConvertFrom-Json
    Write-Host "Target Account:     $($state.Account)" -ForegroundColor Green
    Write-Host "Target Region:      $($state.Region)" -ForegroundColor Green
    Write-Host "Current Phase:      $($state.CurrentPhase)" -ForegroundColor Cyan
    Write-Host "Last Verified At:   $($state.LastVerifiedAt)" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "--- Phases ---" -ForegroundColor Yellow
    foreach ($prop in $state.Phases.PSObject.Properties) {
        $color = "Yellow"
        if ($prop.Value -eq "COMPLETED") { $color = "Green" }
        elseif ($prop.Value -eq "IN_PROGRESS") { $color = "Cyan" }
        elseif ($prop.Value -eq "FAILED") { $color = "Red" }
        Write-Host "  $($prop.Name.PadRight(35)): $($prop.Value)" -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "--- Tracked Resources ---" -ForegroundColor Yellow
    $resCount = 0
    foreach ($prop in $state.Resources.PSObject.Properties) {
        $resCount++
        Write-Host "  $($prop.Name): $($prop.Value)" -ForegroundColor White
    }
    if ($resCount -eq 0) {
        Write-Host "  (No infrastructure resources deployed yet)" -ForegroundColor DarkGray
    }
} else {
    Write-Host "[WARN] No state file found at $stateFile" -ForegroundColor Yellow
}
