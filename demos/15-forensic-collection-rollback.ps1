# demos/15-forensic-collection-rollback.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 15: FORENSIC ARTIFACT PRESERVATION & SYSTEM ROLLBACK   " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
aws s3 ls s3://sathvik-forensics-009160054307/evidence/ --recursive --region us-east-1 --profile sathvik-dev
aws ssm get-document --name sathvik-forensic-collection --region us-east-1 --profile sathvik-dev
& "$PSScriptRoot\..\scripts\rollback-quarantine.ps1"
