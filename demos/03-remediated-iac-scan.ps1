# demos/03-remediated-iac-scan.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 3: REMEDIATED SECURE IAC (CHECKOV 100% PASS)          " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
checkov -d security-tests/phase1/secure --framework terraform
