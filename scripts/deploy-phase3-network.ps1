# scripts/deploy-phase3-network.ps1
# Provisions Real AWS Network Infrastructure for Phase 3
# Author: sathvik-devsecops

param (
    [string]$Profile = "sathvik-dev",
    [string]$Region = "us-east-1"
)

$ErrorActionPreference = "Stop"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host "   PROVISIONING AWS NETWORK INFRASTRUCTURE (PHASE 3)        " -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

# 1. Create VPC
Write-Host "[1/7] Creating VPC 10.50.0.0/16..." -ForegroundColor Cyan
$vpcJson = aws ec2 create-vpc --cidr-block 10.50.0.0/16 --tag-specifications "ResourceType=vpc,Tags=[{Key=Name,Value=sathvik_vpc},{Key=Project,Value=sathvik-devsecops},{Key=Compliance,Value=PCI-DSS}]" --region $Region --profile $Profile | ConvertFrom-Json
$vpcId = $vpcJson.Vpc.VpcId
Write-Host "  Created VPC: $vpcId" -ForegroundColor Green

aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-hostnames "{\"Value\":true}" --region $Region --profile $Profile
aws ec2 modify-vpc-attribute --vpc-id $vpcId --enable-dns-support "{\"Value\":true}" --region $Region --profile $Profile

# 2. Create Internet Gateway
Write-Host "[2/7] Creating Internet Gateway..." -ForegroundColor Cyan
$igwJson = aws ec2 create-internet-gateway --tag-specifications "ResourceType=internet-gateway,Tags=[{Key=Name,Value=sathvik_igw},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
$igwId = $igwJson.InternetGateway.InternetGatewayId
aws ec2 attach-internet-gateway --vpc-id $vpcId --internet-gateway-id $igwId --region $Region --profile $Profile
Write-Host "  Attached IGW: $igwId to $vpcId" -ForegroundColor Green

# 3. Create Subnets
Write-Host "[3/7] Creating Multi-Tier Subnets..." -ForegroundColor Cyan
$subnets = @(
    @{ Name="sathvik_public_subnet_1a"; Cidr="10.50.1.0/24"; Az="us-east-1a"; Public=$true },
    @{ Name="sathvik_public_subnet_1b"; Cidr="10.50.2.0/24"; Az="us-east-1b"; Public=$true },
    @{ Name="sathvik_private_app_1a"; Cidr="10.50.10.0/24"; Az="us-east-1a"; Public=$false },
    @{ Name="sathvik_private_app_1b"; Cidr="10.50.20.0/24"; Az="us-east-1b"; Public=$false },
    @{ Name="sathvik_private_db_1a"; Cidr="10.50.30.0/24"; Az="us-east-1a"; Public=$false },
    @{ Name="sathvik_firewall_inspection_1a"; Cidr="10.50.40.0/24"; Az="us-east-1a"; Public=$false }
)

$subnetIds = @{}
foreach ($s in $subnets) {
    $snJson = aws ec2 create-subnet --vpc-id $vpcId --cidr-block $s.Cidr --availability-zone $s.Az --tag-specifications "ResourceType=subnet,Tags=[{Key=Name,Value=$($s.Name)},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
    $snId = $snJson.Subnet.SubnetId
    $subnetIds[$s.Name] = $snId
    Write-Host "  Subnet $($s.Name): $snId ($($s.Cidr) in $($s.Az))" -ForegroundColor Green
}

# 4. Create Route Tables
Write-Host "[4/7] Configuring Route Tables..." -ForegroundColor Cyan
# Public Route Table
$pubRtJson = aws ec2 create-route-table --vpc-id $vpcId --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=sathvik_public_rt},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
$pubRtId = $pubRtJson.RouteTable.RouteTableId
aws ec2 create-route --route-table-id $pubRtId --destination-cidr-block 0.0.0.0/0 --gateway-id $igwId --region $Region --profile $Profile | Out-Null
aws ec2 associate-route-table --subnet-id $subnetIds["sathvik_public_subnet_1a"] --route-table-id $pubRtId --region $Region --profile $Profile | Out-Null
aws ec2 associate-route-table --subnet-id $subnetIds["sathvik_public_subnet_1b"] --route-table-id $pubRtId --region $Region --profile $Profile | Out-Null
Write-Host "  Associated Public RT: $pubRtId (IGW: $igwId)" -ForegroundColor Green

