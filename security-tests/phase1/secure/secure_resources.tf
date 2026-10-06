# security-tests/phase1/secure/secure_resources.tf
# REMEDIATED FULLY COMPLIANT SECURE TERRAFORM SAMPLES

terraform {
  required_version = ">= 1.5.0"
}

# 1. Remediated Secure S3 Bucket
resource "aws_s3_bucket" "secure_bucket" {
  #checkov:skip=CKV_AWS_18:Test bucket access logging disabled for isolated demonstration
  #checkov:skip=CKV_AWS_144:Cross-region replication not required for test environment
  #checkov:skip=CKV2_AWS_62:S3 event notifications not required for static test bucket
  bucket = "sathvik-secure-test-bucket-remediated"
}

resource "aws_s3_bucket_public_access_block" "secure_pab" {
  bucket = aws_s3_bucket.secure_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "secure_versioning" {
  bucket = aws_s3_bucket.secure_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secure_encryption" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
    }
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "secure_lifecycle" {
  bucket = aws_s3_bucket.secure_bucket.id

  rule {
    id     = "expire-old-versions"
    status = "Enabled"

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    noncurrent_version_expiration {
      noncurrent_days = 30
    }
  }
}

resource "aws_s3_bucket_policy" "secure_tls_only" {
  bucket = aws_s3_bucket.secure_bucket.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "EnforceTLSRequestsOnly"
        Effect    = "Deny"
        Principal = "*"
        Action    = "s3:*"
        Resource = [
          aws_s3_bucket.secure_bucket.arn,
          "${aws_s3_bucket.secure_bucket.arn}/*"
        ]
        Condition = {
          Bool = {
            "aws:SecureTransport" = "false"
          }
        }
      }
    ]
  })
}

# 2. Remediated Secure Security Group
resource "aws_security_group" "secure_sg" {
  #checkov:skip=CKV2_AWS_5:Standalone security group template for shift-left validation
  name        = "sathvik_secure_sg"
  description = "Secure SG with restricted VPC ingress and no public SSH"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "Allow inbound HTTPS from private VPC only"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow outbound HTTPS for secure dependencies"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
