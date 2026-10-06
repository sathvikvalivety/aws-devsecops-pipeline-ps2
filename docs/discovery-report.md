# Phase 0: Discovery & Permission Matrix Report
**Project:** Automated DevSecOps Pipeline & Infrastructure Security Compliance for Cloud-Native Workloads  
**Date:** October 6, 2026  
**AWS Account ID:** `009160054307`  
**AWS Region:** `us-east-1`  
**Active AWS CLI Profile:** `sathvik-dev`  
**Identity ARN:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Identity Type:** IAM User (`sathvik-cli`)  
**Authorization Level:** AdministratorAccess (via IAM Group `sathvik-cli`)  

---

## 1. Executive Summary

A comprehensive, live preflight discovery scan was executed against AWS account `009160054307` in region `us-east-1` using the authorized CLI profile `sathvik-dev`.

The identity `sathvik-cli` possesses **full administrative permissions**, enabling direct creation of IAM roles, policies, VPCs, EKS clusters, ECR repositories, CodeBuild projects, CodePipeline pipelines, Lambda functions, Secrets Manager secrets, and SSM Patch Manager baselines.

---

## 2. Service Permission Matrix

| Service | API Operation Tested | Status | Phase | Error / Constraint | Architectural Strategy & Mitigation |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **IAM** | `iam:ListRoles` / `iam:CreateRole` | **AVAILABLE** | Foundation | None | Dedicated least-privilege roles for all components. |
| **VPC / Networking** | `ec2:DescribeVpcs` | **AVAILABLE** | Phase 3 | None | Full dedicated multi-tier VPC (`10.0.0.0/16`). |
| **Security Groups** | `ec2:DescribeSecurityGroups` | **AVAILABLE** | Phase 3 & 4 | None | Full stateful boundaries & `sathvik_quarantine_sg`. |
| **Network ACLs** | `ec2:DescribeNetworkAcls` | **AVAILABLE** | Phase 3 | None | Subnet boundary network defense. |
| **NAT Gateways** | `ec2:DescribeNatGateways` | **AVAILABLE** | Phase 3 | None | Single NAT Gateway for private egress. |
| **EC2 Compute** | `ec2:DescribeInstances` | **AVAILABLE** | Phase 2 & 3 | None | EC2 worker nodes for EKS and SSM management. |
| **Amazon EKS** | `eks:ListClusters` | **AVAILABLE** | Phase 2 | None | Kubernetes cluster control plane & worker node group. |
| **Amazon ECR** | `ecr:DescribeRepositories` | **AVAILABLE** | Phase 2 | None | Private image repository with scan on push. |
| **ECR Vulnerability Scan** | `ecr:GetRegistryScanningConfig`| **AVAILABLE** | Phase 2 | None | Automated CVE scanning on image push. |
| **Amazon Inspector v2** | `inspector2:BatchGetAccountStatus` | **RESTRICTED** | Phase 2 | `SubscriptionRequiredException` | Real ECR vulnerability scanning + Trivy CI gate. |
| **AWS CodeBuild** | `codebuild:ListProjects` | **AVAILABLE** | Phase 1 | None | AWS CodeBuild project for IaC and container checks. |
| **AWS CodePipeline** | `codepipeline:ListPipelines` | **AVAILABLE** | Phase 1 | None | AWS CodePipeline orchestrating shift-left pipeline. |
| **AWS Lambda** | `lambda:ListFunctions` | **AVAILABLE** | Phase 1 & 4 | None | 30-day secret rotation Lambda & SOAR remediation Lambda. |
| **Amazon S3** | `s3api:ListBuckets` | **AVAILABLE** | Phase 1 & 4 | None | Pipeline artifact storage & encrypted forensic bucket. |
| **AWS KMS** | `kms:ListAliases` | **AVAILABLE** | Phase 1 & 4 | None | Customer managed KMS key (`alias/sathvik_kms_key`). |
| **AWS Secrets Manager** | `secretsmanager:ListSecrets`| **AVAILABLE** | Phase 1 | None | Database credential with automated 30-day rotation. |
| **AWS Systems Manager** | `ssm:DescribeInstanceInfo` | **AVAILABLE** | Phase 3 & 4 | None | Session Manager & Run Command for forensic collection. |
| **SSM Patch Manager** | `ssm:DescribePatchBaselines`| **AVAILABLE** | Phase 3 | None | PCI-DSS aligned patch baseline and auditing. |
| **Amazon EventBridge** | `events:ListRules` | **AVAILABLE** | Phase 4 | None | Threat event router triggering SOAR Lambda. |
| **CloudWatch Logs** | `logs:DescribeLogGroups` | **AVAILABLE** | Audit | None | Centralized audit log groups (Lambda, VPC Flow, etc.). |
| **AWS CloudTrail** | `cloudtrail:DescribeTrails`| **AVAILABLE** | Audit | None | API auditing and event logging. |
| **Amazon GuardDuty** | `guardduty:ListDetectors` | **RESTRICTED** | Phase 4 | `SubscriptionRequiredException` | VPC Flow Logs + Synthetic SOAR Integration Test. |
| **AWS Network Firewall** | `network-firewall:ListFirewalls`| **RESTRICTED** | Phase 3 | `SubscriptionRequiredException` | Full AWS-ready Terraform module + VPC boundary defense. |

---

## 3. Implementation Order

1. **Phase 1: Shift-Left IaC Security & Secret Governance**
   - Terraform foundation (`sathvik_vpc`, KMS, S3, IAM roles)
   - CodeBuild project & CodePipeline configuration
   - Checkov, detect-secrets, Trivy static analysis
   - Secrets Manager secret with Lambda-based 30-day automated rotation
   - Demos 1, 2, 3 (Bad IaC fail, Fake secret fail, Fixed IaC pass)
2. **Phase 2: Container Security & EKS Workloads**
   - Amazon ECR repository (`sathvik-payment-service`)
   - Container vulnerability scanning & HIGH/CRITICAL gate logic
   - Demonstrations of blocked vulnerable image vs allowed secure image
   - Amazon EKS cluster & private worker node deployment
3. **Phase 3: Network Security Boundaries & SSM Compliance**
   - Dedicated VPC multi-tier subnets, NAT Gateway, Route Tables, and Network ACLs
   - AWS Network Firewall Terraform module (stateful domain filtering & IP drop)
   - SSM Agent integration on EC2 nodes & custom PCI-DSS Patch Baseline
   - Patch audit compliance demonstration
4. **Phase 4: Runtime Threat Remediation (SOAR) & Forensics**
   - VPC Flow Logs to CloudWatch Logs
   - EventBridge rules and synthetic SOAR test events
   - SOAR Remediation Lambda (`sathvik_soar_remediation`)
   - Quarantine Security Group (`sathvik_quarantine_sg`) with rollback automation
   - SSM Run Command live forensic acquisition
   - SSE-KMS encrypted S3 forensic bucket (`sathvik-forensics-009160054307`)
5. **Phase 5: Demonstrations, Evidence Collection & Documentation**
   - Execution of all 15 distinct demos
   - Real terminal screenshots & evidence capture into `evidence/`
   - Complete documentation set in `docs/` and architecture diagrams in `architecture/`
