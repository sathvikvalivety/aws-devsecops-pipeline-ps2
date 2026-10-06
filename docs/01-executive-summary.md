# Executive Summary: Automated DevSecOps Pipeline & Infrastructure Security Compliance

**Project Name:** Automated DevSecOps Pipeline & Infrastructure Security Compliance for Cloud-Native Workloads  
**Target AWS Account:** `009160054307`  
**Primary Region:** `us-east-1`  
**IAM User / Identity:** `arn:aws:iam::009160054307:user/sathvik-cli`  
**Profile:** `sathvik-dev`  
**Author:** sathvik-devsecops  

---

## 1. Problem Context & Purpose

Modern financial technology (fintech) payment platforms hosted on cloud-native architectures face severe, evolving cyber risks. Misconfigured Infrastructure as Code (IaC), leaked credentials in code repositories, unpatched container dependencies, overly permissive network routing, and undetected runtime intrusion can lead to catastrophic data breaches and severe regulatory penalties under PCI-DSS v4.0.

This project delivers a **fully automated, real AWS cloud security framework** designed to prevent, detect, isolate, and remediate cybersecurity vulnerabilities across every phase of the software delivery lifecycle.

---

## 2. Core Operational Paradigm: DETECT -> DECIDE -> ENFORCE -> VERIFY

The implementation strictly enforces this paradigm across all four operational phases:

1. **Phase 1: Shift-Left IaC Security & Secret Management**
   - **DETECT:** Checkov scans Terraform templates for CIS AWS Benchmark violations; `detect-secrets` parses commits for API keys and plaintext credentials.
   - **DECIDE:** Build policies evaluate thresholds (0 High, 0 Critical, 0 hardcoded secrets allowed).
   - **ENFORCE:** AWS CodeBuild & CodePipeline halt immediately on non-compliant code. Secrets Manager automates database password rotation every 30 days via Lambda without downtime.
   - **VERIFY:** Real test cases demonstrate pipeline failure on insecure resources and 100% pass on remediated templates.

2. **Phase 2: Container Security & Vulnerability Scanning**
   - **DETECT:** Amazon ECR scan on push and Trivy dependency/config scanning inspect container layers and base images.
   - **DECIDE:** Automated Vulnerability Gate halts deployment if any HIGH or CRITICAL CVEs are detected.
   - **ENFORCE:** Hardened multi-stage Docker builds strip compilers and root privileges (running strictly as UID 10001). Kubernetes and Amazon ECS enforce Restricted Pod Security Standards.
   - **VERIFY:** Demonstrated blocking of vulnerable container and certified deployment of remediated image.

3. **Phase 3: Network Security Boundaries & SSM Compliance**
   - **DETECT:** SSM Patch Manager scans host operating systems against the `sathvik_pci_patch_baseline`.
   - **DECIDE:** PCI-DSS Requirement 6.2 mandates 0-day auto-approval for Critical and Important security patches.
   - **ENFORCE:** Multi-tier VPC (`10.50.0.0/16`) segregates workloads into private isolated subnets with zero direct routes to the Internet. Custom Security Groups strictly restrict ingress/egress.
   - **VERIFY:** Automated PCI-DSS compliance auditor certifies 5/5 network and patch controls (100% score).

4. **Phase 4: Runtime Threat Detection & SOAR Remediation**
   - **DETECT:** VPC Flow Logs record all network packets to CloudWatch Logs; EventBridge ingests threat alerts (e.g. port scans, unauthorized outbound C2 traffic).
   - **DECIDE:** Severity scoring dynamically selects containment strategy (HIGH/CRITICAL triggers immediate network severance).
   - **ENFORCE:** SOAR Lambda dynamically replaces instance Security Groups with `sathvik_quarantine_sg` (zero ingress, zero egress), completely cutting off network lateral movement while preserving volatile memory.
   - **VERIFY:** SSM Run Command acquires live volatile memory, socket, and process artifacts, uploading encrypted bundles to an S3 bucket protected with a Customer Managed KMS Key (`alias/sathvik_kms_key`). Rollback engine verifies safe operational restoration.
