# demos/13-vpc-flow-logs.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 13: VPC FLOW LOGS NETWORK RUNTIME MONITORING          " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
aws ec2 describe-flow-logs --flow-log-ids fl-015a0f8e30012e5f8 --region us-east-1 --profile sathvik-dev
aws logs describe-log-groups --log-group-name-prefix /aws/vpc/sathvik_flow_logs --region us-east-1 --profile sathvik-dev
