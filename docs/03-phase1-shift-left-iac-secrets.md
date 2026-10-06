# Phase 1: Shift-Left IaC Security & Secret Management

**AWS Account:** `009160054307` | **Region:** `us-east-1` | **Profile:** `sathvik-dev`

---

## 1. Problem Statement & Objectives
Static infrastructure declarations and committed application code frequently introduce vulnerabilities and credential leaks before deployment. In Phase 1, automated gates shift security left into the developer feedback loop and CI/CD pipeline, guaranteeing that insecure resources and hardcoded secrets never reach cloud environments.

---

## 2. Shift-Left Tooling & Implementation

### Checkov Static Analysis
- **Tool Version:** Checkov 3.3.23
- **Framework:** Terraform & CloudFormation
- **Insecure Demonstration:** Scanned [`security-tests/phase1/insecure/insecure_resources.tf`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/security-tests/phase1/insecure/insecure_resources.tf). Caught 12 High/Critical violations (unencrypted S3 bucket, open 0.0.0.0/0 ingress SG, unencrypted EBS volume, unencrypted RDS instance). Pipeline blocked.
- **Remediated Demonstration:** Scanned [`security-tests/phase1/secure/secure_resources.tf`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/security-tests/phase1/secure/secure_resources.tf). Enforced SSE-KMS CMK encryption, TLS policy enforcement, private security groups, and automated backups. 20 passed, 0 failed.

### detect-secrets Credential Protection
- **Tool Version:** detect-secrets 1.5.52
- **Insecure Demonstration:** Scanned [`security-tests/secrets/fake_credentials.py`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/security-tests/secrets/fake_credentials.py). Flagged 5 hardcoded secrets (AWS Access Keys, Secret Keys, DB passwords, JWT tokens).
- **Remediated Demonstration:** Scanned [`security-tests/secrets/clean_code.py`](file:///E:/pdfs/notes/4-1/dscc/labexam%20ps2/security-tests/secrets/clean_code.py). Uses dynamic AWS Secrets Manager API retrieval at runtime. Zero secrets found.

---

## 3. Real AWS Services Deployed

### AWS Secrets Manager & Automated Lambda Rotation
- **Secret ARN:** `arn:aws:secretsmanager:us-east-1:009160054307:secret:sathvik_payment_db_credentials-bhIsEP`
- **Rotation Frequency:** 30 Days (`AutomaticallyAfterDays=30`)
- **Rotation Lambda:** `arn:aws:lambda:us-east-1:009160054307:function:sathvik_secret_rotation`
- **4-Step Protocol Executed Live:**
  1. `createSecret`: Generated new cryptographic password and staged as `AWSPENDING`.
  2. `setSecret`: Updated database authentication credentials securely.
  3. `testSecret`: Validated database login with the pending credential version.
  4. `finishSecret`: Promoted `AWSPENDING` to `AWSCURRENT` version.
  - Verification: CloudWatch Logs confirmed seamless rotation with zero plaintext leaks.

### AWS CodeBuild & AWS CodePipeline
- **CodeBuild Project:** `arn:aws:codebuild:us-east-1:009160054307:project/sathvik-iac-scan`
- **CodePipeline Pipeline:** `arn:aws:codepipeline:us-east-1:009160054307:sathvik-devsecops-pipeline`
- **Artifact Bucket:** `sathvik-pipeline-009160054307`
- **Buildspecs:** `build/buildspec-iac-scan.yml` and `build/buildspec-iac-scan-failing.yml`
- **Local Runner:** `pipeline/run-ci-pipeline.ps1` mirrors the 4-stage pipeline execution with automated exit codes.

---

## 4. Evidence Artifacts
- `evidence/phase1/phase1_02_checkov_failure.png`
- `evidence/phase1/phase1_03_secret_scan_failure.png`
- `evidence/phase1/phase1_04_checkov_success.png`
- `evidence/phase1/phase1_05_secret_scan_success.png`
- `evidence/phase1/phase1_06_secrets_manager.png`
- `evidence/phase1/phase1_07_rotation_configuration.png`
- `evidence/phase1/phase1_08_rotation_lambda.png`
- `evidence/phase1/phase1_09_rotation_cloudwatch_logs.png`
- `evidence/phase1/phase1_10_codebuild_project.png`
- `evidence/phase1/phase1_11_codepipeline.png`
- `evidence/phase1/phase1_12_failed_pipeline.png`
- `evidence/phase1/phase1_13_successful_pipeline.png`
