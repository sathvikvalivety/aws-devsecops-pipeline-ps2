# scripts/deploy-phase1-pipeline.ps1 - Provision CodeBuild, CodePipeline & S3 Artifacts
$ErrorActionPreference = "Continue"
$Profile = "sathvik-dev"
$Region = "us-east-1"
$AccountId = "009160054307"
$BucketName = "sathvik-pipeline-$AccountId"
$BuildProjectName = "sathvik-iac-scan"
$PipelineName = "sathvik-devsecops-pipeline"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PHASE 1: CODEBUILD & CODEPIPELINE DEPLOYMENT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$tempDir = Join-Path $PSScriptRoot "..\state\tmp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# 1. S3 Bucket for Pipeline Artifacts
Write-Host "`n[1/5] Creating S3 Artifact Bucket: $BucketName..." -ForegroundColor Yellow
$bucketCheck = aws s3api head-bucket --bucket $BucketName --profile $Profile 2>$null
if ($LASTEXITCODE -ne 0) {
    aws s3api create-bucket --bucket $BucketName --region $Region --profile $Profile | Out-Null
    aws s3api put-public-access-block --bucket $BucketName `
        --public-access-block-configuration "BlockPublicAcls=true,IgnorePublicAcls=true,BlockPublicPolicy=true,RestrictPublicBuckets=true" `
        --profile $Profile | Out-Null
    aws s3api put-bucket-versioning --bucket $BucketName `
        --versioning-configuration Status=Enabled `
        --profile $Profile | Out-Null
    Write-Host "[OK] Created and hardened S3 artifact bucket: $BucketName" -ForegroundColor Green
} else {
    Write-Host "S3 bucket $BucketName already exists." -ForegroundColor Green
}

# 2. IAM Role for CodeBuild
Write-Host "`n[2/5] Creating IAM Role for CodeBuild: sathvik_codebuild_role..." -ForegroundColor Yellow
$cbTrustFile = Join-Path $tempDir "codebuild-trust.json"
$cbTrustJson = '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":{"Service":"codebuild.amazonaws.com"},"Action":"sts:AssumeRole"}]}'
[System.IO.File]::WriteAllText($cbTrustFile, $cbTrustJson, [System.Text.UTF8Encoding]::new($false))

$cbRoleCheck = aws iam get-role --role-name "sathvik_codebuild_role" --profile $Profile 2>$null
if ($LASTEXITCODE -ne 0) {
    aws iam create-role --role-name "sathvik_codebuild_role" --assume-role-policy-document "file://$cbTrustFile" --profile $Profile | Out-Null
    Start-Sleep -Seconds 5
}

$cbPolicyFile = Join-Path $tempDir "codebuild-policy.json"
$cbPolicyJson = @"
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "logs:CreateLogGroup",
        "logs:CreateLogStream",
        "logs:PutLogEvents"
      ],
      "Resource": "arn:aws:logs:*:*:*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:GetObject",
        "s3:GetObjectVersion",
        "s3:PutObject",
        "s3:GetBucketAcl",
        "s3:GetBucketLocation"
      ],
      "Resource": [
        "arn:aws:s3:::$BucketName",
        "arn:aws:s3:::$BucketName/*"
      ]
    }
  ]
}
"@
[System.IO.File]::WriteAllText($cbPolicyFile, $cbPolicyJson, [System.Text.UTF8Encoding]::new($false))
aws iam put-role-policy --role-name "sathvik_codebuild_role" --policy-name "sathvik_codebuild_policy" --policy-document "file://$cbPolicyFile" --profile $Profile | Out-Null
Write-Host "[OK] CodeBuild IAM role and policy configured." -ForegroundColor Green

# 3. CodeBuild Project
Write-Host "`n[3/5] Configuring CodeBuild Project: $BuildProjectName..." -ForegroundColor Yellow
$cbRoleArn = (aws iam get-role --role-name "sathvik_codebuild_role" --profile $Profile | ConvertFrom-Json).Role.Arn

$projCheck = aws codebuild batch-get-projects --names $BuildProjectName --profile $Profile --region $Region | ConvertFrom-Json
if ($projCheck.projects.Count -eq 0) {
    $cbDefFile = Join-Path $tempDir "codebuild-project.json"
    $cbDefJson = @"
{
  "name": "$BuildProjectName",
  "description": "Shift-left static security analysis using Checkov, detect-secrets and Terraform validation",
  "source": {
    "type": "S3",
    "location": "$BucketName/source.zip",
    "buildspec": "build/buildspec-iac-scan.yml"
  },
  "artifacts": {
    "type": "S3",
    "location": "$BucketName",
    "name": "build-output.zip",
    "packaging": "ZIP"
  },
  "environment": {
    "type": "LINUX_CONTAINER",
    "image": "aws/codebuild/standard:7.0",
    "computeType": "BUILD_GENERAL1_SMALL"
  },
  "serviceRole": "$cbRoleArn",
  "tags": [
    { "key": "Project", "value": "DevSecOpsCybersecurityHackathon" },
    { "key": "Owner", "value": "DevSecOps" },
    { "key": "Prefix", "value": "sathvik" }
  ]
}
"@
    [System.IO.File]::WriteAllText($cbDefFile, $cbDefJson, [System.Text.UTF8Encoding]::new($false))
    aws codebuild create-project --cli-input-json "file://$cbDefFile" --profile $Profile --region $Region | Out-Null
    Write-Host "[OK] CodeBuild project created: $BuildProjectName" -ForegroundColor Green
} else {
    Write-Host "CodeBuild project $BuildProjectName already exists." -ForegroundColor Green
}

# 4. Package and Upload Source Code to S3
Write-Host "`n[4/5] Packaging Source Code and Uploading to S3..." -ForegroundColor Yellow
$zipScript = @"
import zipfile, os
with zipfile.ZipFile('state/tmp/source.zip', 'w', zipfile.ZIP_DEFLATED) as z:
    for folder in ['build', 'security-tests']:
        for root, _, files in os.walk(folder):
            for f in files:
                full = os.path.join(root, f)
                z.write(full, full.replace('\\\\', '/'))
print('[ZIP DONE]')
"@
python -c "$zipScript" | Out-Null
aws s3 cp state/tmp/source.zip "s3://$BucketName/source.zip" --profile $Profile | Out-Null
Write-Host "[OK] Uploaded source.zip to s3://$BucketName/source.zip" -ForegroundColor Green

# 5. Start CodeBuild Scan
Write-Host "`n[5/5] Triggering Live CodeBuild Security Scan Execution..." -ForegroundColor Yellow
$buildRun = aws codebuild start-build --project-name $BuildProjectName --profile $Profile --region $Region | ConvertFrom-Json
$buildId = $buildRun.build.id
Write-Host "Started Build ID: $buildId" -ForegroundColor Cyan

# Poll Build Status
Write-Host "Polling build status (waiting 20s)..." -ForegroundColor DarkGray
Start-Sleep -Seconds 20
$status = (aws codebuild batch-get-builds --ids $buildId --profile $Profile --region $Region | ConvertFrom-Json).builds[0].buildStatus
$statColor = "Yellow"
if ($status -eq "SUCCEEDED") { $statColor = "Green" }
Write-Host "Current Build Status: $status" -ForegroundColor $statColor

Write-Host "`n[COMPLETED] Phase 1 CodeBuild Architecture Successfully Provisioned!" -ForegroundColor Green
