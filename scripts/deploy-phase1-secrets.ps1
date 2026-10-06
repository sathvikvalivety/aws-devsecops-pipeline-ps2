# scripts/deploy-phase1-secrets.ps1 - Provision Secrets Manager & 30-Day Rotation
$ErrorActionPreference = "Continue"
$Profile = "sathvik-dev"
$Region = "us-east-1"
$RoleName = "sathvik_rotation_lambda_role"
$FunctionName = "sathvik_secret_rotation"
$SecretName = "sathvik_payment_db_credentials"

Write-Host "============================================================" -ForegroundColor Cyan
Write-Host " PHASE 1: SECRETS MANAGER & AUTOMATED ROTATION DEPLOYMENT" -ForegroundColor Cyan
Write-Host "============================================================" -ForegroundColor Cyan

$tempDir = Join-Path $PSScriptRoot "..\state\tmp"
if (-not (Test-Path $tempDir)) { New-Item -ItemType Directory -Path $tempDir -Force | Out-Null }

# 1. Write trust policy & permissions policy files
$trustPolicyFile = Join-Path $tempDir "lambda-trust.json"
@'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
'@ | Set-Content -Path $trustPolicyFile -Encoding UTF8

$lambdaPolicyFile = Join-Path $tempDir "lambda-policy.json"
@'
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
        "secretsmanager:DescribeSecret",
        "secretsmanager:GetSecretValue",
        "secretsmanager:PutSecretValue",
        "secretsmanager:UpdateSecretVersionStage"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetRandomPassword"
      ],
      "Resource": "*"
    }
  ]
}
'@ | Set-Content -Path $lambdaPolicyFile -Encoding UTF8

# 1. Verify / Create IAM Role for Lambda
Write-Host "`n[1/6] Configuring IAM Role for Secret Rotation Lambda..." -ForegroundColor Yellow
$roleCheck = aws iam get-role --role-name $RoleName --profile $Profile 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating IAM role: $RoleName..." -ForegroundColor Cyan
    aws iam create-role --role-name $RoleName --assume-role-policy-document "file://$trustPolicyFile" --profile $Profile | Out-Null
    Start-Sleep -Seconds 5
} else {
    Write-Host "IAM role $RoleName already exists." -ForegroundColor Green
}

aws iam put-role-policy --role-name $RoleName --policy-name "${RoleName}_policy" --policy-document "file://$lambdaPolicyFile" --profile $Profile | Out-Null
Write-Host "[OK] IAM role policy attached." -ForegroundColor Green

# 2. Package and Deploy Lambda Function
Write-Host "`n[2/6] Packaging and Deploying Lambda Function: $FunctionName..." -ForegroundColor Yellow
$roleArn = (aws iam get-role --role-name $RoleName --profile $Profile | ConvertFrom-Json).Role.Arn

# Wait for IAM role propagation
Write-Host "Waiting 10s for IAM role propagation..." -ForegroundColor DarkGray
Start-Sleep -Seconds 10

