# Automated DevSecOps Pipeline & Runtime Threat Detection Framework
## Comprehensive Technical Architecture Specification

**AWS Account ID:** `009160054307`  
**Primary Region:** `us-east-1`  
**IAM Role / User:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Compliance Standards:** PCI-DSS v4.0, CIS AWS Foundations Benchmark, CIS Docker Benchmark  

---

## 1. System Overview

This architecture implements an end-to-end cloud-native security automation framework for fintech and payment processing workloads on AWS. The design implements a continuous security lifecycle based on the **DETECT → DECIDE → ENFORCE → VERIFY** operational paradigm across four dedicated phases:

1. **Shift-Left IaC & Secret Security:** Security scanning at the earliest pipeline stages preventing insecure infrastructure and static credentials from reaching deployment.
2. **Container Security & Vulnerability Gating:** Immutable container builds, dependency vulnerability scanning, and hard blocking gates stopping vulnerable container images before deployment.
3. **Network Perimeter & SSM Patch Compliance:** Multi-tier VPC isolation, egress stateful inspection rules, and zero-day patch automation for PCI-DSS compliance.
4. **Runtime Threat Detection & SOAR Remediation:** Full-packet VPC Flow Logs capture, near-real-time threat event routing via EventBridge, automated host isolation via zero-traffic Security Groups, live volatile forensic capture, and cryptographic evidence preservation.

---

## 2. Component Architecture Breakdown

```
+----------------------------------------------------------------------------------------------------+
|                                    AWS CLOUD (009160054307)                                        |
|                                                                                                    |
|  [PHASE 1: CI/CD PIPELINE]                                                                         |
|  CodePipeline -> CodeBuild -> Checkov (IaC) & detect-secrets                                        |
|      |                                                                                             |
|      v                                                                                             |
|  Secrets Manager (sathvik_payment_db_credentials) <--- Lambda Rotation (sathvik_secret_rotation)    |
|                                                                                                    |
|  [PHASE 2: CONTAINER REGISTRY & GATES]                                                             |
|  Docker Multi-Stage Build -> Trivy Vulnerability Gate (0 High/0 Critical) -> ECR Scan on Push       |
|      |                                                                                             |
|      v                                                                                             |
|  Amazon ECS / EKS Cluster (sathvik-cluster) [Non-root UID 10001, Read-only Root, PSS Restricted]   |
|                                                                                                    |
|  [PHASE 3: NETWORK ISOLATION & SSM]                                                                |
|  VPC: sathvik_vpc (10.50.0.0/16)                                                                   |
|    |-- Public Subnets (10.50.1.0/24, 10.50.2.0/24) -> IGW                                         |
|    |-- Private App Subnets (10.50.10.0/24, 10.50.20.0/24) -> sathvik_app_sg (Port 8000 only)      |
|    |-- Private DB Subnets (10.50.30.0/24) -> sathvik_db_sg (Port 5432 from App SG only)            |
|    |-- Inspection Subnet (10.50.40.0/24) -> Network Firewall IaC (Domain Filter & Suricata IPS)    |
|  SSM Patch Baseline: pb-0ff7e6df7ee92f06d (0-Day Auto-Approval for Critical CVEs)                  |
|                                                                                                    |
|  [PHASE 4: RUNTIME DETECTION & SOAR REMEDIATION]                                                   |
|  VPC Flow Logs -> /aws/vpc/sathvik_flow_logs                                                       |
|  Threat Event -> EventBridge (sathvik_threat_detection_rule)                                       |
|      |                                                                                             |
|      v                                                                                             |
|  SOAR Lambda (sathvik_soar_remediation)                                                            |
|    |-- 1. Snapshot original Security Groups                                                        |
|    |-- 2. Sever network: Attach sathvik_quarantine_sg (0 Ingress / 0 Egress)                        |
|    |-- 3. Tag instance: IncidentStatus=QUARANTINED                                                 |
|    |-- 4. Execute SSM Run Command (sathvik-forensic-collection)                                     |
|    |-- 5. Upload evidence bundle to S3 (sathvik-forensics-009160054307)                            |
|           Encrypted via KMS CMK (alias/sathvik_kms_key)                                            |
|    |-- 6. Safe Rollback Engine (scripts/rollback-quarantine.ps1)                                   |
+----------------------------------------------------------------------------------------------------+
```

---

## 3. Trust Boundaries & Network Flow

| Tier | Subnet CIDR | Ingress Policy | Egress Policy |
|---|---|---|---|
| **Public Edge** | `10.50.1.0/24`, `10.50.2.0/24` | 80/443 from Internet | Forward to Private App |
| **Private Workload** | `10.50.10.0/24`, `10.50.20.0/24` | 8000 from Internal Edge | 443 to AWS VPC Endpoints |
| **Private Database** | `10.50.30.0/24` | 5432 from App SG only | Deny All |
| **Inspection Tier** | `10.50.40.0/24` | All Egress Traffic | Filtered Outbound (Approved Domains) |
| **Quarantine Zone** | Any Subnet | **DENY ALL (0 rules)** | **DENY ALL (0 rules)** |

---

## 4. Cryptographic Key Architecture

All sensitive workloads and evidence stores utilize envelope encryption:
- **KMS Key ID:** `7905802c-d140-43d8-b64b-396b766b8e73`
- **Alias:** `alias/sathvik_kms_key`
- **Key Spec:** Symmetric Default (`AES_256_GCM`)
- **Protected Resources:**
  - Forensic Evidence Bucket: `sathvik-forensics-009160054307`
  - Secrets Manager DB Credentials: `sathvik_payment_db_credentials`
  - CloudWatch Log Streams & Flow Logs
