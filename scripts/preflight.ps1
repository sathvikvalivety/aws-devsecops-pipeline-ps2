# scripts/preflight.ps1 - Discovery & Permission Verification for sathvik-dev
$ErrorActionPreference = "Continue"
$Profile = "sathvik-dev"
$Region = "us-east-1"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PHASE 0: PREFLIGHT & PERMISSION DISCOVERY (Profile: $Profile)" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. AWS Identity Check
try {
    $identityJson = aws sts get-caller-identity --profile $Profile 2>$null
    if (-not $identityJson) {
        Write-Error "CRITICAL: Unable to get AWS caller identity with profile $Profile."
        exit 1
    }
    $identity = $identityJson | ConvertFrom-Json
} catch {
    Write-Error "CRITICAL: AWS CLI failed to run: $_"
    exit 1
}

$configuredRegion = aws configure get region --profile $Profile 2>$null
if (-not $configuredRegion) {
    $configuredRegion = $Region
}

Write-Host "ACCOUNT:            $($identity.Account)" -ForegroundColor Green
Write-Host "REGION:             $configuredRegion" -ForegroundColor Green
Write-Host "IDENTITY ARN:       $($identity.Arn)" -ForegroundColor Green
Write-Host "USER ID:            $($identity.UserId)" -ForegroundColor Green
Write-Host "IDENTITY TYPE:      IAM User (Administrator)" -ForegroundColor Green
Write-Host ""

# 2. Service Verification Matrix
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " TESTING PERMISSIONS ACROSS REQUIRED SERVICES" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$services = @(
    @{ Name = "IAM (ListRoles)"; Command = "aws iam list-roles --profile $Profile --max-items 1"; Phase = "Foundation" },
    @{ Name = "IAM (CreateRole Check)"; Command = "aws iam get-user --profile $Profile"; Phase = "Foundation" },
    @{ Name = "VPC / EC2 Network"; Command = "aws ec2 describe-vpcs --profile $Profile --region $configuredRegion --max-items 1"; Phase = "Phase 3 Network Security" },
    @{ Name = "Security Groups"; Command = "aws ec2 describe-security-groups --profile $Profile --region $configuredRegion --max-results 5"; Phase = "Phase 3 & 4 Isolation" },
    @{ Name = "Network ACLs"; Command = "aws ec2 describe-network-acls --profile $Profile --region $configuredRegion --max-results 5"; Phase = "Phase 3 Network Boundary" },
    @{ Name = "NAT Gateways"; Command = "aws ec2 describe-nat-gateways --profile $Profile --region $configuredRegion --max-results 5"; Phase = "Phase 3 Egress Routing" },
    @{ Name = "EC2 Compute"; Command = "aws ec2 describe-instances --profile $Profile --region $configuredRegion --max-items 1"; Phase = "Phase 2 & 3 EKS Nodes" },
    @{ Name = "EKS Clusters"; Command = "aws eks list-clusters --profile $Profile --region $configuredRegion"; Phase = "Phase 2 Container Security" },
    @{ Name = "ECR Repositories"; Command = "aws ecr describe-repositories --profile $Profile --region $configuredRegion"; Phase = "Phase 2 ECR Scanning" },
    @{ Name = "ECR Basic Scan"; Command = "aws ecr get-registry-scanning-configuration --profile $Profile --region $configuredRegion"; Phase = "Phase 2 Vulnerability Scanning" },
    @{ Name = "Inspector v2"; Command = "aws inspector2 batch-get-account-status --profile $Profile --region $configuredRegion"; Phase = "Phase 2 Enhanced Scanning" },
    @{ Name = "CodeBuild Projects"; Command = "aws codebuild list-projects --profile $Profile --region $configuredRegion"; Phase = "Phase 1 Shift-Left IaC" },
    @{ Name = "CodePipeline"; Command = "aws codepipeline list-pipelines --profile $Profile --region $configuredRegion"; Phase = "Phase 1 IaC Pipeline" },
    @{ Name = "Lambda Functions"; Command = "aws lambda list-functions --profile $Profile --region $configuredRegion --max-items 2"; Phase = "Phase 1 Rotation & Phase 4 SOAR" },
    @{ Name = "S3 Buckets"; Command = "aws s3api list-buckets --profile $Profile"; Phase = "Phase 1 Pipeline & Phase 4 Forensics" },
    @{ Name = "KMS Aliases"; Command = "aws kms list-aliases --profile $Profile --region $configuredRegion --limit 2"; Phase = "Phase 1 & 4 Encryption" },
    @{ Name = "Secrets Manager"; Command = "aws secretsmanager list-secrets --profile $Profile --region $configuredRegion --max-results 2"; Phase = "Phase 1 Secret Governance" },
    @{ Name = "SSM Agent/Info"; Command = "aws ssm describe-instance-information --profile $Profile --region $configuredRegion --max-results 5"; Phase = "Phase 3 & 4 Host Management" },
    @{ Name = "SSM Patch Baselines"; Command = "aws ssm describe-patch-baselines --profile $Profile --region $configuredRegion --max-results 2"; Phase = "Phase 3 Patch Compliance" },
    @{ Name = "GuardDuty Detectors"; Command = "aws guardduty list-detectors --profile $Profile --region $configuredRegion"; Phase = "Phase 4 Runtime Threat Detection" },
    @{ Name = "EventBridge Rules"; Command = "aws events list-rules --profile $Profile --region $configuredRegion --limit 2"; Phase = "Phase 4 SOAR Trigger" },
    @{ Name = "CloudWatch Logs"; Command = "aws logs describe-log-groups --profile $Profile --region $configuredRegion --limit 2"; Phase = "Audit Logging" },
    @{ Name = "CloudTrail Trails"; Command = "aws cloudtrail describe-trails --profile $Profile --region $configuredRegion"; Phase = "Audit Logging" },
    @{ Name = "Network Firewall"; Command = "aws network-firewall list-firewalls --profile $Profile --region $configuredRegion"; Phase = "Phase 3 Perimeter Defense" }
)

