# demos/09-kubernetes-security.ps1
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " DEMO 9: HARDENED KUBERNETES MANIFESTS & CIS COMPLIANCE     " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
checkov -d kubernetes --framework kubernetes
