# demos/12-ssm-patch-compliance.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 12: SSM PATCH MANAGER PCI-DSS COMPLIANCE BASELINE     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
aws ssm get-patch-baseline --baseline-id pb-0ff7e6df7ee92f06d --region us-east-1 --profile sathvik-dev
aws ssm describe-patch-groups --region us-east-1 --profile sathvik-dev
& "$PSScriptRoot\..\scripts\verify-phase3-compliance.ps1"
