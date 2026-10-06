# demos/run-all-demos.ps1
# Master Automated Demonstration Runner for Hackathon Presentation
# Author: sathvik-devsecops

param (
    [switch]$Interactive = $false
)

$ErrorActionPreference = "Continue"

$demos = @(
    @{ Id="Demo 01"; Name="Insecure IaC Static Analysis Scan"; Script="01-insecure-iac-scan.ps1" },
    @{ Id="Demo 02"; Name="Hardcoded Secret Detection & Blocking"; Script="02-secret-scanning.ps1" },
    @{ Id="Demo 03"; Name="Remediated Secure IaC Scan (Checkov Pass)"; Script="03-remediated-iac-scan.ps1" },
    @{ Id="Demo 04"; Name="Secrets Manager 30-Day Auto-Rotation"; Script="04-secret-rotation.ps1" },
    @{ Id="Demo 05"; Name="AWS CodeBuild & Pipeline Shift-Left Gates"; Script="05-cicd-pipeline.ps1" },
    @{ Id="Demo 06"; Name="Amazon ECR Repository & Scan on Push"; Script="06-ecr-vulnerability-scan.ps1" },
    @{ Id="Demo 07"; Name="Container Vulnerability Gate Blocking (CVEs)"; Script="07-vulnerability-gate-blocked.ps1" },
    @{ Id="Demo 08"; Name="Remediated Container Workload Promotion"; Script="08-container-remediation.ps1" },
    @{ Id="Demo 09"; Name="Hardened Kubernetes Manifests (CIS PSS)"; Script="09-kubernetes-security.ps1" },
    @{ Id="Demo 10"; Name="Multi-Tier VPC Isolation & Security Groups"; Script="10-vpc-segmentation.ps1" },
    @{ Id="Demo 11"; Name="AWS Network Firewall Egress Rules & IaC"; Script="11-network-firewall.ps1" },
    @{ Id="Demo 12"; Name="SSM Patch Manager PCI-DSS Compliance Baseline"; Script="12-ssm-patch-compliance.ps1" },
    @{ Id="Demo 13"; Name="VPC Flow Logs Runtime Monitoring"; Script="13-vpc-flow-logs.ps1" },
    @{ Id="Demo 14"; Name="Runtime Threat Detection & SOAR Remediation"; Script="14-threat-remediation.ps1" },
    @{ Id="Demo 15"; Name="Forensic Preservation & Containment Rollback"; Script="15-forensic-collection-rollback.ps1" }
)

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   AWS DEVSECOPS MASTER DEMONSTRATION SUITE (15 DEMOS)     " -ForegroundColor Cyan
Write-Host "   Target: AWS Account 009160054307 | Profile: sathvik-dev  " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$results = @()

foreach ($d in $demos) {
    Write-Host "`n>>> RUNNING $($d.Id): $($d.Name)..." -ForegroundColor Yellow
    $startTime = Get-Date
    try {
        & "$PSScriptRoot\$($d.Script)"
        $status = "PASSED"
    } catch {
        Write-Host "[ERROR] $($_.Exception.Message)" -ForegroundColor Red
        $status = "FAILED"
    }
    $duration = [math]::Round(((Get-Date) - $startTime).TotalSeconds, 1)
    $results += [PSCustomObject]@{
        Id = $d.Id
        Demo = $d.Name
        Status = $status
        DurationSeconds = $duration
    }
    
    if ($Interactive) {
        Read-Host "Press Enter to continue to next demo..."
    }
}

Write-Host "`n============================================================" -ForegroundColor Cyan
Write-Host "   MASTER DEMONSTRATION SUITE EXECUTION SUMMARY             " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
$results | Format-Table -Property Id, Demo, Status, DurationSeconds -AutoSize

$passed = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
Write-Host "Execution Status: $passed / $($results.Count) Demonstrations Verified Successfully!" -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Cyan
