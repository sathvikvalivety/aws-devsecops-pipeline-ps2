# security-tests/phase1/insecure/insecure_resources.tf
# DELIBERATELY INSECURE TERRAFORM SAMPLES FOR SHIFT-LEFT GATE TESTING
# WARNING: NEVER DEPLOY OR APPLY THIS FILE

terraform {
  required_version = ">= 1.5.0"
}

# 1. Insecure Public S3 Bucket (Checkov CKV_AWS_18, CKV_AWS_19, CKV_AWS_20, CKV_AWS_144, CKV_AWS_145)
resource "aws_s3_bucket" "insecure_bucket" {
  bucket = "sathvik-insecure-test-bucket-do-not-deploy"
  # Missing encryption
  # Missing versioning
  # Missing logging
}

resource "aws_s3_bucket_acl" "insecure_acl" {
  bucket = aws_s3_bucket.insecure_bucket.id
  acl    = "public-read" # Critical violation
}

# 2. Insecure Security Group with 0.0.0.0/0 SSH open (Checkov CKV_AWS_24, CKV_AWS_260)
resource "aws_security_group" "insecure_sg" {
  name        = "sathvik_insecure_sg"
  description = "Insecure SG with world open SSH"
  vpc_id      = "vpc-12345678"

  ingress {
    description = "World open SSH - CRITICAL SECURITY FLAW"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Critical violation
  }

  ingress {
    description = "World open Telnet"
    from_port   = 23
    to_port     = 23
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Critical violation
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
