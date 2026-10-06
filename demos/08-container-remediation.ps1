# demos/08-container-remediation.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 8: REMEDIATED CONTAINER DEPLOYMENT PASSING GATE       " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
& "$PSScriptRoot\..\pipeline\vulnerability-gate.ps1" -Target "application"
aws ecs describe-task-definition --task-definition sathvik-payment-service:1 --region us-east-1 --profile sathvik-dev
