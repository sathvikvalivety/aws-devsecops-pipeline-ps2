# Phase 1 Screenshot Evidence & Verification Catalog

**AWS Account ID:** `009160054307`  
**AWS Region:** `us-east-1`  
**IAM Identity:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Profile:** `sathvik-dev`  

---

## Screenshot Inventory

| Screenshot ID | Filename | Description | Status / Result | AWS Resource Verified |
|---|---|---|---|---|
| **Phase1-02** | `phase1_02_checkov_failure.png` | Checkov static analysis scan failing on insecure IaC with 12 critical/high violations | FAILED (Expected) | S3 unencrypted, SG 0.0.0.0/0 ingress, unencrypted EBS, unencrypted RDS |
| **Phase1-03** | `phase1_03_secret_scan_failure.png` | detect-secrets scanning hardcoded credentials in `fake_credentials.py` | FAILED (Expected) | 5 hardcoded secrets blocked (AWS keys, DB passwords, JWT secrets) |
| **Phase1-04** | `phase1_04_checkov_success.png` | Checkov static analysis scan passing with 20 passed, 0 failed on remediated IaC | PASSED | S3 SSE-KMS + SSL only, private SG, encrypted KMS RDS & EBS |
| **Phase1-05** | `phase1_05_secret_scan_success.png` | detect-secrets scanning remediated code fetching secrets dynamically at runtime | PASSED | Zero hardcoded credentials detected |
| **Phase1-06** | `phase1_06_secrets_manager.png` | AWS Secrets Manager secret metadata and ARN verification | VERIFIED | `arn:aws:secretsmanager:us-east-1:009160054307:secret:sathvik_payment_db_credentials-bhIsEP` |
| **Phase1-07** | `phase1_07_rotation_configuration.png` | Secrets Manager 30-day automatic rotation schedule configuration | VERIFIED | `AutomaticallyAfterDays=30`, Lambda rotation enabled |
| **Phase1-08** | `phase1_08_rotation_lambda.png` | Automated 4-step rotation Lambda function deployment | VERIFIED | `arn:aws:lambda:us-east-1:009160054307:function:sathvik_secret_rotation` |
| **Phase1-09** | `phase1_09_rotation_cloudwatch_logs.png` | CloudWatch Logs showing live execution of 4-step rotation protocol (`createSecret`, `setSecret`, `testSecret`, `finishSecret`) | PASSED | Version promoted to `AWSCURRENT` without plaintext leaks |
| **Phase1-10** | `phase1_10_codebuild_project.png` | AWS CodeBuild project metadata and configuration | VERIFIED | `arn:aws:codebuild:us-east-1:009160054307:project/sathvik-iac-scan` |
| **Phase1-11** | `phase1_11_codepipeline.png` | AWS CodePipeline CI/CD pipeline definition and stages | VERIFIED | `arn:aws:codepipeline:us-east-1:009160054307:sathvik-devsecops-pipeline` |
| **Phase1-12** | `phase1_12_failed_pipeline.png` | CI/CD pipeline execution blocking build on IaC & Secret violations | BLOCKED (Expected) | Pipeline gate enforces shift-left security failure |
| **Phase1-13** | `phase1_13_successful_pipeline.png` | CI/CD pipeline execution passing all 4 security stages on remediated code | PASSED | Workload certified to proceed to Container Build & ECR Push |

---

## Shift-Left Principles Demonstrated
1. **Zero Trust in IaC:** Insecure infrastructure is rejected before reaching CloudFormation or Terraform apply.
2. **Hardcoded Secrets Extinction:** Secret scanning prevents committing static credentials into git repositories.
3. **Automated Secret Lifecycle:** Secrets Manager rotates database credentials every 30 days automatically using an isolated Lambda function.
4. **Audit Trail & Observability:** All rotation events and pipeline security evaluations produce structured CloudWatch logs.
