# Hackathon Viva & Presentation Defense Guide

**Project:** Automated DevSecOps Pipeline & Infrastructure Security Compliance for Cloud-Native Workloads  
**Account:** `009160054307` | **Region:** `us-east-1`  
**Author:** sathvik-devsecops  

---

## 1. High-Impact 2-Minute Pitch

> "Judges, our project addresses the critical security challenge in modern fintech: **how to maintain rapid cloud delivery without compromising on regulatory compliance or runtime defense**. We implemented a real, production-ready AWS DevSecOps framework structured around the principle of **DETECT → DECIDE → ENFORCE → VERIFY**.
>
> In Phase 1, our CI/CD pipeline shifts security left: Checkov blocks insecure IaC before provisioning, detect-secrets prevents credential leaks, and AWS Secrets Manager automates database password rotation every 30 days via Lambda without downtime.
> In Phase 2, container images undergo automated vulnerability gating in Amazon ECR; builds with High or Critical CVEs are blocked, while hardened, non-root containers are certified for Amazon ECS/EKS.
> In Phase 3, we provisioned a dedicated multi-tier VPC isolating payment databases from the internet, with AWS Network Firewall egress controls and an SSM Patch Baseline enforcing 0-day security updates under PCI-DSS Requirement 6.2.
> In Phase 4, we built a fully autonomous SOAR engine: when runtime threats like port scanning or C2 traffic are detected, EventBridge triggers a Lambda that severs network traffic via a zero-traffic Quarantine Security Group, captures live volatile memory forensics via SSM, encrypts evidence with a Customer Managed KMS key in S3, and supports automated rollback. Every single resource is real, verifiable, and running in AWS Account 009160054307."

---

## 2. Anticipated Viva Technical Questions & Answers

### Q1: Why use Quarantine Security Groups instead of terminating or stopping the EC2 instance immediately?
**Answer:** Terminating or stopping a compromised host destroys volatile forensic memory (RAM), active network socket states (`netstat`), and injected processes residing only in memory. By attaching a zero-ingress, zero-egress Security Group (`sathvik_quarantine_sg`), we instantly sever all network communication to stop lateral movement, while keeping the machine running so our SSM Run Command can acquire live forensic triage artifacts.

### Q2: How does the Secrets Manager 30-day rotation work without interrupting payment processing?
**Answer:** AWS Secrets Manager uses a 4-step Lambda rotation protocol (`createSecret`, `setSecret`, `testSecret`, `finishSecret`). A pending secret (`AWSPENDING`) is created and tested against the database first. Once verified, the version label is atomically swapped to `AWSCURRENT`. The application pulls credentials dynamically at runtime using IAM authentication, ensuring zero downtime.

### Q3: How do you enforce Pod Security Standards in Kubernetes / Container runtimes?
**Answer:** In `kubernetes/deployment.yaml`, we enforce `securityContext` at both Pod and Container levels: `runAsNonRoot: true`, `runAsUser: 10001`, `allowPrivilegeEscalation: false`, `readOnlyRootFilesystem: true`, and Linux capabilities `drop: ["ALL"]`. Checkov validates these manifests against the CIS Kubernetes Benchmark with 0 violations.

### Q4: Why is Customer Managed KMS Key (CMK) superior to AWS Managed Keys for evidence storage?
**Answer:** AWS Managed Keys do not permit custom key policies, cross-account access restrictions, or explicit key disablement during an ongoing breach investigation. A Customer Managed Key (`alias/sathvik_kms_key`) allows cryptographic separation of duties: only the SOAR Lambda and forensic auditor roles possess decryption permissions, preventing rogue IAM administrators from tampering with chain-of-custody evidence.

### Q5: What happens if an automated containment action isolates a false positive?
**Answer:** Operational resilience is built in. Before applying `sathvik_quarantine_sg`, the SOAR Lambda preserves the original Security Group IDs in incident metadata. Our automated rollback engine (`scripts/rollback-quarantine.ps1`) verifies the forensic integrity in S3 and restores original production security groups in seconds, minimizing operational disruption.