$fnCheck = aws lambda get-function --function-name $FunctionName --profile $Profile --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Lambda function: $FunctionName..." -ForegroundColor Cyan
    aws lambda create-function `
        --function-name $FunctionName `
        --runtime python3.11 `
        --role $roleArn `
        --handler lambda_function.lambda_handler `
        --zip-file "fileb://lambda/secret_rotation/function.zip" `
        --description "Automated 30-day database secret rotation function" `
        --timeout 60 `
        --profile $Profile `
        --region $Region | Out-Null
    Start-Sleep -Seconds 5
} else {
    Write-Host "Updating existing Lambda function code..." -ForegroundColor Cyan
    aws lambda update-function-code `
        --function-name $FunctionName `
        --zip-file "fileb://lambda/secret_rotation/function.zip" `
        --profile $Profile `
        --region $Region | Out-Null
    Start-Sleep -Seconds 5
}

# Grant Secrets Manager permission to invoke Lambda
Write-Host "Granting Secrets Manager invocation permission..." -ForegroundColor Cyan
aws lambda add-permission `
    --function-name $FunctionName `
    --statement-id "SecretsManagerInvokeAccess" `
    --action "lambda:InvokeFunction" `
    --principal "secretsmanager.amazonaws.com" `
    --profile $Profile `
    --region $Region 2>$null | Out-Null

$fnArn = (aws lambda get-function --function-name $FunctionName --profile $Profile --region $Region | ConvertFrom-Json).Configuration.FunctionArn
Write-Host "[OK] Lambda function ready: $fnArn" -ForegroundColor Green

# 3. Create Secrets Manager Secret
Write-Host "`n[3/6] Configuring AWS Secrets Manager Secret: $SecretName..." -ForegroundColor Yellow
$secretPayloadFile = Join-Path $tempDir "initial-secret.json"
@'
{
  "username": "sathvik_dbadmin",
  "engine": "postgres",
  "host": "sathvik-payment-db.internal",
  "port": 5432,
  "password": "InitialSecurePassword987!#%",
  "system": "payment-api"
}
'@ | Set-Content -Path $secretPayloadFile -Encoding UTF8

$secCheck = aws secretsmanager describe-secret --secret-id $SecretName --profile $Profile --region $Region 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Creating Secret in AWS Secrets Manager..." -ForegroundColor Cyan
    aws secretsmanager create-secret `
        --name $SecretName `
        --description "Payment API production database credential with automated 30-day rotation" `
        --secret-string "file://$secretPayloadFile" `
        --tags Key=Project,Value=DevSecOpsCybersecurityHackathon Key=Owner,Value=DevSecOps Key=Prefix,Value=sathvik `
        --profile $Profile `
        --region $Region | Out-Null
} else {
    Write-Host "Secret $SecretName already exists in Secrets Manager." -ForegroundColor Green
}

# 4. Configure Automatic 30-Day Rotation
Write-Host "`n[4/6] Enabling 30-Day Automatic Rotation on $SecretName..." -ForegroundColor Yellow
aws secretsmanager rotate-secret `
    --secret-id $SecretName `
    --rotation-lambda-arn $fnArn `
    --rotation-rules AutomaticallyAfterDays=30 `
    --profile $Profile `
    --region $Region | Out-Null

Start-Sleep -Seconds 5

# 5. Verify Secret & Rotation Status
Write-Host "`n[5/6] Verifying Secret & Rotation Configuration..." -ForegroundColor Yellow
$secretDesc = aws secretsmanager describe-secret --secret-id $SecretName --profile $Profile --region $Region | ConvertFrom-Json
Write-Host "Secret ARN:         $($secretDesc.ARN)" -ForegroundColor Green
Write-Host "Rotation Enabled:   $($secretDesc.RotationEnabled)" -ForegroundColor Green
Write-Host "Rotation Lambda:    $($secretDesc.RotationLambdaARN)" -ForegroundColor Green
Write-Host "Rotation Interval:  $($secretDesc.RotationRules.AutomaticallyAfterDays) days" -ForegroundColor Green
Write-Host "Last Rotated Date:  $($secretDesc.LastRotatedDate)" -ForegroundColor Green

# 6. Test Runtime Application Retrieval (Without Printing Value)
Write-Host "`n[6/6] Testing Secure Application Retrieval..." -ForegroundColor Yellow
$appRetrieval = aws secretsmanager get-secret-value --secret-id $SecretName --profile $Profile --region $Region | ConvertFrom-Json
if ($appRetrieval.SecretString) {
    Write-Host "[PASS] Application successfully retrieved secret payload (Length: $($appRetrieval.SecretString.Length) chars)." -ForegroundColor Green
    Write-Host "[AUDIT] Secret value is protected and NOT printed to console." -ForegroundColor Green
}

Write-Host "`n[COMPLETED] Phase 1 Secrets Manager & 30-Day Rotation Successfully Configured!" -ForegroundColor Green