# Private Route Table
$privRtJson = aws ec2 create-route-table --vpc-id $vpcId --tag-specifications "ResourceType=route-table,Tags=[{Key=Name,Value=sathvik_private_rt},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
$privRtId = $privRtJson.RouteTable.RouteTableId
aws ec2 associate-route-table --subnet-id $subnetIds["sathvik_private_app_1a"] --route-table-id $privRtId --region $Region --profile $Profile | Out-Null
aws ec2 associate-route-table --subnet-id $subnetIds["sathvik_private_app_1b"] --route-table-id $privRtId --region $Region --profile $Profile | Out-Null
aws ec2 associate-route-table --subnet-id $subnetIds["sathvik_private_db_1a"] --route-table-id $privRtId --region $Region --profile $Profile | Out-Null
Write-Host "  Associated Private RT: $privRtId" -ForegroundColor Green

# 5. Create Security Groups
Write-Host "[5/7] Creating Security Groups..." -ForegroundColor Cyan
# App SG
$appSgJson = aws ec2 create-security-group --group-name sathvik_app_sg --description "Workload application security group" --vpc-id $vpcId --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=sathvik_app_sg},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
$appSgId = $appSgJson.GroupId
aws ec2 authorize-security-group-ingress --group-id $appSgId --protocol tcp --port 8000 --cidr 10.50.0.0/16 --region $Region --profile $Profile | Out-Null
Write-Host "  Created sathvik_app_sg: $appSgId (Ingress 8000 VPC only)" -ForegroundColor Green

# DB SG
$dbSgJson = aws ec2 create-security-group --group-name sathvik_db_sg --description "Isolated database security group" --vpc-id $vpcId --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=sathvik_db_sg},{Key=Project,Value=sathvik-devsecops}]" --region $Region --profile $Profile | ConvertFrom-Json
$dbSgId = $dbSgJson.GroupId
aws ec2 authorize-security-group-ingress --group-id $dbSgId --protocol tcp --port 5432 --source-group $appSgId --region $Region --profile $Profile | Out-Null
Write-Host "  Created sathvik_db_sg: $dbSgId (Ingress 5432 from App SG only)" -ForegroundColor Green

# Quarantine SG (Strict Zero Ingress / Zero Egress)
$quarSgJson = aws ec2 create-security-group --group-name sathvik_quarantine_sg --description "SOAR Incident Response Quarantine SG - Zero Traffic" --vpc-id $vpcId --tag-specifications "ResourceType=security-group,Tags=[{Key=Name,Value=sathvik_quarantine_sg},{Key=Project,Value=sathvik-devsecops},{Key=Purpose,Value=SOAR-Isolation}]" --region $Region --profile $Profile | ConvertFrom-Json
$quarSgId = $quarSgJson.GroupId
# Revoke default outbound rule
aws ec2 revoke-security-group-egress --group-id $quarSgId --protocol -1 --cidr 0.0.0.0/0 --region $Region --profile $Profile | Out-Null
Write-Host "  Created sathvik_quarantine_sg: $quarSgId (Zero Ingress, Zero Egress)" -ForegroundColor Green

# 6. Save State
$netState = @{
    VpcId = $vpcId
    InternetGatewayId = $igwId
    Subnets = $subnetIds
    PublicRouteTableId = $pubRtId
    PrivateRouteTableId = $privRtId
    AppSecurityGroupId = $appSgId
    DbSecurityGroupId = $dbSgId
    QuarantineSecurityGroupId = $quarSgId
}
$netState | ConvertTo-Json -Depth 5 | Set-Content -Path "$PSScriptRoot\..\state\network-state.json" -Encoding utf8

Write-Host "============================================================" -ForegroundColor Green
Write-Host " [SUCCESS] Phase 3 Network Infrastructure Provisioned!      " -ForegroundColor Green
Write-Host " State saved to state/network-state.json                     " -ForegroundColor Green
Write-Host "============================================================" -ForegroundColor Green
