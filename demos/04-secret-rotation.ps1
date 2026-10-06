# demos/04-secret-rotation.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 4: AWS SECRETS MANAGER 30-DAY AUTOMATED ROTATION     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
aws secretsmanager describe-secret --secret-id sathvik_payment_db_credentials --region us-east-1 --profile sathvik-dev
