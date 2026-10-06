# demos/02-secret-scanning.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 2: HARDCODED SECRET DETECTION & PREVENTION GATES      " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
detect-secrets scan security-tests/secrets/fake_credentials.py