$availableServices = @()
$blockedServices = @()

foreach ($svc in $services) {
    Write-Host -NoNewline "Checking $($svc.Name)... "
    $cmdParts = $svc.Command -split " "
    $cmd = $cmdParts[0]
    $args = $cmdParts[1..($cmdParts.Length - 1)]
    
    $output = & $cmd $args 2>&1
    $exitCode = $LASTEXITCODE

    if ($exitCode -eq 0) {
        Write-Host "[AVAILABLE]" -ForegroundColor Green
        $availableServices += $svc.Name
    } else {
        if ($output -match "SubscriptionRequiredException") {
            Write-Host "[SUBSCRIPTION REQUIRED]" -ForegroundColor Yellow
            $blockedServices += [PSCustomObject]@{
                Service = $svc.Name
                Phase = $svc.Phase
                Status = "SUBSCRIPTION_REQUIRED"
                Error = "SubscriptionRequiredException: Service pending activation on new AWS account"
            }
        } else {
            Write-Host "[DENIED / ERROR]" -ForegroundColor Red
            $blockedServices += [PSCustomObject]@{
                Service = $svc.Name
                Phase = $svc.Phase
                Status = "DENIED"
                Error = "$output"
            }
        }
    }
}

Write-Host ""
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " SUMMARY DISCOVERY REPORT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "AVAILABLE SERVICES ($($availableServices.Count)/$($services.Count)):" -ForegroundColor Green
foreach ($s in $availableServices) {
    Write-Host "  + $s" -ForegroundColor Green
}

if ($blockedServices.Count -gt 0) {
    Write-Host "`nSERVICES WITH SUBSCRIPTION/RESTRICTIONS ($($blockedServices.Count)):" -ForegroundColor Yellow
    foreach ($b in $blockedServices) {
        Write-Host "  - $($b.Service) ($($b.Phase)): $($b.Status)" -ForegroundColor Yellow
        Write-Host "    Reason: $($b.Error)" -ForegroundColor DarkGray
    }
}

Write-Host "============================================================" -ForegroundColor Cyan
