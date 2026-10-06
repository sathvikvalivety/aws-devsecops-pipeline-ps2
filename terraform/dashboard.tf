# terraform/dashboard.tf
# AWS-Native DevSecOps Cloud Control Plane & Interactive Dashboard
# 100% Cloud-Native Execution Architecture (S3 + API Gateway + Lambda + SOAR)

# 1. S3 Bucket for Dashboard Static Hosting & Evidence
resource "aws_s3_bucket" "dashboard_bucket" {
  bucket        = "sathvik-devsecops-dashboard-${var.aws_account_id}"
  force_destroy = false

  tags = merge(local.common_tags, {
    Name = "sathvik-devsecops-dashboard-${var.aws_account_id}"
    Role = "ControlPlaneFrontend"
  })
}

resource "aws_s3_bucket_website_configuration" "dashboard_website" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "dashboard_public_access" {
  bucket = aws_s3_bucket.dashboard_bucket.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "dashboard_public_read" {
  bucket     = aws_s3_bucket.dashboard_bucket.id
  depends_on = [aws_s3_bucket_public_access_block.dashboard_public_access]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.dashboard_bucket.arn}/*"
      }
    ]
  })
}

# 2. IAM Role for Backend Lambda
resource "aws_iam_role" "dashboard_backend_role" {
  name = "sathvik_dashboard_backend_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action    = "sts:AssumeRole"
        Effect    = "Allow"
        Principal = { Service = "lambda.amazonaws.com" }
      }
    ]
  })

  tags = merge(local.common_tags, {
    Name = "sathvik_dashboard_backend_role"
    Role = "ControlPlaneBackendIAM"
  })
}

resource "aws_iam_role_policy" "dashboard_backend_policy" {
  name = "sathvik_dashboard_backend_policy"
  role = aws_iam_role.dashboard_backend_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogs"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogGroups"
        ]
        Resource = "*"
      },
      {
        Sid    = "EC2AndVPCControls"
        Effect = "Allow"
        Action = [
          "ec2:DescribeInstances",
          "ec2:ModifyInstanceAttribute",
          "ec2:CreateTags",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeVpcs",
          "ec2:DescribeSubnets",
          "ec2:DescribeRouteTables",
          "ec2:DescribeFlowLogs"
        ]
        Resource = "*"
      },
      {
        Sid    = "SecurityServicesTelemetry"
        Effect = "Allow"
        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:ListSecretVersionIds",
          "secretsmanager:RotateSecret",
          "ecr:DescribeRepositories",
          "ecr:GetRegistryScanningConfiguration",
          "ecr:DescribeImages",
          "ecs:DescribeTaskDefinition",
          "ssm:GetPatchBaseline",
          "ssm:DescribePatchGroups",
          "ssm:GetDocument",
          "ssm:DescribeInstanceInformation",
          "codepipeline:GetPipelineState",
          "codepipeline:StartPipelineExecution",
          "codebuild:StartBuild",
          "codebuild:BatchGetBuilds",
          "codebuild:BatchGetProjects",
          "events:PutEvents"
        ]
        Resource = "*"
      },
      {
        Sid    = "S3AndForensics"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          aws_s3_bucket.dashboard_bucket.arn,
          "${aws_s3_bucket.dashboard_bucket.arn}/*",
          "arn:aws:s3:::sathvik-forensics-${var.aws_account_id}",
          "arn:aws:s3:::sathvik-forensics-${var.aws_account_id}/*"
        ]
      },
      {
        Sid    = "KMSAccess"
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      },
      {
        Sid    = "InvokeRemediationLambda"
        Effect = "Allow"
        Action = [
          "lambda:InvokeFunction"
        ]
        Resource = "*"
      }
    ]
  })
}

# 3. Backend Lambda Function
resource "aws_lambda_function" "dashboard_backend" {
  function_name = "sathvik_dashboard_backend"
  role          = aws_iam_role.dashboard_backend_role.arn
  handler       = "lambda_function.lambda_handler"
  runtime       = "python3.11"
  timeout       = 30
  memory_size   = 256

  # Deployed via zip packaging
  filename         = "${path.module}/../state/dashboard_backend.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/dashboard_backend/lambda_function.py")

  environment {
    variables = {
      AWS_ACCOUNT_ID     = var.aws_account_id
      TARGET_INSTANCE_ID = "i-002cd1c4695a9efb2"
      PRODUCTION_SG      = "sg-0401849589b4d299e"
      QUARANTINE_SG      = "sg-0a0a38a865302e6bc"
      FORENSICS_BUCKET   = "sathvik-forensics-${var.aws_account_id}"
      DASHBOARD_BUCKET   = aws_s3_bucket.dashboard_bucket.bucket
    }
  }

  tags = merge(local.common_tags, {
    Name = "sathvik_dashboard_backend"
    Role = "ControlPlaneBackend"
  })
}

# 4. API Gateway HTTP API v2
resource "aws_apigatewayv2_api" "dashboard_api" {
  name          = "sathvik-devsecops-api"
  protocol_type = "HTTP"
  description   = "API Gateway for sathvik DevSecOps Cyber Command Center"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["*"]
  }

  tags = merge(local.common_tags, {
    Name = "sathvik-devsecops-api"
    Role = "ControlPlaneAPIGateway"
  })
}

resource "aws_apigatewayv2_integration" "lambda_integration" {
  api_id                 = aws_apigatewayv2_api.dashboard_api.id
  integration_type       = "AWS_PROXY"
  integration_method     = "POST"
  integration_uri        = aws_lambda_function.dashboard_backend.invoke_arn
  payload_format_version = "2.0"
}

resource "aws_apigatewayv2_route" "default_route" {
  api_id    = aws_apigatewayv2_api.dashboard_api.id
  route_key = "$default"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_route" "proxy_route" {
  api_id    = aws_apigatewayv2_api.dashboard_api.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.lambda_integration.id}"
}

resource "aws_apigatewayv2_stage" "default_stage" {
  api_id      = aws_apigatewayv2_api.dashboard_api.id
  name        = "$default"
  auto_deploy = true
}

resource "aws_lambda_permission" "apigw_lambda_permission" {
  statement_id  = "apigateway-invoke-permission"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.dashboard_backend.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_apigatewayv2_api.dashboard_api.execution_arn}/*"
}

# 5. Outputs
output "dashboard_s3_website_url" {
  description = "Public URL for DevSecOps Dashboard frontend hosted in S3"
  value       = aws_s3_bucket_website_configuration.dashboard_website.website_endpoint
}

output "dashboard_api_gateway_url" {
  description = "Base API Gateway endpoint executing all DevSecOps controls and demos"
  value       = aws_apigatewayv2_api.dashboard_api.api_endpoint
}
