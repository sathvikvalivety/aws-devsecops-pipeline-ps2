# demos/01-insecure-iac-scan.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 1: SHIFT-LEFT IAC STATIC ANALYSIS SCAN (INSECURE)    " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
checkov -d security-tests/phase1/insecure --framework terraform
