# demos/11-network-firewall.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 11: AWS NETWORK FIREWALL EGRESS RULES & CMK ENCRYPTION" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
checkov -d sathvik-devsecops/terraform/modules/network-firewall --framework terraform
